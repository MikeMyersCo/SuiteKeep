//
//  DynamicFireSuiteApp.swift
//  SuiteKeep
//
//  Created by Mike Myers on 7/30/25.
//

import SwiftUI
import AVFoundation
import CloudKit
import UIKit

// MARK: - Keyboard Dismissal Extension
extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Extensions
extension CGFloat {
    var safeValue: CGFloat {
        return self.isFinite ? self : 0
    }
}

extension Notification.Name {
    static let concertDataSynced = Notification.Name("concertDataSynced")
    static let migrateLocalConcerts = Notification.Name("migrateLocalConcerts")
    static let memberListUpdated = Notification.Name("memberListUpdated")
}


// MARK: - Charity Data Model
struct SavedCharity: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var address: String
    var ein: String
    var contactName: String
    var contactInfo: String
    
    init(name: String, address: String, ein: String, contactName: String, contactInfo: String) {
        self.name = name
        self.address = address
        self.ein = ein
        self.contactName = contactName
        self.contactInfo = contactInfo
    }
}

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    weak var sharedSuiteManager: SharedSuiteManager?

    @Published var suiteName: String {
        didSet {
            // Only save locally if not in shared suite or if user is owner
            if !isInSharedSuite || sharedSuiteManager?.userRole == .owner {
                UserDefaults.standard.set(suiteName, forKey: "suiteName")
                NSUbiquitousKeyValueStore.default.set(suiteName, forKey: "suiteName")
                NSUbiquitousKeyValueStore.default.synchronize()
            }
        }
    }
    
    @Published var venueLocation: String {
        didSet {
            // Only save locally if not in shared suite or if user is owner
            if !isInSharedSuite || sharedSuiteManager?.userRole == .owner {
                UserDefaults.standard.set(venueLocation, forKey: "venueLocation")
                NSUbiquitousKeyValueStore.default.set(venueLocation, forKey: "venueLocation")
                NSUbiquitousKeyValueStore.default.synchronize()
            }
        }
    }

    @Published var familyTicketPrice: Double {
        didSet {
            // Only save locally if not in shared suite or if user is owner
            if !isInSharedSuite || sharedSuiteManager?.userRole == .owner {
                UserDefaults.standard.set(familyTicketPrice, forKey: "familyTicketPrice")
                NSUbiquitousKeyValueStore.default.set(familyTicketPrice, forKey: "familyTicketPrice")
                NSUbiquitousKeyValueStore.default.synchronize()
            }
        }
    }

    @Published var defaultSeatCost: Double {
        didSet {
            // Only save locally if not in shared suite or if user is owner
            if !isInSharedSuite || sharedSuiteManager?.userRole == .owner {
                UserDefaults.standard.set(defaultSeatCost, forKey: "defaultSeatCost")
                NSUbiquitousKeyValueStore.default.set(defaultSeatCost, forKey: "defaultSeatCost")
                NSUbiquitousKeyValueStore.default.synchronize()
            }
        }
    }
    
    @Published var enableMultiTenantSuites: Bool {
        didSet {
            UserDefaults.standard.set(enableMultiTenantSuites, forKey: "enableMultiTenantSuites")
            NSUbiquitousKeyValueStore.default.set(enableMultiTenantSuites, forKey: "enableMultiTenantSuites")
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }
    
    // MARK: - CloudSync Settings
    @Published var isCloudSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isCloudSyncEnabled, forKey: "isCloudSyncEnabled")
            if isCloudSyncEnabled {
                print("🔄 CloudSync enabled - will sync on next app launch")
            } else {
                print("⏸️ CloudSync disabled - app will work locally only")
            }
        }
    }
    
    @Published var cloudSyncStatus: CloudSyncStatus = .disabled
    @Published var lastSyncDate: Date?
    @Published var syncErrorMessage: String?

    // CloudSync Auto-enable Alert
    @Published var showCloudSyncEnabledAlert = false
    @Published var cloudSyncAlertTitle = ""
    @Published var cloudSyncAlertMessage = ""

    // Shared Suite Read-Only Alert
    @Published var showSharedSuiteReadOnlyAlert = false
    @Published var sharedSuiteAlertTitle = ""
    @Published var sharedSuiteAlertMessage = ""
    
    // MARK: - CloudSync Status
    enum CloudSyncStatus: String, CaseIterable {
        case disabled = "Disabled"
        case enabled = "Enabled" 
        case syncing = "Syncing..."
        case error = "Error"
        case offline = "Offline"
        
        var color: Color {
            switch self {
            case .disabled: return .gray
            case .enabled: return .green
            case .syncing: return .blue
            case .error: return .red
            case .offline: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .disabled: return "icloud.slash"
            case .enabled: return "icloud.fill"
            case .syncing: return "arrow.clockwise.icloud"
            case .error: return "icloud.slash.fill"
            case .offline: return "wifi.slash"
            }
        }
    }
    
    
    private var iCloudObserver: NSObjectProtocol?
    
    init() {
        // Load from local first
        self.suiteName = UserDefaults.standard.string(forKey: "suiteName") ?? "Fire Suite"
        self.venueLocation = UserDefaults.standard.string(forKey: "venueLocation") ?? "Ford Amphitheater"
        let storedFamilyPrice = UserDefaults.standard.double(forKey: "familyTicketPrice")
        self.familyTicketPrice = storedFamilyPrice == 0 ? 50.0 : storedFamilyPrice // Default to $50
        if let storedDefaultCost = UserDefaults.standard.object(forKey: "defaultSeatCost") as? Double {
            self.defaultSeatCost = storedDefaultCost // Use stored value (including 0)
        } else {
            self.defaultSeatCost = 25.0 // Default to $25 only if no value was ever set
        }
        
        // Load multi-tenant setting (defaults to false)
        self.enableMultiTenantSuites = UserDefaults.standard.bool(forKey: "enableMultiTenantSuites")
        
        // Load CloudSync setting (defaults to false)
        self.isCloudSyncEnabled = UserDefaults.standard.bool(forKey: "isCloudSyncEnabled")
        self.cloudSyncStatus = self.isCloudSyncEnabled ? .enabled : .disabled
        self.lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
        
        // Check iCloud for newer values
        if let iCloudSuiteName = NSUbiquitousKeyValueStore.default.string(forKey: "suiteName") {
            self.suiteName = iCloudSuiteName
        }
        if let iCloudVenueLocation = NSUbiquitousKeyValueStore.default.string(forKey: "venueLocation") {
            self.venueLocation = iCloudVenueLocation
        }
        let iCloudFamilyPrice = NSUbiquitousKeyValueStore.default.double(forKey: "familyTicketPrice")
        if iCloudFamilyPrice > 0 {
            self.familyTicketPrice = iCloudFamilyPrice
        }
        if let iCloudDefaultCost = NSUbiquitousKeyValueStore.default.object(forKey: "defaultSeatCost") as? Double {
            self.defaultSeatCost = iCloudDefaultCost // Use iCloud value (including 0)
        }
        
        // Check iCloud for multi-tenant setting
        let iCloudMultiTenant = NSUbiquitousKeyValueStore.default.object(forKey: "enableMultiTenantSuites")
        if iCloudMultiTenant != nil {
            self.enableMultiTenantSuites = NSUbiquitousKeyValueStore.default.bool(forKey: "enableMultiTenantSuites")
        }
        
        // Listen for iCloud changes
        iCloudObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            self?.syncFromiCloud()
        }
        
        NSUbiquitousKeyValueStore.default.synchronize()
        
        // Load saved charities
        loadSavedCharities()
    }

    // MARK: - Shared Suite Support
    private var isInSharedSuite: Bool {
        return sharedSuiteManager?.isSharedSuite == true
    }

    // Update settings from shared suite data
    func updateFromSharedSuite(_ suiteInfo: SharedSuiteInfo) {
        // Temporarily disable property observers by using direct assignment
        // We'll manually trigger objectWillChange at the end

        // Use a flag to prevent didSet from saving while updating
        let originalSharedSuiteManager = sharedSuiteManager
        sharedSuiteManager = nil // Temporarily disable to prevent saves

        suiteName = suiteInfo.suiteName
        venueLocation = suiteInfo.venueLocation

        if let familyPrice = suiteInfo.familyTicketPrice {
            familyTicketPrice = familyPrice
        }

        if let seatCost = suiteInfo.defaultSeatCost {
            defaultSeatCost = seatCost
        }

        // Restore the shared suite manager
        sharedSuiteManager = originalSharedSuiteManager

        // Manually trigger objectWillChange since we may have bypassed some didSet calls
        objectWillChange.send()
    }

    // For owners: update shared suite with current settings
    func syncToSharedSuite() {
        guard let sharedSuiteManager = sharedSuiteManager,
              sharedSuiteManager.userRole == .owner,
              var suiteInfo = sharedSuiteManager.currentSuiteInfo else { return }

        suiteInfo.familyTicketPrice = familyTicketPrice
        suiteInfo.defaultSeatCost = defaultSeatCost

        let suiteInfoToSync = suiteInfo
        Task {
            await sharedSuiteManager.updateSuiteSettings(suiteInfoToSync)
        }
    }
    
    deinit {
        if let observer = iCloudObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func syncFromiCloud() {
        if let iCloudSuiteName = NSUbiquitousKeyValueStore.default.string(forKey: "suiteName") {
            self.suiteName = iCloudSuiteName
        }
        if let iCloudVenueLocation = NSUbiquitousKeyValueStore.default.string(forKey: "venueLocation") {
            self.venueLocation = iCloudVenueLocation
        }
        let iCloudFamilyPrice = NSUbiquitousKeyValueStore.default.double(forKey: "familyTicketPrice")
        if iCloudFamilyPrice > 0 {
            self.familyTicketPrice = iCloudFamilyPrice
        }
        if let iCloudDefaultCost = NSUbiquitousKeyValueStore.default.object(forKey: "defaultSeatCost") as? Double {
            self.defaultSeatCost = iCloudDefaultCost
        }
        let iCloudMultiTenant = NSUbiquitousKeyValueStore.default.object(forKey: "enableMultiTenantSuites")
        if iCloudMultiTenant != nil {
            self.enableMultiTenantSuites = NSUbiquitousKeyValueStore.default.bool(forKey: "enableMultiTenantSuites")
        }
    }
    
    // MARK: - Charity Management
    @Published var savedCharities: [SavedCharity] = []
    
    func loadSavedCharities() {
        if let data = UserDefaults.standard.data(forKey: "SavedCharities"),
           let charities = try? JSONDecoder().decode([SavedCharity].self, from: data) {
            self.savedCharities = charities
        }
    }
    
    func saveCharity(_ charity: SavedCharity) {
        // Check if charity already exists (by name)
        if !savedCharities.contains(where: { $0.name.lowercased() == charity.name.lowercased() }) {
            savedCharities.append(charity)
            saveCharitiestoUserDefaults()
        }
    }
    
    func updateCharity(_ charity: SavedCharity) {
        if let index = savedCharities.firstIndex(where: { $0.id == charity.id }) {
            savedCharities[index] = charity
            saveCharitiestoUserDefaults()
        }
    }
    
    private func saveCharitiestoUserDefaults() {
        if let data = try? JSONEncoder().encode(savedCharities) {
            UserDefaults.standard.set(data, forKey: "SavedCharities")
        }
    }
    
    // MARK: - CloudSync Management Methods
    
    func enableCloudSync() {
        print("🔄 Enabling CloudSync...")
        cloudSyncStatus = .syncing
        
        // Enable the flag
        isCloudSyncEnabled = true
        
        // Post notification to trigger migration of existing concerts
        NotificationCenter.default.post(name: .migrateLocalConcerts, object: nil)
        
        // Update status
        cloudSyncStatus = .enabled
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
        
        print("✅ CloudSync enabled successfully")
    }
    
    func disableCloudSync() {
        print("⏸️ Disabling CloudSync...")
        cloudSyncStatus = .disabled
        
        // Disable the flag
        isCloudSyncEnabled = false
        
        // Clear sync data
        lastSyncDate = nil
        syncErrorMessage = nil
        UserDefaults.standard.removeObject(forKey: "lastSyncDate")
        
        print("✅ CloudSync disabled - app will work locally only")
    }

    func showCloudSyncEnabledForSharingAlert() {
        cloudSyncAlertTitle = "CloudSync Enabled"
        cloudSyncAlertMessage = "CloudSync has been automatically enabled to support your shared suite. This ensures your concert data stays synchronized with all suite members and is safely backed up to iCloud."
        showCloudSyncEnabledAlert = true
    }

    func showReadOnlySharedSuiteAlert() {
        sharedSuiteAlertTitle = "Welcome to Shared Suite"
        sharedSuiteAlertMessage = "You're now viewing a shared suite in read-only mode. You can see all concert data and seat statuses, but editing capabilities will be available in a future release. Stay tuned for collaboration features!"
        showSharedSuiteReadOnlyAlert = true
    }

    func updateSyncStatus(_ status: CloudSyncStatus, error: String? = nil) {
        cloudSyncStatus = status
        syncErrorMessage = error
        
        if status == .enabled {
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
        }
    }
}

// MARK: - Vibrant Color Theme
extension Color {
    // MARK: - 🎭 NOIR LUXE Design System
    // A sophisticated dark theme with warm champagne/gold accents
    // Inspired by luxury hospitality and premium concert experiences

    // Fire colors for firepit animation (fireOrange is defined in Assets.xcassets)
    static let fireRed = Color(red: 0.95, green: 0.25, blue: 0.15)
    static let fireYellow = Color(red: 1.0, green: 0.75, blue: 0.2)

    // MARK: - Primary Palette: Champagne & Noir
    // Primary accent: Warm champagne gold - evokes luxury, celebration
    static let champagne = Color(red: 0.87, green: 0.75, blue: 0.52)
    static let champagneLight = Color(red: 0.95, green: 0.88, blue: 0.72)
    static let champagneMuted = Color(red: 0.75, green: 0.65, blue: 0.45)

    // Deep noir backgrounds with warm undertones
    static let noirDeep = Color(red: 0.06, green: 0.05, blue: 0.07)
    static let noirCard = Color(red: 0.10, green: 0.09, blue: 0.11)
    static let noirElevated = Color(red: 0.14, green: 0.13, blue: 0.15)
    static let noirSurface = Color(red: 0.18, green: 0.16, blue: 0.19)

    // MARK: - Card Gradients: Rich & Dimensional
    static let cardPurple = LinearGradient(colors: [Color(red: 0.35, green: 0.22, blue: 0.45), Color(red: 0.45, green: 0.30, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardBlue = LinearGradient(colors: [Color(red: 0.18, green: 0.30, blue: 0.45), Color(red: 0.25, green: 0.40, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardTeal = LinearGradient(colors: [Color(red: 0.15, green: 0.35, blue: 0.38), Color(red: 0.20, green: 0.45, blue: 0.48)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardOrange = LinearGradient(colors: [Color(red: 0.55, green: 0.30, blue: 0.18), Color(red: 0.65, green: 0.40, blue: 0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardPink = LinearGradient(colors: [Color(red: 0.40, green: 0.25, blue: 0.35), Color(red: 0.50, green: 0.32, blue: 0.42)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardGreen = LinearGradient(colors: [Color(red: 0.18, green: 0.35, blue: 0.25), Color(red: 0.25, green: 0.45, blue: 0.32)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardIndigo = LinearGradient(colors: [Color(red: 0.22, green: 0.22, blue: 0.40), Color(red: 0.30, green: 0.30, blue: 0.50)], startPoint: .topLeading, endPoint: .bottomTrailing)

    // MARK: - Semantic Colors (Adaptive)
    static let modernBackground = Color(.systemBackground)
    static let modernSecondary = Color(.secondarySystemBackground)
    static let modernCard = Color(.tertiarySystemBackground)
    static let modernAccent = champagne // Champagne gold as primary accent
    static let modernText = Color(.label)
    static let modernTextSecondary = Color(.secondaryLabel)
    static let modernSuccess = Color(red: 0.35, green: 0.75, blue: 0.55) // Muted emerald
    static let modernWarning = Color(red: 0.90, green: 0.65, blue: 0.30) // Warm amber
    static let modernDanger = Color(red: 0.85, green: 0.35, blue: 0.40) // Dusty rose-red

    // MARK: - Dynamic Background Gradient
    static func dynamicGradient(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            // Sophisticated noir with subtle warm undertones
            return LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.06, blue: 0.10),
                    Color(red: 0.10, green: 0.08, blue: 0.12),
                    Color(red: 0.09, green: 0.07, blue: 0.11),
                    Color(red: 0.06, green: 0.05, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Warm cream with subtle champagne tint
            return LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.97, blue: 0.94),
                    Color(red: 0.99, green: 0.98, blue: 0.96),
                    Color(red: 0.97, green: 0.96, blue: 0.93),
                    Color(red: 0.96, green: 0.95, blue: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Seat Status Colors (Refined)
    static let seatAvailable = Color(red: 0.40, green: 0.75, blue: 0.55) // Muted emerald
    static let seatReserved = champagne // Champagne gold for reserved
    static let seatSold = Color(red: 0.45, green: 0.55, blue: 0.75) // Soft slate blue

    // MARK: - Glass Effect Colors (Warm-tinted)
    static let glassWhite = Color.white.opacity(0.08)
    static let glassBorder = champagne.opacity(0.15)
    static let glassHighlight = champagne.opacity(0.25)
    static let glassShimmer = champagne.opacity(0.4)

    // MARK: - Accent Palette (Sophisticated)
    static let liquidBlue = Color(red: 0.45, green: 0.60, blue: 0.80)
    static let liquidPurple = Color(red: 0.55, green: 0.45, blue: 0.70)
    static let liquidTeal = Color(red: 0.40, green: 0.65, blue: 0.65)
    static let liquidPink = Color(red: 0.75, green: 0.50, blue: 0.60)
    static let liquidGreen = Color(red: 0.45, green: 0.70, blue: 0.55)
    static let liquidOrange = champagne // Use champagne as orange accent

    // MARK: - Hero Gradient (Premium Header)
    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.20, green: 0.15, blue: 0.25),
            Color(red: 0.30, green: 0.22, blue: 0.35),
            Color(red: 0.25, green: 0.18, blue: 0.30)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Shimmer Effect Gradient
    static let shimmerGradient = LinearGradient(
        colors: [
            champagne.opacity(0),
            champagne.opacity(0.3),
            champagne.opacity(0)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Design System Constants
extension CGFloat {
    // Standardized corner radius scale
    static let radiusSmall: CGFloat = 12      // Buttons, small controls
    static let radiusMedium: CGFloat = 20     // Cards, containers
    static let radiusLarge: CGFloat = 24      // Large panels, modal sheets

    // Standardized spacing scale
    static let spacingTight: CGFloat = 8      // Within components
    static let spacingNormal: CGFloat = 16    // Related groups
    static let spacingSections: CGFloat = 24  // Major sections
}

// MARK: - Liquid Glass View Modifiers
struct LiquidGlassBackground: ViewModifier {
    var cornerRadius: CGFloat = .radiusMedium
    var intensity: Double = 0.15

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base ultra thin material
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    // Glass tint overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.glassWhite)

                    // Subtle gradient overlay for depth
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(intensity * 0.6),
                                    Color.clear,
                                    Color.black.opacity(intensity * 0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Border glow
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.glassBorder,
                                    Color.glassBorder.opacity(0.5),
                                    Color.glassBorder
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            .shadow(color: Color.black.opacity(0.05), radius: 40, x: 0, y: 20)
    }
}

struct LiquidGlassCard: ViewModifier {
    var accentColor: Color = .champagne
    var cornerRadius: CGFloat = .radiusLarge

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Noir base with warmth
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color(.tertiarySystemBackground))

                    // Subtle champagne accent gradient
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.08),
                                    accentColor.opacity(0.02),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Mesh gradient effect
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            RadialGradient(
                                colors: [
                                    accentColor.opacity(0.15),
                                    Color.clear
                                ],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 300
                            )
                        )

                    // Border with gradient
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.4),
                                    Color.glassHighlight,
                                    accentColor.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .drawingGroup()
            )
            .shadow(color: accentColor.opacity(0.15), radius: 15, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.1), radius: 30, x: 0, y: 15)
    }
}

struct LiquidGlassButton: ViewModifier {
    var accentColor: Color = .liquidBlue
    var isPressed: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: .radiusSmall)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: .radiusSmall)
                        .fill(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(isPressed ? 0.5 : 0.3),
                                    accentColor.opacity(isPressed ? 0.3 : 0.15)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    RoundedRectangle(cornerRadius: .radiusSmall)
                        .strokeBorder(accentColor.opacity(0.5), lineWidth: 1)
                }
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .shadow(color: accentColor.opacity(0.3), radius: isPressed ? 5 : 10, x: 0, y: isPressed ? 2 : 5)
    }
}

struct ShimmerEffect: ViewModifier {
    @State private var shimmerOffset: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.glassShimmer,
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .rotationEffect(.degrees(45))
                        .offset(x: shimmerOffset * geometry.size.width * 2)
                        .animation(
                            Animation.linear(duration: 2.5)
                                .repeatForever(autoreverses: false),
                            value: shimmerOffset
                        )
                }
                .clipped()
            )
            .onAppear {
                shimmerOffset = 1
            }
    }
}

// View extension for easy application
extension View {
    func liquidGlass(cornerRadius: CGFloat = .radiusMedium, intensity: Double = 0.15) -> some View {
        self.modifier(LiquidGlassBackground(cornerRadius: cornerRadius, intensity: intensity))
    }

    func liquidGlassCard(accentColor: Color = .liquidBlue, cornerRadius: CGFloat = .radiusLarge) -> some View {
        self.modifier(LiquidGlassCard(accentColor: accentColor, cornerRadius: cornerRadius))
    }

    func liquidGlassButton(accentColor: Color = .liquidBlue, isPressed: Bool = false) -> some View {
        self.modifier(LiquidGlassButton(accentColor: accentColor, isPressed: isPressed))
    }

    func shimmer() -> some View {
        self.modifier(ShimmerEffect())
    }

    // Smooth spring animation for all interactions
    func smoothSpring() -> Animation {
        .spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0)
    }

    // Fluid scale effect for interactive elements
    func fluidScale(isPressed: Bool) -> some View {
        self.scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
}

// MARK: - Animation Constants
extension Animation {
    // Standard animations for consistency
    static let standardSpring = Animation.spring(response: 0.4, dampingFraction: 0.75)
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let gentleSpring = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let standardEase = Animation.easeInOut(duration: 0.3)
    static let quickEase = Animation.easeInOut(duration: 0.15)
}

// MARK: - Haptic Feedback Manager
class HapticManager {
    static let shared = HapticManager()

    private init() {}

    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }

    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
        #endif
    }

    func selection() {
        #if canImport(UIKit)
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
        #endif
    }
}

// MARK: - Share Manager
@MainActor
class ShareManager: ObservableObject {
    static let shared = ShareManager()
    
    enum ShareFormat {
        case square      // 1:1 for Instagram feed
        case story       // 9:16 for Instagram/Snapchat stories
        case wide        // 16:9 for Twitter/Facebook
        case print       // High-res with contact details
        
        var size: CGSize {
            switch self {
            case .square: return CGSize(width: 1080, height: 1080)
            case .story: return CGSize(width: 1080, height: 1920)
            case .wide: return CGSize(width: 1920, height: 1080)
            case .print: return CGSize(width: 2400, height: 1600)
            }
        }
        
        var displayName: String {
            switch self {
            case .square: return "Instagram Feed"
            case .story: return "Instagram Story"
            case .wide: return "Social Media"
            case .print: return "High Quality"
            }
        }
        
        var icon: String {
            switch self {
            case .square: return "square"
            case .story: return "rectangle.portrait"
            case .wide: return "rectangle"
            case .print: return "doc"
            }
        }
        
        var description: String {
            switch self {
            case .square: return "Perfect for Instagram posts"
            case .story: return "Ideal for stories and reels"
            case .wide: return "Great for Twitter and Facebook"
            case .print: return "High resolution for printing"
            }
        }
    }
    
    private init() {}
    
    @available(iOS 16.0, *)
    func captureView<Content: View>(_ view: Content, format: ShareFormat = .square) async -> UIImage? {
        let renderer = ImageRenderer(content: view)
        
        // Configure based on format
        renderer.proposedSize = .init(format.size)
        renderer.scale = UIScreen.main.scale * 2 // High quality
        
        return renderer.uiImage
    }
    
    func shareImage(_ image: UIImage, from sourceView: UIView) {
        let activityViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        // Exclude some activities that don't make sense for images
        activityViewController.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks,
            .postToVimeo
        ]
        
        // Present from the root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            // Handle iPad presentation
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = sourceView
                popover.sourceRect = sourceView.bounds
            }
            
            rootViewController.present(activityViewController, animated: true)
        }
    }
}

// MARK: - Shareable Buyer View
@available(iOS 16.0, *)
struct ShareableBuyerView: View {
    let concert: Concert
    let suiteName: String
    let venueLocation: String
    @State private var buyerViewMode: BuyerViewMode = .seatView

    enum BuyerViewMode {
        case seatView
        case listView
    }

    var availableSeats: [Seat] {
        concert.seats.filter { $0.status == .available }
    }

    var soldSeats: [Seat] {
        concert.seats.filter { $0.status == .sold }
    }
    
    var body: some View {
        ZStack {
            // Liquid glass gradient background
            LinearGradient(
                colors: [
                    Color.black,
                    Color.liquidBlue.opacity(0.03),
                    Color.liquidPurple.opacity(0.02),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Text(concert.artist)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.modernText)

                    Text(concert.date, style: .date)
                        .font(.system(size: 14))
                        .foregroundColor(.modernTextSecondary)

                    // Parking status
                    if let parkingTicket = concert.parkingTicket {
                        HStack(spacing: 8) {
                            Image(systemName: "parkingsign.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Parking: \(parkingTicket.status == .available ? "Available" : "Sold")")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(parkingTicket.status == .available ? .green : .red)
                    }
                }
                .padding(.top, 20)

                // Seat View - U-Shaped Suite Layout
                VStack(spacing: 12) {
                    // Stage indicator
                    HStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "music.mic")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                            Text("STAGE")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        Spacer()
                    }

                    // Main suite card with U-shaped layout
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.clear)
                            .frame(height: 220)
                            .liquidGlassCard(accentColor: .liquidTeal, cornerRadius: 20)

                        RoundedRectangle(cornerRadius: 20)
                            .fill(.clear)
                            .frame(height: 220)
                            .overlay(
                            ZStack {
                                // Bottom row
                                VStack {
                                    Spacer()
                                    HStack(spacing: 14) {
                                        ShareableCompactSeatView(seatNumber: 6, seat: concert.seats[5])
                                        ShareableCompactSeatView(seatNumber: 5, seat: concert.seats[4])
                                        ShareableCompactSeatView(seatNumber: 4, seat: concert.seats[3])
                                        ShareableCompactSeatView(seatNumber: 3, seat: concert.seats[2])
                                    }
                                    .padding(.bottom, 8)
                                }

                                // Left side
                                HStack {
                                    VStack(spacing: -2) {
                                        ShareableCompactSeatView(seatNumber: 8, seat: concert.seats[7])
                                        ShareableCompactSeatView(seatNumber: 7, seat: concert.seats[6])
                                        Spacer()
                                            .frame(height: 72)
                                    }
                                    .padding(.leading, 8)

                                    Spacer()
                                }

                                // Right side
                                HStack {
                                    Spacer()

                                    VStack(spacing: -2) {
                                        ShareableCompactSeatView(seatNumber: 1, seat: concert.seats[0])
                                        ShareableCompactSeatView(seatNumber: 2, seat: concert.seats[1])
                                        Spacer()
                                            .frame(height: 72)
                                    }
                                    .padding(.trailing, 8)
                                }

                                // Center firepit
                                VStack {
                                    CompactFirepitView(isPulsing: true)
                                        .offset(y: 25)
                                    Spacer()
                                }
                            }
                            .padding(.top, 20)
                        )
                    }
                }

                Spacer()
            }
            .padding(20)
        }
    }
}

// MARK: - Shareable Compact Seat View (for captures - no interactions, no prices)
struct ShareableCompactSeatView: View {
    let seatNumber: Int
    let seat: Seat

    var seatColor: Color {
        // Buyer view: only green for available, red for sold/reserved
        switch seat.status {
        case .available: return .green
        case .reserved, .sold: return .red
        }
    }

    var statusText: String {
        // Buyer view: simple "OPEN" or "SOLD"
        switch seat.status {
        case .available: return "OPEN"
        case .reserved, .sold: return "SOLD"
        }
    }

    var body: some View {
        VStack(spacing: -2) {
            // Seat button with liquid glass effect (matching CompactSeatView)
            ZStack {
                // Glass background
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .frame(width: 48, height: 48)

                // Colored gradient overlay
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        RadialGradient(
                            colors: [
                                seatColor.opacity(0.6),
                                seatColor.opacity(0.4)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 24
                        )
                    )
                    .frame(width: 48, height: 48)

                // Border
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(seatColor.opacity(0.7), lineWidth: 2)
                    .frame(width: 48, height: 48)

                // Seat number
                Text("\(seatNumber)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
            .shadow(color: seatColor.opacity(0.4), radius: 8, x: 0, y: 4)

            // Status text
            Text(statusText.isEmpty ? " " : statusText)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(height: 24)
                .opacity(statusText.isEmpty ? 0 : 1)
        }
    }
}

// MARK: - Buyer Suite Visualization
struct BuyerSuiteVisualization: View {
    let concert: Concert
    
    var body: some View {
        ZStack {
            // Firepit (central focus)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .orange.opacity(0.8),
                            .red.opacity(0.6),
                            .black.opacity(0.3)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 50
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(Color.orange.opacity(0.5), lineWidth: 2)
                )
                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 0)
            
            // Seats arranged around firepit
            ForEach(Array(concert.seats.enumerated()), id: \.offset) { index, seat in
                BuyerSeatView(seat: seat, seatNumber: index + 1)
                    .offset(seatOffset(for: index))
            }
        }
        .frame(width: 280, height: 280)
    }
    
    private func seatOffset(for index: Int) -> CGSize {
        let positions: [CGSize] = [
            CGSize(width: 100, height: -40),   // Seat 1 (top right)
            CGSize(width: 100, height: 40),    // Seat 2 (bottom right)
            CGSize(width: 100, height: 100),   // Seat 3 (bottom right - aligned with seat 2)
            CGSize(width: 33, height: 100),    // Seat 4 (bottom center-right)
            CGSize(width: -33, height: 100),   // Seat 5 (bottom center-left)
            CGSize(width: -100, height: 100),  // Seat 6 (bottom left - aligned with seat 7)
            CGSize(width: -100, height: 40),   // Seat 7 (bottom left side)
            CGSize(width: -100, height: -40)   // Seat 8 (top left side)
        ]
        return positions[index]
    }
}

// MARK: - Buyer Seat View
struct BuyerSeatView: View {
    let seat: Seat
    let seatNumber: Int
    
    var seatColor: Color {
        switch seat.status {
        case .available: return .green
        case .sold: return .red
        case .reserved: return .red // Show as unavailable to buyers
        }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Seat back
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                seatColor.opacity(0.3),
                                seatColor.opacity(0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 44, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(seatColor, lineWidth: 2)
                    )
                
                // Seat cushion
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [
                                seatColor.opacity(0.4),
                                seatColor.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 38, height: 24)
                    .offset(y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(seatColor, lineWidth: 1.5)
                            .offset(y: 6)
                    )
                
                // Status indicator
                ZStack {
                    Circle()
                        .fill(.black.opacity(0.7))
                        .frame(width: 20, height: 20)
                    
                    Image(systemName: seat.status == .available ? "checkmark" : "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(y: -2)
            }
            .shadow(color: seatColor.opacity(0.4), radius: 4, x: 0, y: 2)
            
            Text("\(seatNumber)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
        }
    }
}

// MARK: - Share Format Selector
struct ShareFormatSelector: View {
    let image: UIImage
    @Binding var selectedFormat: ShareManager.ShareFormat
    let onShare: (ShareManager.ShareFormat) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Choose Share Format")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    ForEach([
                        ShareManager.ShareFormat.square,
                        .story,
                        .wide,
                        .print
                    ], id: \.hashValue) { format in
                        FormatButton(
                            format: format,
                            isSelected: selectedFormat == format,
                            onTap: { selectedFormat = format }
                        )
                    }
                }
                
                Button("Share") {
                    onShare(selectedFormat)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .cornerRadius(12)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Format Button
struct FormatButton: View {
    let format: ShareManager.ShareFormat
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(format.displayName)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .orange : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.orange.opacity(0.1) : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Basic Buyer Suite View (Fallback for iOS < 16)
struct BasicBuyerSuiteView: View {
    let concert: Concert
    
    var availableSeats: [Seat] {
        concert.seats.filter { $0.status == .available }
    }
    
    var soldSeats: [Seat] {
        concert.seats.filter { $0.status == .sold }
    }
    
    var urgencyMessage: String {
        let availableCount = availableSeats.count
        switch availableCount {
        case 0: return "SOLD OUT"
        case 1: return "LAST SEAT AVAILABLE!"
        case 2: return "ONLY 2 SEATS LEFT!"
        case 3...4: return "ONLY \(availableCount) SEATS REMAINING"
        default: return "\(availableCount) PREMIUM SEATS AVAILABLE"
        }
    }
    
    var urgencyColor: Color {
        let availableCount = availableSeats.count
        switch availableCount {
        case 0: return .red
        case 1...2: return .orange
        case 3...4: return .yellow
        default: return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Urgency banner
            Text(urgencyMessage)
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(urgencyColor)
                )
            
            // Simplified seat visualization
            ZStack {
                // Firepit (central focus)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .orange.opacity(0.6),
                                .red.opacity(0.4),
                                .black.opacity(0.2)
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 40
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                    )
                
                // Seats arranged around firepit
                ForEach(Array(concert.seats.enumerated()), id: \.offset) { index, seat in
                    SimpleBuyerSeatView(seat: seat, seatNumber: index + 1)
                        .offset(simpleSeatOffset(for: index))
                }
            }
            .frame(width: 220, height: 220)
        }
        .padding()
    }
    
    private func simpleSeatOffset(for index: Int) -> CGSize {
        let positions: [CGSize] = [
            CGSize(width: 75, height: -25),   // Seat 1 (top right)
            CGSize(width: 75, height: 25),    // Seat 2 (bottom right)
            CGSize(width: 75, height: 75),    // Seat 3 (bottom right - aligned with seat 2)
            CGSize(width: 25, height: 75),    // Seat 4 (bottom center-right)
            CGSize(width: -25, height: 75),   // Seat 5 (bottom center-left)
            CGSize(width: -75, height: 75),   // Seat 6 (bottom left - aligned with seat 7)
            CGSize(width: -75, height: 25),   // Seat 7 (bottom left side)
            CGSize(width: -75, height: -25)   // Seat 8 (top left side)
        ]
        return positions[index]
    }
}

// MARK: - Simple Buyer Seat View (Fallback)
struct SimpleBuyerSeatView: View {
    let seat: Seat
    let seatNumber: Int
    
    var seatColor: Color {
        switch seat.status {
        case .available: return .green
        case .sold: return .red
        case .reserved: return .red // Show as unavailable to buyers
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Simplified seat back
                RoundedRectangle(cornerRadius: 6)
                    .fill(seatColor.opacity(0.4))
                    .frame(width: 32, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(seatColor, lineWidth: 1.5)
                    )
                
                // Simplified seat cushion
                RoundedRectangle(cornerRadius: 4)
                    .fill(seatColor.opacity(0.5))
                    .frame(width: 28, height: 18)
                    .offset(y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(seatColor, lineWidth: 1)
                            .offset(y: 4)
                    )
                
                // Status indicator
                Circle()
                    .fill(.black.opacity(0.7))
                    .frame(width: 14, height: 14)
                    .overlay(
                        Image(systemName: seat.status == .available ? "checkmark" : "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(y: -2)
            }
            .shadow(color: seatColor.opacity(0.3), radius: 2, x: 0, y: 1)
            
            Text("\(seatNumber)")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.modernTextSecondary)
        }
    }
}

// MARK: - Consistent UI Components

// Standardized sheet presentation types
enum SheetType: Identifiable {
    case addConcert
    case editConcert(Concert)
    case allConcerts
    case concertDetails(Concert)
    case settings
    case analytics
    case shareSheet
    case joinSuite
    case memberManagement
    
    var id: String {
        switch self {
        case .addConcert: return "addConcert"
        case .editConcert(let concert): return "editConcert-\(concert.id)"
        case .allConcerts: return "allConcerts"
        case .concertDetails(let concert): return "concertDetails-\(concert.id)"
        case .settings: return "settings"
        case .analytics: return "analytics"
        case .shareSheet: return "shareSheet"
        case .joinSuite: return "joinSuite"
        case .memberManagement: return "memberManagement"
        }
    }
}

// Consistent card component
struct ConsistentCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content
    var padding: CGFloat = 20
    
    init(padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.modernSecondary)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
    }
}

// Consistent primary button style
// MARK: - Standardized Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, .spacingSections)
            .padding(.vertical, .radiusSmall)
            .background(
                RoundedRectangle(cornerRadius: .radiusSmall)
                    .fill(isEnabled ? Color.modernAccent : Color.gray.opacity(0.5))
                    .shadow(color: .black.opacity(0.15), radius: configuration.isPressed ? 2 : 4, x: 0, y: configuration.isPressed ? 1 : 2)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.quickEase, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(isEnabled ? Color.modernAccent : .gray)
            .padding(.horizontal, .radiusMedium)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: .radiusSmall)
                    .stroke(isEnabled ? Color.modernAccent : .gray, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: .radiusSmall)
                            .fill(Color.modernSecondary.opacity(configuration.isPressed ? 0.3 : 0.1))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.quickEase, value: configuration.isPressed)
    }
}

// Compact button styles for settings and collaboration sections
struct CompactPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    let color: Color

    init(color: Color = .modernAccent) {
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: .radiusSmall)
                    .fill(isEnabled ? color : Color.gray)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.quickEase, value: configuration.isPressed)
    }
}

struct CompactSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    let color: Color

    init(color: Color = .modernAccent) {
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(isEnabled ? color : .gray)
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: .radiusSmall)
                    .fill(isEnabled ? color.opacity(0.1) : .gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: .radiusSmall)
                            .stroke(isEnabled ? color.opacity(0.3) : .gray.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.quickEase, value: configuration.isPressed)
    }
}

// Legacy aliases for compatibility
typealias CollaborationPrimaryButtonStyle = CompactPrimaryButtonStyle
typealias CollaborationSecondaryButtonStyle = CompactSecondaryButtonStyle

// Consistent toolbar button
struct ToolbarButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 16, weight: .medium))
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(.modernAccent)
    }
}

// Consistent empty state view
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(title: String, message: String, systemImage: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: systemImage)
                .font(.system(size: 64))
                .foregroundColor(.modernAccent.opacity(0.6))
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.modernText)
                
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.modernTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(40)
    }
}

// Consistent section header
struct SectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.modernText)
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.modernAccent)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// Consistent loading view
struct LoadingView: View {
    let message: String
    
    init(_ message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .modernAccent))
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.modernTextSecondary)
        }
        .padding(40)
    }
}

// Clean Settings Components for Redesigned Settings
struct CleanSettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header with refined styling
            HStack(spacing: 14) {
                // Icon container with champagne accent
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.champagne.opacity(0.12))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.champagne)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.5)
                        .foregroundColor(.champagne.opacity(0.8))
                }

                Spacer()
            }

            // Subtle divider
            Rectangle()
                .fill(Color.champagne.opacity(0.1))
                .frame(height: 1)

            content
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.secondarySystemBackground))

                // Subtle top glow
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color.champagne.opacity(0.03), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )

                // Refined border
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.champagne.opacity(0.08), lineWidth: 0.5)
            }
        )
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
    }
}

struct CleanSettingsField: View {
    let title: String
    let value: String
    let placeholder: String
    let onChange: (String) -> Void
    @State private var editableValue: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.modernText)

            TextField(placeholder, text: $editableValue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit {
                    onChange(editableValue)
                    isFocused = false
                    UIApplication.shared.dismissKeyboard()
                }
                .onChange(of: isFocused) { oldValue, newValue in
                    if !newValue && editableValue != value {
                        onChange(editableValue)
                    }
                }
        }
        .onAppear {
            editableValue = value
        }
        .onChange(of: value) { oldValue, newValue in
            if !isFocused {
                editableValue = newValue
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            if isFocused {
                UIApplication.shared.dismissKeyboard()
            }
        }
    }
}

struct CleanPriceField: View {
    let title: String
    let value: Double
    let actionButton: (() -> AnyView)?
    let onChange: (Double) -> Void
    @State private var editableValue: String = ""
    @FocusState private var isFocused: Bool
    
    init(title: String, value: Double, actionButton: (() -> AnyView)? = nil, onChange: @escaping (Double) -> Void) {
        self.title = title
        self.value = value
        self.actionButton = actionButton
        self.onChange = onChange
        self._editableValue = State(initialValue: String(format: "%.0f", value))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.modernText)
            
            HStack {
                HStack {
                    Text("$")
                        .foregroundColor(.modernTextSecondary)
                    TextField("0", text: $editableValue)
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    if let newPrice = Double(editableValue), newPrice >= 0 {
                                        onChange(newPrice)
                                    }
                                    isFocused = false
                                }
                            }
                        }
                        .onChange(of: editableValue) { oldValue, newValue in
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            if filtered != newValue {
                                editableValue = filtered
                            }
                        }
                        .onSubmit {
                            if let newPrice = Double(editableValue), newPrice >= 0 {
                                onChange(newPrice)
                            }
                            isFocused = false
                        }
                        .onChange(of: isFocused) { oldValue, newValue in
                            if !newValue {
                                if let newPrice = Double(editableValue), newPrice >= 0 {
                                    onChange(newPrice)
                                } else {
                                    editableValue = String(format: "%.0f", value)
                                }
                            }
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                if let actionButton = actionButton {
                    actionButton()
                }
            }
        }
        .onAppear {
            editableValue = String(format: "%.0f", value)
        }
        .onChange(of: value) { oldValue, newValue in
            if !isFocused {
                editableValue = String(format: "%.0f", newValue)
            }
        }
    }
}

// Legacy settings field component (kept for compatibility)
struct SettingsField: View {
    let title: String
    let subtitle: String?
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var prefix: String? = nil
    var showBorder: Bool = true
    var actionButton: (() -> AnyView)? = nil
    var onSubmit: () -> Void = {}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.modernText)
                .textCase(.uppercase)
            
            // Subtitle if provided
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.modernTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Input field with optional action button
            HStack(spacing: 8) {
                HStack(spacing: 12) {
                    if let prefix = prefix {
                        Text(prefix)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.modernTextSecondary)
                            .padding(.leading, 16)
                    }
                    
                    TextField(placeholder, text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(.modernText)
                        .keyboardType(keyboardType)
                        .padding(.vertical, 16)
                        .padding(.horizontal, prefix != nil ? 8 : 16)
                        .onSubmit(onSubmit)
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.modernSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(showBorder ? Color.modernAccent.opacity(0.2) : Color.clear, lineWidth: 1)
                        )
                )
                
                // Action button if provided
                if let actionButton = actionButton {
                    actionButton()
                }
            }
        }
    }
}

// Enhanced charity search field with dropdown
struct CharitySearchField: View {
    @Binding var selectedCharity: String
    let savedCharities: [SavedCharity]
    let onCharitySelected: (SavedCharity) -> Void
    
    @State private var showDropdown: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    // Computed property for filtering - avoids state dependency issues
    private var filteredCharities: [SavedCharity] {
        if selectedCharity.isEmpty {
            return savedCharities
        } else {
            return savedCharities.filter { charity in
                charity.name.localizedCaseInsensitiveContains(selectedCharity)
            }
        }
    }
    
    private var shouldShowDropdown: Bool {
        showDropdown && !filteredCharities.isEmpty && !savedCharities.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("Full Legal Name of Charity", text: $selectedCharity)
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
                .onTapGesture {
                    showDropdown = true
                }
                .onChange(of: selectedCharity) { _, _ in
                    showDropdown = !selectedCharity.isEmpty
                }
                .onSubmit {
                    showDropdown = false
                }
            
            if shouldShowDropdown {
                DropdownList(items: Array(filteredCharities.prefix(5))) { charity in
                    selectedCharity = charity.name
                    onCharitySelected(charity)
                    showDropdown = false
                    isTextFieldFocused = false
                }
                .zIndex(100)
            }
        }
        .onChange(of: isTextFieldFocused) { _, focused in
            if !focused {
                showDropdown = false
            }
        }
    }
}

// Basic charity item row component
struct CharityItem: View {
    let charity: SavedCharity
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(charity.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.modernText)
                    if !charity.address.isEmpty {
                        Text(charity.address)
                            .font(.system(size: 12))
                            .foregroundColor(.modernTextSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Basic dropdown list component  
struct DropdownList: View {
    let items: [SavedCharity]
    let onSelect: (SavedCharity) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(items, id: \.id) { charity in
                CharityItem(charity: charity) {
                    onSelect(charity)
                }
                if charity.id != items.last?.id {
                    Divider()
                }
            }
        }
        .background(Color.modernCard)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Splash Screen
struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var showFireEffect = false
    @State private var titleOpacity = 0.0
    @State private var subtitleOpacity = 0.0
    @State private var fireScale = 0.1
    @State private var particleOffset = CGSize.zero
    @Binding var isShowingSplash: Bool
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.05, blue: 0.15),
                    Color(red: 0.15, green: 0.08, blue: 0.2),
                    Color(red: 0.2, green: 0.1, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Fire particles background
            ForEach(0..<20, id: \.self) { index in
                FireParticle(delay: Double(index) * 0.1)
                    .offset(particleOffset)
            }
            
            VStack(spacing: 40) {
                // Animated fire icon
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.orange.opacity(0.3),
                                    Color.orange.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .blur(radius: 20)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                    
                    // Fire icon
                    Image(systemName: "flame.fill")
                        .font(.system(size: 120))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.8, blue: 0.0),
                                    Color.orange,
                                    Color(red: 1.0, green: 0.3, blue: 0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(fireScale)
                        .rotationEffect(.degrees(isAnimating ? 5 : -5))
                        .shadow(color: .orange, radius: 30)
                        .shadow(color: .orange.opacity(0.5), radius: 50)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
                }
                
                VStack(spacing: 16) {
                    // Main title
                    Text("SuiteKeep")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 1.0, green: 0.9, blue: 0.7)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(titleOpacity)
                        .shadow(color: .orange.opacity(0.5), radius: 10)
                    
                    Text("Concert Management")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(subtitleOpacity)
                    
                    // Loading indicator
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isAnimating ? 1.0 : 0.5)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }
                    .padding(.top, 40)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                fireScale = 1.0
            }
            
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                titleOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 1.0).delay(0.6)) {
                subtitleOpacity = 1.0
            }
            
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                particleOffset = CGSize(width: 100, height: -1000)
            }
            
            isAnimating = true
            
            // Transition to main app
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    isShowingSplash = false
                }
            }
        }
    }
}

// Colorful floating music notes
struct FireParticle: View {
    @State private var offset: CGSize
    @State private var rotation: Double = 0.0
    @State private var scale: Double = 1.0
    
    let delay: Double
    private let animationDuration: Double
    private let selectedNote: String
    private let noteSize: CGFloat
    private let noteColor: Color
    private let endPosition: CGSize
    
    init(delay: Double) {
        self.delay = delay
        self.animationDuration = Double.random(in: 8...15)
        self.selectedNote = "♪"
        self.noteSize = CGFloat.random(in: 32...48)
        
        // Ember colors only
        self.noteColor = .orange
        
        let startX = CGFloat.random(in: -200...200)
        let endX = CGFloat.random(in: -200...200)
        self._offset = State(initialValue: CGSize(width: startX, height: 600))
        self.endPosition = CGSize(width: endX, height: -700)
    }
    
    var body: some View {
        Text(selectedNote)
            .font(.system(size: noteSize, weight: .bold))
            .foregroundStyle(
                RadialGradient(
                    colors: [
                        Color.fireYellow,
                        Color.orange,
                        Color.fireRed.opacity(0.8)
                    ],
                    center: .center,
                    startRadius: 5,
                    endRadius: 25
                )
            )
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .shadow(color: noteColor.opacity(0.6), radius: 4)
            .shadow(color: noteColor.opacity(0.3), radius: 8)
            .offset(offset)
            .onAppear {
                // Start the upward movement
                withAnimation(
                    .linear(duration: animationDuration)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    offset = endPosition
                }
                
                // Gentle rotation animation
                withAnimation(
                    .linear(duration: Double.random(in: 3...6))
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    rotation = Double.random(in: -20...20)
                }
                
                // Gentle scale pulsing
                withAnimation(
                    .easeInOut(duration: Double.random(in: 1.5...3.0))
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    scale = Double.random(in: 0.8...1.3)
                }
            }
    }
}

struct DynamicFireSuiteApp: View {
    @State private var selectedTab = 0
    @State private var animateFlames = true
    @State private var isShowingSplash = true
    @EnvironmentObject var sharedSuiteManager: SharedSuiteManager
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var concertManager = ConcertDataManager()
    
    var body: some View {
        ZStack {
            if isShowingSplash {
                SplashScreenView(isShowingSplash: $isShowingSplash)
                    .transition(.opacity)
            } else {
        TabView(selection: $selectedTab) {
            DynamicDashboard(concerts: $concertManager.concerts, concertManager: concertManager, settingsManager: settingsManager, sharedSuiteManager: sharedSuiteManager)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Dashboard")
                }
                .tag(0)
            
            DynamicConcerts(concertManager: concertManager, settingsManager: settingsManager)
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "music.note.list" : "music.note")
                    Text("Concerts")
                }
                .tag(1)
            
            DynamicAnalytics(concerts: $concertManager.concerts, settingsManager: settingsManager)
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "chart.bar.xaxis" : "chart.bar")
                    Text("Analytics")
                }
                .tag(2)
            
            SettingsView(settingsManager: settingsManager, concertManager: concertManager, sharedSuiteManager: sharedSuiteManager, selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                    Text("Settings")
                }
                .tag(3)
        }
        .tint(.champagne)
        .onAppear {
            startFlameAnimation()
            // Connect SharedSuiteManager and ConcertDataManager to each other
            concertManager.sharedSuiteManager = sharedSuiteManager
            sharedSuiteManager.concertManager = concertManager

            // Connect SettingsManager to other managers
            concertManager.settingsManager = settingsManager
            settingsManager.sharedSuiteManager = sharedSuiteManager
            
            // Auto-sync on app startup if in shared suite (or if we think we should be)
            if sharedSuiteManager.isSharedSuite {
                print("🔄 DEBUG: Auto-syncing on app startup for shared suite")
                Task {
                    await sharedSuiteManager.syncWithCloudKit()
                    await sharedSuiteManager.syncConcertData()
                }
            }
        }
        .alert("Suite No Longer Available", isPresented: $sharedSuiteManager.showSuiteDeletedAlert) {
            Button("OK") { }
        } message: {
            Text("The shared suite '\(sharedSuiteManager.deletedSuiteName)' has been deleted by the owner. You have been returned to your individual suite.")
        }
        .alert(settingsManager.cloudSyncAlertTitle, isPresented: $settingsManager.showCloudSyncEnabledAlert) {
            Button("OK") { }
        } message: {
            Text(settingsManager.cloudSyncAlertMessage)
        }
        .alert(settingsManager.sharedSuiteAlertTitle, isPresented: $settingsManager.showSharedSuiteReadOnlyAlert) {
            Button("Got it!") { }
        } message: {
            Text(settingsManager.sharedSuiteAlertMessage)
        }
            }
        }
    }
    
    private func startFlameAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever()) {
            animateFlames.toggle()
        }
    }
}

// MARK: - Dynamic Dashboard
struct DynamicDashboard: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var pulseFirepit = false
    @State private var rotateValue: Double = 0
    @State private var selectedConcert: Concert?
    @State private var activeSheet: SheetType?
    @Binding var concerts: [Concert]
    @ObservedObject var concertManager: ConcertDataManager
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var sharedSuiteManager: SharedSuiteManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background that adapts to light/dark mode
                Color(.systemBackground)
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: .spacingNormal) {
                        // MARK: - Noir Luxe Header Card
                        VStack(spacing: 12) {
                            // Decorative top accent line
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.champagne)
                                .frame(width: 40, height: 3)
                                .opacity(0.8)

                            // Suite name - elegant serif styling
                            Text(settingsManager.suiteName.uppercased())
                                .font(.system(size: 13, weight: .medium))
                                .tracking(4)
                                .foregroundColor(.champagne)

                            // Venue name - bold display
                            Text(settingsManager.venueLocation)
                                .font(.system(size: 26, weight: .bold, design: .serif))
                                .foregroundColor(.white)

                            // Subtle tagline
                            Text("PRIVATE SUITE")
                                .font(.system(size: 10, weight: .medium))
                                .tracking(3)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .padding(.horizontal, 20)
                        .background(
                            ZStack {
                                // Deep noir base
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.12, green: 0.10, blue: 0.14),
                                                Color(red: 0.16, green: 0.13, blue: 0.18),
                                                Color(red: 0.12, green: 0.10, blue: 0.14)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                // Subtle champagne glow at top
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.champagne.opacity(0.08),
                                                Color.clear,
                                                Color.clear
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                // Inner border with champagne tint
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                Color.champagne.opacity(0.3),
                                                Color.champagne.opacity(0.1),
                                                Color.champagne.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                            .shadow(color: Color.champagne.opacity(0.1), radius: 20, x: 0, y: 10)
                            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                        )

                        // Suite Overview Summary
                        SuiteSummaryView(concerts: concerts, settingsManager: settingsManager, concertManager: concertManager)
                        
                        // Recent Activity
                        RecentActivityFeed(concerts: concerts) { concert in
                            selectedConcert = concert
                        }
                    }
                    .padding(.horizontal)
                }
                .safeAreaPadding(.top, -8)
            }
            .navigationBarHidden(true)
            .sheet(item: $activeSheet) { sheetType in
                switch sheetType {
                case .concertDetails(let concert):
                    ConcertDetailView(
                        concert: concert,
                        concertManager: concertManager,
                        settingsManager: settingsManager
                    )
                default:
                    EmptyView()
                }
            }
            .onChange(of: selectedConcert) { oldValue, newValue in
                if let concert = newValue {
                    activeSheet = .concertDetails(concert)
                    selectedConcert = nil
                }
            }
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever()) {
            pulseFirepit.toggle()
        }
    }
}

// MARK: - Suite Summary View
struct SuiteSummaryView: View {
    let concerts: [Concert]
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var concertManager: ConcertDataManager
    @State private var animateStats = false
    @EnvironmentObject var sharedSuiteManager: SharedSuiteManager
    
    var totalTicketsSold: Int {
        concerts.reduce(0) { $0 + $1.ticketsSold }
    }
    
    var totalRevenue: Double {
        concerts.reduce(0) { $0 + $1.totalRevenue }
    }
    
    var upcomingConcerts: Int {
        concerts.filter { $0.date >= Date() }.count
    }
    
    var totalCost: Double {
        concerts.reduce(0) { $0 + $1.totalCost }
    }
    
    var totalProfit: Double {
        totalRevenue - totalCost
    }
    
    var averageOccupancy: Int {
        let currentDate = Date()
        let pastConcerts = concerts.filter { $0.date <= currentDate }
        guard !pastConcerts.isEmpty else { return 0 }
        let totalOccupancy = pastConcerts.reduce(0) { $0 + $1.ticketsSold }
        return Int((Double(totalOccupancy) / Double(pastConcerts.count * 8)) * 100)
    }
    
    
    var body: some View {
        VStack(spacing: 20) {
            // Sync Status Indicator for Shared Suites (only show if multi-tenant is enabled)
            if sharedSuiteManager.isInSharedSuite && settingsManager.enableMultiTenantSuites {
                Button(action: {
                    Task {
                        await sharedSuiteManager.syncWithCloudKit()
                        await sharedSuiteManager.syncConcertData()
                    }
                }) {
                    HStack(spacing: 12) {
                        // Sync Icon
                        if sharedSuiteManager.isSyncing {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.modernAccent)
                                .rotationEffect(.degrees(animateStats ? 360 : 0))
                                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: animateStats)
                        } else if sharedSuiteManager.isOffline || sharedSuiteManager.pendingOperationsCount > 0 {
                            Image(systemName: "arrow.triangle.2.circlepath.circle")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.orange)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.green)
                        }

                        // Last Sync Date/Time
                        VStack(spacing: 2) {
                            if let lastSync = concertManager.lastSyncDate {
                                Text("Last synced")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.modernTextSecondary)

                                Text(lastSync.formatted(date: .omitted, time: .shortened))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.modernText)
                            } else {
                                Text("Tap to sync")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.modernTextSecondary)

                                Text("Sync pending")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.modernText)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(sharedSuiteManager.isSyncing)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            
            // Key Metrics Cards with Beautiful Gradients
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                MetricCard(
                    title: "Total Tickets Sold",
                    value: "\(totalTicketsSold)",
                    subtitle: "tickets sold",
                    gradient: Color.cardGreen,
                    icon: "ticket.fill",
                    accentColor: .liquidGreen
                )

                MetricCard(
                    title: "Revenue",
                    value: "$\(Int(totalRevenue))",
                    subtitle: "total earnings",
                    gradient: Color.cardBlue,
                    icon: "dollarsign.circle.fill",
                    accentColor: .liquidBlue
                )

                MetricCard(
                    title: "Total Cost",
                    value: "$\(Int(totalCost))",
                    subtitle: "ticket costs",
                    gradient: Color.cardOrange,
                    icon: "minus.circle.fill",
                    accentColor: .liquidOrange
                )

                MetricCard(
                    title: "Profit",
                    value: "$\(Int(totalProfit))",
                    subtitle: "net earnings",
                    gradient: totalProfit >= 0 ? Color.cardGreen : Color.cardPink,
                    icon: totalProfit >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                    accentColor: totalProfit >= 0 ? .liquidGreen : .liquidPink
                )
            }
        }
        .scaleEffect(animateStats ? 1.0 : 0.8)
        .opacity(animateStats ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animateStats = true
            }
        }
    }
}

// MARK: - Enhanced Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let gradient: LinearGradient
    let icon: String
    var accentColor: Color = .champagne

    @State private var isPressed = false
    @State private var animateValue = false
    @State private var showShimmer = false

    var body: some View {
        VStack(spacing: 6) {
            // Icon with sophisticated treatment
            ZStack {
                // Subtle glow ring
                Circle()
                    .stroke(accentColor.opacity(0.2), lineWidth: 1)
                    .frame(width: 38, height: 38)

                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 34, height: 34)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accentColor)
            }

            Spacer(minLength: 4)

            VStack(spacing: 3) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .scaleEffect(animateValue ? 1.03 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateValue)

                Text(title.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 4)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 105)
        .background(
            ZStack {
                // Noir card base
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.tertiarySystemBackground))

                // Subtle top highlight
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.05), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )

                // Refined border
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0.2),
                                accentColor.opacity(0.05),
                                accentColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
        )
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed.toggle()
                animateValue.toggle()
            }
            HapticManager.shared.impact(style: .light)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed.toggle()
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.1...0.5)) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    animateValue = true
                }
            }
        }
    }
}

// MARK: - Status Indicator
struct StatusIndicator: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.modernTextSecondary)
        }
    }
}

// MARK: - Fire Suite Hero View (Legacy - kept for reference)
/* struct FireSuiteHeroView: View {
    @Binding var pulseFirepit: Bool
    @State private var seatColors: [Color] = Array(repeating: .gray.opacity(0.6), count: 8)
    @State private var animateSales = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Title with animated gradient
            VStack(spacing: 5) {
                Text("FIRE SUITE")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("FORD AMPHITHEATER")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(2)
            }
            
            // 3D-like Fire Suite Layout
            ZStack {
                // Stage background
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .cyan.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 420, height: 250)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                VStack(spacing: 25) {
                    // Stage
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "music.mic")
                                .font(.title)
                                .foregroundColor(.blue)
                            Text("STAGE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                    }
                    
                    // Fire Suite Layout
                    VStack(spacing: 8) {
                        // Top section with side seats and firepit
                        HStack(spacing: 40) {
                            // Left side: Seats 8 (top) and 7 (bottom)
                            VStack(spacing: 25) {
                                DynamicSeatView(
                                    seatNumber: 8,
                                    color: seatColors[7],
                                    isAnimating: animateSales
                                )
                                DynamicSeatView(
                                    seatNumber: 7,
                                    color: seatColors[6],
                                    isAnimating: animateSales
                                )
                            }
                            
                            // Center Firepit
                            DynamicFirepitView(isPulsing: pulseFirepit)
                            
                            // Right side: Seats 1 (top) and 2 (bottom)
                            VStack(spacing: 25) {
                                DynamicSeatView(
                                    seatNumber: 1,
                                    color: seatColors[0],
                                    isAnimating: animateSales
                                )
                                DynamicSeatView(
                                    seatNumber: 2,
                                    color: seatColors[1],
                                    isAnimating: animateSales
                                )
                            }
                        }
                        
                        // Bottom row: Seats 3, 4, 5, 6 in line
                        HStack(spacing: 30) {
                            DynamicSeatView(
                                seatNumber: 3,
                                color: seatColors[2],
                                isAnimating: animateSales
                            )
                            DynamicSeatView(
                                seatNumber: 4,
                                color: seatColors[3],
                                isAnimating: animateSales
                            )
                            DynamicSeatView(
                                seatNumber: 5,
                                color: seatColors[4],
                                isAnimating: animateSales
                            )
                            DynamicSeatView(
                                seatNumber: 6,
                                color: seatColors[5],
                                isAnimating: animateSales
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            startSeatAnimation()
        }
        .onTapGesture {
            simulateSales()
        }
    }
    
    private func startSeatAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever()) {
            animateSales.toggle()
        }
    }
    
    private func simulateSales() {
        // Animate random seat sales
        for i in 0..<8 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    seatColors[i] = Bool.random() ? .green : .orange
                }
            }
        }
    }
} */

// MARK: - Dynamic Seat View
struct DynamicSeatView: View {
    let seatNumber: Int
    let color: Color
    let isAnimating: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .shadow(color: color.opacity(0.5), radius: isAnimating ? 8 : 4)
                
                Text("\(seatNumber)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Text("")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .frame(height: 10)
        }
    }
}

// MARK: - Dynamic Firepit View
struct DynamicFirepitView: View {
    let isPulsing: Bool
    @State private var flameOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Glass container background
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.liquidOrange.opacity(0.3),
                                    Color.fireYellow.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 35
                            )
                        )
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.liquidOrange.opacity(0.6),
                                    Color.fireYellow.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .frame(width: 70, height: 70)
                .shadow(color: Color.liquidOrange.opacity(0.3), radius: 15, x: 0, y: 5)

            // Firepit base
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.yellow, .orange, .red, .black.opacity(0.8)],
                        center: .center,
                        startRadius: 5,
                        endRadius: 25
                    )
                )
                .frame(width: 50, height: 50)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .shadow(color: .orange, radius: isPulsing ? 15 : 10)

            // Animated flames
            VStack(spacing: -5) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: "flame.fill")
                        .font(.system(size: CGFloat(16 - index * 2)))
                        .foregroundColor([.red, .orange, .yellow][index])
                        .offset(y: flameOffset + CGFloat(index * -3))
                        .opacity(0.8)
                }
            }
            .offset(y: -10)

            // Sparks effect
            ForEach(0..<5, id: \.self) { _ in
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 2, height: 2)
                    .offset(
                        x: CGFloat.random(in: -20...20).safeValue,
                        y: CGFloat.random(in: -30...10).safeValue
                    )
                    .opacity(isPulsing ? 0.8 : 0.3)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
                flameOffset = -5
            }
        }
    }
}

// MARK: - Powered by SuiteKeep Advertising View
struct PoweredBySuiteKeepView: View {
    var body: some View {
        VStack(spacing: 4) {
            // "Powered by" text above flame
            Text("Powered by")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
            
            // Single orange flame (smaller)
            Image(systemName: "flame.fill")
                .font(.system(size: 24))
                .foregroundColor(.orange)
            
            // "SuiteKeep" text below flame
            Text("SuiteKeep")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Enhanced Performance Metrics View
struct PerformanceMetricsView: View {
    let concerts: [Concert]
    @State private var showChart = false
    @State private var animateBars = false
    
    var chartData: [Double] {
        let currentDate = Date()
        let pastConcerts = concerts.filter { $0.date <= currentDate }
        let sortedConcerts = pastConcerts.sorted { $0.date < $1.date }
        guard sortedConcerts.count > 0 else { 
            return Array(repeating: 0, count: 12)
        }
        
        var data: [Double] = []
        for concert in sortedConcerts.prefix(12) {
            let occupancyRate = Double(concert.ticketsSold) / 8.0 * 100.0
            data.append(occupancyRate)
        }
        
        while data.count < 12 {
            data.append(0)
        }
        
        return data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Enhanced Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Performance Trends")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text("Concert occupancy over time")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()

                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            // Empty state when no concerts
            if concerts.isEmpty {
                VStack(spacing: .spacingNormal) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.top, .spacingSections)

                    Text("No Performance Data")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Add concerts to see trends and analytics")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: .radiusMedium)
                        .fill(.ultraThinMaterial)
                )
            } else if showChart {
                // Beautiful Concert Performance Chart - Fixed overflow
                VStack(spacing: 16) {
                    GeometryReader { geometry in
                        let availableWidth = geometry.size.width - 32 // Account for padding
                        let barSpacing: CGFloat = 4
                        let totalSpacing = barSpacing * 11 // 11 spaces between 12 bars
                        let barWidth = max(8, (availableWidth - totalSpacing) / 12) // Minimum 8pt width
                        
                        HStack(alignment: .bottom, spacing: barSpacing) {
                            ForEach(0..<12, id: \.self) { index in
                                VStack(spacing: 6) {
                                    // Animated bar with gradient
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            LinearGradient(
                                                colors: chartData[index] > 75 ? 
                                                    [Color(red: 0.1, green: 0.8, blue: 0.4), Color(red: 0.2, green: 0.9, blue: 0.5)] :
                                                chartData[index] > 50 ?
                                                    [Color(red: 1.0, green: 0.5, blue: 0.1), Color(red: 1.0, green: 0.7, blue: 0.2)] :
                                                    [Color(red: 0.6, green: 0.6, blue: 0.7), Color(red: 0.7, green: 0.7, blue: 0.8)],
                                                startPoint: .bottom,
                                                endPoint: .top
                                            )
                                        )
                                        .frame(width: barWidth.safeValue, height: animateBars ? max(20, CGFloat(chartData[index] * 0.8).safeValue) : 0)
                                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(Double(index) * 0.08), value: animateBars)
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    
                                    // Month indicator
                                    Text("\(index + 1)")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                    }
                    .frame(height: 80)
                    
                    // Performance indicators
                    HStack(spacing: 20) {
                        HStack(spacing: 6) {
                            Circle().fill(Color(red: 0.1, green: 0.8, blue: 0.4)).frame(width: 8, height: 8)
                            Text("75%+ Sold")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        HStack(spacing: 6) {
                            Circle().fill(Color(red: 1.0, green: 0.5, blue: 0.1)).frame(width: 8, height: 8)
                            Text("50-75% Sold")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        HStack(spacing: 6) {
                            Circle().fill(Color(red: 0.6, green: 0.6, blue: 0.7)).frame(width: 8, height: 8)
                            Text("<50% Sold")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .padding(24)
            }
        }
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.cardTeal)

                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.05), .clear, .black.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .drawingGroup()
            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                showChart = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                animateBars = true
            }
        }
    }
}

// MARK: - Enhanced Recent Activity Feed
struct RecentActivityFeed: View {
    let concerts: [Concert]
    let onConcertTap: (Concert) -> Void
    @State private var animateRows = false
    
    var recentActivities: [(String, String, String, String, LinearGradient, Concert)] {
        let now = Date()
        let sortedConcerts = concerts.sorted { 
            abs($0.date.timeIntervalSince(now)) < abs($1.date.timeIntervalSince(now))
        }.prefix(4)
        return sortedConcerts.map { concert in
            let timeAgo = timeAgoString(from: concert.date)
            let icon = concert.ticketsSold == 8 ? "checkmark.seal.fill" : (concert.ticketsSold > 0 ? "ticket.fill" : "music.note")
            let subtitle = concert.ticketsSold == 8 ? "Sold out!" : "Tickets sold: \(concert.ticketsSold)/8"
            let gradient: LinearGradient = concert.ticketsSold == 8 ? Color.cardGreen : (concert.ticketsSold > 0 ? Color.cardOrange : Color.cardPink)
            
            return (icon, concert.artist, subtitle, timeAgo, gradient, concert)
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if days > 0 {
                return "\(days) days ago"
            } else {
                let futureDays = calendar.dateComponents([.day], from: now, to: date).day ?? 0
                return "In \(futureDays) days"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Enhanced Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent Activity")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text("Latest concert updates")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Debug: Show what concerts Recent Activity sees
                }
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            if recentActivities.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.white.opacity(0.1), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                        Image(systemName: "music.note")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    VStack(spacing: 8) {
                        Text("No recent activity")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Add a concert to get started")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 16) {
                    ForEach(Array(recentActivities.enumerated()), id: \.offset) { index, activity in
                        EnhancedActivityRow(
                            icon: activity.0,
                            title: activity.1,
                            subtitle: activity.2,
                            time: activity.3,
                            gradient: activity.4,
                            index: index,
                            onTap: { onConcertTap(activity.5) }
                        )
                        .opacity(animateRows ? 1.0 : 0.0)
                        .offset(y: animateRows ? 0 : 20)
                        .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(Double(index) * 0.1), value: animateRows)
                    }
                }
            }
        }
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.cardPink)

                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.05), .clear, .black.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .drawingGroup()
            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateRows = true
            }
        }
    }
}

// MARK: - Enhanced Activity Row
struct EnhancedActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let gradient: LinearGradient
    let index: Int
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Gradient icon background
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(time)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Circle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    index % 2 == 0 
                    ? LinearGradient(colors: [Color(red: 0.1, green: 0.2, blue: 0.4).opacity(0.3), Color(red: 0.15, green: 0.25, blue: 0.5).opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(colors: [Color(red: 0.9, green: 0.8, blue: 0.3).opacity(0.2), Color(red: 1.0, green: 0.85, blue: 0.4).opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            // Haptic feedback
            HapticManager.shared.impact(style: .light)
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed.toggle()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed.toggle()
                }
                onTap()
            }
        }
    }
}

// MARK: - Activity Row (Legacy - keeping for compatibility)
struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.modernText)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            
            Spacer()
            
            Text(time)
                .font(.system(size: 12))
                .foregroundColor(.modernTextSecondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.modernSecondary)
        )
    }
}

// MARK: - Concert Management
struct DynamicConcerts: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var concertManager: ConcertDataManager
    @ObservedObject var settingsManager: SettingsManager
    @State private var activeSheet: SheetType?
    
    var upcomingConcerts: [Concert] {
        let twoWeeksFromNow = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
        return concertManager.concerts.filter { $0.date <= twoWeeksFromNow && $0.date >= Date() }
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background that adapts to light/dark mode
                Color(.systemBackground)
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: .spacingSections) {
                        // Header
                        VStack(spacing: .spacingTight) {
                            Text("Concerts")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Manage upcoming performances")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.3, green: 0.2, blue: 0.9),
                                                Color(red: 0.5, green: 0.3, blue: 0.95),
                                                Color(red: 0.7, green: 0.4, blue: 1.0)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.1), .clear, .black.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .drawingGroup()
                            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
                        )
                        .padding(.top, 20)
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                activeSheet = .addConcert
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Concert")
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            
                            Button(action: {
                                activeSheet = .allConcerts
                            }) {
                                HStack {
                                    Image(systemName: "list.bullet")
                                    Text("View All")
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        
                        // Section Header
                        SectionHeader("Next 2 Weeks", actionTitle: "\(upcomingConcerts.count) concerts")
                        
                        // Upcoming Concerts
                        if upcomingConcerts.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 50))
                                    .foregroundColor(.modernTextSecondary.opacity(0.3))
                                
                                Text("No concerts in the next 2 weeks")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.modernTextSecondary)
                                
                                Text("Add a concert to get started")
                                    .font(.system(size: 14))
                                    .foregroundColor(.modernTextSecondary.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.modernSecondary)
                            )
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(upcomingConcerts) { concert in
                                    NavigationLink(destination: ConcertDetailView(concert: concert, concertManager: concertManager, settingsManager: settingsManager)) {
                                        ConcertRowView(concert: concert)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $activeSheet) { sheetType in
                switch sheetType {
                case .addConcert:
                    AddConcertView(settingsManager: settingsManager) { newConcert in
                        concertManager.addConcert(newConcert)
                    }
                case .allConcerts:
                    AllConcertsView(concertManager: concertManager, settingsManager: settingsManager)
                default:
                    EmptyView()
                }
            }
        }
    }
}

// MARK: - Seat Status Enum
enum SeatStatus: String, Codable, CaseIterable {
    case available = "available"
    case reserved = "reserved"
    case sold = "sold"
    
    var color: Color {
        switch self {
        case .available: return .green
        case .reserved: return .orange
        case .sold: return .red
        }
    }
    
    var displayText: String {
        switch self {
        case .available: return "Avail"
        case .reserved: return "RESERVED"
        case .sold: return "SOLD"
        }
    }
}

// MARK: - Ticket Source Enum
enum TicketSource: String, Codable, CaseIterable {
    case family = "Family"
    case facebook = "Facebook"
    case stubhub = "Stubhub"
    case axs = "AXS"
    case venu = "VENU"
    case other = "Other"
    case donation = "Donation"
}

// MARK: - Multi-User Sharing Models

enum UserRole: String, Codable, CaseIterable {
    case owner = "owner"
    case editor = "editor"
    case viewer = "viewer"
    
    var displayName: String {
        switch self {
        case .owner: return "Owner"
        case .editor: return "Editor"
        case .viewer: return "Viewer"
        }
    }
    
    var canEdit: Bool {
        switch self {
        case .owner, .editor: return true
        case .viewer: return false
        }
    }
    
    var canManageUsers: Bool {
        return self == .owner
    }
}

struct SharedSuiteInfo: Codable {
    let suiteId: String
    let suiteName: String
    let venueLocation: String
    let ownerId: String
    let createdDate: Date
    var members: [SuiteMember]
    var lastModified: Date
    var concertIds: [Int]? // Concert IDs for discovery
    var familyTicketPrice: Double?
    var defaultSeatCost: Double?
    
    init(suiteId: String, suiteName: String, venueLocation: String, ownerId: String) {
        self.suiteId = suiteId
        self.suiteName = suiteName
        self.venueLocation = venueLocation
        self.ownerId = ownerId
        self.createdDate = Date()
        self.members = []
        self.lastModified = Date()
    }
}

struct SuiteMember: Codable, Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let role: UserRole
    let joinedDate: Date
    var lastActive: Date
    
    init(userId: String, displayName: String, role: UserRole) {
        self.id = UUID().uuidString
        self.userId = userId
        self.displayName = displayName
        self.role = role
        self.joinedDate = Date()
        self.lastActive = Date()
    }
}

struct SeatModification: Codable, Equatable {
    let userId: String
    let userName: String
    let timestamp: Date
    let previousStatus: SeatStatus
    let newStatus: SeatStatus
    
    init(userId: String, userName: String, previousStatus: SeatStatus, newStatus: SeatStatus) {
        self.userId = userId
        self.userName = userName
        self.timestamp = Date()
        self.previousStatus = previousStatus
        self.newStatus = newStatus
    }
}

// MARK: - Invitation Token Model
struct InvitationToken: Codable, Identifiable {
    let id: String
    let suiteId: String
    let invitedBy: String
    let role: UserRole
    let expirationDate: Date
    let createdDate: Date
    var used: Bool
    var usedBy: String?
    var usedDate: Date?
    
    init(suiteId: String, invitedBy: String, role: UserRole, validForDays: Int = 7) {
        self.id = UUID().uuidString
        self.suiteId = suiteId
        self.invitedBy = invitedBy
        self.role = role
        self.createdDate = Date()
        self.expirationDate = Calendar.current.date(byAdding: .day, value: validForDays, to: Date()) ?? Date()
        self.used = false
    }
    
    var isExpired: Bool {
        return Date() > expirationDate
    }
    
    var isValid: Bool {
        return !used && !isExpired
    }
}

// MARK: - Suite Sync Model
struct SuiteSync: Codable {
    let suiteId: String
    let lastSyncDate: Date
    let syncVersion: Int
    var pendingChanges: [String: String] // Changed to Codable types only
    
    init(suiteId: String, syncVersion: Int = 1) {
        self.suiteId = suiteId
        self.lastSyncDate = Date()
        self.syncVersion = syncVersion
        self.pendingChanges = [:]
    }
}

// MARK: - CloudKit Record Types

enum CloudKitRecordType {
    static let sharedSuite = "SharedSuite"
    static let concert = "Concert"  
    static let suiteMember = "SuiteMember"
    static let invitationToken = "InvitationToken"
    static let suiteSync = "SuiteSync"
    static let usedTokens = "UsedTokens"
}

// MARK: - CloudKit Zone Configuration
struct CloudKitZone {
    static let sharedSuiteZoneID = CKRecordZone.ID(zoneName: "SharedSuiteZone", ownerName: CKCurrentUserDefaultName)
    
    static func createCustomZone() -> CKRecordZone {
        return CKRecordZone(zoneID: sharedSuiteZoneID)
    }
}

// Extensions to convert models to/from CloudKit records
extension SharedSuiteInfo {
    func toCloudKitRecord() -> CKRecord {
        // Use default zone for both suites and invitation tokens for consistency
        let record = CKRecord(recordType: CloudKitRecordType.sharedSuite, 
                             recordID: CKRecord.ID(recordName: suiteId))
        record["suiteName"] = suiteName
        record["venueLocation"] = venueLocation
        record["ownerId"] = ownerId
        record["createdDate"] = createdDate
        record["lastModified"] = lastModified
        record["isActive"] = true
        record["memberCount"] = Int64(members.count)
        
        // Store members as JSON data
        if let membersData = try? JSONEncoder().encode(members) {
            record["membersData"] = membersData
        }
        
        // Store concert IDs for discovery (will be updated by suite owner)
        if let concertIds = concertIds, !concertIds.isEmpty {
            record["concertIds"] = concertIds
        }

        // Store pricing settings
        if let familyTicketPrice = familyTicketPrice {
            record["familyTicketPrice"] = familyTicketPrice
        }

        if let defaultSeatCost = defaultSeatCost {
            record["defaultSeatCost"] = defaultSeatCost
        }

        return record
    }
    
    static func fromCloudKitRecord(_ record: CKRecord) -> SharedSuiteInfo? {
        guard let suiteName = record["suiteName"] as? String,
              let venueLocation = record["venueLocation"] as? String,
              let ownerId = record["ownerId"] as? String,
              let _ = record["createdDate"] as? Date,
              let lastModified = record["lastModified"] as? Date else {
            return nil
        }
        
        var suiteInfo = SharedSuiteInfo(
            suiteId: record.recordID.recordName,
            suiteName: suiteName,
            venueLocation: venueLocation,
            ownerId: ownerId
        )
        suiteInfo.lastModified = lastModified
        
        // Decode members from JSON data
        if let membersData = record["membersData"] as? Data,
           let members = try? JSONDecoder().decode([SuiteMember].self, from: membersData) {
            suiteInfo.members = members
        }
        
        // Get concert IDs if available
        if let concertIds = record["concertIds"] as? [Int] {
            suiteInfo.concertIds = concertIds
        }

        // Get pricing settings if available
        if let familyTicketPrice = record["familyTicketPrice"] as? Double {
            suiteInfo.familyTicketPrice = familyTicketPrice
        }

        if let defaultSeatCost = record["defaultSeatCost"] as? Double {
            suiteInfo.defaultSeatCost = defaultSeatCost
        }

        return suiteInfo
    }
}

extension Concert {
    func toCloudKitRecord(suiteRecord: CKRecord? = nil, suiteRecordID: CKRecord.ID? = nil) -> CKRecord {
        let recordID = CKRecord.ID(recordName: "concert_\(id)")
        let record = CKRecord(recordType: CloudKitRecordType.concert, recordID: recordID)
        
        record["concertId"] = Int64(id)
        record["artist"] = artist
        record["date"] = date
        // Store suiteId for backward compatibility, but use reference as primary
        record["createdBy"] = createdBy
        record["lastModifiedBy"] = lastModifiedBy
        record["lastModifiedDate"] = lastModifiedDate
        record["sharedVersion"] = Int64(sharedVersion ?? 1)
        
        // Store seats and parking ticket as JSON data
        if let seatsData = try? JSONEncoder().encode(seats) {
            record["seatsData"] = seatsData
        }
        
        if let parkingTicket = parkingTicket,
           let parkingData = try? JSONEncoder().encode(parkingTicket) {
            record["parkingTicketData"] = parkingData
        }
        
        // Store suite ID as string for querying (references aren't queryable by default)
        if let suiteRecordID = suiteRecordID {
            record["suiteId"] = suiteRecordID.recordName
            record["suite"] = CKRecord.Reference(recordID: suiteRecordID, action: .none)
        } else if let suiteRecord = suiteRecord {
            record["suiteId"] = suiteRecord.recordID.recordName
            record["suite"] = CKRecord.Reference(record: suiteRecord, action: .deleteSelf)
        }
        
        return record
    }
    
    static func fromCloudKitRecord(_ record: CKRecord) -> Concert? {
        guard let concertId = record["concertId"] as? Int64,
              let artist = record["artist"] as? String,
              let date = record["date"] as? Date else {
            return nil
        }
        
        var seats: [Seat] = []
        if let seatsData = record["seatsData"] as? Data,
           let decodedSeats = try? JSONDecoder().decode([Seat].self, from: seatsData) {
            seats = decodedSeats
        } else {
            seats = Array(repeating: Seat(), count: 8)
        }
        
        var parkingTicket: ParkingTicket?
        if let parkingData = record["parkingTicketData"] as? Data {
            parkingTicket = try? JSONDecoder().decode(ParkingTicket.self, from: parkingData)
        }
        
        return Concert(
            id: Int(concertId),
            artist: artist,
            date: date,
            seats: seats,
            parkingTicket: parkingTicket,
            suiteId: record["suite"] != nil ? (record["suite"] as? CKRecord.Reference)?.recordID.recordName : nil,
            createdBy: record["createdBy"] as? String,
            lastModifiedBy: record["lastModifiedBy"] as? String,
            lastModifiedDate: record["lastModifiedDate"] as? Date,
            sharedVersion: record["sharedVersion"] as? Int
        )
    }
}

// Extensions for new CloudKit models
extension InvitationToken {
    func toCloudKitRecord() -> CKRecord {
        // Use default zone for invitation tokens to avoid zone issues
        let record = CKRecord(recordType: CloudKitRecordType.invitationToken, 
                             recordID: CKRecord.ID(recordName: id))
        record["suiteId"] = suiteId
        record["invitedBy"] = invitedBy
        record["role"] = role.rawValue
        record["expirationDate"] = expirationDate
        record["createdDate"] = createdDate
        record["used"] = used
        record["usedBy"] = usedBy
        record["usedDate"] = usedDate
        
        return record
    }
    
    static func fromCloudKitRecord(_ record: CKRecord) -> InvitationToken? {
        guard let suiteId = record["suiteId"] as? String,
              let invitedBy = record["invitedBy"] as? String,
              let roleString = record["role"] as? String,
              let role = UserRole(rawValue: roleString),
              let _ = record["expirationDate"] as? Date,
              let _ = record["createdDate"] as? Date,
              let used = record["used"] as? Bool else {
            return nil
        }

        var token = InvitationToken(suiteId: suiteId, invitedBy: invitedBy, role: role)
        token.used = used
        token.usedBy = record["usedBy"] as? String
        token.usedDate = record["usedDate"] as? Date
        
        return token
    }
}

extension SuiteSync {
    func toCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: CloudKitRecordType.suiteSync, 
                             recordID: CKRecord.ID(recordName: "sync_\(suiteId)"))
        record["suiteId"] = suiteId
        record["lastSyncDate"] = lastSyncDate
        record["syncVersion"] = Int64(syncVersion)
        
        // Store pending changes as JSON
        if let changesData = try? JSONEncoder().encode(pendingChanges) {
            record["pendingChanges"] = changesData
        }
        
        return record
    }
    
    static func fromCloudKitRecord(_ record: CKRecord) -> SuiteSync? {
        guard let suiteId = record["suiteId"] as? String,
              let _ = record["lastSyncDate"] as? Date,
              let syncVersionInt = record["syncVersion"] as? Int64 else {
            return nil
        }
        
        var sync = SuiteSync(suiteId: suiteId, syncVersion: Int(syncVersionInt))
        
        // Decode pending changes
        if let changesData = record["pendingChanges"] as? Data,
           let changes = try? JSONDecoder().decode([String: String].self, from: changesData) {
            sync.pendingChanges = changes
        }
        
        return sync
    }
}

// MARK: - Seat Model
struct Seat: Codable, Equatable {
    var status: SeatStatus
    var price: Double?
    var note: String? // For reserved seats - max 5 words
    var source: TicketSource? // For sold seats - ticket source
    var cost: Double? // Cost per ticket (default $25)
    var dateSold: Date? // Date when ticket was sold
    var datePaid: Date? // Date when payment was received
    var familyPersonName: String? // For family seats - person's name
    
    // Donation-specific properties (only used when source == .donation)
    var donationDate: Date? // Date tickets were transferred to charity
    var donationFaceValue: Double? // MSRP per ticket from venue
    var charityName: String? // Full legal name of charity
    var charityAddress: String? // Charity mailing address
    var charityEIN: String? // Employer Identification Number
    var charityContactName: String? // Contact person at charity
    var charityContactInfo: String? // Email or phone for contact person
    
    // Multi-user sharing properties
    var lastModifiedBy: String? // User ID who last modified this seat
    var lastModifiedDate: Date? // When this seat was last modified
    var modificationHistory: [SeatModification]? // History of changes for conflict resolution
    var conflictResolutionVersion: Int? // Version number for conflict resolution
    
    init(status: SeatStatus = .available, price: Double? = nil, note: String? = nil, source: TicketSource? = nil, cost: Double? = nil, dateSold: Date? = nil, datePaid: Date? = nil, familyPersonName: String? = nil, donationDate: Date? = nil, donationFaceValue: Double? = nil, charityName: String? = nil, charityAddress: String? = nil, charityEIN: String? = nil, charityContactName: String? = nil, charityContactInfo: String? = nil, lastModifiedBy: String? = nil, lastModifiedDate: Date? = nil, modificationHistory: [SeatModification]? = nil, conflictResolutionVersion: Int? = nil) {
        self.status = status
        self.price = price
        self.note = note
        self.source = source
        self.cost = cost
        self.dateSold = dateSold
        self.datePaid = datePaid
        self.familyPersonName = familyPersonName
        self.donationDate = donationDate
        self.donationFaceValue = donationFaceValue
        self.charityName = charityName
        self.charityAddress = charityAddress
        self.charityEIN = charityEIN
        self.charityContactName = charityContactName
        self.charityContactInfo = charityContactInfo
        self.lastModifiedBy = lastModifiedBy
        self.lastModifiedDate = lastModifiedDate
        self.modificationHistory = modificationHistory ?? []
        self.conflictResolutionVersion = conflictResolutionVersion ?? 1
    }
    
    // Helper method to record a modification
    mutating func recordModification(by userId: String, userName: String, previousStatus: SeatStatus) {
        let modification = SeatModification(
            userId: userId,
            userName: userName,
            previousStatus: previousStatus,
            newStatus: self.status
        )
        
        if modificationHistory == nil {
            modificationHistory = []
        }
        modificationHistory?.append(modification)
        
        lastModifiedBy = userId
        lastModifiedDate = Date()
        conflictResolutionVersion = (conflictResolutionVersion ?? 1) + 1
    }
}

// MARK: - Parking Ticket Model
struct ParkingTicket: Codable, Equatable {
    var status: SeatStatus
    var price: Double?
    var source: TicketSource?
    var cost: Double?
    var dateSold: Date?
    var datePaid: Date?
    var note: String?
    
    init(status: SeatStatus = .available, price: Double? = nil, source: TicketSource? = nil, cost: Double? = nil, dateSold: Date? = nil, datePaid: Date? = nil, note: String? = nil) {
        self.status = status
        self.price = price
        self.source = source
        self.cost = cost ?? 0.0
        self.dateSold = dateSold
        self.datePaid = datePaid
        self.note = note
    }
}

// MARK: - Concert Model
struct Concert: Identifiable, Codable, Equatable {
    let id: Int
    var artist: String
    var date: Date
    var seats: [Seat] // Array of 8 seats
    var parkingTicket: ParkingTicket? // One parking ticket per show
    
    // Multi-user sharing properties
    var suiteId: String? // ID of the shared suite this concert belongs to
    var createdBy: String? // User ID who created this concert
    var lastModifiedBy: String? // User ID who last modified this concert
    var lastModifiedDate: Date? // When this concert was last modified
    var sharedVersion: Int? // Version number for conflict resolution
    
    var ticketsSold: Int {
        seats.filter { $0.status == .sold }.count
    }
    
    var ticketsReserved: Int {
        seats.filter { $0.status == .reserved }.count
    }
    
    var parkingTicketSold: Bool {
        parkingTicket?.status == .sold
    }
    
    var parkingTicketReserved: Bool {
        parkingTicket?.status == .reserved
    }
    
    var totalRevenue: Double {
        let seatRevenue = seats.compactMap { seat in
            seat.status == .sold ? seat.price : nil
        }.reduce(0, +)
        
        let parkingRevenue = parkingTicket?.status == .sold ? (parkingTicket?.price ?? 0.0) : 0.0
        
        return seatRevenue + parkingRevenue
    }
    
    var totalCost: Double {
        let seatCost = seats.compactMap { seat in
            seat.status == .sold ? (seat.cost ?? 0.0) : nil
        }.reduce(0, +)
        
        let parkingCost = parkingTicket?.status == .sold ? (parkingTicket?.cost ?? 0.0) : 0.0
        
        return seatCost + parkingCost
    }
    
    var profit: Double {
        totalRevenue - totalCost
    }
    
    // Legacy compatibility for existing data
    var seatsSold: [Bool] {
        seats.map { $0.status == .sold }
    }
    
    init(id: Int, artist: String, date: Date, seats: [Seat] = Array(repeating: Seat(), count: 8), parkingTicket: ParkingTicket? = ParkingTicket(), suiteId: String? = nil, createdBy: String? = nil, lastModifiedBy: String? = nil, lastModifiedDate: Date? = nil, sharedVersion: Int? = nil) {
        self.id = id
        self.artist = artist
        self.date = date
        self.seats = seats
        self.parkingTicket = parkingTicket
        self.suiteId = suiteId
        self.createdBy = createdBy
        self.lastModifiedBy = lastModifiedBy
        self.lastModifiedDate = lastModifiedDate
        self.sharedVersion = sharedVersion ?? 1
    }
    
    // Helper method to record a modification
    mutating func recordModification(by userId: String) {
        lastModifiedBy = userId
        lastModifiedDate = Date()
        sharedVersion = (sharedVersion ?? 1) + 1
    }
}

// MARK: - Backup Data Structure
struct BackupData: Codable {
    let concerts: [Concert]
    let backupDate: Date
    let version: String
    let suiteSettings: SuiteSettings?
    
    enum CodingKeys: String, CodingKey {
        case concerts, backupDate, version, suiteSettings
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        concerts = try container.decode([Concert].self, forKey: .concerts)
        backupDate = try container.decode(Date.self, forKey: .backupDate)
        version = try container.decode(String.self, forKey: .version)
        // suiteSettings is optional for backwards compatibility with v1.0
        suiteSettings = try container.decodeIfPresent(SuiteSettings.self, forKey: .suiteSettings)
    }
    
    init(concerts: [Concert], backupDate: Date, version: String, suiteSettings: SuiteSettings) {
        self.concerts = concerts
        self.backupDate = backupDate
        self.version = version
        self.suiteSettings = suiteSettings
    }
}

struct SuiteSettings: Codable {
    let suiteName: String
    let venueLocation: String
    let familyTicketPrice: Double
    let defaultSeatCost: Double
}

// MARK: - Year-End Archive Models

enum ArchiveError: Error, LocalizedError {
    case noArchivesDirectory
    case archiveAlreadyExists(year: Int)
    case noConcertsForYear(year: Int)
    case failedToSave(Error)
    case failedToLoad(Error)
    case failedToDelete(Error)
    case invalidArchiveData

    var errorDescription: String? {
        switch self {
        case .noArchivesDirectory:
            return "Could not access archives directory"
        case .archiveAlreadyExists(let year):
            return "An archive for \(year) already exists"
        case .noConcertsForYear(let year):
            return "No concerts found for \(year)"
        case .failedToSave(let error):
            return "Failed to save archive: \(error.localizedDescription)"
        case .failedToLoad(let error):
            return "Failed to load archive: \(error.localizedDescription)"
        case .failedToDelete(let error):
            return "Failed to delete archive: \(error.localizedDescription)"
        case .invalidArchiveData:
            return "Archive data is invalid or corrupted"
        }
    }
}

enum ArchiveReportType: String, CaseIterable, Identifiable {
    case full = "Full Report"
    case executiveSummary = "Executive Summary"
    case concertOverview = "Concert Overview"
    case seatData = "Seat Data"
    case profitAnalysis = "Profit Analysis"
    case charity = "Charity Report"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .full: return "doc.text.fill"
        case .executiveSummary: return "chart.bar.doc.horizontal"
        case .concertOverview: return "list.bullet.rectangle"
        case .seatData: return "tablecells"
        case .profitAnalysis: return "chart.line.uptrend.xyaxis"
        case .charity: return "heart.fill"
        }
    }

    var filename: String {
        switch self {
        case .full: return "Full_Report"
        case .executiveSummary: return "Executive_Summary"
        case .concertOverview: return "Concert_Overview"
        case .seatData: return "Seat_Data"
        case .profitAnalysis: return "Profit_Analysis"
        case .charity: return "Charity_Report"
        }
    }
}

struct ArchiveReports: Codable {
    let fullReport: String
    let executiveSummary: String
    let concertOverview: String
    let seatData: String
    let profitAnalysis: String
    let charityReport: String

    func getReport(for type: ArchiveReportType) -> String {
        switch type {
        case .full: return fullReport
        case .executiveSummary: return executiveSummary
        case .concertOverview: return concertOverview
        case .seatData: return seatData
        case .profitAnalysis: return profitAnalysis
        case .charity: return charityReport
        }
    }
}

struct ArchiveMetadata: Codable {
    let concertCount: Int
    let totalRevenue: Double
    let totalProfit: Double
    let totalSeatsSold: Int
    let totalSeatsReserved: Int
    let totalCharityDonations: Int
}

struct YearArchive: Identifiable, Codable {
    let id: UUID
    let year: Int
    let archiveDate: Date
    let concerts: [Concert]
    let suiteSettings: SuiteSettings
    let reports: ArchiveReports
    let metadata: ArchiveMetadata

    init(year: Int, concerts: [Concert], suiteSettings: SuiteSettings, reports: ArchiveReports, metadata: ArchiveMetadata) {
        self.id = UUID()
        self.year = year
        self.archiveDate = Date()
        self.concerts = concerts
        self.suiteSettings = suiteSettings
        self.reports = reports
        self.metadata = metadata
    }
}

// MARK: - Shared Suite Manager
class SharedSuiteManager: ObservableObject {
    @Published var currentSuiteInfo: SharedSuiteInfo?
    @Published var userRole: UserRole = .owner
    @Published var currentUserId: String = ""
    @Published var currentUserName: String = ""
    @Published var isSharedSuite: Bool = false
    @Published var cloudKitStatus: String = "Ready"
    @Published var isCloudKitAvailable: Bool = false
    @Published var isSyncing: Bool = false
    @Published var isOffline: Bool = false
    @Published var pendingOperationsCount: Int = 0
    
    // Local token tracking to prevent immediate reuse
    @Published private var usedTokens = Set<String>()
    @Published private var tokenUsageHistory: [String: Date] = [:]
    
    // Suite-level tracking to prevent using different tokens for same suite after leaving
    @Published private var accessedSuites: [String: Date] = [:] // suiteId -> last accessed date
    
    // Alert state for suite deletion
    @Published var showSuiteDeletedAlert = false
    @Published var deletedSuiteName = ""
    
    private let userDefaults = UserDefaults.standard
    private let iCloudStore = NSUbiquitousKeyValueStore.default
    private let cloudKitContainer = CKContainer.default()
    private var cloudKitDatabase: CKDatabase { 
        return cloudKitContainer.privateCloudDatabase 
    }
    
    private var publicCloudKitDatabase: CKDatabase {
        return cloudKitContainer.publicCloudDatabase
    }
    
    private let suiteInfoKey = "SharedSuiteInfo"
    private let userIdKey = "CurrentUserId"
    private let userNameKey = "CurrentUserName"
    private let subscriptionID = "SharedSuiteUpdates"
    private let offlineQueueKey = "OfflineOperationQueue"
    
    // Concert data manager reference for clearing data when leaving suite
    weak var concertManager: ConcertDataManager?
    
    // Offline operation queue
    private var offlineQueue: [OfflineOperation] = []
    private var retryTimer: Timer?
    
    var isInSharedSuite: Bool {
        return currentSuiteInfo != nil
    }
    
    init() {
        loadUserInfo()
        loadSuiteInfo()
        loadOfflineQueue()
        checkCloudKitAvailability()
        startRetryTimer()
    }
    
    private func loadUserInfo() {
        // Generate or load user ID
        if let existingUserId = userDefaults.string(forKey: userIdKey) {
            self.currentUserId = existingUserId
            print("🔧 DEBUG: Loaded existing user ID: \(existingUserId)")
        } else {
            self.currentUserId = UUID().uuidString
            userDefaults.set(self.currentUserId, forKey: userIdKey)
            print("🔧 DEBUG: Generated new user ID: \(self.currentUserId)")
        }
        
        // Load user name (default to device name)
        if let existingUserName = userDefaults.string(forKey: userNameKey) {
            currentUserName = existingUserName
        } else {
            #if canImport(UIKit)
            currentUserName = UIDevice.current.name
            #else
            currentUserName = "Unknown User"
            #endif
            userDefaults.set(currentUserName, forKey: userNameKey)
        }
    }
    
    private func loadSuiteInfo() {
        if let data = userDefaults.data(forKey: suiteInfoKey),
           let suiteInfo = try? JSONDecoder().decode(SharedSuiteInfo.self, from: data) {
            currentSuiteInfo = suiteInfo
            isSharedSuite = true
            
            // Determine user role
            print("🔧 DEBUG: Role determination - Current User ID: \(self.currentUserId)")
            print("🔧 DEBUG: Role determination - Suite Owner ID: \(suiteInfo.ownerId)")
            print("🔧 DEBUG: Role determination - Suite Members: \(suiteInfo.members.map { "\($0.userId)(\($0.role.rawValue))" })")

            if suiteInfo.ownerId == self.currentUserId {
                userRole = .owner
                print("🔧 DEBUG: Role determination - DETECTED AS OWNER")
            } else if let member = suiteInfo.members.first(where: { $0.userId == self.currentUserId }) {
                userRole = member.role
                print("🔧 DEBUG: Role determination - DETECTED AS MEMBER with role: \(member.role.rawValue)")
            } else {
                userRole = .viewer
                print("🔧 DEBUG: Role determination - DETECTED AS VIEWER (not in members list)")
            }
        }
    }
    
    private func saveSuiteInfo() {
        guard let suiteInfo = currentSuiteInfo else { return }
        
        do {
            let data = try JSONEncoder().encode(suiteInfo)
            userDefaults.set(data, forKey: suiteInfoKey)
            
            // Also save to iCloud for sharing
            iCloudStore.set(data, forKey: suiteInfoKey)
            iCloudStore.synchronize()
        } catch {
            // Failed to save suite info: \(error)
        }
    }
    
    // MARK: - Suite Management
    
    func createSharedSuite(suiteName: String, venueLocation: String) {
        let suiteId = UUID().uuidString
        let suiteInfo = SharedSuiteInfo(
            suiteId: suiteId,
            suiteName: suiteName,
            venueLocation: venueLocation,
            ownerId: self.currentUserId
        )

        currentSuiteInfo = suiteInfo
        userRole = .owner
        isSharedSuite = true
        saveSuiteInfo()

        // For owners: enable CloudSync automatically and sync current settings to shared suite
        if let concertManager = concertManager,
           let settingsManager = concertManager.settingsManager {
            // Automatically enable CloudSync for shared suite owners
            if !settingsManager.isCloudSyncEnabled {
                settingsManager.enableCloudSync()
                settingsManager.showCloudSyncEnabledForSharingAlert()
            }
            settingsManager.syncToSharedSuite()
        }
    }
    
    func joinSharedSuite(_ suiteInfo: SharedSuiteInfo, as role: UserRole = .viewer) {
        // Add current user as a member
        let member = SuiteMember(
            userId: self.currentUserId,
            displayName: currentUserName,
            role: role
        )
        
        var updatedSuiteInfo = suiteInfo
        updatedSuiteInfo.members.append(member)
        updatedSuiteInfo.lastModified = Date()
        
        currentSuiteInfo = updatedSuiteInfo
        userRole = role
        isSharedSuite = true
        saveSuiteInfo()
    }
    
    func leaveSharedSuite() {
        // Remove self from CloudKit member list and invalidate tokens before cleaning up
        Task {
            await removeSelfFromSuite()
            await invalidateUserInvitationTokens()
            try? await removeCloudKitSubscriptions()
        }
        
        // Clear all concert data when leaving shared suite
        concertManager?.clearAllData()
        
        currentSuiteInfo = nil
        userRole = .owner
        isSharedSuite = false
        userDefaults.removeObject(forKey: suiteInfoKey)
        iCloudStore.removeObject(forKey: suiteInfoKey)
        
        cloudKitStatus = "Left shared suite"
    }
    
    func deleteSharedSuite() {
        // Delete the suite from CloudKit and remove subscriptions
        Task {
            await deleteSharedSuiteFromCloudKit()
            try? await removeCloudKitSubscriptions()
        }
        
        // Owner keeps their local concert data - just remove sharing state
        currentSuiteInfo = nil
        userRole = .owner
        isSharedSuite = false
        userDefaults.removeObject(forKey: suiteInfoKey)
        iCloudStore.removeObject(forKey: suiteInfoKey)
        
        cloudKitStatus = "Shared suite deleted"
    }
    
    private func deleteSharedSuiteFromCloudKit() async {
        guard let suiteInfo = currentSuiteInfo, userRole == .owner else { return }
        
        print("🔧 DEBUG: Deleting shared suite from CloudKit: \(suiteInfo.suiteId)")
        
        do {
            // Delete the suite record
            let suiteRecordID = CKRecord.ID(recordName: "suite_\(suiteInfo.suiteId)")
            try await publicCloudKitDatabase.deleteRecord(withID: suiteRecordID)
            print("✅ DEBUG: Suite record deleted from CloudKit")
            
            // Delete associated invitation tokens
            await deleteInvitationTokensForSuite(suiteId: suiteInfo.suiteId)
            
            // Delete associated concert records (they're now orphaned)
            await deleteOrphanedConcertRecords(suiteId: suiteInfo.suiteId)
            
        } catch {
            print("❌ DEBUG: Failed to delete suite from CloudKit: \(error)")
        }
    }
    
    private func deleteInvitationTokensForSuite(suiteId: String) async {
        print("🔧 DEBUG: Deleting invitation tokens for suite: \(suiteId)")
        
        let predicate = NSPredicate(format: "suiteId == %@", suiteId)
        let query = CKQuery(recordType: CloudKitRecordType.invitationToken, predicate: predicate)
        
        do {
            let result = try await publicCloudKitDatabase.records(matching: query)
            let recordIDs = result.matchResults.compactMap { _, result in
                try? result.get().recordID
            }
            
            if !recordIDs.isEmpty {
                for recordID in recordIDs {
                    try await publicCloudKitDatabase.deleteRecord(withID: recordID)
                }
                print("✅ DEBUG: Deleted \(recordIDs.count) invitation tokens")
            }
        } catch {
            print("❌ DEBUG: Failed to delete invitation tokens: \(error)")
        }
    }
    
    private func deleteOrphanedConcertRecords(suiteId: String) async {
        print("🔧 DEBUG: Deleting orphaned concert records for suite: \(suiteId)")
        
        let predicate = NSPredicate(format: "suiteId == %@", suiteId)
        let query = CKQuery(recordType: CloudKitRecordType.concert, predicate: predicate)
        
        do {
            let result = try await publicCloudKitDatabase.records(matching: query)
            let recordIDs = result.matchResults.compactMap { _, result in
                try? result.get().recordID
            }
            
            if !recordIDs.isEmpty {
                for recordID in recordIDs {
                    try await publicCloudKitDatabase.deleteRecord(withID: recordID)
                }
                print("✅ DEBUG: Deleted \(recordIDs.count) orphaned concert records")
            }
        } catch {
            print("❌ DEBUG: Failed to delete orphaned concert records: \(error)")
        }
    }
    
    func updateUserRole(for userId: String, to newRole: UserRole) {
        guard var suiteInfo = currentSuiteInfo,
              userRole.canManageUsers,
              let memberIndex = suiteInfo.members.firstIndex(where: { $0.userId == userId }) else {
            return
        }
        
        var updatedMember = suiteInfo.members[memberIndex]
        updatedMember = SuiteMember(
            userId: updatedMember.userId,
            displayName: updatedMember.displayName,
            role: newRole
        )
        
        suiteInfo.members[memberIndex] = updatedMember
        suiteInfo.lastModified = Date()
        currentSuiteInfo = suiteInfo
        saveSuiteInfo()
        
        // Sync to CloudKit
        Task {
            do {
                let record = suiteInfo.toCloudKitRecord()
                _ = try await self.publicCloudKitDatabase.save(record)
            } catch {
                // Handle error silently for now
            }
        }
    }
    
    func removeMember(userId: String) {
        guard var suiteInfo = currentSuiteInfo,
              userRole.canManageUsers,
              userId != self.currentUserId else { // Can't remove self
            return
        }

        suiteInfo.members.removeAll { $0.userId == userId }
        suiteInfo.lastModified = Date()
        currentSuiteInfo = suiteInfo
        saveSuiteInfo()

        // Sync to CloudKit
        let suiteInfoToSync = suiteInfo
        Task {
            do {
                let record = suiteInfoToSync.toCloudKitRecord()
                _ = try await self.publicCloudKitDatabase.save(record)
            } catch {
                // Handle error silently for now
            }
        }
    }
    
    private func removeSelfFromSuite() async {
        guard var suiteInfo = currentSuiteInfo else { return }
        
        // Remove current user from members list
        let originalCount = suiteInfo.members.count
        suiteInfo.members.removeAll { $0.userId == self.currentUserId }
        
        // Only update CloudKit if we actually removed someone
        if suiteInfo.members.count < originalCount {
            suiteInfo.lastModified = Date()
            
            // Use fetch-then-update pattern to avoid "record to insert already exists" errors
            do {
                let suiteRecordID = CKRecord.ID(recordName: "suite_\(suiteInfo.suiteId)")
                let existingRecord = try await publicCloudKitDatabase.record(for: suiteRecordID)
                
                // Update existing record with new member list
                if let membersData = try? JSONEncoder().encode(suiteInfo.members) {
                    existingRecord["membersData"] = membersData
                }
                existingRecord["lastModified"] = suiteInfo.lastModified
                existingRecord["memberCount"] = Int64(suiteInfo.members.count)
                
                _ = try await publicCloudKitDatabase.save(existingRecord)
                print("🔄 Successfully removed self from suite members in CloudKit")
            } catch let ckError as CKError where ckError.code == .unknownItem {
                // Suite record was deleted by owner - this is expected behavior
                print("ℹ️ Suite record was already deleted by owner - no action needed")
            } catch {
                print("❌ Failed to remove self from suite members in CloudKit: \(error)")
            }
        }
    }
    
    private func cleanupLocalTokenHistory() {
        // Clean up tokens older than 24 hours to prevent memory bloat
        let dayAgo = Date().addingTimeInterval(-86400) // 24 hours ago
        
        let oldTokens = tokenUsageHistory.filter { _, date in
            date < dayAgo
        }.map { token, _ in token }
        
        for token in oldTokens {
            tokenUsageHistory.removeValue(forKey: token)
            usedTokens.remove(token)
        }
        
        // Clean up suite access history older than 24 hours
        let oldSuites = accessedSuites.filter { _, date in
            date < dayAgo
        }.map { suiteId, _ in suiteId }
        
        for suiteId in oldSuites {
            accessedSuites.removeValue(forKey: suiteId)
        }
        
        let totalCleaned = oldTokens.count + oldSuites.count
        if totalCleaned > 0 {
            print("🧹 DEBUG: Cleaned up \(oldTokens.count) old token records and \(oldSuites.count) old suite access records")
        }
    }
    
    private func invalidateUserInvitationTokens() async {
        guard let suiteInfo = currentSuiteInfo else { return }
        
        // Clean up old local token history
        await MainActor.run {
            cleanupLocalTokenHistory()
        }
        
        print("🔧 DEBUG: Checking invitation tokens for user leaving suite: \(currentUserId)")
        
        // Query for invitation tokens that were used by this specific user
        let predicate = NSPredicate(format: "suiteId == %@ AND usedBy == %@", suiteInfo.suiteId, currentUserId)
        let query = CKQuery(recordType: CloudKitRecordType.invitationToken, predicate: predicate)
        
        do {
            let result = try await publicCloudKitDatabase.records(matching: query)
            let records = result.matchResults.compactMap { _, result in
                try? result.get()
            }
            
            print("🔧 DEBUG: Found \(records.count) tokens used by current user")
            
            if records.isEmpty {
                print("ℹ️ DEBUG: No tokens found for current user - this is expected if tokens are properly marked as used")
            } else {
                // These tokens should already be marked as used=true, so they shouldn't work again
                // But let's double-check and ensure they're definitely invalid
                for tokenRecord in records {
                    if let used = tokenRecord["used"] as? Bool, !used {
                        // This shouldn't happen, but if we find an unused token, mark it as used
                        tokenRecord["used"] = true
                        tokenRecord["usedDate"] = Date()
                        try await publicCloudKitDatabase.save(tokenRecord)
                        print("🔄 DEBUG: Fixed unused token that should have been marked as used")
                    } else {
                        print("✅ DEBUG: Token already properly marked as used")
                    }
                }
            }
        } catch {
            print("❌ DEBUG: Failed to check invitation tokens: \(error)")
        }
    }
    
    // MARK: - Permission Checking
    
    func canModifySeats() -> Bool {
        return !isSharedSuite || userRole.canEdit
    }
    
    func canManageMembers() -> Bool {
        return !isSharedSuite || userRole.canManageUsers
    }
    
    func canDeleteConcerts() -> Bool {
        return !isSharedSuite || userRole.canEdit
    }
    
    // MARK: - Token Invalidation
    
    private func invalidateAllInvitationTokens(forSuite suiteId: String) async {
        print("🔧 DEBUG: Invalidating all invitation tokens for suite: \(suiteId)")
        
        // Query for all invitation tokens for this suite
        let predicate = NSPredicate(format: "suiteId == %@", suiteId)
        let query = CKQuery(recordType: CloudKitRecordType.invitationToken, predicate: predicate)
        
        do {
            let result = try await publicCloudKitDatabase.records(matching: query)
            let records = result.matchResults.compactMap { _, result in
                try? result.get()
            }
            
            print("🔧 DEBUG: Found \(records.count) invitation tokens for suite")
            
            var invalidatedCount = 0
            for tokenRecord in records {
                do {
                    // Mark token as used to invalidate it
                    tokenRecord["used"] = true
                    tokenRecord["usedBy"] = "INVALIDATED_AFTER_JOIN"
                    tokenRecord["usedDate"] = Date()
                    
                    _ = try await publicCloudKitDatabase.save(tokenRecord)
                    invalidatedCount += 1
                } catch {
                    print("⚠️ DEBUG: Failed to invalidate token \(tokenRecord.recordID): \(error)")
                }
            }
            
            print("✅ DEBUG: Successfully invalidated \(invalidatedCount) invitation tokens")
            
        } catch {
            print("❌ DEBUG: Failed to query invitation tokens: \(error)")
        }
    }
    
    // MARK: - Token Usage Tracking
    
    private func isTokenAlreadyUsed(tokenId: String, suiteId: String) async -> Bool {
        // Check local storage first
        let localUsedTokensKey = "usedTokens_\(suiteId)"
        if let usedTokens = UserDefaults.standard.stringArray(forKey: localUsedTokensKey),
           usedTokens.contains(tokenId) {
            print("🔧 DEBUG: Token \(tokenId) found in local used tokens list")
            return true
        }
        
        // Check CloudKit for a shared "used tokens" record
        do {
            let usedTokensRecordID = CKRecord.ID(recordName: "usedTokens_\(suiteId)")
            let usedTokensRecord = try await publicCloudKitDatabase.record(for: usedTokensRecordID)
            
            if let usedTokensList = usedTokensRecord["tokenIds"] as? [String],
               usedTokensList.contains(tokenId) {
                print("🔧 DEBUG: Token \(tokenId) found in CloudKit used tokens list")
                // Also cache locally for faster future checks
                var localUsedTokens = UserDefaults.standard.stringArray(forKey: localUsedTokensKey) ?? []
                if !localUsedTokens.contains(tokenId) {
                    localUsedTokens.append(tokenId)
                    UserDefaults.standard.set(localUsedTokens, forKey: localUsedTokensKey)
                }
                return true
            }
        } catch let ckError as CKError where ckError.code == .unknownItem {
            // No used tokens record exists yet - this is fine
            print("🔧 DEBUG: No used tokens record exists yet for suite \(suiteId)")
        } catch {
            print("❌ DEBUG: Failed to check used tokens: \(error)")
            // If we can't check CloudKit, fall back to local check only
        }
        
        return false
    }
    
    private func recordTokenAsUsed(tokenId: String, suiteId: String, userId: String) async {
        print("🔧 DEBUG: Recording token \(tokenId) as used")
        
        // Record locally first
        let localUsedTokensKey = "usedTokens_\(suiteId)"
        var localUsedTokens = UserDefaults.standard.stringArray(forKey: localUsedTokensKey) ?? []
        if !localUsedTokens.contains(tokenId) {
            localUsedTokens.append(tokenId)
            UserDefaults.standard.set(localUsedTokens, forKey: localUsedTokensKey)
            print("✅ DEBUG: Token recorded in local used tokens list")
        }
        
        // Try to update CloudKit used tokens record
        do {
            let usedTokensRecordID = CKRecord.ID(recordName: "usedTokens_\(suiteId)")
            
            // Try to fetch existing record first
            do {
                let existingRecord = try await publicCloudKitDatabase.record(for: usedTokensRecordID)
                var tokenIds = (existingRecord["tokenIds"] as? [String]) ?? []
                
                if !tokenIds.contains(tokenId) {
                    tokenIds.append(tokenId)
                    existingRecord["tokenIds"] = tokenIds
                    existingRecord["lastModified"] = Date()
                    
                    _ = try await publicCloudKitDatabase.save(existingRecord)
                    print("✅ DEBUG: Updated existing used tokens record in CloudKit")
                }
            } catch let ckError as CKError where ckError.code == .unknownItem {
                // Create new used tokens record
                let usedTokensRecord = CKRecord(recordType: CloudKitRecordType.usedTokens, recordID: usedTokensRecordID)
                usedTokensRecord["suiteId"] = suiteId
                usedTokensRecord["tokenIds"] = [tokenId]
                usedTokensRecord["lastModified"] = Date()
                
                _ = try await publicCloudKitDatabase.save(usedTokensRecord)
                print("✅ DEBUG: Created new used tokens record in CloudKit")
            }
            
        } catch {
            print("❌ DEBUG: Failed to update used tokens in CloudKit: \(error)")
            // Local recording still worked, so not a complete failure
        }
    }
    
    
    // MARK: - CloudKit Integration
    
    private func checkCloudKitAvailability() {
        cloudKitContainer.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.isCloudKitAvailable = true
                    self?.cloudKitStatus = "Ready"
                    // Set up CloudKit zone when available
                    Task {
                        await self?.ensureCloudKitZoneExists()
                    }
                case .noAccount:
                    self?.isCloudKitAvailable = false
                    self?.cloudKitStatus = "No iCloud account"
                case .couldNotDetermine:
                    self?.isCloudKitAvailable = false
                    self?.cloudKitStatus = "Could not determine status"
                case .restricted:
                    self?.isCloudKitAvailable = false
                    self?.cloudKitStatus = "Restricted"
                case .temporarilyUnavailable:
                    self?.isCloudKitAvailable = false
                    self?.cloudKitStatus = "Temporarily unavailable"
                @unknown default:
                    self?.isCloudKitAvailable = false
                    self?.cloudKitStatus = "Unknown status"
                }
            }
        }
    }
    
    private func ensureCloudKitZoneExists() async {
        do {
            let zone = CloudKitZone.createCustomZone()
            _ = try await cloudKitDatabase.save(zone)
            await MainActor.run {
                cloudKitStatus = "CloudKit zone ready"
            }
        } catch {
            // Zone might already exist, which is fine
            if let ckError = error as? CKError {
                switch ckError.code {
                case .serverRecordChanged, .unknownItem:
                    // Zone already exists, continue
                    await MainActor.run {
                        cloudKitStatus = "CloudKit zone ready (existing)"
                    }
                    return
                default:
                    await MainActor.run {
                        cloudKitStatus = "Zone creation failed: \(ckError.localizedDescription)"
                    }
                }
            }
        }
    }
    
    func createSharedSuiteInCloud(suiteName: String, venueLocation: String) async throws -> String {
        guard isCloudKitAvailable else {
            throw CloudKitError.notAvailable
        }
        
        await MainActor.run {
            cloudKitStatus = "Creating shared suite..."
            isSyncing = true
        }
        
        // Create suite info with owner as initial member (move outside do block)
        var suiteInfo = SharedSuiteInfo(
            suiteId: UUID().uuidString,
            suiteName: suiteName,
            venueLocation: venueLocation,
            ownerId: self.currentUserId
        )

        // Include current pricing settings from SettingsManager
        if let concertManager = concertManager,
           let settingsManager = concertManager.settingsManager {
            suiteInfo.familyTicketPrice = settingsManager.familyTicketPrice
            suiteInfo.defaultSeatCost = settingsManager.defaultSeatCost
        }
        
        // Add owner as first member
        let ownerMember = SuiteMember(
            userId: self.currentUserId,
            displayName: currentUserName,
            role: .owner
        )
        suiteInfo.members = [ownerMember]
        
        do {
            // Ensure the zone exists first
            await ensureCloudKitZoneExists()
            
            let record = suiteInfo.toCloudKitRecord()
            let savedRecord = try await executeWithRetry { [self] in
                try await self.publicCloudKitDatabase.save(record)
            }
            
            // Update local state
            await MainActor.run {
                currentSuiteInfo = SharedSuiteInfo.fromCloudKitRecord(savedRecord)
                isSharedSuite = true
                userRole = .owner
                cloudKitStatus = "Suite created successfully"
                isSyncing = false
                saveSuiteInfo()

                // Automatically enable CloudSync for shared suite owners
                if let concertManager = concertManager,
                   let settingsManager = concertManager.settingsManager,
                   !settingsManager.isCloudSyncEnabled {
                    settingsManager.enableCloudSync()
                    settingsManager.showCloudSyncEnabledForSharingAlert()
                }
            }
            
            // Set up real-time updates for the new suite
            Task {
                await setupCloudKitSubscriptions()
                // Migrate existing local concerts to the shared suite
                await self.migrateLocalConcertsToSuite()
            }
            
            return savedRecord.recordID.recordName
        } catch {
            let cloudKitError = handleCloudKitError(error)
            
            // If it's a network error, queue the operation for later
            if cloudKitError == .networkUnavailable {
                if let data = try? JSONEncoder().encode(suiteInfo) {
                    let operation = OfflineOperation(type: .createSuite, data: data)
                    addToOfflineQueue(operation)
                }
            }
            
            await MainActor.run {
                cloudKitStatus = cloudKitError.localizedDescription
                isOffline = (cloudKitError == .networkUnavailable)
                isSyncing = false
            }
            throw cloudKitError
        }
    }
    
    func joinSharedSuiteFromCloud(suiteId: String) async throws {
        guard isCloudKitAvailable else {
            throw CloudKitError.notAvailable
        }
        
        await MainActor.run {
            cloudKitStatus = "Joining shared suite..."
            isSyncing = true
        }
        
        let recordID = CKRecord.ID(recordName: suiteId)
        
        do {
            let record = try await self.publicCloudKitDatabase.record(for: recordID)
            
            if var suiteInfo = SharedSuiteInfo.fromCloudKitRecord(record) {
                // Check if user is already a member
                if suiteInfo.members.contains(where: { $0.userId == self.currentUserId }) {
                    // User is already a member, just update local state
                    let userRole = suiteInfo.members.first(where: { $0.userId == self.currentUserId })?.role ?? .viewer
                    let suiteInfoToSync = suiteInfo

                    await MainActor.run {
                        currentSuiteInfo = suiteInfoToSync
                        isSharedSuite = true
                        self.userRole = userRole
                        cloudKitStatus = "Rejoined suite successfully"
                        isSyncing = false
                        saveSuiteInfo()

                        // Sync settings from shared suite
                        if let concertManager = concertManager,
                           let settingsManager = concertManager.settingsManager {
                            settingsManager.updateFromSharedSuite(suiteInfoToSync)
                            // Immediately refresh concert data for UI
                            concertManager.loadConcerts()
                        }
                    }
                    
                    // Set up real-time updates and sync concert data
                    Task {
                        await setupCloudKitSubscriptions()
                        await syncConcertData()
                    }
                } else {
                    // Add current user as new member (remove any stale entries first to prevent duplicates)
                    suiteInfo.members.removeAll { $0.userId == self.currentUserId }
                    let member = SuiteMember(
                        userId: self.currentUserId,
                        displayName: currentUserName,
                        role: .viewer // Default role for new members
                    )
                    suiteInfo.members.append(member)
                    suiteInfo.lastModified = Date()
                    
                    // Try to save updated suite info to CloudKit with conflict resolution
                    do {
                        try await addMemberToSuiteRecord(member: member, suiteInfo: suiteInfo)
                        print("✅ DEBUG: Added member to suite record successfully")
                    } catch let error as CKError {
                        if error.code == .permissionFailure {
                            print("⚠️ DEBUG: Permission denied - only suite owner can add members (continuing anyway)")
                        } else {
                            print("⚠️ DEBUG: Could not update suite record with new member (continuing anyway): \(error)")
                        }
                        // Don't fail the join - user can still access the suite locally
                    } catch {
                        print("⚠️ DEBUG: Could not update suite record with new member (continuing anyway): \(error)")
                    }

                    // Update local state
                    let suiteInfoToSync = suiteInfo
                    await MainActor.run {
                        currentSuiteInfo = suiteInfoToSync
                        isSharedSuite = true
                        userRole = .viewer
                        cloudKitStatus = "Joined suite successfully"
                        isSyncing = false
                        saveSuiteInfo()

                        // Sync settings from shared suite
                        if let concertManager = concertManager,
                           let settingsManager = concertManager.settingsManager {
                            settingsManager.updateFromSharedSuite(suiteInfoToSync)
                            // Show read-only alert for new users joining the suite
                            settingsManager.showReadOnlySharedSuiteAlert()
                            // Immediately refresh concert data for UI
                            concertManager.loadConcerts()
                        }
                    }
                    
                    // Set up real-time updates, migrate existing data, and sync concert data
                    Task {
                        await setupCloudKitSubscriptions()
                        await migrateConcertRecordsWithSuiteId()
                        await syncConcertData()
                    }
                }
            } else {
                throw CloudKitError.recordNotFound
            }
        } catch {
            await MainActor.run {
                cloudKitStatus = "Failed to join suite: \(error.localizedDescription)"
                isSyncing = false
            }
            throw error
        }
    }
    
    func generateSharingLink() -> String? {
        guard let suiteInfo = currentSuiteInfo else { return nil }
        return "suitekeep://invite/\(suiteInfo.suiteId)"
    }
    
    func generateUniversalLink(tokenId: String) -> String {
        // Return just the URL - iOS will make it tappable automatically
        return "suitekeep://invite/\(tokenId)"
    }
    
    func generateInvitationInstructions() -> String {
        return """
🔥 You're invited to join my Fire Suite!

To join:
1. Download SuiteKeep from the App Store if you don't have it
2. Open SuiteKeep 
3. Go to Settings → Suite Sharing → Join Suite
4. Paste the invitation code or tap the link I'm sending next
"""
    }
    
    func generateInvitationCode(tokenId: String) -> String {
        return tokenId
    }
    
    func generateInvitationMessage(tokenId: String) -> String {
        return """
🔥 You're invited to join my Fire Suite!

Invitation Code: \(tokenId)

Tap to join: suitekeep://invite/\(tokenId)

Or open SuiteKeep → Settings → Suite Sharing → Join Suite and paste the code above.
"""
    }
    
    func generateInvitationLink(role: UserRole = .viewer, validForDays: Int = 7) async throws -> String {
        let tokenId = try await generateInvitationToken(role: role, validForDays: validForDays)
        return generateInvitationCode(tokenId: tokenId)
    }
    
    
    // MARK: - Invitation Management
    
    func generateInvitationToken(role: UserRole = .viewer, validForDays: Int = 7) async throws -> String {
        guard isCloudKitAvailable,
              let suiteInfo = currentSuiteInfo,
              userRole.canManageUsers else {
            throw CloudKitError.permissionDenied
        }
        
        await MainActor.run {
            cloudKitStatus = "Creating invitation..."
            isSyncing = true
        }
        
        do {
            // Ensure the zone exists first
            await ensureCloudKitZoneExists()
            
            // Check if suite record exists, create only if needed
            print("🔧 DEBUG: Checking if suite exists in CloudKit with ID: \(suiteInfo.suiteId)")
            do {
                let recordID = CKRecord.ID(recordName: suiteInfo.suiteId)
                _ = try await self.publicCloudKitDatabase.record(for: recordID)
                print("✅ DEBUG: Suite record already exists in CloudKit")
            } catch let ckError as CKError where ckError.code == .unknownItem {
                // Record doesn't exist, create it
                print("🔧 DEBUG: Suite record doesn't exist, creating it...")
                let suiteRecord = suiteInfo.toCloudKitRecord()
                _ = try await withTimeout(seconds: 30) { [self] in
                    try await executeWithRetry { [self] in
                        print("🔧 DEBUG: Attempting to create new suite record...")
                        let result = try await self.publicCloudKitDatabase.save(suiteRecord)
                        print("🔧 DEBUG: New suite record created: \(result.recordID)")
                        return result
                    }
                }
                print("✅ DEBUG: Suite record created successfully")
            } catch {
                print("❌ DEBUG: Error checking suite record: \(error)")
                // Continue anyway - we'll try to create the invitation token
            }
            
            let token = InvitationToken(
                suiteId: suiteInfo.suiteId,
                invitedBy: self.currentUserId,
                role: role,
                validForDays: validForDays
            )
            
            let tokenRecord = token.toCloudKitRecord()
            print("🔧 DEBUG: Saving invitation token to CloudKit with ID: \(token.id)")
            print("🔧 DEBUG: Token zone: \(tokenRecord.recordID.zoneID)")
            _ = try await withTimeout(seconds: 30) { [self] in
                try await executeWithRetry { [self] in
                    print("🔧 DEBUG: Attempting invitation token save...")
                    let result = try await self.publicCloudKitDatabase.save(tokenRecord)
                    print("🔧 DEBUG: Token save returned: \(result.recordID)")
                    return result
                }
            }
            print("✅ DEBUG: Invitation token saved successfully")
            
            await MainActor.run {
                cloudKitStatus = "Invitation created"
                isSyncing = false
            }
            
            return token.id
        } catch {
            let cloudKitError = handleCloudKitError(error)
            await MainActor.run {
                cloudKitStatus = "Failed to create invitation: \(cloudKitError.localizedDescription)"
                isSyncing = false
            }
            throw cloudKitError
        }
    }
    
    func validateAndUseInvitationToken(_ tokenId: String) async throws -> SharedSuiteInfo {
        guard isCloudKitAvailable else {
            throw CloudKitError.notAvailable
        }
        
        await MainActor.run {
            cloudKitStatus = "Validating invitation..."
            isSyncing = true
        }
        
        do {
            // Try to find the invitation token in default zone (since we save tokens there now)
            let tokenRecordID = CKRecord.ID(recordName: tokenId)
            print("🔧 DEBUG: Looking for invitation token with ID: \(tokenId)")
            print("🔧 DEBUG: Token record ID zone: \(tokenRecordID.zoneID)")
            let tokenRecord = try await withTimeout(seconds: 30) { [self] in
                try await self.publicCloudKitDatabase.record(for: tokenRecordID)
            }
            print("✅ DEBUG: Found invitation token record")
            
            guard let token = InvitationToken.fromCloudKitRecord(tokenRecord),
                  token.isValid else {
                print("❌ DEBUG: Token is invalid or expired")
                await MainActor.run {
                    cloudKitStatus = "Invalid or expired invitation"
                    isSyncing = false
                }
                throw CloudKitError.permissionDenied
            }
            print("✅ DEBUG: Token is valid, looking for suite: \(token.suiteId)")
            
            // Look for the suite in the default zone (since we're now saving both there)
            let suiteRecordID = CKRecord.ID(recordName: token.suiteId)
            print("🔧 DEBUG: Looking for suite record with ID: \(token.suiteId)")
            print("🔧 DEBUG: Suite record ID zone: \(suiteRecordID.zoneID)")
            let suiteRecord: CKRecord
            do {
                suiteRecord = try await withTimeout(seconds: 30) { [self] in
                    try await self.publicCloudKitDatabase.record(for: suiteRecordID)
                }
                print("✅ DEBUG: Found suite record")
            } catch let error as CKError {
                print("❌ DEBUG: Suite record lookup failed - Code: \(error.code.rawValue), Description: \(error.localizedDescription)")
                throw error
            }
            
            guard let suiteInfo = SharedSuiteInfo.fromCloudKitRecord(suiteRecord) else {
                await MainActor.run {
                    cloudKitStatus = "Suite record is invalid"
                    isSyncing = false
                }
                throw CloudKitError.recordNotFound
            }
            
            // Check if current user is already a member of the suite (prevents token reuse)
            if suiteInfo.members.contains(where: { $0.userId == self.currentUserId }) {
                print("❌ DEBUG: User is already a member of this suite")
                await MainActor.run {
                    cloudKitStatus = "You are already a member of this suite"
                    isSyncing = false
                }
                throw CloudKitError.permissionDenied
            }
            
            // Check local token usage tracking for immediate prevention of reuse
            if await MainActor.run(body: { self.usedTokens.contains(tokenId) }) {
                print("❌ DEBUG: Token already used locally - preventing reuse")
                await MainActor.run {
                    self.cloudKitStatus = "Token already used. Please contact suite owner for access"
                    self.isSyncing = false
                }
                // Create a specific error for used tokens that won't be converted by handleCloudKitError
                throw NSError(domain: "SuiteKeepErrorDomain", code: 1001, userInfo: [
                    NSLocalizedDescriptionKey: "Token already used. Please contact suite owner for access"
                ])
            }
            
            // Check if token was used recently (within 5 minutes) to prevent rapid reuse
            if let lastUsed = await MainActor.run(body: { self.tokenUsageHistory[tokenId] }),
               Date().timeIntervalSince(lastUsed) < 300 {
                print("❌ DEBUG: Token used recently - preventing reuse within 5 minutes")
                await MainActor.run {
                    self.cloudKitStatus = "Please wait before reusing this invitation"
                    self.isSyncing = false
                }
                throw NSError(domain: "SuiteKeepErrorDomain", code: 1002, userInfo: [
                    NSLocalizedDescriptionKey: "Please wait before reusing this invitation"
                ])
            }
            
            // Check if user has accessed this suite recently (within 10 minutes) - prevents using different tokens
            let tokenSuiteId = token.suiteId
            if let lastAccessed = await MainActor.run(body: { self.accessedSuites[tokenSuiteId] }),
               Date().timeIntervalSince(lastAccessed) < 600 { // 10 minutes
                print("❌ DEBUG: Suite accessed recently with different token - preventing abuse")
                await MainActor.run {
                    self.cloudKitStatus = "You recently left this suite. Please wait before rejoining."
                    self.isSyncing = false
                }
                throw NSError(domain: "SuiteKeepErrorDomain", code: 1003, userInfo: [
                    NSLocalizedDescriptionKey: "You recently left this suite. Please wait before rejoining."
                ])
            }
            
            // Immediately mark token as used locally first (provides instant protection)
            await MainActor.run {
                self.usedTokens.insert(tokenId)
                self.tokenUsageHistory[tokenId] = Date()
                self.accessedSuites[tokenSuiteId] = Date()
            }
            print("🔒 DEBUG: Token marked as used locally - immediate protection active")
            
            // Also invalidate in CloudKit for distributed protection
            print("🔒 DEBUG: Token validated successfully - invalidating in CloudKit to prevent reuse")
            
            // Try to mark the specific token as used first
            do {
                tokenRecord["used"] = true
                tokenRecord["usedBy"] = self.currentUserId
                tokenRecord["usedDate"] = Date()
                
                _ = try await self.publicCloudKitDatabase.save(tokenRecord)
                print("✅ DEBUG: Token marked as used in CloudKit successfully")
            } catch {
                print("⚠️ DEBUG: Could not mark token as used directly: \(error)")
                // If we can't mark this token, invalidate ALL tokens as a safety measure
                print("🔒 DEBUG: Falling back to invalidating all tokens for suite")
                await invalidateAllInvitationTokens(forSuite: token.suiteId)
            }
            
            await MainActor.run {
                cloudKitStatus = "Invitation validated"
                isSyncing = false
            }
            
            return suiteInfo
            
        } catch {
            // Check if this is one of our specific SuiteKeep errors (already handled with user-friendly message)
            if let nsError = error as NSError?, nsError.domain == "SuiteKeepErrorDomain" {
                // Status already set above, just re-throw the original error
                throw nsError
            }
            
            let cloudKitError = handleCloudKitError(error)
            await MainActor.run {
                cloudKitStatus = "Failed to validate invitation: \(cloudKitError.localizedDescription)"
                isSyncing = false
            }
            throw cloudKitError
        }
    }
    
    func joinSuiteWithInvitation(_ tokenId: String) async throws {
        let suiteInfo = try await validateAndUseInvitationToken(tokenId)
        try await joinSharedSuiteFromCloud(suiteId: suiteInfo.suiteId)
    }
    
    func syncWithCloudKit() async {
        guard isCloudKitAvailable else { return }

        // If we're supposed to be in a shared suite but have no suite info, we need to clean up
        if isSharedSuite && currentSuiteInfo == nil {
            print("🔄 DEBUG: In shared suite mode but no suite info - cleaning up orphaned state")
            await cleanupDeletedSuite()
            return
        }

        guard let suiteInfo = currentSuiteInfo else { return }

        await MainActor.run {
            cloudKitStatus = "Syncing with CloudKit..."
            isSyncing = true
        }
        
        do {
            let recordID = CKRecord.ID(recordName: suiteInfo.suiteId)
            let record = try await self.publicCloudKitDatabase.record(for: recordID)
            
            if let updatedSuiteInfo = SharedSuiteInfo.fromCloudKitRecord(record) {
                print("🔄 DEBUG: syncWithCloudKit - Updated suite info with \(updatedSuiteInfo.members.count) members")
                print("🔄 DEBUG: syncWithCloudKit - Members: \(updatedSuiteInfo.members.map { "\($0.displayName)(\($0.role.rawValue))" })")

                await MainActor.run {
                    let oldMemberCount = currentSuiteInfo?.members.count ?? 0
                    currentSuiteInfo = updatedSuiteInfo
                    let newMemberCount = updatedSuiteInfo.members.count

                    if oldMemberCount != newMemberCount {
                        print("🔄 DEBUG: Member count changed from \(oldMemberCount) to \(newMemberCount)")
                    }

                    cloudKitStatus = "Sync complete"
                    isSyncing = false
                    saveSuiteInfo()

                    // Force UI update by triggering objectWillChange
                    objectWillChange.send()
                }
            }
        } catch let ckError as CKError where ckError.code == .unknownItem {
            // Suite was deleted by owner - clean up local data
            print("🔄 DEBUG: Shared suite was deleted by owner - cleaning up local data")
            await cleanupDeletedSuite()
        } catch {
            await MainActor.run {
                cloudKitStatus = "Sync failed: \(error.localizedDescription)"
                isSyncing = false
            }
        }
    }

    func syncConcertData() async {
        guard isCloudKitAvailable else { return }
        
        // If we're supposed to be in a shared suite but have no suite info, we need to clean up
        if isSharedSuite && currentSuiteInfo == nil {
            print("🔄 DEBUG: In shared suite mode but no suite info during concert sync - cleaning up orphaned state")
            await cleanupDeletedSuite()
            return
        }
        
        guard let suiteInfo = currentSuiteInfo else { return }

        await MainActor.run {
            isSyncing = true
        }

        print("🔧 DEBUG: Syncing concert data for suite: \(suiteInfo.suiteId)")

        // Add small delay to account for CloudKit consistency
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        print("🔧 DEBUG: Waited 2 seconds for CloudKit consistency")
        
        do {
            print("🔧 DEBUG: Using direct record fetch approach (no queries due to schema limitations)")
            
            // Since CloudKit queries aren't working due to schema issues, we'll try a different approach:
            // 1. Get local concert data to know what record IDs to fetch
            // 2. Attempt to fetch those records directly from CloudKit
            // 3. Also try some common record ID patterns
            
            var syncedConcerts: [Concert] = []
            var recordsToFetch: [CKRecord.ID] = []
            
            // Add record IDs from suite info (shared concert IDs)
            if let concertIds = suiteInfo.concertIds {
                for concertId in concertIds {
                    let recordID = CKRecord.ID(recordName: "concert_\(concertId)")
                    recordsToFetch.append(recordID)
                }
                print("🔧 DEBUG: Found \(concertIds.count) concert IDs in suite record")
            }
            
            // Also add record IDs based on local concerts (if any exist)
            // Note: This would require access to concert data, but since we're in SharedSuiteManager,
            // we'll rely on the suite record's concert IDs for discovery
            
            print("🔧 DEBUG: Attempting to fetch \(recordsToFetch.count) known concert record IDs")
            
            // Try to fetch known records with fresh data (bypass cache)
            if !recordsToFetch.isEmpty {
                print("🔧 DEBUG: Fetching records with fresh data (bypassing cache)")
                let fetchResults = try await publicCloudKitDatabase.records(for: recordsToFetch)
                
                var fetchFailures = 0
                for (recordID, result) in fetchResults {
                    switch result {
                    case .success(let record):
                        // Verify this record belongs to our suite
                        let suiteRef = record["suite"] as? CKRecord.Reference
                        let suiteIdField = record["suiteId"] as? String
                        let createdBy = record["createdBy"] as? String
                        
                        if suiteIdField == suiteInfo.suiteId ||
                           suiteRef?.recordID.recordName == suiteInfo.suiteId ||
                           (suiteRef == nil && createdBy == currentUserId) {
                            if let concert = Concert.fromCloudKitRecord(record) {
                                syncedConcerts.append(concert)
                                print("✅ DEBUG: Fetched concert \(recordID.recordName) for suite")
                            }
                        } else {
                            print("🔧 DEBUG: Concert \(recordID.recordName) doesn't belong to this suite - suiteId: \(suiteIdField ?? "none"), suite ref: \(suiteRef?.recordID.recordName ?? "none")")
                        }
                    case .failure(let error):
                        print("⚠️ DEBUG: Could not fetch concert \(recordID.recordName): \(error)")
                        if let ckError = error as? CKError, ckError.code == .unknownItem {
                            fetchFailures += 1
                        }
                    }
                }
                
                // If ALL concert records failed to fetch with "Unknown Item", suite was likely deleted
                if fetchFailures > 0 && fetchFailures == recordsToFetch.count && !recordsToFetch.isEmpty {
                    print("⚠️ DEBUG: All \(fetchFailures) concert records not found - suite was deleted by owner")
                    await cleanupDeletedSuite()
                    return
                }
            }
            
            // Check if this looks like a deleted suite (had concerts before but now has none)
            if syncedConcerts.isEmpty {
                // If this is the first sync after joining, that's normal
                // But if we had concerts before and now have none, the suite might have been deleted
                let hadConcertsIds = suiteInfo.concertIds?.isEmpty == false
                
                if hadConcertsIds {
                    print("⚠️ DEBUG: Suite previously had concerts but now has none - likely deleted by owner")
                    await cleanupDeletedSuite()
                    return
                } else {
                    print("ℹ️ DEBUG: No concerts found - this may be the first sync or no concerts have been created yet")
                }
            }
            
            print("✅ DEBUG: Found \(syncedConcerts.count) concerts for suite")

            // Update concert data via notification on main thread
            let concertsToSync = syncedConcerts
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .concertDataSynced,
                    object: nil,
                    userInfo: ["concerts": concertsToSync]
                )
                isSyncing = false
            }
        } catch let ckError as CKError where ckError.code == .unknownItem {
            // Suite was deleted by owner - clean up local data
            print("🔄 DEBUG: Shared suite was deleted by owner during concert sync - cleaning up local data")
            await MainActor.run {
                isSyncing = false
            }
            await cleanupDeletedSuite()
        } catch {
            print("❌ DEBUG: Failed to sync concert data: \(error)")
            await MainActor.run {
                isSyncing = false
            }
        }
    }
    
    private func cleanupDeletedSuite() async {
        let suiteNameForAlert = currentSuiteInfo?.suiteName ?? "Unknown Suite"
        let suiteIdToRemove = currentSuiteInfo?.suiteId
        
        print("🧹 DEBUG: Starting cleanup for deleted suite: \(suiteNameForAlert)")
        
        await MainActor.run {
            // Show alert to user
            deletedSuiteName = suiteNameForAlert
            showSuiteDeletedAlert = true
            
            // Clear shared suite info
            currentSuiteInfo = nil
            userRole = .owner
            isSharedSuite = false
            cloudKitStatus = "Suite was deleted by owner"
            
            // Clear concerts by posting empty array
            NotificationCenter.default.post(
                name: .concertDataSynced,
                object: nil,
                userInfo: ["concerts": [] as [Concert]]
            )
            
            print("🧹 DEBUG: Cleared shared suite data and concerts")
        }
        
        // Remove from UserDefaults
        userDefaults.removeObject(forKey: "SharedSuiteInfo")
        userDefaults.removeObject(forKey: "UserRole")
        userDefaults.removeObject(forKey: "IsSharedSuite")
        
        // Clear iCloud KV store
        iCloudStore.removeObject(forKey: "SharedSuiteInfo")
        iCloudStore.removeObject(forKey: "UserRole") 
        iCloudStore.removeObject(forKey: "IsSharedSuite")
        
        // Clean up local token history for this suite
        await MainActor.run {
            // Remove any tokens related to this suite
            let tokensToRemove = tokenUsageHistory.keys.filter { _ in true } // Keep all for now, could be more selective
            for token in tokensToRemove {
                tokenUsageHistory.removeValue(forKey: token)
                usedTokens.remove(token)
            }
            
            // Remove suite from accessed suites if we have the suite ID
            if let suiteId = suiteIdToRemove {
                accessedSuites.removeValue(forKey: suiteId)
            }
            
            print("🧹 DEBUG: Cleaned up local token and suite access history")
        }
        
        print("✅ DEBUG: Suite cleanup complete - app returned to individual suite mode")
    }
    
    // MARK: - Concert Migration for suiteId Field  
    func migrateConcertRecordsWithSuiteId() async {
        guard isCloudKitAvailable, let _ = currentSuiteInfo else { return }
        
        print("🔄 DEBUG: Starting migration to add suiteId field to existing concerts")
        print("ℹ️ DEBUG: Skipping migration due to CloudKit query limitations - will handle during individual record saves")
        
        // Instead of migration, let's ensure the suite record has concert IDs
        // This will be handled by the sync process when called with concert data
    }
    
    // Populate suite record with concert IDs from local concert data
    func populateSuiteRecordWithLocalConcertIds(_ concertIds: [Int]) async {
        guard let suiteInfo = currentSuiteInfo,
              isCloudKitAvailable,
              userRole == .owner else { return }
        
        print("🔄 DEBUG: Populating suite record with \(concertIds.count) local concert IDs")
        
        do {
            // Fetch the latest suite record
            let recordID = CKRecord.ID(recordName: suiteInfo.suiteId)
            let record = try await publicCloudKitDatabase.record(for: recordID)
            
            // Update concert IDs
            record["concertIds"] = concertIds
            record["lastModified"] = Date()
            
            // Save updated record
            _ = try await publicCloudKitDatabase.save(record)
            print("✅ DEBUG: Updated suite record with \(concertIds.count) concert IDs")
            
            // Update local suite info
            await MainActor.run {
                var updatedSuiteInfo = suiteInfo
                updatedSuiteInfo.concertIds = concertIds
                currentSuiteInfo = updatedSuiteInfo
                saveSuiteInfo()
            }
        } catch {
            print("⚠️ DEBUG: Failed to populate suite record with concert IDs: \(error)")
        }
    }
    
    // Migrate existing concert records to current suite
    func migrateConcertsToCurrentSuite(_ concertIds: [Int]) async {
        guard let suiteInfo = currentSuiteInfo,
              isCloudKitAvailable,
              userRole == .owner else { return }
        
        print("🔄 DEBUG: Migrating \(concertIds.count) concerts to current suite: \(suiteInfo.suiteId)")
        
        let recordsToFetch = concertIds.map { CKRecord.ID(recordName: "concert_\($0)") }
        
        do {
            let fetchResults = try await publicCloudKitDatabase.records(for: recordsToFetch)
            var migratedCount = 0
            
            for (recordID, result) in fetchResults {
                switch result {
                case .success(let record):
                    let _ = record["suite"] as? CKRecord.Reference
                    let currentSuiteId = record["suiteId"] as? String
                    
                    // Only migrate if not already in current suite
                    if currentSuiteId != suiteInfo.suiteId {
                        // Update suite reference and suiteId
                        let newSuiteRecordID = CKRecord.ID(recordName: suiteInfo.suiteId)
                        record["suite"] = CKRecord.Reference(recordID: newSuiteRecordID, action: .none)
                        record["suiteId"] = suiteInfo.suiteId
                        record["lastModifiedDate"] = Date()
                        
                        do {
                            _ = try await publicCloudKitDatabase.save(record)
                            migratedCount += 1
                            print("✅ DEBUG: Migrated concert \(recordID.recordName) to current suite")
                        } catch {
                            print("⚠️ DEBUG: Failed to migrate concert \(recordID.recordName): \(error)")
                        }
                    } else {
                        print("ℹ️ DEBUG: Concert \(recordID.recordName) already belongs to current suite")
                    }
                case .failure(let error):
                    print("⚠️ DEBUG: Could not fetch concert \(recordID.recordName) for migration: \(error)")
                }
            }
            
            if migratedCount > 0 {
                print("✅ DEBUG: Migration completed - updated \(migratedCount) concerts to current suite")
            } else {
                print("ℹ️ DEBUG: No concerts needed migration to current suite")
            }
        } catch {
            print("❌ DEBUG: Failed to migrate concerts to current suite: \(error)")
        }
    }

    // MARK: - Suite Settings Management
    func updateSuiteSettings(_ suiteInfo: SharedSuiteInfo) async {
        guard isCloudKitAvailable,
              userRole == .owner else { return }

        do {
            let recordID = CKRecord.ID(recordName: suiteInfo.suiteId)
            let record = try await publicCloudKitDatabase.record(for: recordID)

            // Update pricing settings
            if let familyPrice = suiteInfo.familyTicketPrice {
                record["familyTicketPrice"] = familyPrice
            }

            if let seatCost = suiteInfo.defaultSeatCost {
                record["defaultSeatCost"] = seatCost
            }

            record["lastModified"] = Date()

            // Save updated record
            _ = try await publicCloudKitDatabase.save(record)
            print("✅ DEBUG: Updated suite settings in CloudKit")

            // Update local suite info
            await MainActor.run {
                currentSuiteInfo = suiteInfo
                saveSuiteInfo()
            }

        } catch {
            print("❌ DEBUG: Failed to update suite settings: \(error)")
        }
    }

    // MARK: - Suite Member Management
    private func addMemberToSuiteRecord(member: SuiteMember, suiteInfo: SharedSuiteInfo) async throws {
        let recordID = CKRecord.ID(recordName: suiteInfo.suiteId)
        
        // Fetch the latest version of the suite record to avoid conflicts
        let record = try await publicCloudKitDatabase.record(for: recordID)
        
        // Get current members from the record
        var currentMembers: [SuiteMember] = []
        if let membersData = record["membersData"] as? Data,
           let members = try? JSONDecoder().decode([SuiteMember].self, from: membersData) {
            currentMembers = members
        }
        
        // Check if member already exists
        if !currentMembers.contains(where: { $0.userId == member.userId }) {
            currentMembers.append(member)
            
            // Update the record with new members
            if let updatedMembersData = try? JSONEncoder().encode(currentMembers) {
                record["membersData"] = updatedMembersData
            }
            record["lastModified"] = Date()
            
            // Save the updated record
            _ = try await publicCloudKitDatabase.save(record)
        }
    }
    
    // MARK: - App Update Migrations
    
    func runAppUpdateMigrations() async {
        let migrationKey = "concertSuiteIdMigrationCompleted"
        
        // Check if migration has already been completed
        guard !userDefaults.bool(forKey: migrationKey),
              isCloudKitAvailable,
              let suiteInfo = currentSuiteInfo else {
            return
        }
        
        print("🔄 Running concert suiteId migration for suite: \(suiteInfo.suiteId)")
        
        // Create backup before migration
        do {
            try await createMigrationBackup()
            print("✅ Pre-migration backup created successfully")
        } catch {
            print("❌ Failed to create backup, aborting migration for safety: \(error)")
            return
        }
        
        do {
            // Query all concert records from public database that might belong to this suite
            let predicate = NSPredicate(format: "createdBy == %@", self.currentUserId)
            let query = CKQuery(recordType: CloudKitRecordType.concert, predicate: predicate)
            
            let (matchResults, _) = try await self.publicCloudKitDatabase.records(matching: query)
            
            var migratedCount = 0
            var totalRecords = 0
            var failedRecords: [String] = []
            
            for (recordID, result) in matchResults {
                switch result {
                case .success(let record):
                    totalRecords += 1
                    // Check if this record already has a suite reference
                    if record["suite"] == nil {
                        // Add the suite reference to the record
                        let suiteRecordID = CKRecord.ID(recordName: suiteInfo.suiteId)
                        record["suite"] = CKRecord.Reference(recordID: suiteRecordID, action: .deleteSelf)
                        
                        do {
                            _ = try await self.publicCloudKitDatabase.save(record)
                            migratedCount += 1
                            print("✅ Migrated concert record: \(recordID.recordName)")
                        } catch {
                            failedRecords.append(recordID.recordName)
                            print("⚠️ Failed to migrate concert record \(recordID.recordName): \(error)")
                        }
                    } else {
                        print("ℹ️ Concert record \(recordID.recordName) already has suite reference, skipping")
                    }
                case .failure(let error):
                    totalRecords += 1
                    failedRecords.append(recordID.recordName)
                    print("❌ Failed to fetch concert record \(recordID.recordName): \(error)")
                }
            }
            
            // Only mark as completed if migration was mostly successful
            if failedRecords.isEmpty {
                print("✅ Migration complete: Updated \(migratedCount)/\(totalRecords) concert records successfully")
                UserDefaults.standard.set(true, forKey: migrationKey)
            } else if failedRecords.count <= totalRecords / 2 {
                print("⚠️ Migration partially complete: \(migratedCount) succeeded, \(failedRecords.count) failed")
                print("⚠️ Failed records: \(failedRecords.joined(separator: ", "))")
                UserDefaults.standard.set(true, forKey: migrationKey) // Mark as done to avoid infinite retries
            } else {
                print("❌ Migration failed: Too many failed records (\(failedRecords.count)/\(totalRecords))")
                print("❌ Will retry on next app launch. Failed records: \(failedRecords.joined(separator: ", "))")
                // Don't mark as completed - will retry next time
            }
            
        } catch {
            print("❌ Migration failed: \(error)")
        }
    }
    
    private func createMigrationBackup() async throws {
        let backupKey = "concertMigrationBackup_\(Date().timeIntervalSince1970)"
        
        guard let suiteInfo = currentSuiteInfo else {
            throw NSError(domain: "MigrationBackup", code: 1, userInfo: [NSLocalizedDescriptionKey: "No suite info available"])
        }
        
        print("📦 Creating migration backup...")
        
        // Backup: Query and store all current concert records
        do {
            let predicate = NSPredicate(format: "createdBy == %@", self.currentUserId)
            let query = CKQuery(recordType: CloudKitRecordType.concert, predicate: predicate)
            
            let (matchResults, _) = try await self.publicCloudKitDatabase.records(matching: query)
            
            var backupData: [String: Any] = [:]
            backupData["timestamp"] = Date()
            backupData["suiteId"] = suiteInfo.suiteId
            backupData["userId"] = self.currentUserId
            backupData["migrationReason"] = "suiteId field addition"
            
            var concertBackups: [[String: Any]] = []
            
            for (recordID, result) in matchResults {
                switch result {
                case .success(let record):
                    var recordBackup: [String: Any] = [:]
                    recordBackup["recordName"] = recordID.recordName
                    recordBackup["recordType"] = record.recordType
                    
                    // Store all field values
                    for key in record.allKeys() {
                        let value = record[key]
                        if let stringValue = value as? String {
                            recordBackup[key] = stringValue
                        } else if let numberValue = value as? NSNumber {
                            recordBackup[key] = numberValue
                        } else if let dateValue = value as? Date {
                            recordBackup[key] = dateValue.timeIntervalSince1970
                        } else if let dataValue = value as? Data {
                            recordBackup[key] = dataValue.base64EncodedString()
                        }
                        // Note: We'll store JSON-encodable types for safety
                    }
                    
                    concertBackups.append(recordBackup)
                    
                case .failure(let error):
                    print("⚠️ Could not backup record \(recordID.recordName): \(error)")
                }
            }
            
            backupData["concerts"] = concertBackups
            backupData["concertCount"] = concertBackups.count
            
            // Store backup in UserDefaults
            if let backupJsonData = try? JSONSerialization.data(withJSONObject: backupData),
               let backupString = String(data: backupJsonData, encoding: .utf8) {
                userDefaults.set(backupString, forKey: backupKey)
                
                // Also save backup metadata for easy access
                let backupMetadataKey = "migrationBackupMetadata"
                var existingBackups = userDefaults.stringArray(forKey: backupMetadataKey) ?? []
                existingBackups.append(backupKey)
                userDefaults.set(existingBackups, forKey: backupMetadataKey)
                
                print("✅ Backup created: \(concertBackups.count) concert records saved as \(backupKey)")
            } else {
                throw NSError(domain: "MigrationBackup", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not serialize backup data"])
            }
            
        } catch {
            throw NSError(domain: "MigrationBackup", code: 3, userInfo: [NSLocalizedDescriptionKey: "Backup failed: \(error.localizedDescription)"])
        }
    }
    
    // Helper function to restore from backup if needed (for emergency use)
    func restoreFromMigrationBackup(backupKey: String) async throws {
        print("🔄 Attempting to restore from backup: \(backupKey)")
        
        guard let backupString = userDefaults.string(forKey: backupKey),
              let backupData = backupString.data(using: .utf8),
              let backup = try? JSONSerialization.jsonObject(with: backupData) as? [String: Any] else {
            throw NSError(domain: "BackupRestore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not load backup data"])
        }
        
        guard let concerts = backup["concerts"] as? [[String: Any]] else {
            throw NSError(domain: "BackupRestore", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid backup format"])
        }
        
        print("📦 Found backup with \(concerts.count) concert records from \(backup["timestamp"] ?? "unknown time")")
        print("⚠️  WARNING: This will overwrite current CloudKit records. Use only in emergency!")
        
        // This would be used manually in extreme cases - not automatically called
        // Implementation would restore the backed up field values to CloudKit records
    }
    
    // MARK: - Real-time Updates with CloudKit Subscriptions
    
    func setupCloudKitSubscriptions() async {
        guard isCloudKitAvailable, isInSharedSuite else { return }
        
        do {
            // Remove any existing subscriptions first
            try await removeCloudKitSubscriptions()
            
            // Create a query subscription for shared suite updates
            let predicate = NSPredicate(format: "TRUEPREDICATE")
            let subscription = CKQuerySubscription(
                recordType: CloudKitRecordType.sharedSuite,
                predicate: predicate,
                subscriptionID: subscriptionID,
                options: [.firesOnRecordUpdate, .firesOnRecordCreation, .firesOnRecordDeletion]
            )
            
            // Configure the notification info
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            notificationInfo.shouldBadge = false
            subscription.notificationInfo = notificationInfo
            
            _ = try await cloudKitDatabase.save(subscription)
            
            await MainActor.run {
                cloudKitStatus = "Real-time updates enabled"
            }
        } catch {
            await MainActor.run {
                cloudKitStatus = "Failed to setup subscriptions: \(error.localizedDescription)"
            }
        }
    }
    
    func removeCloudKitSubscriptions() async throws {
        guard isCloudKitAvailable else { return }
        
        do {
            // Fetch existing subscriptions
            let subscriptions = try await cloudKitDatabase.allSubscriptions()
            
            // Remove subscriptions with our ID
            let subscriptionIDs = subscriptions
                .filter { $0.subscriptionID == subscriptionID }
                .map { $0.subscriptionID }
            
            if !subscriptionIDs.isEmpty {
                _ = try await cloudKitDatabase.modifySubscriptions(saving: [], deleting: subscriptionIDs)
            }
        } catch {
            // Subscription might not exist, which is fine
        }
    }
    
    func handleCloudKitNotification(_ notification: CKNotification) {
        guard let _ = notification as? CKQueryNotification,
              isInSharedSuite else { return }
        
        // Sync with CloudKit when we receive notifications
        Task {
            await syncWithCloudKit()
        }
    }
}

// MARK: - Conflict Resolution and Data Merging
extension SharedSuiteManager {
    func mergeConflictingChanges(localConcert: Concert, remoteConcert: Concert) -> Concert {
        var mergedConcert = remoteConcert // Start with remote version
        
        // Merge seat-by-seat using modification timestamps
        for (index, localSeat) in localConcert.seats.enumerated() {
            let remoteSeat = remoteConcert.seats[index]
            
            // Use the seat with the most recent modification
            if let localModified = localSeat.lastModifiedDate,
               let remoteModified = remoteSeat.lastModifiedDate {
                
                if localModified > remoteModified {
                    // Local seat is newer, use local version
                    mergedConcert.seats[index] = localSeat
                } else if localModified < remoteModified {
                    // Remote seat is newer, already using remote
                    continue
                } else {
                    // Same timestamp, check conflict resolution version
                    let localVersion = localSeat.conflictResolutionVersion ?? 1
                    let remoteVersion = remoteSeat.conflictResolutionVersion ?? 1
                    
                    if localVersion > remoteVersion {
                        mergedConcert.seats[index] = localSeat
                    }
                }
            } else if localSeat.lastModifiedDate != nil {
                // Only local has modification date, prefer local
                mergedConcert.seats[index] = localSeat
            }
        }
        
        // Update merged concert metadata
        mergedConcert.lastModifiedBy = self.currentUserId
        mergedConcert.lastModifiedDate = Date()
        mergedConcert.sharedVersion = (mergedConcert.sharedVersion ?? 1) + 1
        
        return mergedConcert
    }
    
    func detectConflicts(localData: [Concert], remoteData: [Concert]) -> [(local: Concert, remote: Concert)] {
        var conflicts: [(local: Concert, remote: Concert)] = []
        
        for localConcert in localData {
            if let remoteConcert = remoteData.first(where: { $0.id == localConcert.id }) {
                // Check if there are actual conflicts
                if hasConflicts(local: localConcert, remote: remoteConcert) {
                    conflicts.append((local: localConcert, remote: remoteConcert))
                }
            }
        }
        
        return conflicts
    }
    
    private func hasConflicts(local: Concert, remote: Concert) -> Bool {
        // Check if concerts have different modification dates and versions
        guard let localModified = local.lastModifiedDate,
              let remoteModified = remote.lastModifiedDate else {
            return false
        }
        
        let timeDifference = abs(localModified.timeIntervalSince(remoteModified))
        
        // If modified within 5 seconds, check for actual content differences
        if timeDifference < 5 {
            return hasSeatConflicts(local: local, remote: remote)
        }
        
        return false
    }
    
    private func hasSeatConflicts(local: Concert, remote: Concert) -> Bool {
        for (index, localSeat) in local.seats.enumerated() {
            let remoteSeat = remote.seats[index]
            
            // Check if seats have different statuses or prices
            if localSeat.status != remoteSeat.status ||
               localSeat.price != remoteSeat.price ||
               localSeat.source != remoteSeat.source {
                return true
            }
        }
        return false
    }
    
    func syncWithConflictResolution(localConcerts: [Concert]) async throws -> [Concert] {
        guard isCloudKitAvailable, let suiteInfo = currentSuiteInfo else {
            throw CloudKitError.notAvailable
        }
        
        await MainActor.run {
            cloudKitStatus = "Syncing with conflict resolution..."
            isSyncing = true
        }
        
        do {
            // Fetch all concerts from CloudKit for this suite using reference
            let suiteRecordID = CKRecord.ID(recordName: suiteInfo.suiteId)
            let suiteReference = CKRecord.Reference(recordID: suiteRecordID, action: .none)
            let predicate = NSPredicate(format: "suite == %@", suiteReference)
            let query = CKQuery(recordType: CloudKitRecordType.concert, predicate: predicate)
            let (matchResults, _) = try await publicCloudKitDatabase.records(matching: query)
            
            var remoteConcerts: [Concert] = []
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let concert = Concert.fromCloudKitRecord(record) {
                        remoteConcerts.append(concert)
                    }
                case .failure:
                    continue
                }
            }
            
            // Detect conflicts
            let conflicts = detectConflicts(localData: localConcerts, remoteData: remoteConcerts)
            var resolvedConcerts = localConcerts
            
            // Resolve conflicts
            for conflict in conflicts {
                let mergedConcert = mergeConflictingChanges(localConcert: conflict.local, remoteConcert: conflict.remote)
                
                // Update the local concert with merged data
                if let index = resolvedConcerts.firstIndex(where: { $0.id == mergedConcert.id }) {
                    resolvedConcerts[index] = mergedConcert
                }
                
                // Save merged concert back to CloudKit
                let record = mergedConcert.toCloudKitRecord()
                _ = try await self.publicCloudKitDatabase.save(record)
            }
            
            // Add any remote concerts that don't exist locally
            for remoteConcert in remoteConcerts {
                if !resolvedConcerts.contains(where: { $0.id == remoteConcert.id }) {
                    resolvedConcerts.append(remoteConcert)
                }
            }
            
            await MainActor.run {
                cloudKitStatus = "Sync with conflict resolution complete"
                isSyncing = false
            }
            
            return resolvedConcerts
        } catch {
            await MainActor.run {
                cloudKitStatus = "Sync failed: \(error.localizedDescription)"
                isSyncing = false
            }
            throw error
        }
    }
}

// MARK: - CloudKit Notification Handling
extension SharedSuiteManager {
    static func handleRemoteNotification(userInfo: [AnyHashable: Any]) async {
        if CKNotification(fromRemoteNotificationDictionary: userInfo) != nil {
            // This should be called from the shared instance in your app
            // You might want to implement a singleton pattern or pass this through the app delegate
        }
    }
}

// MARK: - Offline Support and Error Handling
extension SharedSuiteManager {
    private func loadOfflineQueue() {
        if let data = userDefaults.data(forKey: offlineQueueKey),
           let queue = try? JSONDecoder().decode([OfflineOperation].self, from: data) {
            offlineQueue = queue
            pendingOperationsCount = queue.count
        }
    }
    
    private func saveOfflineQueue() {
        if let encoded = try? JSONEncoder().encode(offlineQueue) {
            userDefaults.set(encoded, forKey: offlineQueueKey)
            pendingOperationsCount = offlineQueue.count
        }
    }
    
    private func addToOfflineQueue(_ operation: OfflineOperation) {
        offlineQueue.append(operation)
        saveOfflineQueue()
    }
    
    private func startRetryTimer() {
        retryTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task {
                await self.processOfflineQueue()
            }
        }
    }
    
    private func processOfflineQueue() async {
        guard isCloudKitAvailable && !offlineQueue.isEmpty else { return }
        
        var successfulOperations: [UUID] = []
        
        for operation in offlineQueue {
            // Skip operations that have exceeded retry limit
            if operation.retryCount >= 5 {
                successfulOperations.append(operation.id)
                continue
            }
            
            do {
                try await processOfflineOperation(operation)
                successfulOperations.append(operation.id)
            } catch {
                // Update retry count
                if let index = offlineQueue.firstIndex(where: { $0.id == operation.id }) {
                    offlineQueue[index].retryCount += 1
                }
            }
        }
        
        // Remove successful operations
        offlineQueue.removeAll { successfulOperations.contains($0.id) }
        saveOfflineQueue()
        
        await MainActor.run {
            isOffline = !offlineQueue.isEmpty
            if offlineQueue.isEmpty {
                cloudKitStatus = "All changes synced"
            }
        }
    }
    
    private func processOfflineOperation(_ operation: OfflineOperation) async throws {
        switch operation.type {
        case .updateConcert:
            if let concert = try? JSONDecoder().decode(Concert.self, from: operation.data) {
                let record = concert.toCloudKitRecord()
                _ = try await self.publicCloudKitDatabase.save(record)
            }
        case .updateSuiteInfo:
            if let suiteInfo = try? JSONDecoder().decode(SharedSuiteInfo.self, from: operation.data) {
                let record = suiteInfo.toCloudKitRecord()
                _ = try await self.publicCloudKitDatabase.save(record)
            }
        default:
            break
        }
    }
    
    func handleCloudKitError(_ error: Error) -> CloudKitError {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .networkUnavailable, .networkFailure:
                return .networkUnavailable
            case .quotaExceeded:
                return .quotaExceeded
            case .serviceUnavailable, .internalError:
                return .serverError
            case .serverRecordChanged:
                return .conflictError
            case .unknownItem:
                return .recordNotFound
            case .permissionFailure:
                return .permissionDenied
            default:
                return .serverError
            }
        }
        return .serverError
    }
    
    func executeWithRetry<T>(
        operation: @escaping () async throws -> T,
        maxRetries: Int = 3,
        initialDelay: TimeInterval = 1.0
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                let cloudKitError = handleCloudKitError(error)
                
                // Don't retry unrecoverable errors
                if !cloudKitError.isRecoverable || attempt == maxRetries {
                    throw cloudKitError
                }
                
                // Exponential backoff
                let delay = initialDelay * pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw lastError ?? CloudKitError.retryLimitExceeded
    }
    
    func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                return try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw CloudKitError.timeout
            }
            
            guard let result = try await group.next() else {
                throw CloudKitError.timeout
            }
            
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - Concert CloudKit Operations
    func saveConcertToCloudKit(_ concert: Concert) async throws {
        guard let suiteInfo = currentSuiteInfo,
              isCloudKitAvailable else {
            throw CloudKitError.notAvailable
        }
        
        let suiteRecordID = CKRecord.ID(recordName: suiteInfo.suiteId)
        let concertRecordID = CKRecord.ID(recordName: "concert_\(concert.id)")
        
        print("🔧 DEBUG: Saving concert to CloudKit with suite reference ID: \(suiteRecordID)")
        
        // Try to fetch existing record first, then update it
        do {
            // Attempt to fetch existing record
            let existingRecord = try await publicCloudKitDatabase.record(for: concertRecordID)
            print("🔧 DEBUG: Found existing record for concert \(concert.id), updating it")
            
            // Update the existing record with current concert data
            existingRecord["concertId"] = Int64(concert.id)
            existingRecord["artist"] = concert.artist
            existingRecord["date"] = concert.date
            existingRecord["createdBy"] = concert.createdBy
            existingRecord["lastModifiedBy"] = concert.lastModifiedBy
            existingRecord["lastModifiedDate"] = concert.lastModifiedDate
            existingRecord["sharedVersion"] = Int64(concert.sharedVersion ?? 1)
            
            // Store seats and parking ticket as JSON data
            if let seatsData = try? JSONEncoder().encode(concert.seats) {
                existingRecord["seatsData"] = seatsData
            }
            
            if let parkingTicket = concert.parkingTicket,
               let parkingData = try? JSONEncoder().encode(parkingTicket) {
                existingRecord["parkingTicketData"] = parkingData
            }
            
            // Ensure suite reference is set
            existingRecord["suite"] = CKRecord.Reference(recordID: suiteRecordID, action: .none)
            existingRecord["suiteId"] = suiteInfo.suiteId
            
            // Save the updated record
            _ = try await publicCloudKitDatabase.save(existingRecord)
            print("✅ DEBUG: Updated existing concert record: \(concert.artist) - \(concertRecordID.recordName)")
            
        } catch let ckError as CKError where ckError.code == .unknownItem {
            // Record doesn't exist, create a new one
            print("🔧 DEBUG: Record doesn't exist for concert \(concert.id), creating new one")
            let concertRecord = concert.toCloudKitRecord(suiteRecordID: suiteRecordID)
            _ = try await publicCloudKitDatabase.save(concertRecord)
            print("✅ DEBUG: Created new concert record: \(concert.artist) - \(concertRecordID.recordName)")
        }
        
        // Update suite record with concert IDs (only if we're the owner)
        if userRole == .owner {
            await updateSuiteWithConcertIds([concert.id])
        }
    }
    
    private func updateSuiteWithConcertIds(_ newConcertIds: [Int]) async {
        guard let suiteInfo = currentSuiteInfo,
              isCloudKitAvailable,
              userRole == .owner else { return }
        
        do {
            // Combine existing concert IDs with new ones
            var allConcertIds = Set(suiteInfo.concertIds ?? [])
            allConcertIds.formUnion(newConcertIds)
            let concertIds = Array(allConcertIds)
            
            // Fetch the latest suite record
            let recordID = CKRecord.ID(recordName: suiteInfo.suiteId)
            let record = try await publicCloudKitDatabase.record(for: recordID)
            
            // Update concert IDs
            record["concertIds"] = concertIds
            record["lastModified"] = Date()
            
            // Save updated record
            _ = try await publicCloudKitDatabase.save(record)
            print("✅ DEBUG: Updated suite record with \(concertIds.count) concert IDs")
            
            // Update local suite info
            await MainActor.run {
                var updatedSuiteInfo = suiteInfo
                updatedSuiteInfo.concertIds = concertIds
                currentSuiteInfo = updatedSuiteInfo
                saveSuiteInfo()
            }
        } catch {
            print("⚠️ DEBUG: Failed to update suite record with concert IDs: \(error)")
        }
    }
    
    // MARK: - Concert Migration
    func migrateLocalConcertsToSuite() async {
        guard let suiteInfo = currentSuiteInfo,
              isCloudKitAvailable else {
            return
        }
        
        // Notify ConcertDataManager to migrate local concerts
        await MainActor.run {
            NotificationCenter.default.post(
                name: .migrateLocalConcerts,
                object: nil,
                userInfo: ["suiteId": suiteInfo.suiteId]
            )
        }
    }
}

enum CloudKitError: Error, LocalizedError {
    case notAvailable
    case recordNotFound
    case permissionDenied
    case networkUnavailable
    case quotaExceeded
    case serverError
    case conflictError
    case retryLimitExceeded
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "CloudKit is not available. Please ensure you're signed into iCloud."
        case .recordNotFound:
            return "The requested suite could not be found."
        case .permissionDenied:
            return "You don't have permission to access this suite."
        case .networkUnavailable:
            return "Network connection unavailable. Changes will be saved locally and synced when connection is restored."
        case .quotaExceeded:
            return "iCloud storage quota exceeded. Please free up space in iCloud."
        case .serverError:
            return "CloudKit server error. Please try again later."
        case .conflictError:
            return "Data conflict detected. Changes have been merged automatically."
        case .retryLimitExceeded:
            return "Operation failed after multiple attempts. Please try again later."
        case .timeout:
            return "Operation timed out. Please check your network connection and try again."
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .networkUnavailable, .serverError, .conflictError:
            return true
        case .notAvailable, .recordNotFound, .permissionDenied, .quotaExceeded, .retryLimitExceeded, .timeout:
            return false
        }
    }
}


// MARK: - Offline Operation Queue
struct OfflineOperation: Codable, Identifiable {
    let id: UUID
    let type: OperationType
    let data: Data
    let timestamp: Date
    var retryCount: Int = 0
    
    enum OperationType: String, Codable {
        case createSuite
        case updateSeat
        case updateConcert
        case deleteConcert
        case updateSuiteInfo
    }
    
    init(type: OperationType, data: Data) {
        self.id = UUID()
        self.type = type
        self.data = data
        self.timestamp = Date()
    }
}

// MARK: - Concert Data Manager
class ConcertDataManager: ObservableObject {
    @Published var concerts: [Concert] = []
    @Published var syncStatus: String = "Ready"
    @Published var lastSyncDate: Date?
    
    private let userDefaults = UserDefaults.standard
    private let iCloudStore = NSUbiquitousKeyValueStore.default
    private let cloudKitContainer = CKContainer.default()
    private var cloudKitDatabase: CKDatabase { 
        return cloudKitContainer.privateCloudDatabase 
    }
    
    private var publicCloudKitDatabase: CKDatabase {
        return cloudKitContainer.publicCloudDatabase
    }
    private let concertsKey = "SavedConcerts"
    private var iCloudObserver: NSObjectProtocol?
    
    // Multi-user sharing support
    weak var sharedSuiteManager: SharedSuiteManager?
    weak var settingsManager: SettingsManager?
    
    init(sharedSuiteManager: SharedSuiteManager? = nil, settingsManager: SettingsManager? = nil) {
        self.sharedSuiteManager = sharedSuiteManager
        self.settingsManager = settingsManager
        setupiCloudSync()
        migrateDataIfNeeded()
        loadConcerts()
        setupConcertSyncListener()
    }
    
    private func migrateDataIfNeeded() {
        let currentVersion = 2 // Increment this when data structure changes (Phase 1 = version 2)
        let versionKey = "dataVersion"
        let lastVersion = userDefaults.integer(forKey: versionKey)
        
        if lastVersion < currentVersion {
            // Migrating data from version \(lastVersion) to \(currentVersion)
            
            // Add migration logic here for future versions
            switch lastVersion {
            case 0:
                // Initial version, no migration needed
                break
            case 1:
                // Migration to Phase 1 multi-user structure
                migrateToMultiUserData()
                break
            default:
                break
            }
            
            userDefaults.set(currentVersion, forKey: versionKey)
        }
    }
    
    private func migrateToMultiUserData() {
        // Migrating existing data to support multi-user sharing
        
        // Load existing concerts and update them with default sharing metadata
        do {
            if let data = userDefaults.data(forKey: concertsKey) {
                var concerts = try JSONDecoder().decode([Concert].self, from: data)
                
                // Update each concert with default sharing properties
                for i in 0..<concerts.count {
                    // Only update if sharing properties are nil (backward compatibility)
                    if concerts[i].suiteId == nil {
                        concerts[i].suiteId = nil // Will remain nil for non-shared suites
                        concerts[i].createdBy = sharedSuiteManager?.self.currentUserId
                        concerts[i].lastModifiedBy = sharedSuiteManager?.self.currentUserId
                        concerts[i].lastModifiedDate = Date()
                        concerts[i].sharedVersion = 1
                    }
                    
                    // Update seats with sharing metadata
                    for j in 0..<concerts[i].seats.count {
                        if concerts[i].seats[j].lastModifiedBy == nil {
                            concerts[i].seats[j].lastModifiedBy = sharedSuiteManager?.self.currentUserId
                            concerts[i].seats[j].lastModifiedDate = Date()
                            concerts[i].seats[j].modificationHistory = []
                            concerts[i].seats[j].conflictResolutionVersion = 1
                        }
                    }
                }
                
                // Save the updated data
                let encodedData = try JSONEncoder().encode(concerts)
                userDefaults.set(encodedData, forKey: concertsKey)
                
                // Successfully migrated \(concerts.count) concerts to multi-user format
            }
        } catch {
            // Failed to migrate data to multi-user format: \(error)
        }
    }
    
    deinit {
        if let observer = iCloudObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupiCloudSync() {
        // Listen for iCloud changes
        iCloudObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore,
            queue: .main
        ) { [weak self] _ in
            self?.syncFromiCloud()
        }
        
        // Initial sync
        iCloudStore.synchronize()
    }
    
    private func syncFromiCloud() {
        if let iCloudData = iCloudStore.data(forKey: concertsKey),
           let iCloudConcerts = try? JSONDecoder().decode([Concert].self, from: iCloudData) {
            // Merge iCloud data with local data (prefer newer data)
            mergeConcerts(iCloudConcerts)
        }
    }
    
    private func mergeConcerts(_ iCloudConcerts: [Concert]) {
        // Simple merge strategy: combine both lists and remove duplicates
        var mergedConcerts = concerts
        for iCloudConcert in iCloudConcerts {
            if !mergedConcerts.contains(where: { $0.id == iCloudConcert.id }) {
                mergedConcerts.append(iCloudConcert)
            }
        }
        concerts = mergedConcerts.sorted { $0.date > $1.date }
        saveToLocalStorage()
    }
    
    func loadConcerts() {
        do {
            if let data = userDefaults.data(forKey: concertsKey) {
                let decodedConcerts = try JSONDecoder().decode([Concert].self, from: data)
                concerts = decodedConcerts
                // Successfully loaded \(concerts.count) concerts
            }
        } catch {
            // Failed to load concerts: \(error)
            // Attempt to recover from backup if available
            loadFromBackup()
        }
    }
    
    func updateWithSyncedConcerts(_ syncedConcerts: [Concert]) {
        print("🔄 Updating local concerts with \(syncedConcerts.count) synced concerts")

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            let localConcertCount = self.concerts.count
            let isOwner = self.sharedSuiteManager?.userRole == .owner
            let isInSharedSuite = (self.sharedSuiteManager?.isInSharedSuite) ?? false
            
            print("🔄 DEBUG: Local concerts: \(localConcertCount), Synced concerts: \(syncedConcerts.count), User role: \(self.sharedSuiteManager?.userRole.rawValue ?? "unknown"), In shared suite: \(isInSharedSuite)")
            
            // Special case: If we're receiving an empty concert list and we're no longer in a shared suite,
            // this means the suite was deleted and we need to clear local data
            if syncedConcerts.isEmpty && !isInSharedSuite && localConcertCount > 0 {
                print("🧹 DEBUG: Suite deleted - clearing local concert data for guest")
                await MainActor.run {
                    self.objectWillChange.send()
                    self.concerts = []
                }
                self.saveLocalOnly()
                return
            }
            
            // If local is empty (like on fresh non-owning phones), accept all synced data
            if localConcertCount == 0 {
                print("🔄 DEBUG: No local concerts, accepting all \(syncedConcerts.count) synced concerts")
                await MainActor.run {
                    self.objectWillChange.send()
                    self.concerts = syncedConcerts
                }
                self.saveLocalOnly()
            } else if !isOwner && syncedConcerts.count > localConcertCount {
                // For non-owners, if CloudKit has more recent data, accept it
                print("🔄 DEBUG: Non-owner with outdated data, accepting \(syncedConcerts.count) CloudKit concerts")
                await MainActor.run {
                    self.objectWillChange.send()
                    self.concerts = syncedConcerts
                }
                self.saveLocalOnly()
            } else if isOwner {
                // For owners, preserve local changes but add any new concerts from CloudKit
                var mergedConcerts = self.concerts
                var hasChanges = false
                
                for syncedConcert in syncedConcerts {
                    if mergedConcerts.contains(where: { $0.id == syncedConcert.id }) {
                        // Concert exists locally - keep local version to preserve recent changes
                        print("🔄 DEBUG: Owner keeping local version of concert \(syncedConcert.id)")
                    } else {
                        // New concert from CloudKit - add it
                        print("✅ DEBUG: Owner adding new synced concert: \(syncedConcert.artist)")
                        mergedConcerts.append(syncedConcert)
                        hasChanges = true
                    }
                }
                
                if hasChanges {
                    await MainActor.run {
                        self.objectWillChange.send()
                        self.concerts = mergedConcerts
                    }
                    self.saveLocalOnly()
                    print("🔄 DEBUG: Owner added \(syncedConcerts.count - localConcertCount) new concerts")
                    
                    // Owner should also upload their current local changes to CloudKit
                    Task {
                        print("🔧 DEBUG: Owner uploading local changes to CloudKit after sync")
                        await self.uploadLocalChangesToCloudKit()
                    }
                } else {
                    print("🔄 DEBUG: Owner keeping all local data intact")
                    
                    // Even when no new concerts were added, owner should upload any local changes
                    Task {
                        print("🔧 DEBUG: Owner uploading local changes to CloudKit (no new remote data)")
                        await self.uploadLocalChangesToCloudKit()
                    }
                }
            } else {
                // For non-owners with same count, update with CloudKit data
                print("🔄 DEBUG: Non-owner with same concert count, updating with CloudKit data")
                print("🔄 DEBUG: Before update - First concert: \(self.concerts.first?.artist ?? "none")")
                print("🔄 DEBUG: Before update - All concerts: \(self.concerts.map { $0.artist }.joined(separator: ", "))")
                
                // Force UI refresh BEFORE updating data
                await MainActor.run {
                    self.objectWillChange.send()
                    self.concerts = syncedConcerts
                }
                
                print("🔄 DEBUG: After update - First concert: \(self.concerts.first?.artist ?? "none")")  
                print("🔄 DEBUG: After update - All concerts: \(self.concerts.map { $0.artist }.joined(separator: ", "))")
                print("🔄 DEBUG: UI refresh triggered for \(syncedConcerts.count) concerts")
                print("🔄 DEBUG: concerts array count is now: \(self.concerts.count)")
                self.saveLocalOnly()
            }
            
            self.syncStatus = "Synced from cloud"
            self.lastSyncDate = Date()
        }
    }
    
    private func setupConcertSyncListener() {
        NotificationCenter.default.addObserver(
            forName: .concertDataSynced,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let concerts = notification.userInfo?["concerts"] as? [Concert] {
                self?.updateWithSyncedConcerts(concerts)
            }
        }
        
        // Listen for local concert migration to shared suite or CloudSync
        NotificationCenter.default.addObserver(
            forName: .migrateLocalConcerts,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let suiteId = notification.userInfo?["suiteId"] as? String {
                self?.migrateLocalConcertsToSharedSuite(suiteId: suiteId)
            } else {
                // CloudSync migration (no suiteId means general CloudSync)
                self?.migrateLocalConcertsToCloudSync()
            }
        }
    }
    
    func saveConcerts() {
        // Don't save changes if user is a viewer in a shared suite
        if let sharedSuiteManager = sharedSuiteManager,
           sharedSuiteManager.isSharedSuite,
           sharedSuiteManager.userRole == .viewer {
            print("🚫 DEBUG: Viewer cannot save changes - operation blocked")
            return
        }

        do {
            let encoded = try JSONEncoder().encode(concerts)

            // Save to local storage
            saveToLocalStorage()

            // Save to iCloud
            saveToiCloud(data: encoded)

            // Sync to CloudKit if in shared suite
            syncToCloudKitAfterSave()
            
            // Successfully saved \(concerts.count) concerts
        } catch {
            // Failed to save concerts: \(error)
        }
    }
    
    func saveLocalOnly() {
        // Ensure we're on main thread when accessing @Published properties
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.saveLocalOnly()
            }
            return
        }
        
        do {
            let _ = try JSONEncoder().encode(concerts)

            // Save to local storage only (no CloudKit sync)
            saveToLocalStorage()

            print("✅ DEBUG: Saved concerts locally only (no CloudKit sync)")
        } catch {
            print("❌ DEBUG: Failed to save concerts locally: \(error)")
        }
    }
    
    private func saveToLocalStorage() {
        do {
            let encoded = try JSONEncoder().encode(concerts)
            userDefaults.set(encoded, forKey: concertsKey)
            userDefaults.synchronize() // Force synchronization
            
            // Create backup
            saveBackup(data: encoded)
        } catch {
            // Failed to save to local storage: \(error)
        }
    }
    
    private func saveToiCloud(data: Data) {
        iCloudStore.set(data, forKey: concertsKey)
        iCloudStore.synchronize()
    }
    
    private func saveBackup(data: Data) {
        let backupKey = "\(concertsKey)_backup"
        userDefaults.set(data, forKey: backupKey)
        userDefaults.set(Date(), forKey: "\(concertsKey)_backup_date")
    }
    
    private func loadFromBackup() {
        let backupKey = "\(concertsKey)_backup"
        if let backupData = userDefaults.data(forKey: backupKey),
           let decodedConcerts = try? JSONDecoder().decode([Concert].self, from: backupData) {
            concerts = decodedConcerts
            // Recovered \(concerts.count) concerts from backup
        }
    }
    
    func addConcert(_ concert: Concert) {
        var updatedConcert = concert
        
        // Add sharing metadata if we're in a shared suite
        if let sharedSuiteManager = sharedSuiteManager,
           let suiteInfo = sharedSuiteManager.currentSuiteInfo {
            updatedConcert.suiteId = suiteInfo.suiteId
            updatedConcert.createdBy = sharedSuiteManager.self.currentUserId
            updatedConcert.lastModifiedBy = sharedSuiteManager.self.currentUserId
            updatedConcert.lastModifiedDate = Date()
            updatedConcert.sharedVersion = 1
        } else if let sharedSuiteManager = sharedSuiteManager {
            // Non-shared suite, just track the user
            updatedConcert.createdBy = sharedSuiteManager.self.currentUserId
            updatedConcert.lastModifiedBy = sharedSuiteManager.self.currentUserId
            updatedConcert.lastModifiedDate = Date()
        }
        
        concerts.append(updatedConcert)
        saveConcerts()
    }
    
    func updateConcert(_ concert: Concert) {
        if let index = concerts.firstIndex(where: { $0.id == concert.id }) {
            var updatedConcert = concert
            
            // Update sharing metadata
            if let sharedSuiteManager = sharedSuiteManager {
                updatedConcert.recordModification(by: sharedSuiteManager.self.currentUserId)
            }
            
            concerts[index] = updatedConcert
            saveConcerts()
        }
    }
    
    func deleteConcert(_ concert: Concert) {
        // Check permissions before deleting
        guard sharedSuiteManager?.canDeleteConcerts() ?? true else {
            // User does not have permission to delete concerts
            return
        }
        
        concerts.removeAll { $0.id == concert.id }
        saveConcerts()
    }
    
    // Helper method to update a seat with sharing metadata
    func updateSeat(concertId: Int, seatIndex: Int, updatedSeat: Seat) {
        guard let concertIndex = concerts.firstIndex(where: { $0.id == concertId }),
              seatIndex >= 0 && seatIndex < concerts[concertIndex].seats.count else {
            return
        }
        
        // Check permissions
        guard sharedSuiteManager?.canModifySeats() ?? true else {
            // User does not have permission to modify seats
            return
        }
        
        let previousStatus = concerts[concertIndex].seats[seatIndex].status
        var newSeat = updatedSeat
        
        // Add sharing metadata
        if let sharedSuiteManager = sharedSuiteManager {
            newSeat.recordModification(
                by: sharedSuiteManager.self.currentUserId,
                userName: sharedSuiteManager.currentUserName,
                previousStatus: previousStatus
            )
        }
        
        concerts[concertIndex].seats[seatIndex] = newSeat
        concerts[concertIndex].recordModification(by: sharedSuiteManager?.self.currentUserId ?? "")
        
        saveConcerts()
    }
    
    // MARK: - Backup/Restore Functionality
    
    func createBackupData(settingsManager: SettingsManager) -> Data? {
        let suiteSettings = SuiteSettings(
            suiteName: settingsManager.suiteName,
            venueLocation: settingsManager.venueLocation,
            familyTicketPrice: settingsManager.familyTicketPrice,
            defaultSeatCost: settingsManager.defaultSeatCost
        )
        
        let backupData = BackupData(
            concerts: concerts,
            backupDate: Date(),
            version: "1.1",
            suiteSettings: suiteSettings
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(backupData)
        } catch {
            // Failed to create backup data: \(error)
            return nil
        }
    }
    
    func restoreFromBackupData(_ data: Data, settingsManager: SettingsManager) -> Bool {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backupData = try decoder.decode(BackupData.self, from: data)
            
            // Validate backup data
            guard validateBackupData(backupData) else {
                // Invalid backup data
                return false
            }
            
            // Create backup of current data before restore
            if let currentBackup = createBackupData(settingsManager: settingsManager) {
                let emergencyBackupKey = "\(concertsKey)_emergency_backup"
                userDefaults.set(currentBackup, forKey: emergencyBackupKey)
                userDefaults.set(Date(), forKey: "\(emergencyBackupKey)_date")
            }
            
            // Restore the concerts
            concerts = backupData.concerts
            saveConcerts()
            
            // Restore settings if available (version 1.1 and later)
            if let settings = backupData.suiteSettings {
                settingsManager.suiteName = settings.suiteName
                settingsManager.venueLocation = settings.venueLocation
                settingsManager.familyTicketPrice = settings.familyTicketPrice
                settingsManager.defaultSeatCost = settings.defaultSeatCost
            }
            
            // Successfully restored \(concerts.count) concerts from backup dated \(backupData.backupDate)
            return true
        } catch {
            // Failed to restore from backup: \(error)
            return false
        }
    }
    
    private func validateBackupData(_ backupData: BackupData) -> Bool {
        // Basic validation - support both v1.0 and v1.1
        guard backupData.version == "1.0" || backupData.version == "1.1" else {
            // Unsupported backup version: \(backupData.version)
            return false
        }
        
        // Validate each concert has required data
        for concert in backupData.concerts {
            if concert.seats.count != 8 {
                // Invalid concert data: \(concert.artist) has \(concert.seats.count) seats instead of 8
                return false
            }
        }
        
        return true
    }
    
    func getBackupInfo() -> (count: Int, lastBackupDate: Date?) {
        let backupDateKey = "\(concertsKey)_backup_date"
        let lastBackupDate = userDefaults.object(forKey: backupDateKey) as? Date
        return (concerts.count, lastBackupDate)
    }
    
    func clearAllData() {
        // Clear concerts array
        concerts.removeAll()
        
        // Clear from UserDefaults
        userDefaults.removeObject(forKey: concertsKey)
        userDefaults.removeObject(forKey: "\(concertsKey)_backup")
        userDefaults.removeObject(forKey: "\(concertsKey)_backup_date")
        
        // Clear from iCloud Key-Value Store
        let iCloudStore = NSUbiquitousKeyValueStore.default
        iCloudStore.removeObject(forKey: concertsKey)
        iCloudStore.removeObject(forKey: "\(concertsKey)_backup")
        iCloudStore.synchronize()
        
        // Clear suite settings from storage
        userDefaults.removeObject(forKey: "suiteName")
        userDefaults.removeObject(forKey: "venueLocation")
        userDefaults.removeObject(forKey: "familyTicketPrice")
        userDefaults.removeObject(forKey: "defaultSeatCost")
        
        iCloudStore.removeObject(forKey: "suiteName")
        iCloudStore.removeObject(forKey: "venueLocation")
        iCloudStore.removeObject(forKey: "familyTicketPrice")
        iCloudStore.removeObject(forKey: "defaultSeatCost")
        iCloudStore.synchronize()
    }
    
    // MARK: - CloudKit Sync
    
    func syncWithCloudKit() async {
        guard let sharedSuiteManager = sharedSuiteManager,
              sharedSuiteManager.isSharedSuite,
              sharedSuiteManager.isCloudKitAvailable else {
            return
        }
        
        await MainActor.run {
            syncStatus = "Syncing with CloudKit..."
            sharedSuiteManager.isSyncing = true
        }
        
        do {
            // Fetch all concerts from CloudKit for this shared suite
            let predicate = NSPredicate(format: "suite != nil")
            let query = CKQuery(recordType: CloudKitRecordType.concert, predicate: predicate)
            
            let records = try await cloudKitDatabase.records(matching: query)
            var cloudKitConcerts: [Concert] = []
            
            for (_, record) in records.matchResults {
                switch record {
                case .success(let record):
                    if let concert = Concert.fromCloudKitRecord(record) {
                        cloudKitConcerts.append(concert)
                    }
                case .failure(_):
                    break // Failed to process record
                }
            }
            
            // Merge with local concerts
            let mergedConcerts = mergeCloudKitConcerts(cloudKitConcerts)
            
            await MainActor.run {
                concerts = mergedConcerts.sorted { $0.date > $1.date }
                syncStatus = "Sync complete"
                lastSyncDate = Date()
                sharedSuiteManager.isSyncing = false
                saveToLocalStorage()
            }
            
        } catch {
            await MainActor.run {
                syncStatus = "Sync failed: \(error.localizedDescription)"
                sharedSuiteManager.isSyncing = false
            }
        }
    }
    
    private func mergeCloudKitConcerts(_ cloudKitConcerts: [Concert]) -> [Concert] {
        var mergedConcerts = concerts
        
        for cloudConcert in cloudKitConcerts {
            if let existingIndex = mergedConcerts.firstIndex(where: { $0.id == cloudConcert.id }) {
                // Use the concert with the latest modification date
                let existingConcert = mergedConcerts[existingIndex]
                
                let cloudModified = cloudConcert.lastModifiedDate ?? Date.distantPast
                let localModified = existingConcert.lastModifiedDate ?? Date.distantPast
                
                if cloudModified > localModified {
                    mergedConcerts[existingIndex] = cloudConcert
                }
            } else {
                // New concert from CloudKit
                mergedConcerts.append(cloudConcert)
            }
        }
        
        return mergedConcerts
    }
    
    func syncConcertToCloudKit(_ concert: Concert) async {
        guard let sharedSuiteManager = sharedSuiteManager,
              sharedSuiteManager.isSharedSuite,
              sharedSuiteManager.isCloudKitAvailable,
              sharedSuiteManager.currentSuiteInfo != nil else {
            return
        }
        
        do {
            // Use SharedSuiteManager to save the concert to CloudKit
            try await sharedSuiteManager.saveConcertToCloudKit(concert)
            // Don't update syncStatus here to avoid thread warnings
        } catch {
            print("❌ Failed to sync concert \(concert.id) to CloudKit: \(error.localizedDescription)")
        }
    }
    
    func syncConcertToPersonalCloudKit(_ concert: Concert) async {
        do {
            // Create a CKRecord for the concert for personal CloudKit storage
            let recordID = CKRecord.ID(recordName: "concert_\(concert.id)")
            let record = CKRecord(recordType: "Concert", recordID: recordID)
            
            // Set concert data
            record["id"] = String(concert.id)
            record["artist"] = concert.artist
            record["date"] = concert.date
            
            // Encode seats as JSON data
            if let seatsData = try? JSONEncoder().encode(concert.seats) {
                record["seats"] = seatsData
            }
            
            // Save to personal CloudKit database
            _ = try await cloudKitDatabase.save(record)
            print("✅ Synced concert \(concert.id) (\(concert.artist)) to personal CloudKit")
            
        } catch {
            print("❌ Failed to sync concert \(concert.id) to personal CloudKit: \(error.localizedDescription)")
            await MainActor.run {
                if let settings = self.settingsManager {
                    settings.updateSyncStatus(.error, error: error.localizedDescription)
                }
            }
        }
    }
    
    // Update the existing saveConcerts method to include CloudKit sync with conflict resolution
    private func syncToCloudKitAfterSave() {
        // Check if CloudSync is enabled
        guard let settingsManager = settingsManager,
              settingsManager.isCloudSyncEnabled else {
            print("🔄 CloudSync disabled - skipping CloudKit sync")
            return
        }
        
        // If we're in a shared suite and user has edit permissions, sync each concert to CloudKit
        if let sharedSuiteManager = sharedSuiteManager,
           sharedSuiteManager.isSharedSuite,
           sharedSuiteManager.userRole != .viewer {
            Task {
                await MainActor.run {
                    syncStatus = "Syncing concerts to CloudKit..."
                }
                
                // Upload all concerts that belong to this suite to CloudKit
                for concert in concerts {
                    if concert.suiteId != nil {
                        await syncConcertToCloudKit(concert)
                    }
                }
                
                await MainActor.run {
                    syncStatus = "Concerts synced to CloudKit"
                    lastSyncDate = Date()
                }
            }
        } else {
            // Individual CloudSync (not in a shared suite)
            Task {
                await MainActor.run {
                    syncStatus = "Syncing to personal iCloud..."
                }
                
                // For individual CloudSync, sync all concerts to personal CloudKit
                for concert in concerts {
                    await syncConcertToPersonalCloudKit(concert)
                }
                
                await MainActor.run {
                    syncStatus = "Personal iCloud sync complete"
                    lastSyncDate = Date()
                    if let settings = self.settingsManager {
                        settings.updateSyncStatus(.enabled)
                    }
                }
            }
        }
    }
    
    // Upload all local concert changes to CloudKit (for owners)
    func uploadLocalChangesToCloudKit() async {
        // Check if CloudSync is enabled
        guard let settingsManager = settingsManager,
              settingsManager.isCloudSyncEnabled else {
            print("🔄 CloudSync disabled - skipping CloudKit upload")
            return
        }
        
        guard let sharedSuiteManager = sharedSuiteManager,
              sharedSuiteManager.isSharedSuite,
              sharedSuiteManager.userRole == .owner else {
            print("🔧 DEBUG: Skipping CloudKit upload - not an owner in shared suite")
            return
        }
        
        await MainActor.run {
            syncStatus = "Uploading local changes to CloudKit..."
        }
        
        print("🔧 DEBUG: Uploading \(concerts.count) concerts to CloudKit as owner")
        
        // Upload all concerts that belong to this suite to CloudKit
        for concert in concerts {
            if concert.suiteId != nil {
                print("🔧 DEBUG: Uploading concert \(concert.id) (\(concert.artist)) to CloudKit")
                await syncConcertToCloudKit(concert)
            }
        }
        
        await MainActor.run {
            syncStatus = "Local changes uploaded to CloudKit"
            lastSyncDate = Date()
        }
        
        print("✅ DEBUG: Finished uploading local changes to CloudKit")
    }
    
    // Enhanced sync method for manual sync with conflict resolution
    func syncWithConflictResolution() async {
        guard let sharedSuiteManager = sharedSuiteManager,
              sharedSuiteManager.isSharedSuite else {
            return
        }
        
        do {
            let resolvedConcerts = try await sharedSuiteManager.syncWithConflictResolution(localConcerts: concerts)
            
            await MainActor.run {
                self.concerts = resolvedConcerts.sorted { $0.date > $1.date }
                self.syncStatus = "Sync complete with conflict resolution"
                self.lastSyncDate = Date()
                self.saveToLocalStorage()
            }
        } catch {
            await MainActor.run {
                self.syncStatus = "Sync failed: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Concert Migration to Shared Suite
    private func migrateLocalConcertsToSharedSuite(suiteId: String) {
        print("🔄 Migrating \(concerts.count) local concerts to shared suite: \(suiteId)")
        
        // Update all existing concerts to be associated with the shared suite
        for i in 0..<concerts.count {
            if concerts[i].suiteId == nil {
                concerts[i].suiteId = suiteId
                concerts[i].createdBy = sharedSuiteManager?.currentUserId
                concerts[i].lastModifiedBy = sharedSuiteManager?.currentUserId
                concerts[i].lastModifiedDate = Date()
                concerts[i].sharedVersion = 1
            }
        }
        
        // Save the updated concerts to trigger CloudKit sync
        saveConcerts()
        
        print("✅ Migration complete: \(concerts.count) concerts now associated with suite")
    }
    
    private func migrateLocalConcertsToCloudSync() {
        print("🔄 Migrating \(concerts.count) local concerts to CloudSync...")

        // Force sync existing concerts to CloudKit
        // This ensures all existing data is backed up to iCloud
        if !concerts.isEmpty {
            print("📤 Syncing existing concert data to iCloud...")
            saveConcerts() // This will trigger CloudKit sync
        }

        print("✅ CloudSync migration complete: \(concerts.count) concerts now synced with iCloud")
    }

    // MARK: - Archive Support

    func removeConcertsForYear(_ year: Int) {
        let calendar = Calendar.current
        concerts.removeAll { concert in
            calendar.component(.year, from: concert.date) == year
        }
        saveConcerts()
    }

    func addConcerts(_ newConcerts: [Concert]) {
        // Add concerts that don't already exist (by ID)
        let existingIds = Set(concerts.map { $0.id })
        let concertsToAdd = newConcerts.filter { !existingIds.contains($0.id) }
        concerts.append(contentsOf: concertsToAdd)
        concerts.sort { $0.date > $1.date }
        saveConcerts()
    }
}

// MARK: - Archive Manager

class ArchiveManager: ObservableObject {
    static let shared = ArchiveManager()

    @Published var availableArchives: [YearArchive] = []
    @Published var isArchiving = false
    @Published var archiveProgress = ""
    @Published var lastError: ArchiveError?

    private let fileManager = FileManager.default
    private let archiveDirectoryName = "Archives"

    private init() {
        loadAvailableArchives()
    }

    // MARK: - Directory Management

    private var archivesDirectoryURL: URL? {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let archivesURL = documentsURL.appendingPathComponent(archiveDirectoryName)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: archivesURL.path) {
            do {
                try fileManager.createDirectory(at: archivesURL, withIntermediateDirectories: true)
            } catch {
                return nil
            }
        }

        return archivesURL
    }

    private func archiveFileURL(for year: Int) -> URL? {
        archivesDirectoryURL?.appendingPathComponent("SuiteKeep_Archive_\(year).json")
    }

    // MARK: - Archive Operations

    func loadAvailableArchives() {
        guard let archivesDir = archivesDirectoryURL else {
            availableArchives = []
            return
        }

        do {
            let files = try fileManager.contentsOfDirectory(at: archivesDir, includingPropertiesForKeys: nil)
            let archiveFiles = files.filter { $0.pathExtension == "json" }

            var archives: [YearArchive] = []
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            for fileURL in archiveFiles {
                if let data = try? Data(contentsOf: fileURL),
                   let archive = try? decoder.decode(YearArchive.self, from: data) {
                    archives.append(archive)
                }
            }

            availableArchives = archives.sorted { $0.year > $1.year }
        } catch {
            availableArchives = []
        }
    }

    func getAvailableYearsToArchive(from concerts: [Concert]) -> [(year: Int, count: Int)] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        // Group concerts by year
        var yearCounts: [Int: Int] = [:]
        for concert in concerts {
            let year = calendar.component(.year, from: concert.date)
            yearCounts[year, default: 0] += 1
        }

        // Filter to only past years that haven't been archived
        let archivedYears = Set(availableArchives.map { $0.year })

        return yearCounts
            .filter { $0.key < currentYear && !archivedYears.contains($0.key) }
            .map { (year: $0.key, count: $0.value) }
            .sorted { $0.year > $1.year }
    }

    func createArchive(for year: Int, concerts: [Concert], settingsManager: SettingsManager) async throws -> YearArchive {
        await MainActor.run {
            isArchiving = true
            archiveProgress = "Preparing archive..."
        }

        // Filter concerts for the specified year
        let calendar = Calendar.current
        let yearConcerts = concerts.filter { calendar.component(.year, from: $0.date) == year }

        guard !yearConcerts.isEmpty else {
            await MainActor.run {
                isArchiving = false
                archiveProgress = ""
            }
            throw ArchiveError.noConcertsForYear(year: year)
        }

        // Check if archive already exists
        if availableArchives.contains(where: { $0.year == year }) {
            await MainActor.run {
                isArchiving = false
                archiveProgress = ""
            }
            throw ArchiveError.archiveAlreadyExists(year: year)
        }

        await MainActor.run {
            archiveProgress = "Generating reports..."
        }

        // Generate all reports
        let reports = generateArchiveReports(concerts: yearConcerts, settingsManager: settingsManager)

        await MainActor.run {
            archiveProgress = "Calculating statistics..."
        }

        // Calculate metadata
        let metadata = calculateMetadata(concerts: yearConcerts)

        await MainActor.run {
            archiveProgress = "Saving archive..."
        }

        // Create suite settings snapshot
        let suiteSettings = SuiteSettings(
            suiteName: settingsManager.suiteName,
            venueLocation: settingsManager.venueLocation,
            familyTicketPrice: settingsManager.familyTicketPrice,
            defaultSeatCost: settingsManager.defaultSeatCost
        )

        // Create archive
        let archive = YearArchive(
            year: year,
            concerts: yearConcerts,
            suiteSettings: suiteSettings,
            reports: reports,
            metadata: metadata
        )

        // Save to file
        guard let fileURL = archiveFileURL(for: year) else {
            await MainActor.run {
                isArchiving = false
                archiveProgress = ""
            }
            throw ArchiveError.noArchivesDirectory
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(archive)
            try data.write(to: fileURL)
        } catch {
            await MainActor.run {
                isArchiving = false
                archiveProgress = ""
            }
            throw ArchiveError.failedToSave(error)
        }

        await MainActor.run {
            isArchiving = false
            archiveProgress = ""
            loadAvailableArchives()
        }

        return archive
    }

    func deleteArchive(_ archive: YearArchive) throws {
        guard let fileURL = archiveFileURL(for: archive.year) else {
            throw ArchiveError.noArchivesDirectory
        }

        do {
            try fileManager.removeItem(at: fileURL)
            loadAvailableArchives()
        } catch {
            throw ArchiveError.failedToDelete(error)
        }
    }

    func restoreArchive(_ archive: YearArchive, to concertManager: ConcertDataManager) {
        concertManager.addConcerts(archive.concerts)
    }

    func exportArchiveReport(_ archive: YearArchive, reportType: ArchiveReportType) -> URL? {
        let reportContent = archive.reports.getReport(for: reportType)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = "SuiteKeep_\(archive.year)_\(reportType.filename)_\(formatter.string(from: Date())).csv"

        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(filename)

        do {
            try reportContent.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            return nil
        }
    }

    // MARK: - Report Generation

    private func generateArchiveReports(concerts: [Concert], settingsManager: SettingsManager) -> ArchiveReports {
        let reportGenerator = ReportGenerator.shared

        // Full report with all sections
        let fullReport = reportGenerator.generateComprehensiveReport(
            concerts: concerts,
            settingsManager: settingsManager,
            options: ReportOptions(
                includeProfitAnalysis: true,
                includeConcertData: true,
                includePerformanceRankings: true,
                includeExecutiveSummary: true,
                includeCharityReport: true,
                includeFutureConcerts: true
            )
        )

        // Executive summary only
        let executiveSummary = reportGenerator.generateComprehensiveReport(
            concerts: concerts,
            settingsManager: settingsManager,
            options: ReportOptions(
                includeProfitAnalysis: false,
                includeConcertData: false,
                includePerformanceRankings: false,
                includeExecutiveSummary: true,
                includeCharityReport: false,
                includeFutureConcerts: true
            )
        )

        // Concert overview
        let concertOverview = reportGenerator.generateComprehensiveReport(
            concerts: concerts,
            settingsManager: settingsManager,
            options: ReportOptions(
                includeProfitAnalysis: false,
                includeConcertData: false,
                includePerformanceRankings: true,
                includeExecutiveSummary: false,
                includeCharityReport: false,
                includeFutureConcerts: true
            )
        )

        // Seat data
        let seatData = reportGenerator.generateComprehensiveReport(
            concerts: concerts,
            settingsManager: settingsManager,
            options: ReportOptions(
                includeProfitAnalysis: false,
                includeConcertData: true,
                includePerformanceRankings: false,
                includeExecutiveSummary: false,
                includeCharityReport: false,
                includeFutureConcerts: true
            )
        )

        // Profit analysis
        let profitAnalysis = reportGenerator.generateComprehensiveReport(
            concerts: concerts,
            settingsManager: settingsManager,
            options: ReportOptions(
                includeProfitAnalysis: true,
                includeConcertData: false,
                includePerformanceRankings: false,
                includeExecutiveSummary: false,
                includeCharityReport: false,
                includeFutureConcerts: true
            )
        )

        // Charity report
        let charityReport = reportGenerator.generateComprehensiveReport(
            concerts: concerts,
            settingsManager: settingsManager,
            options: ReportOptions(
                includeProfitAnalysis: false,
                includeConcertData: false,
                includePerformanceRankings: false,
                includeExecutiveSummary: false,
                includeCharityReport: true,
                includeFutureConcerts: true
            )
        )

        return ArchiveReports(
            fullReport: fullReport,
            executiveSummary: executiveSummary,
            concertOverview: concertOverview,
            seatData: seatData,
            profitAnalysis: profitAnalysis,
            charityReport: charityReport
        )
    }

    private func calculateMetadata(concerts: [Concert]) -> ArchiveMetadata {
        let totalSeatsSold = concerts.reduce(0) { $0 + $1.ticketsSold }
        let totalSeatsReserved = concerts.reduce(0) { $0 + $1.ticketsReserved }

        let totalRevenue = concerts.reduce(0.0) { total, concert in
            let seatRevenue = concert.seats.filter { $0.source != .donation }.compactMap { $0.price }.reduce(0.0, +)
            let parkingRevenue = concert.parkingTicket?.price ?? 0.0
            return total + seatRevenue + parkingRevenue
        }

        let totalCosts = concerts.reduce(0.0) { total, concert in
            let seatCosts = concert.seats.filter { $0.source != .donation }.reduce(0.0) { $0 + ($1.cost ?? 0.0) }
            let parkingCost = concert.parkingTicket?.cost ?? 0.0
            return total + seatCosts + parkingCost
        }

        let totalCharityDonations = concerts.reduce(0) { total, concert in
            total + concert.seats.filter { $0.source == .donation }.count
        }

        return ArchiveMetadata(
            concertCount: concerts.count,
            totalRevenue: totalRevenue,
            totalProfit: totalRevenue - totalCosts,
            totalSeatsSold: totalSeatsSold,
            totalSeatsReserved: totalSeatsReserved,
            totalCharityDonations: totalCharityDonations
        )
    }
}

// MARK: - Concert Row View
struct ConcertRowView: View {
    let concert: Concert

    var statusColor: Color {
        if concert.ticketsSold == 8 {
            return .liquidGreen
        } else if concert.ticketsSold > 0 {
            return .liquidOrange
        } else if concert.ticketsReserved > 0 {
            return .liquidTeal
        } else {
            return .liquidBlue
        }
    }

    var body: some View {
        HStack(spacing: .spacingNormal) {
            // Concert Icon with glass effect
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [statusColor.opacity(0.3), statusColor.opacity(0.1)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 26
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(statusColor.opacity(0.4), lineWidth: 1.5)
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: statusColor.opacity(0.2), radius: 6, x: 0, y: 3)

                Image(systemName: "music.note")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(statusColor)
            }

            // Concert Info
            VStack(alignment: .leading, spacing: 4) {
                Text(concert.artist)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Text(concert.date, style: .date)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(concert.ticketsSold == 8 ? Color.liquidGreen : (concert.ticketsSold > 0 ? Color.liquidOrange : Color.secondary))
                            .frame(width: 6, height: 6)
                        Text("\(concert.ticketsSold)/8 tickets sold")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(concert.ticketsSold == 8 ? .liquidGreen : (concert.ticketsSold > 0 ? .liquidOrange : .secondary))
                    }

                    if concert.ticketsReserved > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.liquidTeal)
                                .frame(width: 6, height: 6)
                            Text("\(concert.ticketsReserved) reserved")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.liquidTeal)
                        }
                    }

                    // Parking ticket status
                    if concert.parkingTicketSold {
                        HStack(spacing: 4) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.liquidGreen)
                            Text("Parking sold")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.liquidGreen)
                        }
                    } else if concert.parkingTicketReserved {
                        HStack(spacing: 4) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.liquidOrange)
                            Text("Parking reserved")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.liquidOrange)
                        }
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.spacingNormal)
        .frame(minHeight: 48) // Minimum touch target height
        .liquidGlass(cornerRadius: .radiusMedium, intensity: 0.12)
    }
}

// MARK: - Add Concert View
struct AddConcertView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var artist = ""
    @State private var selectedDate = Date()
    
    let settingsManager: SettingsManager
    let onSave: (Concert) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background that adapts to light/dark mode
                Color(.systemBackground)
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Add Concert")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.modernText)
                        
                        Text("Schedule a new performance")
                            .font(.system(size: 16))
                            .foregroundColor(.modernTextSecondary)
                    }
                    .padding(.top, 20)
                    
                    // Form Card
                    VStack(spacing: 24) {
                        // Artist field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Artist Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.modernTextSecondary)
                            
                            TextField("Enter artist name", text: $artist)
                                .font(.system(size: 16))
                                .foregroundColor(.modernText)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.modernSecondary)
                                )
                        }
                    
                        // Date field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Concert Date")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.modernTextSecondary)
                            
                            DatePicker("Select date", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .accentColor(.modernAccent)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.modernSecondary)
                                )
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.35, green: 0.35, blue: 0.4))
                    )
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            let defaultSeats = Array(repeating: Seat(cost: settingsManager.defaultSeatCost), count: 8)
                            let newConcert = Concert(
                                id: Int.random(in: 1000...9999),
                                artist: artist,
                                date: selectedDate,
                                seats: defaultSeats
                            )
                            onSave(newConcert)
                            dismiss()
                        }) {
                            Text("Add Concert")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.modernAccent)
                                )
                        }
                        .disabled(artist.isEmpty)
                        .opacity(artist.isEmpty ? 0.6 : 1.0)
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.modernTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - All Concerts View
struct AllConcertsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var concertManager: ConcertDataManager
    @ObservedObject var settingsManager: SettingsManager
    @State private var showingAddConcert = false
    @State private var isCalendarView = false
    
    var sortedConcerts: [Concert] {
        concertManager.concerts.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background that adapts to light/dark mode
                Color(.systemBackground)
                .ignoresSafeArea()
                
                if concertManager.concerts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.house")
                            .font(.system(size: 60))
                            .foregroundColor(.modernTextSecondary.opacity(0.3))
                        
                        Text("No Concerts Yet")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.modernText)
                        
                        Text("Add your first concert to get started")
                            .font(.system(size: 16))
                            .foregroundColor(.modernTextSecondary)
                        
                        Button(action: {
                            showingAddConcert = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Concert")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.modernAccent)
                            )
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header with space for navigation buttons
                            VStack(spacing: 20) {
                                // Header spacing - increased for button area
                                Spacer().frame(height: 70)
                                
                                // Header Card
                                VStack(spacing: 8) {
                                    Text("All Concerts")
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                        .foregroundColor(.modernText)
                                    
                                    Text("\(sortedConcerts.count) total concerts")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.modernTextSecondary)
                                    
                                    // View selector buttons
                                    HStack(spacing: 16) {
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                isCalendarView = false
                                            }
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: isCalendarView ? "list.bullet" : "list.bullet.circle.fill")
                                                    .font(.system(size: 18))
                                                Text("List")
                                                    .font(.system(size: 14, weight: .medium))
                                            }
                                            .foregroundColor(isCalendarView ? .modernAccent.opacity(0.6) : .modernAccent)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(isCalendarView ? Color.clear : Color.modernAccent.opacity(0.1))
                                            )
                                        }
                                        
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                isCalendarView = true
                                            }
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: isCalendarView ? "calendar.circle.fill" : "calendar")
                                                    .font(.system(size: 18))
                                                Text("Calendar")
                                                    .font(.system(size: 14, weight: .medium))
                                            }
                                            .foregroundColor(isCalendarView ? .modernAccent : .modernAccent.opacity(0.6))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(isCalendarView ? Color.modernAccent.opacity(0.1) : Color.clear)
                                            )
                                        }
                                    }
                                    .padding(.top, 12)
                                }
                                .padding(.vertical, 20)
                                .padding(.horizontal, 24)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.modernAccent.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.modernAccent.opacity(0.3), lineWidth: 1)
                                        )
                                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                )
                            }
                            .padding(.top, 20)
                            
                            // Content based on view mode
                            if isCalendarView {
                                ConcertCalendarView(concerts: sortedConcerts, concertManager: concertManager, settingsManager: settingsManager)
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(Array(sortedConcerts.enumerated()), id: \.offset) { index, concert in
                                        NavigationLink(destination: ConcertDetailView(concert: concert, concertManager: concertManager, settingsManager: settingsManager)) {
                                            ConcertRowView(concert: concert)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay(
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Done")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.modernAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.modernSecondary.opacity(0.8))
                        )
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingAddConcert = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                            Text("Add")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.modernAccent)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 50)
                , alignment: .top
            )
            .sheet(isPresented: $showingAddConcert) {
                AddConcertView(settingsManager: settingsManager) { newConcert in
                    concertManager.addConcert(newConcert)
                }
            }
        }
    }
}

// MARK: - Concert Calendar View
struct ConcertCalendarView: View {
    let concerts: [Concert]
    @ObservedObject var concertManager: ConcertDataManager
    @ObservedObject var settingsManager: SettingsManager
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            // Month Navigation
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.modernAccent)
                        .padding(8)
                        .background(Circle().fill(Color.modernAccent.opacity(0.1)))
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: currentMonth))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.modernText)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.modernAccent)
                        .padding(8)
                        .background(Circle().fill(Color.modernAccent.opacity(0.1)))
                }
            }
            .padding(.horizontal)
            
            // Calendar Grid
            CalendarGridView(
                currentMonth: currentMonth,
                concerts: concerts,
                concertManager: concertManager,
                settingsManager: settingsManager
            )
        }
        .padding(.vertical)
    }
}

// MARK: - Calendar Grid View
struct CalendarGridView: View {
    let currentMonth: Date
    let concerts: [Concert]
    @ObservedObject var concertManager: ConcertDataManager
    @ObservedObject var settingsManager: SettingsManager
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    private var monthDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        
        let firstOfMonth = monthInterval.start
        let lastOfMonth = monthInterval.end
        
        guard let firstWeekday = calendar.dateInterval(of: .weekOfYear, for: firstOfMonth)?.start else { return [] }
        
        var days: [Date] = []
        var currentDate = firstWeekday
        
        while currentDate < lastOfMonth {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    private func concertsForDate(_ date: Date) -> [Concert] {
        return concerts.filter { concert in
            calendar.isDate(concert.date, inSameDayAs: date)
        }
    }
    
    private func isInCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.modernTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            
            // Calendar days
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(monthDays, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        concerts: concertsForDate(date),
                        isInCurrentMonth: isInCurrentMonth(date),
                        concertManager: concertManager,
                        settingsManager: settingsManager
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.modernAccent.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.modernAccent.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let concerts: [Concert]
    let isInCurrentMonth: Bool
    @ObservedObject var concertManager: ConcertDataManager
    @ObservedObject var settingsManager: SettingsManager
    
    private let calendar = Calendar.current
    private var dayNumber: String {
        String(calendar.component(.day, from: date))
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Day number
            Text(dayNumber)
                .font(.system(size: 14, weight: isToday ? .bold : .medium))
                .foregroundColor(
                    isToday ? .white : 
                    isInCurrentMonth ? .modernText : .modernTextSecondary.opacity(0.5)
                )
                .frame(width: 24, height: 24)
                .background(
                    Circle().fill(isToday ? Color.modernAccent : Color.clear)
                )
            
            // Concert indicators
            VStack(spacing: 2) {
                ForEach(concerts.prefix(3), id: \.id) { concert in
                    NavigationLink(destination: ConcertDetailView(concert: concert, concertManager: concertManager, settingsManager: settingsManager)) {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(getConcertColor(for: concert))
                                .frame(width: 4, height: 4)
                            if concerts.count <= 2 {
                                Text(concert.artist)
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.modernText)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if concerts.count > 3 {
                    Text("+\(concerts.count - 3)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.modernAccent)
                }
            }
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(concerts.isEmpty ? Color.clear : Color.modernAccent.opacity(0.05))
        )
        .opacity(isInCurrentMonth ? 1.0 : 0.3)
    }
    
    private func getConcertColor(for concert: Concert) -> Color {
        let occupancyRate = Double(concert.ticketsSold) / 8.0
        
        if occupancyRate >= 0.8 {
            return .green
        } else if occupancyRate >= 0.5 {
            return .orange
        } else if occupancyRate > 0 {
            return .blue
        } else {
            return .gray
        }
    }
}

// MARK: - Concert Detail View
struct ConcertDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var sharedSuiteManager: SharedSuiteManager
    @State var concert: Concert
    @ObservedObject var concertManager: ConcertDataManager
    @ObservedObject var settingsManager: SettingsManager
    @State private var showingAllConcerts = false
    @State private var showingDeleteConfirmation = false
    @State private var isEditingDetails = false
    @State private var editedArtist = ""
    @State private var editedDate = Date()
    @Environment(\.dismiss) private var dismiss
    
    // View mode state
    @State private var viewMode: ViewMode = .seatView
    @State private var isBuyerView = false
    
    // Enhanced permission system for viewer role
    private var canEdit: Bool {
        return !sharedSuiteManager.isSharedSuite ||
               sharedSuiteManager.userRole == .owner ||
               sharedSuiteManager.userRole == .editor
    }

    private var isViewerMode: Bool {
        return sharedSuiteManager.isSharedSuite && sharedSuiteManager.userRole == .viewer
    }

    private var canAccessBuyerView: Bool {
        return true // All users can access buyer view for sharing availability
    }

    // Computed property for read-only state
    private var isReadOnlyView: Bool {
        return isBuyerView || !canEdit
    }
    
    enum ViewMode {
        case seatView, listView
    }
    
    // Batch operation states
    @State private var isBatchMode = false
    @State private var selectedSeats = Set<Int>()
    @State private var showingBatchOptions = false
    
    var body: some View {
        ZStack {
            // Full screen background
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top safe area spacer
                Color.clear
                    .frame(height: 0)

                ScrollView {
                    VStack(spacing: 16) {
                        // Navigation Header
                        HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.modernAccent)
                        }
                        .buttonStyle(HoverableButtonStyle())
                        
                        Spacer()
                        
                        // Enhanced read-only indicator for viewer mode
                        if isViewerMode {
                            HStack(spacing: 6) {
                                Image(systemName: "eye.fill")
                                    .font(.system(size: 12, weight: .medium))
                                Text("Viewer Mode")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.blue)
                        } else if isReadOnlyView && !isBuyerView {
                            HStack(spacing: 6) {
                                Image(systemName: "eye.fill")
                                    .font(.system(size: 12, weight: .medium))
                                Text("Read Only")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.orange.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                        if !isReadOnlyView {
                            Button(action: {
                                showingDeleteConfirmation = true
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(HoverableButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Concert Header Card with batch operations overlay
                    ZStack {
                        VStack(spacing: 12) {
                            HStack {
                                Spacer()
                                if !isReadOnlyView {
                                    Button(action: {
                                        if isEditingDetails {
                                            // Save changes
                                            concert.artist = editedArtist
                                            concert.date = editedDate
                                            concertManager.updateConcert(concert)
                                            isEditingDetails = false
                                        } else {
                                            // Enter edit mode
                                            editedArtist = concert.artist
                                            editedDate = concert.date
                                            isEditingDetails = true
                                        }
                                    }) {
                                        Text(isEditingDetails ? "Save" : "Edit")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.modernAccent)
                                    }
                                }
                                
                                if isEditingDetails {
                                    Button {
                                        isEditingDetails = false
                                        editedArtist = concert.artist
                                        editedDate = concert.date
                                    } label: {
                                        HStack {
                                            Image(systemName: "xmark.circle")
                                            Text("Cancel")
                                        }
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.modernTextSecondary)
                                    }
                                }
                            }
                            
                            if isEditingDetails {
                                // Edit mode
                                VStack(spacing: 9) {
                                    TextField("Artist Name", text: $editedArtist)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.modernText)
                                        .multilineTextAlignment(.center)
                                        .padding(8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 9)
                                                .fill(Color.black.opacity(0.2))
                                        )
                                    
                                    DatePicker("", selection: $editedDate, displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .colorScheme(.dark)
                                        .labelsHidden()
                                }
                            } else {
                                // Display mode
                                Text(concert.artist)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.modernText)
                                
                                VStack(spacing: 4) {
                                    Text(concert.date, style: .date)
                                        .font(.system(size: 11))
                                        .foregroundColor(.modernTextSecondary)
                                    
                                    VStack(spacing: 4) {
                                        HStack {
                                            Circle()
                                                .fill(Color.red)  // Red for sold - matches seat color
                                                .frame(width: 6, height: 6)
                                            Text("\(concert.ticketsSold) sold")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(.red)
                                        }
                                        
                                        if concert.ticketsReserved > 0 {
                                            HStack {
                                                Circle()
                                                    .fill(Color.orange)  // Orange for reserved - matches seat color
                                                    .frame(width: 6, height: 6)
                                                Text("\(concert.ticketsReserved) reserved")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                        
                                        let availableSeats = 8 - concert.ticketsSold - concert.ticketsReserved
                                        if availableSeats > 0 {
                                            HStack {
                                                Circle()
                                                    .fill(Color.green)
                                                    .frame(width: 6, height: 6)
                                                Text("\(availableSeats) available")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.green)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .liquidGlassCard(accentColor: .liquidPurple, cornerRadius: 20)
                        .opacity(!isEditingDetails && isBatchMode && !selectedSeats.isEmpty ? 0.3 : 1.0)
                        
                        // Batch operations overlay (only when not editing and batch mode is active)
                        if !isEditingDetails && isBatchMode && !selectedSeats.isEmpty {
                            VStack(spacing: 12) {
                                Text("Batch Operations")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.modernText)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    Button(action: {
                                        showingBatchOptions = true
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "slider.horizontal.3")
                                                .font(.system(size: 16, weight: .medium))
                                            Text("Bulk Edit")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .foregroundColor(.blue)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: {
                                        batchSetStatus(.available)
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.system(size: 16, weight: .medium))
                                            Text("Mark Available")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .foregroundColor(.green)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: {
                                        batchSetStatus(.reserved)
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "clock")
                                                .font(.system(size: 16, weight: .medium))
                                            Text("Mark Reserved")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .foregroundColor(.orange)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: {
                                        batchSetStatus(.sold)
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 16, weight: .medium))
                                            Text("Mark Sold")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.modernSecondary)
                            )
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                    
                    // View Toggle and Batch Mode Controls - Hidden in buyer view
                    if !isBuyerView {
                        VStack(spacing: .spacingNormal) {
                            // View Mode Toggle
                            HStack(spacing: 0) {
                                Button(action: {
                                    if viewMode != .seatView {
                                        HapticManager.shared.selection()
                                        withAnimation(.standardEase) {
                                            viewMode = .seatView
                                        }
                                    }
                                }) {
                                    Text("Seat View")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(viewMode == .seatView ? .white : .modernTextSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            viewMode == .seatView ? Color.modernAccent : Color.clear
                                        )
                                }

                                Button(action: {
                                    if viewMode != .listView {
                                        HapticManager.shared.selection()
                                        withAnimation(.standardEase) {
                                            viewMode = .listView
                                        }
                                    }
                                }) {
                                    Text("List View")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(viewMode == .listView ? .white : .modernTextSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            viewMode == .listView ? Color.modernAccent : Color.clear
                                        )
                                }
                            }
                            .liquidGlass(cornerRadius: .radiusSmall, intensity: 0.15)
                            .overlay(
                                RoundedRectangle(cornerRadius: .radiusSmall)
                                    .stroke(Color.modernAccent.opacity(0.3), lineWidth: 1)
                            )

                            // Batch Mode Toggle - Now Always Visible
                            if !isReadOnlyView {
                                Button(action: {
                                    withAnimation(.standardSpring) {
                                        isBatchMode.toggle()
                                        if !isBatchMode {
                                            selectedSeats.removeAll()
                                        }
                                    }
                                    HapticManager.shared.impact(style: .medium)
                                }) {
                                    HStack(spacing: .spacingTight) {
                                        if isBatchMode {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16, weight: .semibold))
                                        }

                                        VStack(alignment: .center, spacing: 2) {
                                            Text(isBatchMode ? "Batch Mode Active" : "Select Multiple Seats")
                                                .font(.system(size: 14, weight: .semibold))

                                            Text(isBatchMode ? "\(selectedSeats.count) selected" : "Tap to enable batch editing")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(maxWidth: .infinity)

                                        if isBatchMode {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .foregroundColor(isBatchMode ? .white : .modernAccent)
                                    .padding(.horizontal, .spacingNormal)
                                    .padding(.vertical, .radiusSmall)
                                    .background(
                                        RoundedRectangle(cornerRadius: .radiusSmall)
                                            .fill(isBatchMode ? Color.modernAccent : Color.modernAccent.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: .radiusSmall)
                                                    .stroke(Color.modernAccent.opacity(isBatchMode ? 0 : 0.3), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Conditional view based on mode
                    switch viewMode {
                    case .listView:
                        // List View
                        SeatListView(
                            concert: $concert,
                            concertManager: concertManager,
                            settingsManager: settingsManager,
                            isBatchMode: $isBatchMode,
                            selectedSeats: $selectedSeats,
                            showingBatchOptions: $showingBatchOptions,
                            isBuyerView: $isBuyerView
                        )
                    case .seatView:
                        // Interactive Fire Suite Layout for seat selection
                        InteractiveFireSuiteView(
                            concert: $concert, 
                            concertManager: concertManager, 
                            settingsManager: settingsManager,
                            isBatchMode: $isBatchMode,
                            selectedSeats: $selectedSeats,
                            showingBatchOptions: $showingBatchOptions,
                            isBuyerView: $isBuyerView
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAllConcerts) {
            AllConcertsView(concertManager: concertManager, settingsManager: settingsManager)
        }
        .sheet(isPresented: $showingBatchOptions) {
            BatchSeatOptionsView(
                selectedSeats: Array(selectedSeats).sorted(),
                concert: concert,
                onUpdate: { updatedSeats in
                    for (index, seat) in updatedSeats {
                        concert.seats[index] = seat
                    }
                    concertManager.updateConcert(concert)
                },
                onComplete: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isBatchMode = false
                        selectedSeats.removeAll()
                    }
                },
                onCancel: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isBatchMode = false
                        selectedSeats.removeAll()
                    }
                }
            )
            .environmentObject(settingsManager)
        }
        .confirmationDialog("Delete Concert", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Concert", role: .destructive) {
                deleteConcert()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete the concert for \(concert.artist)? This action cannot be undone.")
        }
    }
    
    private func deleteConcert() {
        concertManager.deleteConcert(concert)
        dismiss()
    }
    
    private func batchSetStatus(_ status: SeatStatus) {
        withAnimation(.easeInOut(duration: 0.3)) {
            for index in selectedSeats {
                concert.seats[index].status = status
                
                // Clear price and source for available seats (but preserve cost)
                if status == .available {
                    concert.seats[index].price = nil
                    concert.seats[index].source = nil
                    concert.seats[index].note = nil
                    // Keep cost - don't set to nil
                    concert.seats[index].dateSold = nil
                    concert.seats[index].datePaid = nil
                    concert.seats[index].familyPersonName = nil
                    // Clear donation fields
                    concert.seats[index].donationDate = nil
                    concert.seats[index].donationFaceValue = nil
                    concert.seats[index].charityName = nil
                    concert.seats[index].charityAddress = nil
                    concert.seats[index].charityEIN = nil
                    concert.seats[index].charityContactName = nil
                    concert.seats[index].charityContactInfo = nil
                }
            }
            
            concertManager.updateConcert(concert)
            selectedSeats.removeAll()
            isBatchMode = false
        }
    }
}


// MARK: - Seat List View
struct SeatListView: View {
    @EnvironmentObject var sharedSuiteManager: SharedSuiteManager
    @Binding var concert: Concert
    @ObservedObject var concertManager: ConcertDataManager
    @ObservedObject var settingsManager: SettingsManager
    @Binding var isBatchMode: Bool
    @Binding var selectedSeats: Set<Int>
    @Binding var showingBatchOptions: Bool
    @Binding var isBuyerView: Bool
    @State private var selectedSeatIndex: Int?
    @State private var isUpdatingData = false

    // Permission computed properties
    private var canEdit: Bool {
        return !sharedSuiteManager.isSharedSuite ||
               sharedSuiteManager.userRole == .owner ||
               sharedSuiteManager.userRole == .editor
    }

    private var isViewerMode: Bool {
        return sharedSuiteManager.isSharedSuite && sharedSuiteManager.userRole == .viewer
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Title and instructions
            seatListHeader
            
            // Seat List
            seatListContent
        }
        .sheet(isPresented: Binding<Bool>(
            get: { selectedSeatIndex != nil },
            set: { isPresented in
                if !isPresented {
                    selectedSeatIndex = nil
                    // Reset the lock when sheet fully dismisses
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isUpdatingData = false
                    }
                }
            }
        )) {
            if let index = selectedSeatIndex {
                SeatOptionsView(
                    seatNumber: index + 1,
                    seat: concert.seats[index],
                    onUpdate: { updatedSeat in
                        isUpdatingData = true
                        concert.seats[index] = updatedSeat
                        concertManager.updateConcert(concert)
                    }
                )
            }
        }
        .environmentObject(settingsManager)
    }
    
    private var seatListHeader: some View {
        VStack(spacing: 12) {
            if isBuyerView {
                PoweredBySuiteKeepView()
                    .padding(.vertical, 5)
                
                VStack(spacing: 4) {
                    Text(concert.artist)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.modernText)
                    
                    Text(formatConcertDate(concert.date))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.modernTextSecondary)
                }
            } else {
                Text("Seating List")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.modernText)
                
                Text(isBuyerView ? "View-only mode - seat details are read-only" : 
                     isBatchMode ? "Select multiple seats for batch operations" : "Tap seats to manage tickets")
                    .font(.system(size: 14))
                    .foregroundColor(.modernTextSecondary)
            }
            
            
            // Batch selection status
            if isBatchMode && !selectedSeats.isEmpty {
                batchSelectionStatus
            }
        }
        .padding(.horizontal)
    }
    
    
    private var batchModeBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isBatchMode ? Color.blue.opacity(0.1) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isBatchMode ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var batchSelectionStatus: some View {
        HStack {
            Text("\(selectedSeats.count) seat\(selectedSeats.count == 1 ? "" : "s") selected")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue)
            
            Spacer()
            
            Button("Clear Selection") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedSeats.removeAll()
                    isBatchMode = false
                }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.red)
            
            if !isBuyerView && canEdit {
                Button("Edit Selected") {
                    showingBatchOptions = true
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.blue)
                .cornerRadius(6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.05))
        )
    }
    
    private var seatListContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(0..<8) { index in
                    seatRowView(for: index)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func seatRowView(for index: Int) -> some View {
        HStack(spacing: 16) {
            // Checkbox for batch mode (disabled in read-only view)
            if isBatchMode && !isBuyerView {
                batchCheckbox(for: index)
            }
            
            // Seat number badge
            seatBadge(for: index)
            
            // Seat details
            seatDetails(for: index)
            
            Spacer()
            
            // Edit button (when not in batch mode and user can edit)
            if !isBatchMode && !isBuyerView && canEdit {
                editButton(for: index)
            }
        }
        .padding(16)
        .background(seatRowBackground(for: index))
    }
    
    private func batchCheckbox(for index: Int) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedSeats.contains(index) {
                    selectedSeats.remove(index)
                } else {
                    selectedSeats.insert(index)
                }
            }
        }) {
            Image(systemName: selectedSeats.contains(index) ? "checkmark.square.fill" : "square")
                .font(.system(size: 20))
                .foregroundColor(selectedSeats.contains(index) ? .blue : .modernTextSecondary)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func seatBadge(for index: Int) -> some View {
        ZStack {
            Circle()
                .fill(seatColor(for: concert.seats[index].status))
                .frame(width: 36, height: 36)
            
            Text("\(index + 1)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    private func seatDetails(for index: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header with seat name and status
            HStack {
                // Show family member name if sold to family
                if concert.seats[index].status == .sold,
                   concert.seats[index].source == .family,
                   let note = concert.seats[index].note,
                   !note.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Seat \(index + 1)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.modernText)
                        Text(note)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                } else {
                    Text("Seat \(index + 1)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.modernText)
                }
                
                Spacer()
                
                // Status badge
                statusBadge(for: index)
            }
            
            // Additional details
            additionalDetails(for: index)
        }
    }
    
    private func statusBadge(for index: Int) -> some View {
        Text(concert.seats[index].status.rawValue.capitalized)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(statusTextColor(for: concert.seats[index].status))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(statusBackgroundColor(for: concert.seats[index].status))
            )
    }
    
    private func additionalDetails(for index: Int) -> some View {
        HStack(spacing: 16) {
            if let price = concert.seats[index].price {
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.modernTextSecondary)
                    Text("$\(Int(price))")
                        .font(.system(size: 14))
                        .foregroundColor(.modernTextSecondary)
                }
            }
            
            if let source = concert.seats[index].source {
                HStack(spacing: 4) {
                    Image(systemName: "ticket.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.modernTextSecondary)
                    Text(source.rawValue)
                        .font(.system(size: 14))
                        .foregroundColor(.modernTextSecondary)
                }
            }
            
            // Only show note if it's not a family member (to avoid duplication)
            if let note = concert.seats[index].note, 
               !note.isEmpty,
               concert.seats[index].source != .family {
                HStack(spacing: 4) {
                    Image(systemName: "note.text")
                        .font(.system(size: 12))
                        .foregroundColor(.modernTextSecondary)
                    Text(note)
                        .font(.system(size: 14))
                        .foregroundColor(.modernTextSecondary)
                        .lineLimit(1)
                }
            }
        }
    }
    
    private func editButton(for index: Int) -> some View {
        Button(action: {
            // Prevent seat selection while data is updating
            guard !isUpdatingData else { return }

            // Prevent editing for users without edit permissions
            guard canEdit else { return }

            // Simply set the selected seat index - SwiftUI will handle sheet transitions smoothly
            selectedSeatIndex = index
        }) {
            Image(systemName: "pencil.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.modernAccent)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func seatRowBackground(for index: Int) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.modernSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedSeats.contains(index) ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
            )
    }
    
    private func seatColor(for status: SeatStatus) -> LinearGradient {
        switch status {
        case .available:
            return LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .reserved:
            return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .sold:
            return LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private func statusTextColor(for status: SeatStatus) -> Color {
        switch status {
        case .available:
            return .green
        case .reserved:
            return .orange
        case .sold:
            return .red
        }
    }
    
    private func statusBackgroundColor(for status: SeatStatus) -> Color {
        switch status {
        case .available:
            return .green.opacity(0.2)
        case .reserved:
            return .orange.opacity(0.2)
        case .sold:
            return .red.opacity(0.2)
        }
    }
    
    private func formatConcertDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Interactive Fire Suite View
struct InteractiveFireSuiteView: View {
    @EnvironmentObject var sharedSuiteManager: SharedSuiteManager
    @Binding var concert: Concert
    @ObservedObject var concertManager: ConcertDataManager
    @ObservedObject var settingsManager: SettingsManager
    @State private var pulseFirepit = false
    @State private var selectedSeatIndex: Int?
    @State private var priceInput: String = ""
    @State private var showingParkingOptions = false
    @State private var isUpdatingData = false
    
    // Batch operation states (now bindings from parent)
    @Binding var isBatchMode: Bool
    @Binding var selectedSeats: Set<Int>
    @Binding var showingBatchOptions: Bool
    @Binding var isBuyerView: Bool

    // Permission computed properties
    private var canEdit: Bool {
        return !sharedSuiteManager.isSharedSuite ||
               sharedSuiteManager.userRole == .owner ||
               sharedSuiteManager.userRole == .editor
    }

    private var isViewerMode: Bool {
        return sharedSuiteManager.isSharedSuite && sharedSuiteManager.userRole == .viewer
    }

    private var canAccessBuyerView: Bool {
        return true // All users can access buyer view for sharing availability
    }

    var body: some View {
        if isBuyerView {
            // Show enhanced shareable buyer view
            if #available(iOS 16.0, *) {
                ShareableBuyerView(
                    concert: concert,
                    suiteName: settingsManager.suiteName,
                    venueLocation: settingsManager.venueLocation
                )
            } else {
                // Fallback for older iOS versions
                VStack(spacing: 16) {
                    PoweredBySuiteKeepView()
                        .padding(.vertical, 5)
                    
                    VStack(spacing: 4) {
                        Text(concert.artist)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.modernText)
                        
                        Text(formatConcertDate(concert.date))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.modernTextSecondary)
                    }
                    
                    // Basic seat visualization for older iOS
                    BasicBuyerSuiteView(concert: concert)
                }
            }
        } else {
            VStack(spacing: 16) {
                // Title and instructions
                VStack(spacing: 12) {
                    Text("Seating")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.modernText)
                    
                    Text(isBatchMode ? "Select multiple seats for batch operations" : "Tap seats to manage tickets")
                        .font(.system(size: 14))
                        .foregroundColor(.modernTextSecondary)
                
                
                // Batch selection status
                if isBatchMode && !selectedSeats.isEmpty {
                    HStack {
                        Text("\(selectedSeats.count) seat\(selectedSeats.count == 1 ? "" : "s") selected")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Button("Clear Selection") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedSeats.removeAll()
                                isBatchMode = false
                            }
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                }
            }
            
            // Professional U-Shaped Suite Layout
            VStack(spacing: 12) {
                // Stage indicator (hidden in buyer view)
                if !isBuyerView {
                    HStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "music.mic")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                            Text("STAGE")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        Spacer()
                    }
                }
                
                // Main suite card with U-shaped layout
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.clear)
                        .frame(height: 220)
                        .liquidGlassCard(accentColor: .liquidTeal, cornerRadius: 20)

                    RoundedRectangle(cornerRadius: 20)
                        .fill(.clear)
                        .frame(height: 220)
                        .overlay(
                        ZStack {
                            // Bottom row positioned at the bottom
                            VStack {
                                Spacer()
                                HStack(spacing: 14) {
                                    CompactSeatView(
                                        seatNumber: 6,
                                        seat: concert.seats[5],
                                        isSelected: selectedSeats.contains(5),
                                        isBatchMode: isBatchMode,
                                        isBuyerView: isBuyerView,
                                        onTap: { handleSeatTap(5) },
                                        onLongPress: { handleSeatLongPress(5) }
                                    )
                                    .id("seat-5-\(isBuyerView)")
                                    CompactSeatView(
                                        seatNumber: 5,
                                        seat: concert.seats[4],
                                        isSelected: selectedSeats.contains(4),
                                        isBatchMode: isBatchMode,
                                        isBuyerView: isBuyerView,
                                        onTap: { handleSeatTap(4) },
                                        onLongPress: { handleSeatLongPress(4) }
                                    )
                                    .id("seat-4-\(isBuyerView)")
                                    CompactSeatView(
                                        seatNumber: 4,
                                        seat: concert.seats[3],
                                        isSelected: selectedSeats.contains(3),
                                        isBatchMode: isBatchMode,
                                        isBuyerView: isBuyerView,
                                        onTap: { handleSeatTap(3) },
                                        onLongPress: { handleSeatLongPress(3) }
                                    )
                                    .id("seat-3-\(isBuyerView)")
                                    CompactSeatView(
                                        seatNumber: 3,
                                        seat: concert.seats[2],
                                        isSelected: selectedSeats.contains(2),
                                        isBatchMode: isBatchMode,
                                        isBuyerView: isBuyerView,
                                        onTap: { handleSeatTap(2) },
                                        onLongPress: { handleSeatLongPress(2) }
                                    )
                                    .id("seat-2-\(isBuyerView)")
                                }
                                .padding(.bottom, 8)  // Moved closer to bottom edge, leaving minimal space for text
                            }
                            
                            // Left side vertical stack aligned with seat 6
                            HStack {
                                VStack(spacing: -2) {  // Negative spacing to bring seat 7 very close to 8
                                    CompactSeatView(
                                        seatNumber: 8,
                                        seat: concert.seats[7],
                                        isSelected: selectedSeats.contains(7),
                                        isBatchMode: isBatchMode,
                                        isBuyerView: isBuyerView,
                                        onTap: { handleSeatTap(7) },
                                        onLongPress: { handleSeatLongPress(7) }
                                    )
                                    .id("seat-7-\(isBuyerView)")
                                    CompactSeatView(
                                        seatNumber: 7,
                                        seat: concert.seats[6],
                                        isSelected: selectedSeats.contains(6),
                                        isBatchMode: isBatchMode,
                                        isBuyerView: isBuyerView,
                                        onTap: { handleSeatTap(6) },
                                        onLongPress: { handleSeatLongPress(6) }
                                    )
                                    .id("seat-6-\(isBuyerView)")
                                    Spacer()
                                        .frame(height: 72) // Adjusted space to align with lower bottom row
                                }
                                .padding(.leading, 8)  // Moved closer to left edge
                                
                                Spacer()
                            }
                            
                            // Right side vertical stack aligned with seat 3
                            HStack {
                                Spacer()
                                
                                VStack(spacing: -2) {  // Negative spacing to bring seat 2 very close to 1
                                    CompactSeatView(
                                        seatNumber: 1,
                                        seat: concert.seats[0],
                                        isSelected: selectedSeats.contains(0),
                                        isBatchMode: isBatchMode,
                                        isBuyerView: isBuyerView,
                                        onTap: { handleSeatTap(0) },
                                        onLongPress: { handleSeatLongPress(0) }
                                    )
                                    .id("seat-0-\(isBuyerView)")
                                    CompactSeatView(
                                        seatNumber: 2,
                                        seat: concert.seats[1],
                                        isSelected: selectedSeats.contains(1),
                                        isBatchMode: isBatchMode,
                                        isBuyerView: isBuyerView,
                                        onTap: { handleSeatTap(1) },
                                        onLongPress: { handleSeatLongPress(1) }
                                    )
                                    .id("seat-1-\(isBuyerView)")
                                    Spacer()
                                        .frame(height: 72) // Adjusted space to align with lower bottom row
                                }
                                .padding(.trailing, 8)  // Moved closer to right edge
                            }
                            
                            // Center firepit positioned between upper seats (8,7 and 1,2)
                            VStack {
                                CompactFirepitView(isPulsing: pulseFirepit)
                                    .offset(y: 25) // Center between seat rows
                                Spacer()
                            }
                        }
                        .padding(.top, 20)
                    )
                }
            }
            
            // Enhanced status legend and metrics
            VStack(spacing: 16) {
                // Status legend with professional design
                HStack(spacing: 20) {
                    // Available legend
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.green)  // Match seat color - available should be green
                            .frame(width: 16, height: 16)
                        Text(isBuyerView ? "Open" : "Available")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }

                    // Reserved legend
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 1.0, green: 0.65, blue: 0.2))  // Match seat color
                            .frame(width: 16, height: 16)
                        Text("Reserved")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                    }

                    // Sold legend
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.red)  // Match seat color - sold should be red
                            .frame(width: 16, height: 16)
                        Text("Sold")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .liquidGlass(cornerRadius: 12, intensity: 0.12)
                
                // Enhanced revenue display (hidden in buyer view)
                if !isBuyerView {
                    VStack(spacing: 8) {
                        Text("Revenue: $\(Int(concert.totalRevenue))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                        
                        HStack(spacing: 20) {
                            VStack(spacing: 2) {
                                Text("\(concert.ticketsSold)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.red)
                                Text("sold")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.red.opacity(0.7))
                            }
                            
                            VStack(spacing: 2) {
                                Text("\(concert.ticketsReserved)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.orange)
                                Text("reserved")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.orange.opacity(0.7))
                            }
                            
                            VStack(spacing: 2) {
                                Text("\(8 - concert.ticketsSold - concert.ticketsReserved)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.green)
                                Text("available")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.green.opacity(0.7))
                            }
                        }
                    }
                }
            }
            
            // Parking ticket status - clickable
            Button(action: {
                showingParkingOptions = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    
                    if concert.parkingTicketSold {
                        Text("Parking: SOLD")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                    } else if concert.parkingTicketReserved {
                        Text("Parking: RESERVED")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.orange)
                    } else {
                        Text("Parking: AVAILABLE")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.blue.opacity(0.6))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // View Mode Toggle - Centered
            HStack {
                Spacer()
                
                // Show appropriate controls based on user permissions
                if isViewerMode {
                    // Enhanced viewer mode indicator with buyer view access note
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("Viewer Mode")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.blue)

                        Text("Can view all data & access buyer view")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                }

                // Buyer View Toggle - Available to all user roles including viewers
                if canAccessBuyerView {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isBuyerView.toggle()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isBuyerView ? "eye.fill" : "eye")
                                .font(.system(size: 14, weight: .medium))
                            Text("Buyer View")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(isBuyerView ? .blue : .modernTextSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isBuyerView ? Color.blue.opacity(0.1) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isBuyerView ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                
                    Spacer()
                }
                .padding(.top, 8)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .onAppear {
                startPulseAnimation()
            }
            .sheet(isPresented: Binding<Bool>(
                get: { selectedSeatIndex != nil },
                set: { isPresented in
                    if !isPresented {
                        selectedSeatIndex = nil
                        // Reset the lock when sheet fully dismisses
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isUpdatingData = false
                        }
                    }
                }
            )) {
                if let index = selectedSeatIndex {
                    SeatOptionsView(
                        seatNumber: index + 1,
                        seat: concert.seats[index],
                        onUpdate: { updatedSeat in
                            isUpdatingData = true
                            concert.seats[index] = updatedSeat
                            concertManager.updateConcert(concert)
                        },
                        onUpdateAll: { templateSeat in
                            isUpdatingData = true
                            // Apply the template seat to all seats, but keep each seat's original seat number context
                            for i in 0..<concert.seats.count {
                                let newSeat = templateSeat
                                // Each seat should maintain its unique identity for seat-specific tracking
                                concert.seats[i] = newSeat
                            }
                            concertManager.updateConcert(concert)
                        }
                    )
                    .environmentObject(settingsManager)
                }
            }
            .sheet(isPresented: $showingParkingOptions) {
                ParkingTicketOptionsView(
                    parkingTicket: concert.parkingTicket ?? ParkingTicket(),
                    onUpdate: { updatedParkingTicket in
                        concert.parkingTicket = updatedParkingTicket
                        concertManager.updateConcert(concert)
                    }
                )
                .environmentObject(settingsManager)
            }
        }
    }
    
    private func handleSeatTap(_ index: Int) {
        // Prevent seat selection while data is updating
        guard !isUpdatingData else { return }

        // Prevent editing for users without edit permissions
        guard canEdit else { return }

        if isBatchMode {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedSeats.contains(index) {
                    selectedSeats.remove(index)
                } else {
                    selectedSeats.insert(index)
                }
            }
            
            // Haptic feedback for batch selection
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        } else {
            // Simply set the selected seat index - SwiftUI will handle sheet transitions smoothly
            selectedSeatIndex = index
            priceInput = concert.seats[index].price != nil ? String(concert.seats[index].price!) : ""
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    private func handleSeatLongPress(_ index: Int) {
        // Prevent seat selection while data is updating
        guard !isUpdatingData else { return }

        // Prevent editing for users without edit permissions
        guard canEdit else { return }

        // Enter batch mode and select the long-pressed seat
        withAnimation(.easeInOut(duration: 0.3)) {
            isBatchMode = true
            selectedSeats.removeAll()
            selectedSeats.insert(index)
        }
    }
    
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever()) {
            pulseFirepit.toggle()
        }
    }
    
    private func formatConcertDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Compact Firepit View
struct CompactFirepitView: View {
    let isPulsing: Bool
    
    var body: some View {
        ZStack {
            // Outer glow for rectangular firepit
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.orange.opacity(0.3),
                            Color.orange.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 15,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 70)
                .blur(radius: 10)
                .scaleEffect(isPulsing ? 1.1 : 1.0)
            
            // Main rectangular firepit
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.fireRed,
                            Color.orange,
                            Color.fireYellow.opacity(0.9)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: 100, height: 50)
                .overlay(
                    // Inner fire detail
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.fireYellow.opacity(0.8),
                                    Color.orange.opacity(0.6)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 85, height: 38)
                        .blur(radius: 2)
                )
                .shadow(color: .orange.opacity(0.6), radius: 12)
                .shadow(color: .fireRed.opacity(0.4), radius: 6)
        }
        .animation(.easeInOut(duration: 2.0).repeatForever(), value: isPulsing)
    }
}

// MARK: - Compact Seat View
struct CompactSeatView: View {
    let seatNumber: Int
    let seat: Seat
    let isSelected: Bool
    let isBatchMode: Bool
    let isBuyerView: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    @State private var isPressed = false
    @State private var shakeOffset: CGFloat = 0
    
    var seatColor: Color {
        if isBuyerView {
            // Buyer view: only green for available, red for sold/reserved
            switch seat.status {
            case .available: return .green
            case .reserved, .sold: return .red
            }
        } else if isBatchMode && isSelected {
            return .blue
        } else {
            switch seat.status {
            case .available: return .green  // Green for available
            case .reserved: return .orange  // Orange for reserved
            case .sold: return .red  // Red for sold
            }
        }
    }
    
    var textColor: Color {
        switch seat.status {
        case .available: return .white  // White text on green background
        case .reserved: return .white  // White text on orange background
        case .sold: return .white  // White text on red background
        }
    }
    
    var statusText: String {
        if isBuyerView {
            // Buyer view: simple "SOLD" or "OPEN"
            switch seat.status {
            case .available: return "OPEN"
            case .reserved, .sold: return "SOLD"
            }
        }
        
        // Management view: detailed status
        // For sold seats, show price OR family member name OR donation
        if seat.status == .sold {
            // Check if it's a donation
            if seat.source == .donation {
                return "DONATION"
            }
            // Check if it's a family member (source is Family)
            if seat.source == .family, let note = seat.note, !note.isEmpty {
                // Show only truncated name (4 chars) for family - no price
                let name = String(note.prefix(4)).uppercased()
                return name
            } else if let price = seat.price {
                // Show price for non-family sold seats
                return "$\(Int(price))"
            }
            return "SOLD"
        }
        
        // For reserved seats, show note if present
        if seat.status == .reserved {
            if let note = seat.note, !note.isEmpty {
                let truncated = String(note.prefix(7))
                return truncated.uppercased()
            }
            return "RESV"
        }
        
        // For available seats, show nothing (seat number is shown in the circle)
        return ""
    }
    
    var body: some View {
        VStack(spacing: -2) {  // Negative spacing to bring text very close to seat
            // Seat button with liquid glass effect
            ZStack {
                // Glass background
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .frame(width: 48, height: 48)

                // Colored gradient overlay
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        RadialGradient(
                            colors: [
                                seatColor.opacity(0.6),
                                seatColor.opacity(0.4)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 24
                        )
                    )
                    .frame(width: 48, height: 48)

                // Border
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(seatColor.opacity(0.7), lineWidth: 2)
                    .frame(width: 48, height: 48)

                if isBatchMode && isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                } else {
                    Text("\(seatNumber)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
            }
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .shadow(color: seatColor.opacity(0.4), radius: isPressed ? 4 : 8, x: 0, y: isPressed ? 2 : 4)

            // Status/Price text - always present with fixed height for alignment
            Text(statusText.isEmpty ? " " : statusText)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(height: 24) // Fixed height to maintain alignment
                .opacity(statusText.isEmpty ? 0 : 1) // Hide when empty but maintain space
        }
        .offset(x: shakeOffset)
        .onTapGesture {
            guard !isBuyerView else { return } // Disable interactions in buyer view

            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            HapticManager.shared.impact(style: .medium)
            onTap()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
        }
        .onLongPressGesture(minimumDuration: 0.6) {
            guard !isBuyerView else { return }

            // Shake animation to indicate batch mode entry
            withAnimation(.interpolatingSpring(stiffness: 900, damping: 8).repeatCount(3, autoreverses: true)) {
                shakeOffset = 5
            }

            // Reset shake after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                shakeOffset = 0
            }

            HapticManager.shared.impact(style: .heavy)
            onLongPress()
        }
    }
}

// MARK: - Interactive Seat View
struct InteractiveSeatView: View {
    let seatNumber: Int
    let seat: Seat
    let isSelected: Bool
    let isBatchMode: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    @State private var isPressed = false
    @State private var isAnimating = false
    @State private var isHovering = false
    @EnvironmentObject var sharedSuiteManager: SharedSuiteManager
    
    var seatGradient: LinearGradient {
        if isBatchMode && isSelected {
            return LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.6, blue: 1.0),
                    Color(red: 0.1, green: 0.4, blue: 0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        switch seat.status {
        case .available:
            return LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.95, blue: 0.97),
                    Color(red: 0.88, green: 0.88, blue: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .reserved:
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.7, blue: 0.2),
                    Color(red: 0.95, green: 0.6, blue: 0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sold:
            return LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.8, blue: 0.4),
                    Color(red: 0.1, green: 0.7, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var seatTextColor: Color {
        switch seat.status {
        case .available:
            return Color(red: 0.2, green: 0.2, blue: 0.3)
        case .reserved, .sold:
            return .white
        }
    }
    
    var statusIcon: String {
        switch seat.status {
        case .available:
            return "circle"
        case .reserved:
            return "clock.circle.fill"
        case .sold:
            return "checkmark.circle.fill"
        }
    }
    
    var modificationInfo: String {
        guard sharedSuiteManager.isInSharedSuite else { return "" }
        
        if let lastModifiedBy = seat.lastModifiedBy,
           let modificationDate = seat.lastModifiedDate {
            let isCurrentUser = lastModifiedBy == sharedSuiteManager.self.currentUserId
            let userDisplayName = isCurrentUser ? "You" : (getUserDisplayName(userId: lastModifiedBy) ?? "User")
            
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            let timeString = formatter.localizedString(for: modificationDate, relativeTo: Date())
            
            return "\(userDisplayName) • \(timeString)"
        }
        return ""
    }
    
    private func getUserDisplayName(userId: String) -> String? {
        return sharedSuiteManager.currentSuiteInfo?.members.first(where: { $0.userId == userId })?.displayName
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Button(action: {
                // Enhanced haptic feedback
                HapticManager.shared.impact(style: seat.status == .available ? .medium : .light)
                
                // Smooth press animation
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7, blendDuration: 0.1)) {
                    isPressed = true
                    isAnimating = true
                }
                
                onTap()
                
                // Reset press animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPressed = false
                    }
                }
                
                // Status change animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isAnimating = false
                    }
                }
            }) {
                ZStack {
                    // Enhanced seat design
                    ZStack {
                        // Main seat body
                        RoundedRectangle(cornerRadius: 12)
                            .fill(seatGradient)
                            .frame(width: 50, height: 50)
                            .scaleEffect(
                                isPressed ? 0.95 : 
                                (isAnimating ? 1.08 : 
                                (isHovering ? 1.03 : 1.0))
                            )
                            .shadow(
                                color: seatShadowColor,
                                radius: isHovering ? 8 : 5,
                                x: 0,
                                y: isHovering ? 4 : 2
                            )
                        
                        // Subtle inner highlight
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(seat.status == .available ? 0.3 : 0.4),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                            .frame(width: 50, height: 50)
                            .scaleEffect(
                                isPressed ? 0.95 : 
                                (isAnimating ? 1.08 : 
                                (isHovering ? 1.03 : 1.0))
                            )
                        
                        // Animated ring for interaction feedback
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Color.white.opacity(isHovering ? 0.6 : 0),
                                lineWidth: 2
                            )
                            .frame(width: 54, height: 54)
                            .scaleEffect(isHovering ? 1.05 : 1.0)
                            .opacity(isHovering ? 1.0 : 0.0)
                    }
                    
                    // Seat content overlay
                    ZStack {
                        // Seat number
                        Text("\(seatNumber)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(seatTextColor)
                        
                        // Status indicators
                        VStack {
                            HStack {
                                // Sync status indicator for shared suites
                                if sharedSuiteManager.isInSharedSuite && sharedSuiteManager.isSyncing {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.blue)
                                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                                        .animation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
                                }
                                
                                // Recent modification indicator
                                if let lastModified = seat.lastModifiedDate,
                                   Date().timeIntervalSince(lastModified) < 300, // 5 minutes
                                   sharedSuiteManager.isInSharedSuite {
                                    Image(systemName: "clock.badge.fill")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.orange)
                                }
                                
                                if isBatchMode && isSelected {
                                    // Batch selection indicator
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .background(
                                            Circle()
                                                .fill(Color(red: 0.1, green: 0.4, blue: 0.9))
                                                .frame(width: 20, height: 20)
                                        )
                                        .scaleEffect(isSelected ? 1.1 : 1.0)
                                        .transition(.scale.combined(with: .opacity))
                                } else if seat.status != .available {
                                    // Status icon for reserved/sold
                                    Image(systemName: statusIcon)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .opacity(0.9)
                                }
                                Spacer()
                            }
                            Spacer()
                        }
                        .frame(width: 44, height: 44)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovering = hovering
                }
            }
            .onLongPressGesture(minimumDuration: 0.6) {
                HapticManager.shared.impact(style: .heavy)
                onLongPress()
            }
            .disabled(false) // Always allow interaction for better UX
            
            // Enhanced information display
            VStack(spacing: 2) {
                // Status text
                Text(primaryStatusText)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(statusTextColor)
                    .lineLimit(1)
                
                // Secondary info
                if !secondaryStatusText.isEmpty {
                    Text(secondaryStatusText)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(statusTextColor.opacity(0.7))
                        .lineLimit(1)
                }
            }
            .frame(width: 60, height: 28)
            .multilineTextAlignment(.center)
        }
        .frame(width: 64, height: 84)
    }
    
    private var seatShadowColor: Color {
        switch seat.status {
        case .available:
            return Color.black.opacity(0.12)
        case .reserved:
            return Color.orange.opacity(0.3)
        case .sold:
            return Color.green.opacity(0.3)
        }
    }
    
    private var statusTextColor: Color {
        switch seat.status {
        case .available:
            return Color(red: 0.4, green: 0.4, blue: 0.5)
        case .reserved:
            return Color.orange
        case .sold:
            return Color.green
        }
    }
    
    private var primaryStatusText: String {
        if isBatchMode && isSelected {
            return "SELECTED"
        }

        switch seat.status {
        case .available:
            return "AVAILABLE"
        case .reserved:
            return "RESERVED"
        case .sold:
            if seat.source == .donation {
                return "DONATION"
            }
            if let price = seat.price {
                return "$\(Int(price))"
            }
            return "SOLD"
        }
    }
    
    private var secondaryStatusText: String {
        // Show modification info if in shared suite and seat has been modified recently
        if sharedSuiteManager.isInSharedSuite && !modificationInfo.isEmpty {
            return modificationInfo
        }
        
        switch seat.status {
        case .available:
            return ""
        case .reserved:
            return seat.note ?? ""
        case .sold:
            if seat.source == .family, let personName = seat.familyPersonName, !personName.isEmpty {
                return personName
            }
            if seat.source == .donation {
                return "Donate"
            }
            return seat.source?.rawValue ?? ""
        }
    }
}

// MARK: - Seat Options View
struct SeatOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsManager: SettingsManager
    
    let seatNumber: Int
    let seat: Seat
    let onUpdate: (Seat) -> Void
    let onUpdateAll: ((Seat) -> Void)?
    
    @State private var selectedStatus: SeatStatus
    @State private var priceInput: String
    @State private var costInput: String
    @State private var noteInput: String
    @State private var selectedSource: TicketSource
    @State private var dateSold: Date
    @State private var datePaid: Date
    @State private var familyPersonName: String
    
    // Donation-specific state variables
    @State private var donationDate: Date
    @State private var donationFaceValueInput: String
    @State private var charityName: String
    @State private var charityAddress: String
    @State private var charityEIN: String
    @State private var charityContactName: String
    @State private var charityContactInfo: String
    
    init(seatNumber: Int, seat: Seat, onUpdate: @escaping (Seat) -> Void, onUpdateAll: ((Seat) -> Void)? = nil) {
        self.seatNumber = seatNumber
        self.seat = seat
        self.onUpdate = onUpdate
        self.onUpdateAll = onUpdateAll
        self._selectedStatus = State(initialValue: seat.status)
        self._priceInput = State(initialValue: seat.price != nil ? String(seat.price!) : "")
        self._costInput = State(initialValue: String(seat.cost ?? 0.0))
        self._noteInput = State(initialValue: seat.note ?? "")
        self._selectedSource = State(initialValue: seat.source ?? .facebook)
        self._dateSold = State(initialValue: seat.dateSold ?? Date())
        self._datePaid = State(initialValue: seat.datePaid ?? Date())
        // Initialize familyPersonName from note if it's a family sale
        self._familyPersonName = State(initialValue: 
            (seat.source == .family && seat.note != nil) ? seat.note! : 
            (seat.familyPersonName ?? "")
        )
        
        // Initialize donation-specific state variables
        self._donationDate = State(initialValue: seat.donationDate ?? Date())
        self._donationFaceValueInput = State(initialValue: seat.donationFaceValue != nil ? String(seat.donationFaceValue!) : "")
        self._charityName = State(initialValue: seat.charityName ?? "")
        self._charityAddress = State(initialValue: seat.charityAddress ?? "")
        self._charityEIN = State(initialValue: seat.charityEIN ?? "")
        self._charityContactName = State(initialValue: seat.charityContactName ?? "")
        self._charityContactInfo = State(initialValue: seat.charityContactInfo ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(selectedStatus.color)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text("\(seatNumber)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            )
                            .animation(.easeInOut(duration: 0.3), value: selectedStatus)
                        
                        Text("Seat \(seatNumber)")
                            .font(.system(size: 24, weight: .bold))
                    }
                    .padding(.top, 20)
                
                    // Status Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Status")
                            .font(.system(size: 18, weight: .semibold))
                        
                        HStack(spacing: 8) {
                            ForEach(SeatStatus.allCases, id: \.self) { status in
                                Button(action: {
                                    selectedStatus = status
                                    if status == .sold {
                                        dateSold = Date()
                                        datePaid = Date()
                                        // Auto-populate family price if Family source is selected
                                        if selectedSource == .family {
                                            priceInput = String(Int(settingsManager.familyTicketPrice))
                                        }
                                    }
                                }) {
                                    VStack(spacing: 6) {
                                        Circle()
                                            .fill(status.color)
                                            .frame(width: 12, height: 12)
                                        Text(status.rawValue.capitalized)
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedStatus == status ? status.color.opacity(0.15) : Color.gray.opacity(0.1))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                
                    // Form Fields with smooth transitions
                    VStack(spacing: 16) {
                        if selectedStatus == .sold {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("$")
                                        .font(.system(size: 18, weight: .bold))
                                    TextField("Price", text: $priceInput)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                        .toolbar {
                                            ToolbarItemGroup(placement: .keyboard) {
                                                Spacer()
                                                Button("Done") {
                                                    UIApplication.shared.dismissKeyboard()
                                                }
                                            }
                                        }
                                }
                                
                                Picker("Source", selection: $selectedSource) {
                                    ForEach(TicketSource.allCases, id: \.self) { source in
                                        Text(source.rawValue).tag(source)
                                    }
                                }
                                .pickerStyle(.menu)
                                .onChange(of: selectedSource) { oldValue, newValue in
                                    // Auto-populate family ticket price when Family is selected
                                    if newValue == .family {
                                        priceInput = String(Int(settingsManager.familyTicketPrice))
                                    }
                                }
                                
                                if selectedSource == .family {
                                    TextField("Person's name", text: $familyPersonName)
                                        .textFieldStyle(.roundedBorder)
                                        .transition(.opacity.combined(with: .scale))
                                }
                                
                                // Donation Details (only when Donation source is selected)
                                if selectedSource == .donation {
                                    VStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Donation Details")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.modernText)
                                            
                                            DatePicker("Donation Date", selection: $donationDate, displayedComponents: .date)
                                            
                                            TextField("Face Value per Ticket", text: $donationFaceValueInput)
                                                .keyboardType(.decimalPad)
                                                .textFieldStyle(.roundedBorder)
                                                .toolbar {
                                                    ToolbarItemGroup(placement: .keyboard) {
                                                        Spacer()
                                                        Button("Done") {
                                                            UIApplication.shared.dismissKeyboard()
                                                        }
                                                    }
                                                }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Charity Information")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.modernText)
                                            
                                            CharitySearchField(
                                                selectedCharity: $charityName,
                                                savedCharities: settingsManager.savedCharities,
                                                onCharitySelected: { charity in
                                                    charityName = charity.name
                                                    charityAddress = charity.address
                                                    charityEIN = charity.ein
                                                    charityContactName = charity.contactName
                                                    charityContactInfo = charity.contactInfo
                                                }
                                            )
                                            
                                            TextField("Charity Mailing Address", text: $charityAddress, axis: .vertical)
                                                .textFieldStyle(.roundedBorder)
                                                .lineLimit(2...4)
                                            
                                            TextField("EIN (Tax ID Number)", text: $charityEIN)
                                                .textFieldStyle(.roundedBorder)
                                            
                                            TextField("Contact Person Name", text: $charityContactName)
                                                .textFieldStyle(.roundedBorder)
                                            
                                            TextField("Contact Email or Phone", text: $charityContactInfo)
                                                .textFieldStyle(.roundedBorder)
                                        }
                                    }
                                    .padding(16)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                    .transition(.opacity.combined(with: .scale))
                                }
                                
                                // Only show Date Sold/Paid for non-donation sources
                                if selectedSource != .donation {
                                    DatePicker("Date Sold", selection: $dateSold, displayedComponents: .date)
                                    DatePicker("Date Paid", selection: $datePaid, displayedComponents: .date)
                                }
                            }
                            .transition(.opacity.combined(with: .scale))
                        } else if selectedStatus == .reserved {
                            TextField("Reserved for", text: $noteInput)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: noteInput) { oldValue, newValue in
                                    let words = newValue.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                                    if words.count > 1 {
                                        noteInput = words.prefix(1).joined(separator: " ")
                                    }
                                }
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: selectedStatus)
                    
                    HStack {
                        Text("Cost: $")
                        TextField("25", text: $costInput)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        UIApplication.shared.dismissKeyboard()
                                    }
                                }
                            }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button("Update Seat") {
                            updateSeat()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .overlay(
                Button("✕") {
                    dismiss()
                }
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.white))
                .shadow(radius: 4)
                .padding()
                .allowsHitTesting(true)
                .zIndex(999)
                , alignment: .topTrailing
            )
        }
    }
    
    private func updateSeat() {
        var updatedSeat = seat
        updatedSeat.status = selectedStatus
        
        if selectedStatus == .sold {
            updatedSeat.price = priceInput.isEmpty ? nil : Double(priceInput)
            updatedSeat.cost = Double(costInput) ?? settingsManager.defaultSeatCost
            // For family members, store the name in the note field
            updatedSeat.note = selectedSource == .family && !familyPersonName.isEmpty ? familyPersonName : nil
            updatedSeat.source = selectedSource
            updatedSeat.familyPersonName = selectedSource == .family ? (familyPersonName.isEmpty ? nil : familyPersonName) : nil
            updatedSeat.dateSold = dateSold
            updatedSeat.datePaid = datePaid
            
            // Handle donation-specific data
            if selectedSource == .donation {
                updatedSeat.donationDate = donationDate
                updatedSeat.donationFaceValue = donationFaceValueInput.isEmpty ? nil : Double(donationFaceValueInput)
                updatedSeat.charityName = charityName.isEmpty ? nil : charityName
                updatedSeat.charityAddress = charityAddress.isEmpty ? nil : charityAddress
                updatedSeat.charityEIN = charityEIN.isEmpty ? nil : charityEIN
                updatedSeat.charityContactName = charityContactName.isEmpty ? nil : charityContactName
                updatedSeat.charityContactInfo = charityContactInfo.isEmpty ? nil : charityContactInfo
            } else {
                // Clear donation fields for non-donation sources
                updatedSeat.donationDate = nil
                updatedSeat.donationFaceValue = nil
                updatedSeat.charityName = nil
                updatedSeat.charityAddress = nil
                updatedSeat.charityEIN = nil
                updatedSeat.charityContactName = nil
                updatedSeat.charityContactInfo = nil
            }
            
            AudioServicesPlaySystemSound(1054)
        } else if selectedStatus == .reserved {
            updatedSeat.price = nil
            updatedSeat.cost = Double(costInput) ?? settingsManager.defaultSeatCost
            updatedSeat.note = noteInput.isEmpty ? nil : noteInput
            updatedSeat.source = nil
            updatedSeat.familyPersonName = nil
            updatedSeat.dateSold = nil
            updatedSeat.datePaid = nil
            // Clear donation fields
            updatedSeat.donationDate = nil
            updatedSeat.donationFaceValue = nil
            updatedSeat.charityName = nil
            updatedSeat.charityAddress = nil
            updatedSeat.charityEIN = nil
            updatedSeat.charityContactName = nil
            updatedSeat.charityContactInfo = nil
        } else {
            updatedSeat.price = nil
            updatedSeat.cost = Double(costInput) ?? settingsManager.defaultSeatCost
            updatedSeat.note = nil
            updatedSeat.source = nil
            updatedSeat.familyPersonName = nil
            updatedSeat.dateSold = nil
            updatedSeat.datePaid = nil
            // Clear donation fields
            updatedSeat.donationDate = nil
            updatedSeat.donationFaceValue = nil
            updatedSeat.charityName = nil
            updatedSeat.charityAddress = nil
            updatedSeat.charityEIN = nil
            updatedSeat.charityContactName = nil
            updatedSeat.charityContactInfo = nil
        }
        
        // Save charity if it's a new donation with complete charity information
        if selectedSource == .donation && 
           !charityName.isEmpty && 
           !charityAddress.isEmpty && 
           !charityEIN.isEmpty {
            let newCharity = SavedCharity(
                name: charityName,
                address: charityAddress,
                ein: charityEIN,
                contactName: charityContactName,
                contactInfo: charityContactInfo
            )
            settingsManager.saveCharity(newCharity)
        }
        
        onUpdate(updatedSeat)
        dismiss()
    }
}

// MARK: - Shareable Seat Layout View
struct ShareableSeatLayoutView: View {
    let concert: Concert
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text(settingsManager.suiteName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(concert.artist)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Text(DateFormatter.localizedString(from: concert.date, dateStyle: .full, timeStyle: .none))
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                Text(settingsManager.venueLocation)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 16)
            
            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 16, height: 16)
                    Text("Open")
                        .font(.system(size: 14, weight: .medium))
                }

                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 16, height: 16)
                    Text("Sold")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .padding(.horizontal)
            
            // Seat Layout - Same arrangement as management view but simplified
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .frame(height: 220)
                .overlay(
                    ZStack {
                        // Bottom row (seats 3, 4, 5, 6)
                        VStack {
                            Spacer()
                            HStack(spacing: 14) {
                                ShareableSeatView(seatNumber: 6, seat: concert.seats[5])
                                ShareableSeatView(seatNumber: 5, seat: concert.seats[4])
                                ShareableSeatView(seatNumber: 4, seat: concert.seats[3])
                                ShareableSeatView(seatNumber: 3, seat: concert.seats[2])
                            }
                            .padding(.bottom, 8)
                        }
                        
                        // Left side (seats 7, 8)
                        HStack {
                            VStack(spacing: -2) {
                                ShareableSeatView(seatNumber: 8, seat: concert.seats[7])
                                ShareableSeatView(seatNumber: 7, seat: concert.seats[6])
                                Spacer()
                                    .frame(height: 72)
                            }
                            .padding(.leading, 8)
                            
                            Spacer()
                        }
                        
                        // Right side (seats 1, 2)
                        HStack {
                            Spacer()
                            
                            VStack(spacing: -2) {
                                ShareableSeatView(seatNumber: 1, seat: concert.seats[0])
                                ShareableSeatView(seatNumber: 2, seat: concert.seats[1])
                                Spacer()
                                    .frame(height: 72)
                            }
                            .padding(.trailing, 8)
                        }
                        
                        // Center firepit
                        VStack {
                            ShareableFirepitView()
                                .padding(.top, 80)
                            Spacer()
                        }
                    }
                )
                .padding(.horizontal)
            
            // Footer with contact info
            VStack(spacing: 4) {
                Text("Select your seat and text your choice!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("Suite seats available for purchase")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Shareable Seat View (Simplified)
struct ShareableSeatView: View {
    let seatNumber: Int
    let seat: Seat
    
    private var seatColor: Color {
        switch seat.status {
        case .available:
            return .green
        case .reserved, .sold:
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(seatColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Text("\(seatNumber)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
                .shadow(color: seatColor.opacity(0.4), radius: 4, x: 0, y: 2)
            
            Text(seat.status == .available ? "Open" : "Sold")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(seatColor)
        }
    }
}

// MARK: - Shareable Firepit View (Simplified)
struct ShareableFirepitView: View {
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [.yellow, .orange, .red.opacity(0.8)],
                    center: .center,
                    startRadius: 5,
                    endRadius: 20
                )
            )
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            )
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.modernText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Parking Ticket Options View
struct ParkingTicketOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsManager: SettingsManager
    @State var parkingTicket: ParkingTicket
    let onUpdate: (ParkingTicket) -> Void
    
    @State private var selectedStatus: SeatStatus
    @State private var priceInput: String
    @State private var costInput: String
    @State private var noteInput: String
    @State private var selectedSource: TicketSource
    @State private var dateSold: Date
    @State private var datePaid: Date
    
    init(parkingTicket: ParkingTicket, onUpdate: @escaping (ParkingTicket) -> Void) {
        self.parkingTicket = parkingTicket
        self.onUpdate = onUpdate
        self._selectedStatus = State(initialValue: parkingTicket.status)
        self._priceInput = State(initialValue: parkingTicket.price != nil ? String(parkingTicket.price!) : "0")
        self._costInput = State(initialValue: String(parkingTicket.cost ?? 0.0))
        self._noteInput = State(initialValue: parkingTicket.note ?? "")
        self._selectedSource = State(initialValue: parkingTicket.source ?? .facebook)
        self._dateSold = State(initialValue: parkingTicket.dateSold ?? Date())
        self._datePaid = State(initialValue: parkingTicket.datePaid ?? Date())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background that adapts to light/dark mode
                Color(.systemBackground)
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Circle()
                                .fill(parkingTicket.status.color.opacity(0.1))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "car.fill")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(parkingTicket.status.color)
                                )
                            
                            Text("Parking Ticket")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.modernText)
                            
                            HStack {
                                Circle()
                                    .fill(parkingTicket.status.color)
                                    .frame(width: 8, height: 8)
                                Text(parkingTicket.status.rawValue.capitalized)
                                    .font(.system(size: 16))
                                    .foregroundColor(parkingTicket.status.color)
                            }
                        }
                        .padding(.top, 20)
                    
                        // Status selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Parking Status")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.modernText)
                            
                            VStack(spacing: 12) {
                                ForEach(SeatStatus.allCases, id: \.self) { status in
                                    Button(action: {
                                        let previousStatus = selectedStatus
                                        selectedStatus = status
                                        
                                        // Auto-populate dateSold when status changes to sold
                                        if status == .sold && previousStatus != .sold {
                                            dateSold = Date()
                                            datePaid = Date()
                                        }
                                    }) {
                                        HStack(spacing: 16) {
                                            Circle()
                                                .fill(status.color.opacity(0.1))
                                                .frame(width: 40, height: 40)
                                                .overlay(
                                                    Circle()
                                                        .fill(status.color)
                                                        .frame(width: 16, height: 16)
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(status.rawValue.capitalized)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.modernText)
                                            }
                                            
                                            Spacer()
                                            
                                            if selectedStatus == status {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(status.color)
                                            }
                                        }
                                        .padding(16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedStatus == status ? status.color.opacity(0.1) : Color.clear)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(selectedStatus == status ? status.color : Color.white.opacity(0.1), lineWidth: 1)
                                                )
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        // Price input (for sold/reserved)
                        if selectedStatus == .sold || selectedStatus == .reserved {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Price")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.modernText)
                                
                                TextField("Enter price", text: $priceInput)
                                    .keyboardType(.decimalPad)
                                    .padding(16)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                    .foregroundColor(.modernText)
                            }
                        }
                        
                        // Cost input (for sold)
                        if selectedStatus == .sold {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Cost (Optional)")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.modernText)
                                
                                TextField("Enter cost", text: $costInput)
                                    .keyboardType(.decimalPad)
                                    .padding(16)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                    .foregroundColor(.modernText)
                            }
                        }
                        
                        // Note input (for reserved)
                        if selectedStatus == .reserved {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Note (Max 5 words)")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.modernText)
                                
                                TextField("Enter note", text: $noteInput)
                                    .padding(16)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                    .foregroundColor(.modernText)
                                    .onChange(of: noteInput) { oldValue, newValue in
                                        let words = newValue.split(separator: " ")
                                        if words.count > 5 {
                                            noteInput = words.prefix(5).joined(separator: " ")
                                        }
                                    }
                            }
                        }
                        
                        // Source selection (for sold)
                        if selectedStatus == .sold {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Ticket Source")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.modernText)
                                
                                VStack(spacing: 8) {
                                    ForEach(TicketSource.allCases, id: \.self) { source in
                                        Button(action: {
                                            selectedSource = source
                                        }) {
                                            HStack {
                                                Text(source.rawValue)
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.modernText)
                                                
                                                Spacer()
                                                
                                                if selectedSource == source {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                            .padding(12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedSource == source ? Color.blue.opacity(0.1) : Color.clear)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(selectedSource == source ? Color.blue : Color.white.opacity(0.1), lineWidth: 1)
                                                    )
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveParkingTicket()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    private func saveParkingTicket() {
        var updatedTicket = parkingTicket
        updatedTicket.status = selectedStatus
        
        // Handle price
        if selectedStatus == .sold || selectedStatus == .reserved {
            updatedTicket.price = Double(priceInput)
        } else {
            updatedTicket.price = nil
        }
        
        // Handle cost and dates for sold tickets
        if selectedStatus == .sold {
            updatedTicket.cost = Double(costInput) ?? 0.0
            updatedTicket.source = selectedSource
            updatedTicket.dateSold = dateSold
            updatedTicket.datePaid = datePaid
        } else {
            updatedTicket.cost = nil
            updatedTicket.source = nil
            updatedTicket.dateSold = nil
            updatedTicket.datePaid = nil
        }
        
        // Handle note for reserved tickets
        if selectedStatus == .reserved {
            updatedTicket.note = noteInput.isEmpty ? nil : noteInput
        } else {
            updatedTicket.note = nil
        }
        
        onUpdate(updatedTicket)
    }
}

struct DynamicAnalytics: View {
    @Binding var concerts: [Concert]
    @ObservedObject var settingsManager: SettingsManager
    @State private var isGeneratingReport = false
    @State private var generatedReportURL: URL?
    @State private var activeSheet: SheetType?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background that adapts to light/dark mode
                Color(.systemBackground)
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: .spacingSections) {
                        // Header
                        VStack(spacing: .radiusSmall) {
                            Text("Analytics")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Performance insights and trends")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.3, green: 0.2, blue: 0.9),
                                                Color(red: 0.5, green: 0.3, blue: 0.95),
                                                Color(red: 0.7, green: 0.4, blue: 1.0)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.1), .clear, .black.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .drawingGroup()
                            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
                        )
                        .padding(.top, 20)

                        // Performance Metrics
                        PerformanceMetricsView(concerts: concerts)
                        
                        // Reporting Section
                        ReportingView(
                            concerts: concerts,
                            settingsManager: settingsManager,
                            isGenerating: $isGeneratingReport,
                            generatedReportURL: $generatedReportURL,
                            activeSheet: $activeSheet
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $activeSheet) { sheetType in
                switch sheetType {
                case .shareSheet:
                    if let reportURL = generatedReportURL {
                        ShareSheet(activityItems: [reportURL])
                    }
                default:
                    EmptyView()
                }
            }
        }
    }
}

// MARK: - Reporting View
struct ReportingView: View {
    let concerts: [Concert]
    @ObservedObject var settingsManager: SettingsManager
    @Binding var isGenerating: Bool
    @Binding var generatedReportURL: URL?
    @Binding var activeSheet: SheetType?
    @State private var animateIcon = false
    
    // Report customization options
    @State private var includeProfitAnalysis = true
    @State private var includeConcertData = true
    @State private var includePerformanceRankings = true
    @State private var includeExecutiveSummary = true
    @State private var includeCharityReport = false
    @State private var includeFutureConcerts = false
    
    private var hasSelectedElements: Bool {
        includeProfitAnalysis || includeConcertData || includePerformanceRankings || includeExecutiveSummary || includeCharityReport
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Business Reports")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text("Comprehensive profit analysis and data export")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(animateIcon ? 360 : 0))
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false), value: animateIcon)
                }
            }
            
            // Report Customization
            VStack(alignment: .leading, spacing: 8) {
                Text("Report Elements")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
                
                VStack(spacing: 16) {
                    CustomizableReportFeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Profit Analysis",
                        description: "Detailed revenue, costs, and profit margins",
                        isEnabled: $includeProfitAnalysis
                    )
                    
                    CustomizableReportFeatureRow(
                        icon: "tablecells",
                        title: "Concert Data",
                        description: "Complete seat-by-seat sales information",
                        isEnabled: $includeConcertData
                    )
                    
                    CustomizableReportFeatureRow(
                        icon: "trophy",
                        title: "Performance Rankings",
                        description: "Top performing concerts and revenue sources",
                        isEnabled: $includePerformanceRankings
                    )
                    
                    CustomizableReportFeatureRow(
                        icon: "percent",
                        title: "Executive Summary",
                        description: "Key metrics and occupancy statistics",
                        isEnabled: $includeExecutiveSummary
                    )
                    
                    CustomizableReportFeatureRow(
                        icon: "heart.circle",
                        title: "Charity Report",
                        description: "Tax-deductible donations and charity analytics",
                        isEnabled: $includeCharityReport
                    )
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Analysis Options")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    CustomizableReportFeatureRow(
                        icon: "calendar.badge.clock",
                        title: "Include Future Concerts",
                        description: "Include upcoming concerts in profit analysis calculations",
                        isEnabled: $includeFutureConcerts
                    )
                }
            }
            
            // Generate Report Button
            Button {
                generateReport()
            } label: {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    Text(isGenerating ? "Generating Report..." : "Generate & Share Report")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.6, blue: 1.0),
                            Color(red: 0.1, green: 0.4, blue: 0.8),
                            Color(red: 0.0, green: 0.3, blue: 0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(isGenerating || concerts.isEmpty || !hasSelectedElements)
            .buttonStyle(HoverableButtonStyle())
            
            if concerts.isEmpty {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)
                    Text("Add concerts to generate reports")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            } else if !hasSelectedElements {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.yellow)
                    Text("Select at least one report element")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.7, blue: 0.4),
                                Color(red: 0.1, green: 0.5, blue: 0.3),
                                Color(red: 0.0, green: 0.4, blue: 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.05), .clear, .black.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
        )
        .onAppear {
            animateIcon = true
        }
    }
    
    private func generateReport() {
        guard !concerts.isEmpty else { return }
        
        isGenerating = true
        HapticManager.shared.impact(style: .medium)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let reportOptions = ReportOptions(
                includeProfitAnalysis: self.includeProfitAnalysis,
                includeConcertData: self.includeConcertData,
                includePerformanceRankings: self.includePerformanceRankings,
                includeExecutiveSummary: self.includeExecutiveSummary,
                includeCharityReport: self.includeCharityReport,
                includeFutureConcerts: self.includeFutureConcerts
            )
            
            let reportFileURL = ReportGenerator.shared.generateComprehensiveReportFile(
                concerts: concerts,
                settingsManager: settingsManager,
                options: reportOptions
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Small delay for UX
                self.generatedReportURL = reportFileURL
                self.isGenerating = false
                if reportFileURL != nil {
                    self.activeSheet = .shareSheet
                }
            }
        }
    }
}

// MARK: - Report Feature Row
struct ReportFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
    }
}

// MARK: - Customizable Report Feature Row
struct CustomizableReportFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(isEnabled ? 0.2 : 0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(isEnabled ? 1.0 : 0.5))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(isEnabled ? 1.0 : 0.6))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(isEnabled ? 0.8 : 0.4))
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.2, green: 0.6, blue: 1.0)))
                .scaleEffect(0.8)
        }
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // Configure for better file sharing experience
        controller.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .postToFlickr,
            .postToVimeo
        ]
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct DynamicPortfolio: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                Text("💰 Portfolio Coming Soon")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .navigationTitle("Portfolio")
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var concertManager: ConcertDataManager
    @ObservedObject var sharedSuiteManager: SharedSuiteManager
    @Binding var selectedTab: Int
    @State private var activeSheet: SheetType?
    @State private var showLeaveConfirmation = false
    @State private var showDataSection = false
    @State private var showAboutSection = false
    @State private var showApplyToAllAlert = false
    @State private var showFinalApplyToAllAlert = false
    @State private var showArchiveList = false
    @State private var archiveYearToCreate: IdentifiableInt?
    @StateObject private var archiveManager = ArchiveManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Dismiss keyboard when tapping background
                        UIApplication.shared.dismissKeyboard()
                    }

                ScrollView {
                    VStack(spacing: .spacingSections) {
                        // Header
                        VStack(spacing: .spacingTight) {
                            Text("Settings")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Customize your suite preferences")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.3, green: 0.2, blue: 0.9),
                                                Color(red: 0.5, green: 0.3, blue: 0.95),
                                                Color(red: 0.7, green: 0.4, blue: 1.0)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.1), .clear, .black.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .drawingGroup()
                            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
                        )
                        .padding(.top, 20)
                        
                        // Suite Setup Section
                        CleanSettingsCard(title: "Suite Setup", icon: "building.2") {
                            VStack(spacing: 16) {
                                CleanSettingsField(
                                    title: "Suite Name",
                                    value: settingsManager.suiteName,
                                    placeholder: "Fire Suite"
                                ) { newValue in
                                    settingsManager.suiteName = newValue
                                }
                                
                                CleanSettingsField(
                                    title: "Venue Location", 
                                    value: settingsManager.venueLocation,
                                    placeholder: "Ford Amphitheater"
                                ) { newValue in
                                    settingsManager.venueLocation = newValue
                                }
                                
                                Divider()
                                
                                CleanPriceField(
                                    title: "Default Family Price",
                                    value: settingsManager.familyTicketPrice
                                ) { newPrice in
                                    settingsManager.familyTicketPrice = newPrice
                                }
                                
                                CleanPriceField(
                                    title: "Default Seat Cost",
                                    value: settingsManager.defaultSeatCost,
                                    actionButton: {
                                        AnyView(
                                            Button(action: {
                                                showApplyToAllAlert = true
                                            }) {
                                                HStack {
                                                    Image(systemName: "arrow.down.to.line.compact")
                                                    Text("Apply to All")
                                                }
                                            }
                                            .buttonStyle(CollaborationSecondaryButtonStyle())
                                            .disabled(concertManager.concerts.isEmpty || (sharedSuiteManager.isSharedSuite && sharedSuiteManager.userRole == .viewer))
                                        )
                                    }
                                ) { newPrice in
                                    settingsManager.defaultSeatCost = newPrice
                                }
                            }
                        }
                        
                        // Collaboration Section - Always show so users can enable it
                        CleanSettingsCard(title: "Collaboration", icon: "person.3") {
                            VStack(alignment: .leading, spacing: 16) {
                                if sharedSuiteManager.isInSharedSuite {
                                        // Active sharing state
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Sharing '\(sharedSuiteManager.currentSuiteInfo?.suiteName ?? "Suite")'")
                                                    .font(.system(size: 16, weight: .medium))
                                                Text("Role: \(sharedSuiteManager.userRole.displayName)")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.modernTextSecondary)
                                            }
                                            Spacer()
                                        }
                                        
                                        VStack(spacing: 12) {
                                            HStack(spacing: 12) {
                                                if sharedSuiteManager.userRole.canManageUsers {
                                                    Button(action: {
                                                        Task {
                                                            do {
                                                                let code = try await sharedSuiteManager.generateInvitationLink(role: .viewer)
                                                                let activityVC = UIActivityViewController(activityItems: [code], applicationActivities: nil)
                                                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                                                   let window = windowScene.windows.first {
                                                                    window.rootViewController?.present(activityVC, animated: true)
                                                                }
                                                            } catch {
                                                                print("Error generating invitation: \(error)")
                                                            }
                                                        }
                                                    }) {
                                                        HStack {
                                                            Image(systemName: "plus.circle.fill")
                                                            Text("Invite")
                                                        }
                                                    }
                                                    .buttonStyle(CollaborationSecondaryButtonStyle())
                                                    
                                                    Button(action: {
                                                        activeSheet = .memberManagement
                                                    }) {
                                                        HStack {
                                                            Image(systemName: "person.2.fill")
                                                            Text("Manage")
                                                        }
                                                    }
                                                    .buttonStyle(CollaborationSecondaryButtonStyle())
                                                }
                                                
                                                Button(action: {
                                                    Task {
                                                        await sharedSuiteManager.syncWithCloudKit()
                                                        if sharedSuiteManager.userRole == .owner {
                                                            let concertIds = concertManager.concerts.map { $0.id }
                                                            await sharedSuiteManager.populateSuiteRecordWithLocalConcertIds(concertIds)
                                                            await sharedSuiteManager.migrateConcertsToCurrentSuite(concertIds)
                                                        }
                                                        await sharedSuiteManager.syncConcertData()
                                                    }
                                                }) {
                                                    HStack {
                                                        Image(systemName: sharedSuiteManager.isSyncing ? "arrow.triangle.2.circlepath" : "arrow.clockwise.circle.fill")
                                                            .rotationEffect(.degrees(sharedSuiteManager.isSyncing ? 360 : 0))
                                                            .animation(sharedSuiteManager.isSyncing ?
                                                                Animation.linear(duration: 1.0).repeatForever(autoreverses: false) :
                                                                .default, value: sharedSuiteManager.isSyncing)
                                                        Text(sharedSuiteManager.isSyncing ? "Syncing..." : "Sync")
                                                    }
                                                }
                                                .buttonStyle(CollaborationPrimaryButtonStyle())
                                                .disabled(sharedSuiteManager.isSyncing)
                                            }

                                            Button(action: {
                                                showLeaveConfirmation = true
                                            }) {
                                                HStack {
                                                    Image(systemName: sharedSuiteManager.userRole == .owner ? "trash.fill" : "arrow.right.square.fill")
                                                    Text(sharedSuiteManager.userRole == .owner ? "Delete Suite" : "Leave Suite")
                                                }
                                            }
                                            .buttonStyle(CollaborationSecondaryButtonStyle(color: .red))
                                        }
                                        
                                    } else {
                                        // Setup sharing
                                        Toggle(isOn: $settingsManager.enableMultiTenantSuites) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Enable Suite Sharing")
                                                    .font(.system(size: 16, weight: .medium))
                                                Text("Collaborate with co-investors")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.modernTextSecondary)
                                            }
                                        }
                                        .toggleStyle(SwitchToggleStyle(tint: .modernAccent))
                                        
                                        if settingsManager.enableMultiTenantSuites {
                                            HStack(spacing: 12) {
                                                Button(action: {
                                                    Task {
                                                        do {
                                                            _ = try await sharedSuiteManager.createSharedSuiteInCloud(
                                                                suiteName: settingsManager.suiteName,
                                                                venueLocation: settingsManager.venueLocation
                                                            )
                                                        } catch {
                                                            print("Error creating suite: \(error)")
                                                        }
                                                    }
                                                }) {
                                                    HStack {
                                                        Image(systemName: "plus.square.fill")
                                                        Text("Create Suite")
                                                    }
                                                }
                                                .buttonStyle(CollaborationPrimaryButtonStyle())
                                                .disabled(!sharedSuiteManager.isCloudKitAvailable)
                                                
                                                Button(action: {
                                                    activeSheet = .joinSuite
                                                }) {
                                                    HStack {
                                                        Image(systemName: "arrow.right.circle.fill")
                                                        Text("Join Suite")
                                                    }
                                                }
                                                .buttonStyle(CollaborationSecondaryButtonStyle())
                                                .disabled(!sharedSuiteManager.isCloudKitAvailable)
                                            }
                                            
                                            if !sharedSuiteManager.isCloudKitAvailable {
                                                Text("iCloud required for sharing")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // CloudSync Section
                        CleanSettingsCard(title: "CloudSync", icon: "icloud") {
                            VStack(alignment: .leading, spacing: 16) {
                                // Status Display
                                HStack {
                                    Image(systemName: settingsManager.cloudSyncStatus.icon)
                                        .foregroundColor(settingsManager.cloudSyncStatus.color)
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Status: \(settingsManager.cloudSyncStatus.rawValue)")
                                            .font(.system(size: 16, weight: .medium))
                                        
                                        if let lastSync = settingsManager.lastSyncDate {
                                            Text("Last sync: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                                                .font(.system(size: 14))
                                                .foregroundColor(.modernTextSecondary)
                                        }
                                        
                                        if let error = settingsManager.syncErrorMessage {
                                            Text("Error: \(error)")
                                                .font(.system(size: 14))
                                                .foregroundColor(.red)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                
                                // Toggle Control
                                Toggle(isOn: Binding(
                                    get: { settingsManager.isCloudSyncEnabled },
                                    set: { newValue in
                                        if newValue {
                                            settingsManager.enableCloudSync()
                                        } else {
                                            // Prevent disabling CloudSync if user is owner of shared suite
                                            if sharedSuiteManager.isInSharedSuite && sharedSuiteManager.userRole == .owner {
                                                // Don't allow disabling - CloudSync is required for shared suite owners
                                                return
                                            }
                                            settingsManager.disableCloudSync()
                                        }
                                    }
                                )) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Enable CloudSync")
                                            .font(.system(size: 16, weight: .medium))
                                        Text(sharedSuiteManager.isInSharedSuite && sharedSuiteManager.userRole != .owner ?
                                             "Data synced via shared suite" :
                                             sharedSuiteManager.isInSharedSuite && sharedSuiteManager.userRole == .owner ?
                                             "Required for shared suite owners" :
                                             "Sync concert data across devices")
                                            .font(.system(size: 14))
                                            .foregroundColor(.modernTextSecondary)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .modernAccent))
                                .disabled(settingsManager.cloudSyncStatus == .syncing ||
                                         (sharedSuiteManager.isInSharedSuite && sharedSuiteManager.userRole != .owner) ||
                                         (sharedSuiteManager.isInSharedSuite && sharedSuiteManager.userRole == .owner))
                                
                                // Info Text
                                if sharedSuiteManager.isInSharedSuite && sharedSuiteManager.userRole != .owner {
                                    Text("Your concert data is automatically synced through the shared suite. Personal CloudSync is not needed while you're a guest.")
                                        .font(.system(size: 14))
                                        .foregroundColor(.modernTextSecondary)
                                        .padding(.top, 8)
                                } else if sharedSuiteManager.isInSharedSuite && sharedSuiteManager.userRole == .owner {
                                    Text("CloudSync is required and automatically enabled for shared suite owners. It cannot be disabled while you own a shared suite. Delete the shared suite to disable CloudSync.")
                                        .font(.system(size: 14))
                                        .foregroundColor(.modernTextSecondary)
                                        .padding(.top, 8)
                                } else if !settingsManager.isCloudSyncEnabled {
                                    Text("CloudSync safely backs up your concert data to iCloud and keeps it in sync across all your devices. You can disable it at any time.")
                                        .font(.system(size: 14))
                                        .foregroundColor(.modernTextSecondary)
                                        .padding(.top, 8)
                                } else {
                                    Text("Your concert data is now synced with iCloud. Changes will automatically sync across all your devices.")
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                        .padding(.top, 8)
                                }
                            }
                        }
                        
                        // Data Management Section
                        CleanSettingsCard(title: "Data Management", icon: "externaldrive") {
                            VStack(spacing: 12) {
                                Button(action: {
                                    showDataSection.toggle()
                                }) {
                                    HStack {
                                        Text("Storage & Privacy Info")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.modernText)
                                        Spacer()
                                        Image(systemName: showDataSection ? "chevron.down" : "chevron.right")
                                            .foregroundColor(.modernTextSecondary)
                                    }
                                }
                                
                                if showDataSection {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("• Data stored locally with iCloud sync")
                                        Text("• No external servers or tracking")
                                        Text("• Full privacy within Apple ecosystem")
                                    }
                                    .font(.system(size: 14))
                                    .foregroundColor(.modernTextSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                Divider()

                                // Only show backup/restore for non-shared suites or suite owners
                                if !sharedSuiteManager.isInSharedSuite || sharedSuiteManager.userRole == .owner {
                                    BackupRestoreSection(concertManager: concertManager, settingsManager: settingsManager)
                                }
                            }
                        }

                        // Year-End Archives Section
                        if !sharedSuiteManager.isInSharedSuite || sharedSuiteManager.userRole == .owner {
                            CleanSettingsCard(title: "Year-End Archives", icon: "archivebox") {
                                ArchiveSection(
                                    archiveManager: archiveManager,
                                    concertManager: concertManager,
                                    settingsManager: settingsManager,
                                    showArchiveList: $showArchiveList,
                                    archiveYearToCreate: $archiveYearToCreate
                                )
                            }
                        }

                        // About Section
                        CleanSettingsCard(title: "About", icon: "info.circle") {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Version 2.1")
                                        .font(.system(size: 16, weight: .medium))
                                    Spacer()
                                }
                                
                                Button(action: {
                                    if let url = URL(string: "https://suitekeepsupport.netlify.app") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack {
                                        Text("Support & Manual")
                                            .foregroundColor(.modernAccent)
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .foregroundColor(.modernAccent)
                                    }
                                }
                                
                                Button(action: {
                                    showAboutSection.toggle()
                                }) {
                                    HStack {
                                        Text("Disclaimer")
                                            .foregroundColor(.modernTextSecondary)
                                        Spacer()
                                        Image(systemName: showAboutSection ? "chevron.down" : "chevron.right")
                                            .foregroundColor(.modernTextSecondary)
                                    }
                                }
                                
                                if showAboutSection {
                                    Text("This app is provided \"as is\" without warranties. Use at your own risk.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.modernTextSecondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $activeSheet) { sheetType in
                switch sheetType {
                case .shareSheet:
                    CreateSharedSuiteView(sharedSuiteManager: sharedSuiteManager, settingsManager: settingsManager)
                case .joinSuite:
                    JoinSharedSuiteView(sharedSuiteManager: sharedSuiteManager)
                case .memberManagement:
                    MemberManagementView(sharedSuiteManager: sharedSuiteManager)
                default:
                    EmptyView()
                }
            }
            .alert(sharedSuiteManager.userRole == .owner ? "Delete Shared Suite" : "Leave Suite", isPresented: $showLeaveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button(sharedSuiteManager.userRole == .owner ? "Delete" : "Leave", role: .destructive) {
                    if sharedSuiteManager.userRole == .owner {
                        sharedSuiteManager.deleteSharedSuite()
                    } else {
                        sharedSuiteManager.leaveSharedSuite()
                    }
                }
            } message: {
                Text(sharedSuiteManager.userRole == .owner ?
                    "This will permanently delete the shared suite for all members." :
                    "You will be removed from this shared suite.")
            }
            .alert("Apply Default Cost to All Seats", isPresented: $showApplyToAllAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Continue", role: .destructive) {
                    showFinalApplyToAllAlert = true
                }
            } message: {
                Text("This will overwrite the cost of all seats across all concerts with the default cost of $\(String(format: "%.0f", settingsManager.defaultSeatCost)). This action cannot be undone.")
            }
            .alert("Final Confirmation", isPresented: $showFinalApplyToAllAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Apply to All Seats", role: .destructive) {
                    for i in 0..<concertManager.concerts.count {
                        for j in 0..<concertManager.concerts[i].seats.count {
                            concertManager.concerts[i].seats[j].cost = settingsManager.defaultSeatCost
                        }
                    }
                    concertManager.saveConcerts()
                    HapticManager.shared.notification(type: .success)
                }
            } message: {
                Text("Are you absolutely sure? This will overwrite ALL seat pricing data across ALL concerts and cannot be undone.")
            }
            .sheet(isPresented: $showArchiveList) {
                ArchiveListView(
                    archiveManager: archiveManager,
                    concertManager: concertManager
                )
            }
            .sheet(item: $archiveYearToCreate) { yearItem in
                CreateArchiveView(
                    archiveManager: archiveManager,
                    concertManager: concertManager,
                    settingsManager: settingsManager,
                    year: yearItem.value
                )
            }
        }
    }

// MARK: - Archive Section View

struct ArchiveSection: View {
    @ObservedObject var archiveManager: ArchiveManager
    @ObservedObject var concertManager: ConcertDataManager
    @ObservedObject var settingsManager: SettingsManager
    @Binding var showArchiveList: Bool
    @Binding var archiveYearToCreate: IdentifiableInt?

    var availableYears: [(year: Int, count: Int)] {
        archiveManager.getAvailableYearsToArchive(from: concertManager.concerts)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Archive summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(archiveManager.availableArchives.count) Archive\(archiveManager.availableArchives.count == 1 ? "" : "s")")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.modernText)

                    if let latest = archiveManager.availableArchives.first {
                        Text("Latest: " + String(latest.year))
                            .font(.system(size: 14))
                            .foregroundColor(.modernTextSecondary)
                    }
                }
                Spacer()
                Button(action: {
                    showArchiveList = true
                }) {
                    Text("View All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.modernAccent)
                }
            }

            if !availableYears.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Available to Archive")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.modernTextSecondary)

                    ForEach(availableYears, id: \.year) { yearInfo in
                        ArchiveYearRow(
                            year: yearInfo.year,
                            concertCount: yearInfo.count,
                            onArchive: {
                                archiveYearToCreate = IdentifiableInt(value: yearInfo.year)
                            }
                        )
                    }
                }
            } else if archiveManager.availableArchives.isEmpty {
                Text("No past years available to archive")
                    .font(.system(size: 14))
                    .foregroundColor(.modernTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct ArchiveYearRow: View {
    let year: Int
    let concertCount: Int
    let onArchive: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(year))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.modernText)
                Text("\(concertCount) concert\(concertCount == 1 ? "" : "s")")
                    .font(.system(size: 13))
                    .foregroundColor(.modernTextSecondary)
            }

            Spacer()

            Button(action: onArchive) {
                HStack(spacing: 4) {
                    Image(systemName: "archivebox")
                    Text("Archive")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.modernAccent)
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Archive View

struct CreateArchiveView: View {
    @ObservedObject var archiveManager: ArchiveManager
    @ObservedObject var concertManager: ConcertDataManager
    @ObservedObject var settingsManager: SettingsManager
    let year: Int
    @Environment(\.dismiss) private var dismiss

    @State private var removeFromActiveList = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var archiveCreated = false

    var yearConcerts: [Concert] {
        let calendar = Calendar.current
        return concertManager.concerts.filter {
            calendar.component(.year, from: $0.date) == year
        }
    }

    var totalRevenue: Double {
        yearConcerts.reduce(0.0) { total, concert in
            let seatRevenue = concert.seats.filter { $0.source != .donation }.compactMap { $0.price }.reduce(0.0, +)
            let parkingRevenue = concert.parkingTicket?.price ?? 0.0
            return total + seatRevenue + parkingRevenue
        }
    }

    var totalSeatsSold: Int {
        yearConcerts.reduce(0) { $0 + $1.ticketsSold }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "archivebox.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.modernAccent)

                        Text("Archive " + String(year))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.modernText)

                        Text("Create a permanent record of your " + String(year) + " season")
                            .font(.system(size: 14))
                            .foregroundColor(.modernTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)

                    // Preview stats
                    VStack(spacing: 16) {
                        Text("Archive Preview")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.modernText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 16) {
                            ArchiveStatCard(
                                title: "Concerts",
                                value: "\(yearConcerts.count)",
                                icon: "music.note.list"
                            )
                            ArchiveStatCard(
                                title: "Seats Sold",
                                value: "\(totalSeatsSold)",
                                icon: "ticket"
                            )
                            ArchiveStatCard(
                                title: "Revenue",
                                value: String(format: "$%.0f", totalRevenue),
                                icon: "dollarsign.circle"
                            )
                        }
                    }
                    .padding()
                    .background(Color.modernCard)
                    .cornerRadius(12)

                    // Options
                    VStack(spacing: 12) {
                        Toggle(isOn: $removeFromActiveList) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Remove from Active List")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.modernText)
                                Text("Archived concerts will be removed from the main list")
                                    .font(.system(size: 13))
                                    .foregroundColor(.modernTextSecondary)
                            }
                        }
                        .tint(.modernAccent)
                    }
                    .padding()
                    .background(Color.modernCard)
                    .cornerRadius(12)

                    // Info text
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Reports are generated at archive time", systemImage: "doc.text")
                        Label("Archives are stored in iCloud Documents", systemImage: "icloud")
                        Label("You can restore archived concerts later", systemImage: "arrow.uturn.backward")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.modernTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    // Action buttons
                    if archiveManager.isArchiving {
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text(archiveManager.archiveProgress)
                                .font(.system(size: 14))
                                .foregroundColor(.modernTextSecondary)
                        }
                    } else {
                        Button(action: createArchive) {
                            HStack {
                                Image(systemName: "archivebox")
                                Text("Create Archive")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.modernAccent)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Archive Created", isPresented: $archiveCreated) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Your " + String(year) + " archive has been created successfully.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func createArchive() {
        Task {
            do {
                let _ = try await archiveManager.createArchive(
                    for: year,
                    concerts: concertManager.concerts,
                    settingsManager: settingsManager
                )

                if removeFromActiveList {
                    await MainActor.run {
                        concertManager.removeConcertsForYear(year)
                    }
                }

                await MainActor.run {
                    HapticManager.shared.notification(type: .success)
                    archiveCreated = true
                }
            } catch let error as ArchiveError {
                await MainActor.run {
                    errorMessage = error.errorDescription ?? "Unknown error"
                    showError = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct ArchiveStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.modernAccent)

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.modernText)

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.modernTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Archive List View

struct ArchiveListView: View {
    @ObservedObject var archiveManager: ArchiveManager
    @ObservedObject var concertManager: ConcertDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedArchive: YearArchive?
    @State private var archiveToDelete: YearArchive?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                if archiveManager.availableArchives.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 48))
                            .foregroundColor(.modernTextSecondary.opacity(0.5))

                        Text("No Archives")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.modernText)

                        Text("Archive past years from Settings to preserve your concert history")
                            .font(.system(size: 14))
                            .foregroundColor(.modernTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(archiveManager.availableArchives) { archive in
                            Button(action: {
                                selectedArchive = archive
                            }) {
                                ArchiveRowView(archive: archive)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    archiveToDelete = archive
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Archives")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedArchive) { archive in
                ArchiveDetailView(
                    archive: archive,
                    archiveManager: archiveManager,
                    concertManager: concertManager
                )
            }
            .alert("Delete Archive?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let archive = archiveToDelete {
                        try? archiveManager.deleteArchive(archive)
                    }
                }
            } message: {
                if let archive = archiveToDelete {
                    Text("This will permanently delete the " + String(archive.year) + " archive. This cannot be undone.")
                }
            }
        }
    }
}

struct ArchiveRowView: View {
    let archive: YearArchive

    private var archiveDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: archive.archiveDate)
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.modernAccent.opacity(0.15))
                    .frame(width: 50, height: 50)

                Text(String(archive.year))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.modernAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(String(archive.year) + " Season")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.modernText)

                Text("\(archive.metadata.concertCount) shows • \(archive.metadata.totalSeatsSold) seats • $\(Int(archive.metadata.totalRevenue).formatted())")
                    .font(.system(size: 12))
                    .foregroundColor(.modernTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.modernTextSecondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Archive Detail View

struct ArchiveDetailView: View {
    let archive: YearArchive
    @ObservedObject var archiveManager: ArchiveManager
    @ObservedObject var concertManager: ConcertDataManager
    @Environment(\.dismiss) private var dismiss

    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var showRestoreConfirmation = false
    @State private var showRestoreSuccess = false
    @State private var showConcertList = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text(String(archive.year))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.modernAccent)

                        Text("Season Archive")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.modernTextSecondary)

                        Text("Archived \(archiveDateFormatted)")
                            .font(.system(size: 13))
                            .foregroundColor(.modernTextSecondary.opacity(0.7))
                    }
                    .padding(.top)

                    // Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ArchiveDetailStatCard(
                            title: "Concerts",
                            value: "\(archive.metadata.concertCount)",
                            icon: "music.note.list",
                            color: .blue
                        )
                        ArchiveDetailStatCard(
                            title: "Seats Sold",
                            value: "\(archive.metadata.totalSeatsSold)",
                            icon: "ticket.fill",
                            color: .green
                        )
                        ArchiveDetailStatCard(
                            title: "Revenue",
                            value: String(format: "$%.0f", archive.metadata.totalRevenue),
                            icon: "dollarsign.circle.fill",
                            color: .orange
                        )
                        ArchiveDetailStatCard(
                            title: "Profit",
                            value: String(format: "$%.0f", archive.metadata.totalProfit),
                            icon: "chart.line.uptrend.xyaxis",
                            color: archive.metadata.totalProfit >= 0 ? .green : .red
                        )
                    }
                    .padding(.horizontal)

                    // Export Reports Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Export Reports")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.modernText)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(ArchiveReportType.allCases) { reportType in
                                ReportExportButton(
                                    reportType: reportType,
                                    onExport: {
                                        if let url = archiveManager.exportArchiveReport(archive, reportType: reportType) {
                                            exportURL = url
                                            showExportSheet = true
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color.modernCard)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Concerts Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Archived Concerts")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.modernText)

                            Spacer()

                            Button(action: {
                                showConcertList = true
                            }) {
                                Text("View All")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.modernAccent)
                            }
                        }

                        ForEach(archive.concerts.prefix(3)) { concert in
                            ArchivedConcertRow(concert: concert)
                        }

                        if archive.concerts.count > 3 {
                            Text("+ \(archive.concerts.count - 3) more concerts")
                                .font(.system(size: 14))
                                .foregroundColor(.modernTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(Color.modernCard)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Restore Section
                    VStack(spacing: 12) {
                        Button(action: {
                            showRestoreConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                Text("Restore to Active List")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.modernAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.modernAccent.opacity(0.1))
                            .cornerRadius(12)
                        }

                        Text("Restoring will add these concerts back to your active list")
                            .font(.system(size: 12))
                            .foregroundColor(.modernTextSecondary)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .sheet(isPresented: $showConcertList) {
                ArchivedConcertsListView(concerts: archive.concerts, year: archive.year)
            }
            .alert("Restore Concerts?", isPresented: $showRestoreConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Restore") {
                    archiveManager.restoreArchive(archive, to: concertManager)
                    HapticManager.shared.notification(type: .success)
                    showRestoreSuccess = true
                }
            } message: {
                Text("This will add \(archive.concerts.count) concerts from " + String(archive.year) + " back to your active list. Duplicate concerts will be skipped.")
            }
            .alert("Concerts Restored", isPresented: $showRestoreSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("The archived concerts have been restored to your active list.")
            }
        }
    }

    private var archiveDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: archive.archiveDate)
    }
}

struct ArchiveDetailStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.modernText)

            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.modernTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.modernCard)
        .cornerRadius(12)
    }
}

struct ReportExportButton: View {
    let reportType: ArchiveReportType
    let onExport: () -> Void

    var body: some View {
        Button(action: onExport) {
            VStack(spacing: 8) {
                Image(systemName: reportType.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.modernAccent)

                Text(reportType.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.modernText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
    }
}

struct ArchivedConcertRow: View {
    let concert: Concert

    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: concert.date)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(dateFormatted)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.modernTextSecondary)
                .frame(width: 50, alignment: .leading)

            Text(concert.artist)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.modernText)
                .lineLimit(1)

            Spacer()

            Text("\(concert.ticketsSold)/8")
                .font(.system(size: 13))
                .foregroundColor(.modernTextSecondary)
        }
        .padding(.vertical, 6)
    }
}

struct ArchivedConcertsListView: View {
    let concerts: [Concert]
    let year: Int
    @Environment(\.dismiss) private var dismiss

    var sortedConcerts: [Concert] {
        concerts.sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(sortedConcerts) { concert in
                    ArchivedConcertDetailRow(concert: concert)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(String(year) + " Concerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ArchivedConcertDetailRow: View {
    let concert: Concert

    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: concert.date)
    }

    private var revenue: Double {
        let seatRevenue = concert.seats.filter { $0.source != .donation }.compactMap { $0.price }.reduce(0.0, +)
        let parkingRevenue = concert.parkingTicket?.price ?? 0.0
        return seatRevenue + parkingRevenue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(concert.artist)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.modernText)

            Text(dateFormatted)
                .font(.system(size: 14))
                .foregroundColor(.modernTextSecondary)

            HStack(spacing: 16) {
                Label("\(concert.ticketsSold) sold", systemImage: "ticket")
                Label(String(format: "$%.0f", revenue), systemImage: "dollarsign.circle")
            }
            .font(.system(size: 13))
            .foregroundColor(.modernTextSecondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Sharing Views

struct CreateSharedSuiteView: View {
    @ObservedObject var sharedSuiteManager: SharedSuiteManager
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var suiteName: String = ""
    @State private var venueLocation: String = ""
    @State private var isCreating = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.12, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.3.sequence")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("Create Shared Suite")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.modernText)
                        
                        Text("Share your suite with family, friends, or colleagues for collaborative booking management.")
                            .font(.system(size: 16))
                            .foregroundColor(.modernTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suite Name")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.modernText)
                            
                            TextField("Enter suite name", text: $suiteName)
                                .font(.system(size: 16))
                                .foregroundColor(.modernText)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.modernSecondary)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Venue Location")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.modernText)
                            
                            TextField("Enter venue location", text: $venueLocation)
                                .font(.system(size: 16))
                                .foregroundColor(.modernText)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.modernSecondary)
                                )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.modernSecondary.opacity(0.3))
                    )
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.1))
                            )
                    }
                    
                    Spacer()
                    
                    // Create Button
                    Button(action: {
                        createSharedSuite()
                    }) {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            
                            Text(isCreating ? "Creating..." : "Create Shared Suite")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(canCreate ? Color.blue : Color.gray)
                        )
                    }
                    .disabled(!canCreate || isCreating)
                }
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.modernTextSecondary)
                }
            }
        }
        .onAppear {
            suiteName = settingsManager.suiteName
            venueLocation = settingsManager.venueLocation
        }
    }
    
    private var canCreate: Bool {
        !suiteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !venueLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        sharedSuiteManager.isCloudKitAvailable
    }
    
    private func createSharedSuite() {
        isCreating = true
        errorMessage = ""
        
        Task {
            do {
                _ = try await sharedSuiteManager.createSharedSuiteInCloud(
                    suiteName: suiteName.trimmingCharacters(in: .whitespacesAndNewlines),
                    venueLocation: venueLocation.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct JoinSharedSuiteView: View {
    @ObservedObject var sharedSuiteManager: SharedSuiteManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var suiteId: String = ""
    @State private var isJoining = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.12, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        
                        Text("Join Shared Suite")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.modernText)
                        
                        Text("Enter the invitation code or suite ID to join an existing shared suite.")
                            .font(.system(size: 16))
                            .foregroundColor(.modernTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invitation Code or Suite ID")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.modernText)
                        
                        TextField("Enter invitation code or suite ID", text: $suiteId)
                            .font(.system(size: 16))
                            .foregroundColor(.modernText)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.modernSecondary)
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onChange(of: suiteId) { oldValue, newValue in
                                // Extract suite ID from sharing link if needed
                                if newValue.hasPrefix("suitekeep://invite/") {
                                    suiteId = String(newValue.dropFirst("suitekeep://invite/".count))
                                }
                            }
                        
                        // Paste button
                        Button(action: {
                            if let clipboard = UIPasteboard.general.string {
                                suiteId = clipboard
                            }
                        }) {
                            HStack {
                                Image(systemName: "doc.on.clipboard")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Paste from Clipboard")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.modernAccent)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.modernAccent.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.modernAccent.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.modernSecondary.opacity(0.3))
                    )
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.1))
                            )
                    }
                    
                    Spacer()
                    
                    // Join Button
                    Button(action: {
                        joinSharedSuite()
                    }) {
                        HStack {
                            if isJoining {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            
                            Text(isJoining ? "Joining..." : "Join Suite")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(canJoin ? Color.green : Color.gray)
                        )
                    }
                    .disabled(!canJoin || isJoining)
                }
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.modernTextSecondary)
                }
            }
        }
    }
    
    private var canJoin: Bool {
        !suiteId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        sharedSuiteManager.isCloudKitAvailable
    }
    
    private func joinSharedSuite() {
        isJoining = true
        errorMessage = ""
        
        let inputValue = suiteId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                // Check if input looks like an invitation token (UUID format) or suite ID
                if inputValue.count == 36 && inputValue.contains("-") {
                    // This looks like an invitation token (UUID format)
                    try await sharedSuiteManager.joinSuiteWithInvitation(inputValue)
                } else {
                    // This looks like a suite ID
                    try await sharedSuiteManager.joinSharedSuiteFromCloud(suiteId: inputValue)
                }
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isJoining = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct MemberManagementView: View {
    @ObservedObject var sharedSuiteManager: SharedSuiteManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.12, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if let suiteInfo = sharedSuiteManager.currentSuiteInfo {
                        // Header
                        VStack(spacing: 8) {
                            Text("Manage Members")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.modernText)
                            
                            Text(suiteInfo.suiteName)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.modernTextSecondary)
                        }
                        .padding(.top, 20)
                        
                        // Members List
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                // Owner (current user if they're the owner)
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Owner")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.modernText)
                                    
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(suiteInfo.ownerId == sharedSuiteManager.self.currentUserId ? "You" : "Owner")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.modernText)
                                            
                                            Text("Full access")
                                                .font(.system(size: 14))
                                                .foregroundColor(.modernTextSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "crown.fill")
                                            .foregroundColor(.yellow)
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.modernSecondary)
                                    )
                                }
                                
                                // Members
                                if !suiteInfo.members.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Members")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.modernText)
                                        
                                        ForEach(suiteInfo.members) { member in
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(member.displayName)
                                                        .font(.system(size: 16, weight: .medium))
                                                        .foregroundColor(.modernText)
                                                    
                                                    Text(member.role.displayName)
                                                        .font(.system(size: 14))
                                                        .foregroundColor(.modernTextSecondary)
                                                }
                                                
                                                Spacer()
                                                
                                                if sharedSuiteManager.canManageMembers() {
                                                    Menu {
                                                        Button("Change to Editor") {
                                                            sharedSuiteManager.updateUserRole(for: member.userId, to: .editor)
                                                        }
                                                        
                                                        Button("Change to Viewer") {
                                                            sharedSuiteManager.updateUserRole(for: member.userId, to: .viewer)
                                                        }
                                                        
                                                        Divider()
                                                        
                                                        Button("Remove from Suite", role: .destructive) {
                                                            sharedSuiteManager.removeMember(userId: member.userId)
                                                        }
                                                    } label: {
                                                        Image(systemName: "ellipsis.circle")
                                                            .foregroundColor(.modernTextSecondary)
                                                    }
                                                }
                                            }
                                            .padding(16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.modernSecondary)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Add Member Button
                        if sharedSuiteManager.canManageMembers() {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Invite New Member")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.modernText)
                                
                                Button(action: {
                                    Task {
                                        do {
                                            let code = try await sharedSuiteManager.generateInvitationLink(role: .viewer)
                                            let activityVC = UIActivityViewController(activityItems: [code], applicationActivities: nil)
                                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                               let window = windowScene.windows.first {
                                                window.rootViewController?.present(activityVC, animated: true)
                                            }
                                        } catch {
                                            print("❌ Error generating invitation: \(error)")
                                        }
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "person.badge.plus")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Generate Invitation Link")
                                            .font(.system(size: 16, weight: .medium))
                                        Spacer()
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 14))
                                    }
                                    .foregroundColor(.modernAccent)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.modernSecondary)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.modernAccent.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                            .padding(.top)
                        }
                        
                        // Suite Info
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Suite Information")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.modernText)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Created:")
                                        .font(.system(size: 14))
                                        .foregroundColor(.modernTextSecondary)
                                    Spacer()
                                    Text(suiteInfo.createdDate, style: .date)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.modernText)
                                }
                                
                                HStack {
                                    Text("Last Updated:")
                                        .font(.system(size: 14))
                                        .foregroundColor(.modernTextSecondary)
                                    Spacer()
                                    Text(suiteInfo.lastModified, style: .relative)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.modernText)
                                }
                                
                                HStack {
                                    Text("CloudKit Status:")
                                        .font(.system(size: 14))
                                        .foregroundColor(.modernTextSecondary)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(sharedSuiteManager.isCloudKitAvailable ? Color.green : Color.red)
                                            .frame(width: 8, height: 8)
                                        Text(sharedSuiteManager.cloudKitStatus)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.modernText)
                                    }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.modernSecondary)
                            )
                        }
                        .padding(.top)
                        
                        Spacer()
                    } else {
                        Text("No suite information available")
                            .font(.system(size: 16))
                            .foregroundColor(.modernTextSecondary)
                    }
                }
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.modernTextSecondary)
                }
            }
        }
    }
}

// MARK: - Report Options
struct ReportOptions {
    let includeProfitAnalysis: Bool
    let includeConcertData: Bool
    let includePerformanceRankings: Bool
    let includeExecutiveSummary: Bool
    let includeCharityReport: Bool
    let includeFutureConcerts: Bool
    
    static let all = ReportOptions(
        includeProfitAnalysis: true,
        includeConcertData: true,
        includePerformanceRankings: true,
        includeExecutiveSummary: true,
        includeCharityReport: true,
        includeFutureConcerts: false
    )
}

// MARK: - Report Generator Service
class ReportGenerator {
    static let shared = ReportGenerator()
    
    private init() {}
    
    func generateComprehensiveReportFile(concerts: [Concert], settingsManager: SettingsManager, options: ReportOptions = .all) -> URL? {
        let csvContent = generateComprehensiveReport(concerts: concerts, settingsManager: settingsManager, options: options)
        
        // Generate filename with timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "SuiteKeep_Report_\(formatter.string(from: Date())).csv"
        
        // Create temporary file URL
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            // Failed to write CSV file: \(error)
            return nil
        }
    }
    
    func generateComprehensiveReport(concerts: [Concert], settingsManager: SettingsManager, options: ReportOptions = .all) -> String {
        var csv = ""
        
        // Header with report metadata
        csv += "SuiteKeep Concert Management Report\n"
        csv += "Generated: \(DateFormatter.reportHeader.string(from: Date()))\n"
        csv += "Suite: \(settingsManager.suiteName)\n"
        csv += "Venue: \(settingsManager.venueLocation)\n\n"
        
        // Executive Summary
        if options.includeExecutiveSummary {
            csv += generateExecutiveSummary(concerts: concerts, includeFutureConcerts: options.includeFutureConcerts)
            csv += "\n"
        }
        
        // Concert Overview / Performance Rankings
        if options.includePerformanceRankings {
            csv += generateConcertOverview(concerts: concerts, includeFutureConcerts: options.includeFutureConcerts)
            csv += "\n"
        }
        
        // Detailed Seat Data
        if options.includeConcertData {
            csv += generateDetailedSeatData(concerts: concerts)
            csv += "\n"
        }
        
        // Profit Analysis
        if options.includeProfitAnalysis {
            csv += generateProfitAnalysis(concerts: concerts, includeFutureConcerts: options.includeFutureConcerts)
        }
        
        // Charity Report
        if options.includeCharityReport {
            csv += generateCharityReport(concerts: concerts, settingsManager: settingsManager)
        }
        
        return csv
    }
    
    private func generateExecutiveSummary(concerts: [Concert], includeFutureConcerts: Bool = false) -> String {
        var csv = "=== EXECUTIVE SUMMARY ===\n"
        
        // Filter concerts based on includeFutureConcerts option
        let currentDate = Date()
        let analysisConcerts = includeFutureConcerts ? concerts : concerts.filter { $0.date <= currentDate }
        let pastConcerts = concerts.filter { $0.date <= currentDate }
        
        // Basic counts include ALL concerts (past and future)
        let totalConcerts = concerts.count
        let totalSeats = concerts.reduce(0) { $0 + $1.seats.count }
        let totalSoldSeats = concerts.reduce(0) { $0 + $1.ticketsSold }
        let totalReservedSeats = concerts.reduce(0) { $0 + $1.ticketsReserved }
        
        // Occupancy calculations use only past concerts
        let pastTotalSeats = pastConcerts.reduce(0) { $0 + $1.seats.count }
        let pastTotalSoldSeats = pastConcerts.reduce(0) { $0 + $1.ticketsSold }
        
        let totalRevenue = analysisConcerts.reduce(0.0) { total, concert in
            let seatRevenue = concert.seats.filter { $0.source != .donation }.compactMap { $0.price }.reduce(0.0, +)
            let parkingRevenue = concert.parkingTicket?.price ?? 0.0
            return total + seatRevenue + parkingRevenue
        }
        
        let totalCosts = analysisConcerts.reduce(0.0) { total, concert in
            let seatCosts = concert.seats.filter { $0.source != .donation }.reduce(0.0) { $0 + ($1.cost ?? 0.0) }
            let parkingCost = concert.parkingTicket?.cost ?? 0.0
            return total + seatCosts + parkingCost
        }
        
        let netProfit = totalRevenue - totalCosts
        let occupancyRate = pastTotalSeats > 0 ? Double(pastTotalSoldSeats) / Double(pastTotalSeats) * 100.0 : 0.0
        let profitMargin = totalCosts > 0 ? (netProfit / totalCosts) * 100.0 : 0.0
        
        let analysisScope = includeFutureConcerts ? "all concerts (past and future)" : "past concerts only"
        csv += "Note: Financial metrics (Revenue/Costs/Profit/ROI/Averages) include \(analysisScope)\n"
        csv += "Revenue and profit calculations exclude charity donations (see Charity Report for donation details)\n"
        csv += "Seat counts include all scheduled concerts (past and future)\n\n"
        csv += "Metric,Value\n"
        csv += "Total Concerts,\(totalConcerts)\n"
        csv += "Total Seats,\(totalSeats)\n"
        csv += "Seats Sold,\(totalSoldSeats)\n"
        csv += "Seats Reserved,\(totalReservedSeats)\n"
        csv += "Occupancy Rate,\(String(format: "%.1f", occupancyRate))%\n"
        csv += "Total Revenue,\(formatCurrency(totalRevenue))\n"
        csv += "Total Costs,\(formatCurrency(totalCosts))\n"
        csv += "Net Profit,\(formatCurrency(netProfit))\n"
        csv += "Return on Investment (ROI),\(String(format: "%.1f", profitMargin))%\n"
        let avgProfitLabel = includeFutureConcerts ? "Average Profit per Concert" : "Average Profit per Concert (Past Shows Only)"
        csv += "\(avgProfitLabel),\(formatCurrency(analysisConcerts.count > 0 ? netProfit / Double(analysisConcerts.count) : 0.0))\n"
        
        return csv
    }
    
    private func generateConcertOverview(concerts: [Concert], includeFutureConcerts: Bool = false) -> String {
        var csv = "=== CONCERT OVERVIEW ===\n"
        csv += "Artist,Date,Seats Sold,Seats Reserved,Occupancy Rate,Revenue,Costs,Profit,ROI %\n"
        
        let sortedConcerts = concerts.sorted { $0.date < $1.date }
        
        for concert in sortedConcerts {
            let seatRevenue = concert.seats.filter { $0.source != .donation }.compactMap { $0.price }.reduce(0.0, +)
            let parkingRevenue = concert.parkingTicket?.price ?? 0.0
            let totalRevenue = seatRevenue + parkingRevenue
            
            let seatCosts = concert.seats.filter { $0.source != .donation }.reduce(0.0) { $0 + ($1.cost ?? 0.0) }
            let parkingCost = concert.parkingTicket?.cost ?? 0.0
            let totalCosts = seatCosts + parkingCost
            
            let profit = totalRevenue - totalCosts
            let occupancyRate = Double(concert.ticketsSold) / 8.0 * 100.0
            let profitMargin = totalCosts > 0 ? (profit / totalCosts) * 100.0 : 0.0
            
            csv += "\"\(concert.artist)\",\(DateFormatter.reportDate.string(from: concert.date)),\(concert.ticketsSold),\(concert.ticketsReserved),\(String(format: "%.1f", occupancyRate))%,\(formatCurrency(totalRevenue)),\(formatCurrency(totalCosts)),\(formatCurrency(profit)),\(String(format: "%.1f", profitMargin))%\n"
        }
        
        return csv
    }
    
    private func generateDetailedSeatData(concerts: [Concert]) -> String {
        var csv = "=== DETAILED SEAT DATA ===\n"
        csv += "Concert,Date,Seat Number,Status,Price,Cost,Source,Family Member,Date Sold,Date Paid,Profit\n"
        
        let sortedConcerts = concerts.sorted { $0.date < $1.date }
        
        for concert in sortedConcerts {
            for (index, seat) in concert.seats.enumerated() {
                let seatNumber = index + 1
                let profit = seat.source == .donation ? 0.0 : (seat.price ?? 0.0) - (seat.cost ?? 0.0)
                let source = seat.source?.rawValue ?? ""
                let familyMember = seat.source == .family && seat.familyPersonName != nil ? seat.familyPersonName! : ""
                let dateSold = seat.dateSold.map { DateFormatter.reportDate.string(from: $0) } ?? ""
                let datePaid = seat.datePaid.map { DateFormatter.reportDate.string(from: $0) } ?? ""
                
                csv += "\"\(concert.artist)\",\(DateFormatter.reportDate.string(from: concert.date)),\(seatNumber),\(seat.status.rawValue.capitalized),\(seat.price.map(formatCurrency) ?? ""),\(formatCurrency(seat.cost ?? 0.0)),\(source),\"\(familyMember)\",\(dateSold),\(datePaid),\(formatCurrency(profit))\n"
            }
            
            // Add parking ticket data if available
            if let parking = concert.parkingTicket {
                let profit = (parking.price ?? 0.0) - (parking.cost ?? 0.0)
                let dateSold = parking.dateSold.map { DateFormatter.reportDate.string(from: $0) } ?? ""
                let datePaid = parking.datePaid.map { DateFormatter.reportDate.string(from: $0) } ?? ""
                
                csv += "\"\(concert.artist)\",\(DateFormatter.reportDate.string(from: concert.date)),Parking,\(parking.status.rawValue.capitalized),\(parking.price.map(formatCurrency) ?? ""),\(formatCurrency(parking.cost ?? 0.0)),,,\(dateSold),\(datePaid),\(formatCurrency(profit))\n"
            }
        }
        
        return csv
    }
    
    private func generateProfitAnalysis(concerts: [Concert], includeFutureConcerts: Bool = false) -> String {
        var csv = "=== PROFIT ANALYSIS ===\n"
        let analysisScope = includeFutureConcerts ? "all concerts (past and future)" : "past concerts only"
        csv += "Note: Analysis includes \(analysisScope)\n\n"
        
        // Filter concerts based on includeFutureConcerts option
        let currentDate = Date()
        let analysisConcerts = includeFutureConcerts ? concerts : concerts.filter { $0.date <= currentDate }
        
        // Performance rankings
        var concertPerformance: [(String, Double, Double)] = []
        
        for concert in analysisConcerts {
            let seatRevenue = concert.seats.filter { $0.source != .donation }.compactMap { $0.price }.reduce(0.0, +)
            let parkingRevenue = concert.parkingTicket?.price ?? 0.0
            let totalRevenue = seatRevenue + parkingRevenue
            
            let seatCosts = concert.seats.filter { $0.source != .donation }.reduce(0.0) { $0 + ($1.cost ?? 0.0) }
            let parkingCost = concert.parkingTicket?.cost ?? 0.0
            let totalCosts = seatCosts + parkingCost
            
            let profit = totalRevenue - totalCosts
            let profitMargin = totalCosts > 0 ? (profit / totalCosts) * 100.0 : 0.0
            
            concertPerformance.append((concert.artist, profit, profitMargin))
        }
        
        // Top Performers
        csv += "\nTOP PERFORMING CONCERTS (by Profit):\n"
        csv += "Rank,Artist,Profit,ROI %\n"
        let topPerformers = concertPerformance.sorted { $0.1 > $1.1 }.prefix(5)
        for (index, (artist, profit, margin)) in topPerformers.enumerated() {
            csv += "\(index + 1),\"\(artist)\",\(formatCurrency(profit)),\(String(format: "%.1f", margin))%\n"
        }
        
        // Revenue Sources Analysis
        csv += "\nREVENUE SOURCES ANALYSIS:\n"
        var sourceRevenue: [String: Double] = [:]
        var sourceCount: [String: Int] = [:]
        
        for concert in analysisConcerts {
            for seat in concert.seats {
                if let source = seat.source, let price = seat.price {
                    sourceRevenue[source.rawValue, default: 0.0] += price
                    sourceCount[source.rawValue, default: 0] += 1
                }
            }
        }
        
        csv += "Source,Revenue,Count,Average Price\n"
        for source in sourceRevenue.keys.sorted() {
            let revenue = sourceRevenue[source] ?? 0.0
            let count = sourceCount[source] ?? 0
            let avgPrice = count > 0 ? revenue / Double(count) : 0.0
            csv += "\(source),\(formatCurrency(revenue)),\(count),\(formatCurrency(avgPrice))\n"
        }
        
        return csv
    }
    
    private func generateCharityReport(concerts: [Concert], settingsManager: SettingsManager) -> String {
        var csv = "=== CHARITY DONATION REPORT ===\n"
        
        // Get all charity donations
        var charityDonations: [(Concert, Int, Seat)] = []
        for concert in concerts {
            for (index, seat) in concert.seats.enumerated() {
                if seat.source == .donation {
                    charityDonations.append((concert, index + 1, seat))
                }
            }
        }
        
        guard !charityDonations.isEmpty else {
            csv += "No charity donations found in this period.\n\n"
            return csv
        }
        
        // Summary by charity
        var charityTotals: [String: (count: Int, faceValue: Double, donationAmount: Double)] = [:]
        
        for (_, _, seat) in charityDonations {
            let charityName = seat.charityName ?? "Unknown Charity"
            let faceValue = seat.donationFaceValue ?? 0.0
            let donationAmount = seat.price ?? 0.0
            
            if var existing = charityTotals[charityName] {
                existing.count += 1
                existing.faceValue += faceValue
                existing.donationAmount += donationAmount
                charityTotals[charityName] = existing
            } else {
                charityTotals[charityName] = (count: 1, faceValue: faceValue, donationAmount: donationAmount)
            }
        }
        
        // Charity Summary Section
        csv += "CHARITY SUMMARY\n"
        csv += "Charity Name,Donations Count,Total Face Value,Total Donation Amount,Tax Deductible Amount\n"
        
        let sortedCharities = charityTotals.sorted { $0.value.donationAmount > $1.value.donationAmount }
        var totalDonations = 0
        var totalFaceValue = 0.0
        var totalDonationAmount = 0.0
        
        for (charityName, totals) in sortedCharities {
            let taxDeductible = totals.donationAmount - totals.faceValue
            csv += "\"\(charityName)\",\(totals.count),\(formatCurrency(totals.faceValue)),\(formatCurrency(totals.donationAmount)),\(formatCurrency(max(0, taxDeductible)))\n"
            totalDonations += totals.count
            totalFaceValue += totals.faceValue
            totalDonationAmount += totals.donationAmount
        }
        
        csv += "\nTOTAL SUMMARY\n"
        csv += "Total Donations,\(totalDonations)\n"
        csv += "Total Face Value,\(formatCurrency(totalFaceValue))\n"
        csv += "Total Donation Amount,\(formatCurrency(totalDonationAmount))\n"
        csv += "Total Tax Deductible Amount,\(formatCurrency(max(0, totalDonationAmount - totalFaceValue)))\n\n"
        
        // Detailed Donation Records
        csv += "DETAILED DONATION RECORDS\n"
        csv += "Concert,Date,Seat,Charity Name,Charity EIN,Charity Address,Contact Name,Contact Info,Face Value,Donation Amount,Tax Deductible,Donation Date\n"
        
        let sortedDonations = charityDonations.sorted { $0.0.date < $1.0.date }
        
        for (concert, seatNumber, seat) in sortedDonations {
            let charityName = seat.charityName ?? ""
            let ein = seat.charityEIN ?? ""
            let charityAddress = seat.charityAddress ?? ""
            let contactName = seat.charityContactName ?? ""
            let contactInfo = seat.charityContactInfo ?? ""
            let faceValue = seat.donationFaceValue ?? 0.0
            let donationAmount = seat.price ?? 0.0
            let taxDeductible = max(0, donationAmount - faceValue)
            let donationDate = seat.donationDate.map { DateFormatter.reportDate.string(from: $0) } ?? ""
            
            csv += "\"\(concert.artist)\",\(DateFormatter.reportDate.string(from: concert.date)),\(seatNumber),\"\(charityName)\",\(ein),\"\(charityAddress)\",\"\(contactName)\",\"\(contactInfo)\",\(formatCurrency(faceValue)),\(formatCurrency(donationAmount)),\(formatCurrency(taxDeductible)),\(donationDate)\n"
        }
        
        // Tax Year Summary (if current year donations exist)
        let currentYear = Calendar.current.component(.year, from: Date())
        let currentYearDonations = charityDonations.filter { 
            if let donationDate = $0.2.donationDate {
                return Calendar.current.component(.year, from: donationDate) == currentYear
            }
            return false
        }
        
        if !currentYearDonations.isEmpty {
            let currentYearTotal = currentYearDonations.reduce(into: 0.0) { total, donation in
                let donationAmount = donation.2.price ?? 0.0
                let faceValue = donation.2.donationFaceValue ?? 0.0
                total += max(0, donationAmount - faceValue)
            }
            
            csv += "\n\(currentYear) TAX YEAR SUMMARY\n"
            csv += "Year,Total Tax Deductible Donations\n"
            csv += "\(currentYear),\(formatCurrency(currentYearTotal))\n"
        }
        
        csv += "\n"
        return csv
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }
}

// MARK: - Date Formatters Extension
extension DateFormatter {
    static let reportHeader: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let reportDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }()
}

// MARK: - Custom Button Styles
struct HoverableButtonStyle: ButtonStyle {
    @State private var isHovering = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : (isHovering ? 1.05 : 1.0))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
    }
}

// MARK: - Identifiable URL Wrapper
struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct IdentifiableInt: Identifiable {
    let id = UUID()
    let value: Int
}

// MARK: - Backup & Restore Section
struct BackupRestoreSection: View {
    @ObservedObject var concertManager: ConcertDataManager
    @ObservedObject var settingsManager: SettingsManager
    @State private var showingBackupAlert = false
    @State private var showingRestoreAlert = false
    @State private var showingFilePicker = false
    @State private var showingClearDataAlert = false
    @State private var showingFinalClearAlert = false
    @State private var backupFileURL: IdentifiableURL?
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Backup & Restore")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.modernText)
            
            VStack(spacing: 16) {
                // Backup Status
                let backupInfo = concertManager.getBackupInfo()
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundColor(.blue)
                        Text("Backup Status")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.modernText)
                    }
                    
                    if let lastBackup = backupInfo.lastBackupDate {
                        Text("Last backup: \(lastBackup, formatter: DateFormatter.backupDate)")
                            .font(.system(size: 14))
                            .foregroundColor(.modernTextSecondary)
                    } else {
                        Text("No backup found")
                            .font(.system(size: 14))
                            .foregroundColor(.modernTextSecondary)
                    }
                    
                    Text("\(backupInfo.count) concerts available for backup")
                        .font(.system(size: 14))
                        .foregroundColor(.modernTextSecondary)
                }
                
                Divider()
                
                // Backup Actions
                VStack(spacing: 12) {
                    // Create Backup Button
                    Button(action: createBackup) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                            Text("Create Backup")
                        }
                    }
                    .buttonStyle(CollaborationPrimaryButtonStyle())
                    .disabled(backupInfo.count == 0)
                    
                    HStack(spacing: 12) {
                        // Restore Backup Button
                        Button(action: { showingFilePicker = true }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down.fill")
                                Text("Restore from Backup")
                            }
                        }
                        .buttonStyle(CollaborationSecondaryButtonStyle(color: .orange))
                        
                        // Clear All Data Button
                        Button(action: { showingClearDataAlert = true }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Clear All Data")
                            }
                        }
                        .buttonStyle(CollaborationSecondaryButtonStyle(color: .red))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.modernSecondary)
            )
        }
        .alert(alertTitle, isPresented: $showingBackupAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .alert(alertTitle, isPresented: $showingRestoreAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Restore", role: .destructive) {
                // Restore action handled by file picker
            }
        } message: {
            Text(alertMessage)
        }
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Continue", role: .destructive) {
                showingFinalClearAlert = true
            }
        } message: {
            Text("This will permanently delete all concerts, seat data, and settings. This action cannot be undone.\n\nConsider creating a backup first.")
        }
        .alert("Final Warning", isPresented: $showingFinalClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Everything", role: .destructive) {
                clearAllAppData()
            }
        } message: {
            Text("Are you absolutely sure? This will erase ALL app data permanently.")
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .sheet(item: $backupFileURL) { identifiableURL in
            ShareSheet(activityItems: [identifiableURL.url])
        }
    }
    
    private func createBackup() {
        guard let backupData = concertManager.createBackupData(settingsManager: settingsManager) else {
            showBackupAlert(title: "Backup Failed", message: "Unable to create backup data. Please try again.")
            return
        }
        
        // Generate filename with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "SuiteKeep_Backup_\(timestamp).json"
        
        // Save to temporary directory
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        do {
            try backupData.write(to: fileURL)
            backupFileURL = IdentifiableURL(url: fileURL)
        } catch {
            showBackupAlert(title: "Backup Failed", message: "Unable to save backup file: \(error.localizedDescription)")
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Access security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                showBackupAlert(title: "Access Denied", message: "Unable to access the selected file. Please check file permissions.")
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                let data = try Data(contentsOf: url)
                let success = concertManager.restoreFromBackupData(data, settingsManager: settingsManager)
                
                if success {
                    showBackupAlert(title: "Restore Successful", message: "Your concert data and suite settings have been restored successfully.")
                } else {
                    showBackupAlert(title: "Restore Failed", message: "The backup file is invalid or corrupted. Please check the file and try again.")
                }
            } catch {
                showBackupAlert(title: "Restore Failed", message: "Unable to read backup file: \(error.localizedDescription)")
            }
        case .failure(let error):
            showBackupAlert(title: "File Selection Failed", message: error.localizedDescription)
        }
    }
    
    private func showBackupAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingBackupAlert = true
    }
    
    private func clearAllAppData() {
        // Clear all concert data and settings from storage
        concertManager.clearAllData()
        
        // Reset SettingsManager to default values
        settingsManager.suiteName = "Fire Suite"
        settingsManager.venueLocation = "Ford Amphitheater"
        settingsManager.familyTicketPrice = 75.0
        settingsManager.defaultSeatCost = 150.0
        
        // Show confirmation
        showBackupAlert(title: "Data Cleared", message: "All app data has been permanently deleted. The app will now reset to its initial state.")
    }
}


// MARK: - Date Formatter for Backup
extension DateFormatter {
    static let backupDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Batch Seat Options View
struct BatchSeatOptionsView: View {
    let selectedSeats: [Int]
    let concert: Concert
    let onUpdate: ([(Int, Seat)]) -> Void
    let onComplete: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsManager: SettingsManager
    
    @State private var selectedStatus: SeatStatus = .available
    @State private var priceInput: String = ""
    @State private var costInput: String = ""
    @State private var selectedSource: TicketSource = .family
    @State private var noteInput: String = ""
    @State private var familyPersonName: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Batch Edit Seats")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.modernText)
                    
                    Text("Editing \(selectedSeats.count) seat\(selectedSeats.count == 1 ? "" : "s"): \(selectedSeats.map { $0 + 1 }.sorted().map(String.init).joined(separator: ", "))")
                        .font(.system(size: 16))
                        .foregroundColor(.modernTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Status Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Seat Status")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.modernText)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach([SeatStatus.available, SeatStatus.reserved, SeatStatus.sold], id: \.self) { status in
                                    Button(action: {
                                        selectedStatus = status
                                        if status == .available {
                                            priceInput = ""
                                            noteInput = ""
                                            familyPersonName = ""
                                        } else if status == .sold {
                                            // Only auto-populate price if Family is selected and price is empty
                                            if selectedSource == .family && priceInput.isEmpty {
                                                priceInput = String(format: "%.0f", settingsManager.familyTicketPrice)
                                            }
                                        } else if status == .reserved {
                                            priceInput = ""
                                            familyPersonName = ""
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: status == .available ? "checkmark.circle" : 
                                                  status == .reserved ? "clock" : "checkmark.circle.fill")
                                                .font(.system(size: 16))
                                            Text(status.displayText)
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .foregroundColor(selectedStatus == status ? .white : status.color)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            selectedStatus == status ? status.color : status.color.opacity(0.1),
                                            in: RoundedRectangle(cornerRadius: 8)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(status.color.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        
                        // Price Input (for sold seats)
                        if selectedStatus == .sold {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Price per Seat")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.modernText)
                                
                                TextField("Enter price", text: $priceInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 16))
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Source Selection (for sold seats)
                        if selectedStatus == .sold {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Ticket Source")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.modernText)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach([TicketSource.family, TicketSource.facebook, TicketSource.stubhub, TicketSource.axs, TicketSource.other], id: \.self) { source in
                                        Button(action: {
                                            selectedSource = source
                                            // Auto-populate price for family tickets
                                            if source == .family && priceInput.isEmpty {
                                                priceInput = String(format: "%.0f", settingsManager.familyTicketPrice)
                                            }
                                        }) {
                                            Text(source.rawValue.capitalized)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(selectedSource == source ? .white : .blue)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(
                                                    selectedSource == source ? Color.blue : Color.blue.opacity(0.1),
                                                    in: RoundedRectangle(cornerRadius: 8)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            
                            // Family Person Name (only when Family source is selected)
                            if selectedSource == .family {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Family Member Name")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.modernText)
                                    
                                    TextField("Enter person's name (optional)", text: $familyPersonName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .font(.system(size: 16))
                                        .autocapitalization(.words)
                                }
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        // Note Input (for reserved seats)
                        if selectedStatus == .reserved {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Reservation Note")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.modernText)
                                
                                TextField("Enter note (optional)", text: $noteInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.system(size: 16))
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Cost Input (for all seats)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cost per Seat")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.modernText)
                            
                            HStack {
                                Text("$")
                                    .font(.system(size: 16))
                                    .foregroundColor(.modernTextSecondary)
                                
                                TextField("25", text: $costInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                    
                    Button("Apply Changes") {
                        applyBatchChanges()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            costInput = String(format: "%.0f", settingsManager.defaultSeatCost)
        }
        .alert("Batch Update", isPresented: $showingAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func applyBatchChanges() {
        var updatedSeats: [(Int, Seat)] = []
        
        for seatIndex in selectedSeats {
            var updatedSeat = concert.seats[seatIndex]
            updatedSeat.status = selectedStatus
            
            // Set cost for all statuses
            updatedSeat.cost = Double(costInput) ?? settingsManager.defaultSeatCost
            
            switch selectedStatus {
            case .available:
                updatedSeat.price = nil
                updatedSeat.source = nil
                updatedSeat.familyPersonName = nil
                updatedSeat.note = nil
                updatedSeat.dateSold = nil
                updatedSeat.datePaid = nil
                // Clear donation fields
                updatedSeat.donationDate = nil
                updatedSeat.donationFaceValue = nil
                updatedSeat.charityName = nil
                updatedSeat.charityAddress = nil
                updatedSeat.charityEIN = nil
                updatedSeat.charityContactName = nil
                updatedSeat.charityContactInfo = nil
                
            case .reserved:
                updatedSeat.price = nil
                updatedSeat.source = nil
                updatedSeat.familyPersonName = nil
                updatedSeat.note = noteInput.isEmpty ? nil : noteInput
                updatedSeat.dateSold = nil
                updatedSeat.datePaid = nil
                
            case .sold:
                if let price = Double(priceInput), price > 0 {
                    updatedSeat.price = price
                    updatedSeat.source = selectedSource
                    updatedSeat.familyPersonName = selectedSource == .family && !familyPersonName.isEmpty ? familyPersonName : nil
                    updatedSeat.note = nil
                    updatedSeat.dateSold = Date()
                    updatedSeat.datePaid = Date()
                } else {
                    alertMessage = "Please enter a valid price for sold seats."
                    showingAlert = true
                    return
                }
            }
            
            updatedSeats.append((seatIndex, updatedSeat))
        }
        
        onUpdate(updatedSeats)
        dismiss()
        
        // Call onComplete after dismissal to ensure proper state cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onComplete()
        }
    }
}

#Preview {
    DynamicFireSuiteApp()
}
