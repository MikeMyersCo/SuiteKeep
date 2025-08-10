//
//  DynamicFireSuiteApp.swift
//  SuiteKeep
//
//  Created by Mike Myers on 7/30/25.
//

import SwiftUI
import AVFoundation
import CloudKit


// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    @Published var suiteName: String {
        didSet {
            UserDefaults.standard.set(suiteName, forKey: "suiteName")
            NSUbiquitousKeyValueStore.default.set(suiteName, forKey: "suiteName")
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }
    
    @Published var venueLocation: String {
        didSet {
            UserDefaults.standard.set(venueLocation, forKey: "venueLocation")
            NSUbiquitousKeyValueStore.default.set(venueLocation, forKey: "venueLocation")
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }
    
    @Published var familyTicketPrice: Double {
        didSet {
            UserDefaults.standard.set(familyTicketPrice, forKey: "familyTicketPrice")
            NSUbiquitousKeyValueStore.default.set(familyTicketPrice, forKey: "familyTicketPrice")
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }
    
    @Published var defaultSeatCost: Double {
        didSet {
            UserDefaults.standard.set(defaultSeatCost, forKey: "defaultSeatCost")
            NSUbiquitousKeyValueStore.default.set(defaultSeatCost, forKey: "defaultSeatCost")
            NSUbiquitousKeyValueStore.default.synchronize()
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
        
        // Listen for iCloud changes
        iCloudObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            self?.syncFromiCloud()
        }
        
        NSUbiquitousKeyValueStore.default.synchronize()
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
    }
}

// MARK: - Vibrant Color Theme
extension Color {
    // Fire colors for firepit animation
    // Note: fireOrange is auto-generated from Assets.xcassets/FireOrange.colorset
    static let fireRed = Color(red: 0.9, green: 0.1, blue: 0.0)
    static let fireYellow = Color(red: 1.0, green: 0.8, blue: 0.0)
    
    // Beautiful gradient backgrounds
    static let primaryGradientStart = Color(red: 0.1, green: 0.4, blue: 0.9) // Deep blue
    static let primaryGradientEnd = Color(red: 0.8, green: 0.2, blue: 0.9) // Magenta
    static let secondaryGradientStart = Color(red: 0.0, green: 0.7, blue: 1.0) // Bright blue
    static let secondaryGradientEnd = Color(red: 0.0, green: 0.9, blue: 0.6) // Teal
    
    // Card gradient colors
    static let cardPurple = LinearGradient(colors: [Color(red: 0.1, green: 0.4, blue: 0.9), Color(red: 0.2, green: 0.6, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardBlue = LinearGradient(colors: [Color(red: 0.1, green: 0.4, blue: 0.9), Color(red: 0.2, green: 0.6, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardTeal = LinearGradient(colors: [Color(red: 0.0, green: 0.7, blue: 0.7), Color(red: 0.1, green: 0.8, blue: 0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardOrange = LinearGradient(colors: [Color(red: 1.0, green: 0.4, blue: 0.1), Color(red: 1.0, green: 0.6, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardPink = LinearGradient(colors: [Color(red: 0.4, green: 0.35, blue: 0.45), Color(red: 0.5, green: 0.45, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardGreen = LinearGradient(colors: [Color(red: 0.1, green: 0.7, blue: 0.3), Color(red: 0.2, green: 0.8, blue: 0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardIndigo = LinearGradient(colors: [Color(red: 0.2, green: 0.3, blue: 0.8), Color(red: 0.3, green: 0.4, blue: 0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
    
    // Modern colors with engagement focus - now adaptive to light/dark mode
    static let modernBackground = Color(.systemBackground)
    static let modernSecondary = Color(.secondarySystemBackground)
    static let modernAccent = Color(red: 0.0, green: 0.7, blue: 1.0) // Bright blue
    static let modernText = Color(.label)
    static let modernTextSecondary = Color(.secondaryLabel)
    static let modernSuccess = Color(red: 0.1, green: 0.8, blue: 0.4) // Brighter green
    static let modernWarning = Color(red: 1.0, green: 0.6, blue: 0.0) // Warmer orange
    static let modernDanger = Color(red: 1.0, green: 0.3, blue: 0.4) // Softer red
    
    // Dynamic background gradient function that adapts to light/dark mode
    static func dynamicGradient(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.15, green: 0.12, blue: 0.2),
                    Color(red: 0.12, green: 0.1, blue: 0.18),
                    Color(red: 0.08, green: 0.08, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.95, blue: 0.97),
                    Color(red: 0.98, green: 0.98, blue: 1.0),
                    Color(red: 0.96, green: 0.97, blue: 0.99),
                    Color(red: 0.94, green: 0.95, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // Seat status colors
    static let seatAvailable = Color(red: 0.2, green: 0.85, blue: 0.5) // Vibrant green
    static let seatReserved = Color(red: 1.0, green: 0.7, blue: 0.0) // Warm yellow
    static let seatSold = Color(red: 0.3, green: 0.6, blue: 1.0) // Bright blue
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
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? Color.modernAccent : Color.gray.opacity(0.5))
                    .shadow(color: .black.opacity(0.15), radius: configuration.isPressed ? 2 : 4, x: 0, y: configuration.isPressed ? 1 : 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Consistent secondary button style
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color.modernAccent)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.modernAccent, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.modernSecondary.opacity(configuration.isPressed ? 0.3 : 0.1))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

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

// Consistent settings field component
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
                                    Color.fireOrange.opacity(0.3),
                                    Color.fireOrange.opacity(0.1),
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
                                    Color.fireOrange,
                                    Color(red: 1.0, green: 0.3, blue: 0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(fireScale)
                        .rotationEffect(.degrees(isAnimating ? 5 : -5))
                        .shadow(color: .fireOrange, radius: 30)
                        .shadow(color: .fireOrange.opacity(0.5), radius: 50)
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
                        .shadow(color: .fireOrange.opacity(0.5), radius: 10)
                    
                    Text("Concert Management")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(subtitleOpacity)
                    
                    // Loading indicator
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.fireOrange)
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
        self.noteColor = .fireOrange
        
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
                        Color.fireOrange,
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
    @StateObject private var sharedSuiteManager = SharedSuiteManager()
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
        .accentColor(.modernAccent)
        .onAppear {
            startFlameAnimation()
            // Connect SharedSuiteManager to ConcertDataManager
            concertManager.sharedSuiteManager = sharedSuiteManager
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
                    VStack(spacing: 16) {
                        // Modern Header Card
                        VStack(spacing: 12) {
                            Text("Dashboard")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "building.2")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(settingsManager.suiteName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Circle()
                                    .fill(.white.opacity(0.5))
                                    .frame(width: 4, height: 4)
                                
                                Image(systemName: "location")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(settingsManager.venueLocation)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                            }
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
                            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
                        )
                        .padding(.top, 20)
                        
                        // Suite Overview Summary
                        SuiteSummaryView(concerts: concerts, settingsManager: settingsManager)
                        
                        // Recent Activity
                        RecentActivityFeed(concerts: concerts) { concert in
                            selectedConcert = concert
                        }
                    }
                    .padding(.horizontal)
                }
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
            .onChange(of: selectedConcert) { newValue in
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
    @State private var animateStats = false
    
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
            
            // Key Metrics Cards with Beautiful Gradients
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                MetricCard(
                    title: "Total Tickets Sold",
                    value: "\(totalTicketsSold)",
                    subtitle: "tickets sold",
                    gradient: Color.cardGreen,
                    icon: "ticket.fill"
                )
                
                MetricCard(
                    title: "Revenue",
                    value: "$\(Int(totalRevenue))",
                    subtitle: "total earnings",
                    gradient: Color.cardBlue,
                    icon: "dollarsign.circle.fill"
                )
                
                MetricCard(
                    title: "Total Cost",
                    value: "$\(Int(totalCost))",
                    subtitle: "ticket costs",
                    gradient: Color.cardOrange,
                    icon: "minus.circle.fill"
                )
                
                MetricCard(
                    title: "Profit",
                    value: "$\(Int(totalProfit))",
                    subtitle: "net earnings",
                    gradient: totalProfit >= 0 ? Color.cardGreen : Color.cardPink,
                    icon: totalProfit >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
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
    
    @State private var isPressed = false
    @State private var animateValue = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon with gradient background - centered
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 36, height: 36)
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer(minLength: 2)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .scaleEffect(animateValue ? 1.05 : 1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateValue)
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer(minLength: 6)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .background(
            ZStack {
                // Main gradient background
                RoundedRectangle(cornerRadius: 24)
                    .fill(gradient)
                
                // Subtle overlay pattern
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.1), .clear, .black.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
        )
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .rotation3DEffect(
            .degrees(isPressed ? 2 : 0),
            axis: (x: 1, y: 0, z: 0)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isPressed.toggle()
                animateValue.toggle()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
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
            // Firepit base
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.yellow, .orange, .red, .black],
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
                        x: CGFloat.random(in: -20...20),
                        y: CGFloat.random(in: -30...10)
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
            
            if showChart {
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
                                        .frame(width: barWidth, height: animateBars ? max(20, CGFloat(chartData[index] * 0.8)) : 0)
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
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Concerts")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.modernText)
                            
                            Text("Manage upcoming performances")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.modernTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.modernAccent.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.modernAccent.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
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

// MARK: - CloudKit Record Types

enum CloudKitRecordType {
    static let sharedSuite = "SharedSuite"
    static let concert = "Concert"
    static let suiteMember = "SuiteMember"
}

// Extensions to convert models to/from CloudKit records
extension SharedSuiteInfo {
    func toCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: CloudKitRecordType.sharedSuite, recordID: CKRecord.ID(recordName: suiteId))
        record["suiteName"] = suiteName
        record["venueLocation"] = venueLocation
        record["ownerId"] = ownerId
        record["createdDate"] = createdDate
        record["lastModified"] = lastModified
        
        // Store members as JSON data
        if let membersData = try? JSONEncoder().encode(members) {
            record["membersData"] = membersData
        }
        
        return record
    }
    
    static func fromCloudKitRecord(_ record: CKRecord) -> SharedSuiteInfo? {
        guard let suiteName = record["suiteName"] as? String,
              let venueLocation = record["venueLocation"] as? String,
              let ownerId = record["ownerId"] as? String,
              let createdDate = record["createdDate"] as? Date,
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
        
        return suiteInfo
    }
}

extension Concert {
    func toCloudKitRecord(suiteRecord: CKRecord? = nil) -> CKRecord {
        let recordID = CKRecord.ID(recordName: "concert_\(id)")
        let record = CKRecord(recordType: CloudKitRecordType.concert, recordID: recordID)
        
        record["concertId"] = Int64(id)
        record["artist"] = artist
        record["date"] = date
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
        
        // Reference to suite if provided
        if let suiteRecord = suiteRecord {
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
            suiteId: record["suite"] != nil ? "shared" : nil,
            createdBy: record["createdBy"] as? String,
            lastModifiedBy: record["lastModifiedBy"] as? String,
            lastModifiedDate: record["lastModifiedDate"] as? Date,
            sharedVersion: record["sharedVersion"] as? Int
        )
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
    
    // Multi-user sharing properties
    var lastModifiedBy: String? // User ID who last modified this seat
    var lastModifiedDate: Date? // When this seat was last modified
    var modificationHistory: [SeatModification]? // History of changes for conflict resolution
    var conflictResolutionVersion: Int? // Version number for conflict resolution
    
    init(status: SeatStatus = .available, price: Double? = nil, note: String? = nil, source: TicketSource? = nil, cost: Double? = nil, dateSold: Date? = nil, datePaid: Date? = nil, familyPersonName: String? = nil, lastModifiedBy: String? = nil, lastModifiedDate: Date? = nil, modificationHistory: [SeatModification]? = nil, conflictResolutionVersion: Int? = nil) {
        self.status = status
        self.price = price
        self.note = note
        self.source = source
        self.cost = cost
        self.dateSold = dateSold
        self.datePaid = datePaid
        self.familyPersonName = familyPersonName
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
    
    private let userDefaults = UserDefaults.standard
    private let iCloudStore = NSUbiquitousKeyValueStore.default
    private let cloudKitContainer = CKContainer.default()
    private var cloudKitDatabase: CKDatabase { cloudKitContainer.privateCloudDatabase }
    
    private let suiteInfoKey = "SharedSuiteInfo"
    private let userIdKey = "CurrentUserId"
    private let userNameKey = "CurrentUserName"
    
    var isInSharedSuite: Bool {
        return currentSuiteInfo != nil
    }
    
    init() {
        loadUserInfo()
        loadSuiteInfo()
        checkCloudKitAvailability()
    }
    
    private func loadUserInfo() {
        // Generate or load user ID
        if let existingUserId = userDefaults.string(forKey: userIdKey) {
            currentUserId = existingUserId
        } else {
            currentUserId = UUID().uuidString
            userDefaults.set(currentUserId, forKey: userIdKey)
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
            if suiteInfo.ownerId == currentUserId {
                userRole = .owner
            } else if let member = suiteInfo.members.first(where: { $0.userId == currentUserId }) {
                userRole = member.role
            } else {
                userRole = .viewer
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
            ownerId: currentUserId
        )
        
        currentSuiteInfo = suiteInfo
        userRole = .owner
        isSharedSuite = true
        saveSuiteInfo()
    }
    
    func joinSharedSuite(_ suiteInfo: SharedSuiteInfo, as role: UserRole = .viewer) {
        // Add current user as a member
        let member = SuiteMember(
            userId: currentUserId,
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
        currentSuiteInfo = nil
        userRole = .owner
        isSharedSuite = false
        userDefaults.removeObject(forKey: suiteInfoKey)
        iCloudStore.removeObject(forKey: suiteInfoKey)
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
    }
    
    func removeMember(userId: String) {
        guard var suiteInfo = currentSuiteInfo,
              userRole.canManageUsers else {
            return
        }
        
        suiteInfo.members.removeAll { $0.userId == userId }
        suiteInfo.lastModified = Date()
        currentSuiteInfo = suiteInfo
        saveSuiteInfo()
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
    
    // MARK: - CloudKit Integration
    
    private func checkCloudKitAvailability() {
        cloudKitContainer.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.isCloudKitAvailable = true
                    self?.cloudKitStatus = "Ready"
                case .noAccount:
                    self?.isCloudKitAvailable = false
                    self?.cloudKitStatus = "No iCloud account"
                case .couldNotDetermine:
                    self?.isCloudKitAvailable = false
                    self?.cloudKitStatus = "Could not determine status"
                case .restricted:
                    self?.isCloudKitAvailable = false
                    self?.cloudKitStatus = "Restricted"
                @unknown default:
                    self?.isCloudKitAvailable = false
                    self?.cloudKitStatus = "Unknown status"
                }
            }
        }
    }
    
    func createSharedSuiteInCloud(suiteName: String, venueLocation: String) async throws -> String {
        guard isCloudKitAvailable else {
            throw CloudKitError.notAvailable
        }
        
        cloudKitStatus = "Creating shared suite..."
        
        let suiteInfo = SharedSuiteInfo(
            suiteId: UUID().uuidString,
            suiteName: suiteName,
            venueLocation: venueLocation,
            ownerId: currentUserId
        )
        
        let record = suiteInfo.toCloudKitRecord()
        
        do {
            let savedRecord = try await cloudKitDatabase.save(record)
            
            // Update local state
            await MainActor.run {
                currentSuiteInfo = SharedSuiteInfo.fromCloudKitRecord(savedRecord)
                isSharedSuite = true
                userRole = .owner
                cloudKitStatus = "Suite created successfully"
                saveSuiteInfo()
            }
            
            return savedRecord.recordID.recordName
        } catch {
            await MainActor.run {
                cloudKitStatus = "Failed to create suite: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    func joinSharedSuiteFromCloud(suiteId: String) async throws {
        guard isCloudKitAvailable else {
            throw CloudKitError.notAvailable
        }
        
        cloudKitStatus = "Joining shared suite..."
        
        let recordID = CKRecord.ID(recordName: suiteId)
        
        do {
            let record = try await cloudKitDatabase.record(for: recordID)
            
            if var suiteInfo = SharedSuiteInfo.fromCloudKitRecord(record) {
                // Add current user as member
                let member = SuiteMember(
                    userId: currentUserId,
                    displayName: currentUserName,
                    role: .viewer // Default role for new members
                )
                suiteInfo.members.append(member)
                suiteInfo.lastModified = Date()
                
                // Save updated suite info to CloudKit
                let updatedRecord = suiteInfo.toCloudKitRecord()
                _ = try await cloudKitDatabase.save(updatedRecord)
                
                // Update local state
                await MainActor.run {
                    currentSuiteInfo = suiteInfo
                    isSharedSuite = true
                    userRole = .viewer
                    cloudKitStatus = "Joined suite successfully"
                    saveSuiteInfo()
                }
            }
        } catch {
            await MainActor.run {
                cloudKitStatus = "Failed to join suite: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    func generateSharingLink() -> String? {
        guard let suiteInfo = currentSuiteInfo else { return nil }
        return "suitekeeper://join/\(suiteInfo.suiteId)"
    }
    
    func syncWithCloudKit() async {
        guard isCloudKitAvailable, let suiteInfo = currentSuiteInfo else { return }
        
        cloudKitStatus = "Syncing with CloudKit..."
        
        do {
            let recordID = CKRecord.ID(recordName: suiteInfo.suiteId)
            let record = try await cloudKitDatabase.record(for: recordID)
            
            if let updatedSuiteInfo = SharedSuiteInfo.fromCloudKitRecord(record) {
                await MainActor.run {
                    currentSuiteInfo = updatedSuiteInfo
                    cloudKitStatus = "Sync complete"
                    saveSuiteInfo()
                }
            }
        } catch {
            await MainActor.run {
                cloudKitStatus = "Sync failed: \(error.localizedDescription)"
            }
        }
    }
}

enum CloudKitError: Error, LocalizedError {
    case notAvailable
    case recordNotFound
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "CloudKit is not available. Please ensure you're signed into iCloud."
        case .recordNotFound:
            return "The requested suite could not be found."
        case .permissionDenied:
            return "You don't have permission to access this suite."
        }
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
    private var cloudKitDatabase: CKDatabase { cloudKitContainer.privateCloudDatabase }
    private let concertsKey = "SavedConcerts"
    private var iCloudObserver: NSObjectProtocol?
    
    // Multi-user sharing support
    weak var sharedSuiteManager: SharedSuiteManager?
    
    init(sharedSuiteManager: SharedSuiteManager? = nil) {
        self.sharedSuiteManager = sharedSuiteManager
        setupiCloudSync()
        migrateDataIfNeeded()
        loadConcerts()
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
                        concerts[i].createdBy = sharedSuiteManager?.currentUserId
                        concerts[i].lastModifiedBy = sharedSuiteManager?.currentUserId
                        concerts[i].lastModifiedDate = Date()
                        concerts[i].sharedVersion = 1
                    }
                    
                    // Update seats with sharing metadata
                    for j in 0..<concerts[i].seats.count {
                        if concerts[i].seats[j].lastModifiedBy == nil {
                            concerts[i].seats[j].lastModifiedBy = sharedSuiteManager?.currentUserId
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
    
    func saveConcerts() {
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
            updatedConcert.createdBy = sharedSuiteManager.currentUserId
            updatedConcert.lastModifiedBy = sharedSuiteManager.currentUserId
            updatedConcert.lastModifiedDate = Date()
            updatedConcert.sharedVersion = 1
        } else if let sharedSuiteManager = sharedSuiteManager {
            // Non-shared suite, just track the user
            updatedConcert.createdBy = sharedSuiteManager.currentUserId
            updatedConcert.lastModifiedBy = sharedSuiteManager.currentUserId
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
                updatedConcert.recordModification(by: sharedSuiteManager.currentUserId)
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
                by: sharedSuiteManager.currentUserId,
                userName: sharedSuiteManager.currentUserName,
                previousStatus: previousStatus
            )
        }
        
        concerts[concertIndex].seats[seatIndex] = newSeat
        concerts[concertIndex].recordModification(by: sharedSuiteManager?.currentUserId ?? "")
        
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
              let suiteInfo = sharedSuiteManager.currentSuiteInfo else {
            return
        }
        
        do {
            // Create suite record reference
            let suiteRecord = suiteInfo.toCloudKitRecord()
            let concertRecord = concert.toCloudKitRecord(suiteRecord: suiteRecord)
            
            _ = try await cloudKitDatabase.save(concertRecord)
            
            await MainActor.run {
                syncStatus = "Concert synced"
                lastSyncDate = Date()
            }
        } catch {
            await MainActor.run {
                syncStatus = "Sync failed: \(error.localizedDescription)"
            }
        }
    }
    
    // Update the existing saveConcerts method to include CloudKit sync
    private func syncToCloudKitAfterSave() {
        // If we're in a shared suite, sync to CloudKit
        if let sharedSuiteManager = sharedSuiteManager,
           sharedSuiteManager.isSharedSuite {
            Task {
                await MainActor.run {
                    sharedSuiteManager.isSyncing = true
                }
                
                for concert in concerts {
                    await syncConcertToCloudKit(concert)
                }
                
                await MainActor.run {
                    sharedSuiteManager.isSyncing = false
                }
            }
        }
    }
}

// MARK: - Concert Row View
struct ConcertRowView: View {
    let concert: Concert
    
    var statusColor: Color {
        if concert.ticketsSold == 8 {
            return .modernSuccess
        } else if concert.ticketsSold > 0 {
            return .modernWarning
        } else if concert.ticketsReserved > 0 {
            return .cyan
        } else {
            return .modernTextSecondary
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Concert Icon
            Circle()
                .fill(statusColor.opacity(0.1))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(statusColor)
                )
            
            // Concert Info
            VStack(alignment: .leading, spacing: 4) {
                Text(concert.artist)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.modernText)
                
                Text(concert.date, style: .date)
                    .font(.system(size: 14))
                    .foregroundColor(.modernTextSecondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(concert.ticketsSold == 8 ? Color.modernSuccess : (concert.ticketsSold > 0 ? Color.modernWarning : Color.modernTextSecondary))
                            .frame(width: 6, height: 6)
                        Text("\(concert.ticketsSold)/8 tickets sold")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(concert.ticketsSold == 8 ? .modernSuccess : (concert.ticketsSold > 0 ? .modernWarning : .modernTextSecondary))
                    }
                    
                    if concert.ticketsReserved > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.cyan)
                                .frame(width: 6, height: 6)
                            Text("\(concert.ticketsReserved) reserved")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.cyan)
                        }
                    }
                    
                    // Parking ticket status
                    if concert.parkingTicketSold {
                        HStack(spacing: 4) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.green)
                            Text("Parking sold")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.green)
                        }
                    } else if concert.parkingTicketReserved {
                        HStack(spacing: 4) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.orange)
                            Text("Parking reserved")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.modernTextSecondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.modernSecondary)
        )
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
    @State private var isListView = false
    
    // Batch operation states
    @State private var isBatchMode = false
    @State private var selectedSeats = Set<Int>()
    @State private var showingBatchOptions = false
    
    var body: some View {
        ZStack {
            // Dynamic background that adapts to light/dark mode
            Color(.systemBackground)
            .ignoresSafeArea()
            
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
                        
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(HoverableButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Concert Header Card with batch operations overlay
                    ZStack {
                        VStack(spacing: 12) {
                            HStack {
                                Spacer()
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
                                                .fill(concert.ticketsSold == 8 ? Color.modernSuccess : Color.modernWarning)
                                                .frame(width: 6, height: 6)
                                            Text("\(concert.ticketsSold)/8 tickets sold")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(concert.ticketsSold == 8 ? .modernSuccess : .modernWarning)
                                        }
                                        
                                        if concert.ticketsReserved > 0 {
                                            HStack {
                                                Circle()
                                                    .fill(Color.cyan)
                                                    .frame(width: 6, height: 6)
                                                Text("\(concert.ticketsReserved) reserved")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.cyan)
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
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.modernSecondary)
                        )
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
                    
                    // View Toggle
                    HStack(spacing: 0) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isListView = false
                            }
                        }) {
                            Text("Seat View")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(!isListView ? .white : .modernTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    !isListView ? Color.modernAccent : Color.clear
                                )
                        }
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isListView = true
                            }
                        }) {
                            Text("List View")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(isListView ? .white : .modernTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    isListView ? Color.modernAccent : Color.clear
                                )
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.modernSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.modernAccent.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    // Conditional view based on toggle
                    if isListView {
                        // List View
                        SeatListView(
                            concert: $concert,
                            concertManager: concertManager,
                            settingsManager: settingsManager,
                            isBatchMode: $isBatchMode,
                            selectedSeats: $selectedSeats,
                            showingBatchOptions: $showingBatchOptions
                        )
                    } else {
                        // Interactive Fire Suite Layout for seat selection
                        InteractiveFireSuiteView(
                            concert: $concert, 
                            concertManager: concertManager, 
                            settingsManager: settingsManager,
                            isBatchMode: $isBatchMode,
                            selectedSeats: $selectedSeats,
                            showingBatchOptions: $showingBatchOptions
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .navigationBarHidden(true)
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
                
                // Clear price and source for available seats
                if status == .available {
                    concert.seats[index].price = nil
                    concert.seats[index].source = nil
                    concert.seats[index].note = nil
                }
            }
            
            concertManager.updateConcert(concert)
            selectedSeats.removeAll()
        }
    }
}

// MARK: - Selected Seat Helper
struct SelectedSeat: Identifiable {
    let id = UUID()
    let index: Int
}

// MARK: - Seat List View
struct SeatListView: View {
    @Binding var concert: Concert
    @ObservedObject var concertManager: ConcertDataManager
    @ObservedObject var settingsManager: SettingsManager
    @Binding var isBatchMode: Bool
    @Binding var selectedSeats: Set<Int>
    @Binding var showingBatchOptions: Bool
    @State private var showingSeatOptions = false
    @State private var selectedSeatIndex: Int?
    
    var body: some View {
        VStack(spacing: 16) {
            // Title and instructions
            seatListHeader
            
            // Seat List
            seatListContent
        }
        .sheet(item: Binding<SelectedSeat?>(
            get: {
                if let index = selectedSeatIndex, showingSeatOptions {
                    return SelectedSeat(index: index)
                }
                return nil
            },
            set: { newValue in
                if newValue == nil {
                    selectedSeatIndex = nil
                    showingSeatOptions = false
                }
            }
        )) { selectedSeat in
            SeatOptionsView(
                seatNumber: selectedSeat.index + 1,
                seat: concert.seats[selectedSeat.index],
                onUpdate: { updatedSeat in
                    concert.seats[selectedSeat.index] = updatedSeat
                    concertManager.updateConcert(concert)
                }
            )
            .environmentObject(settingsManager)
        }
    }
    
    private var seatListHeader: some View {
        VStack(spacing: 12) {
            Text("Seating List")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.modernText)
            
            Text(isBatchMode ? "Select multiple seats for batch operations" : "Tap seats to manage tickets")
                .font(.system(size: 14))
                .foregroundColor(.modernTextSecondary)
            
            // Batch mode toggle
            batchModeToggle
            
            // Batch selection status
            if isBatchMode && !selectedSeats.isEmpty {
                batchSelectionStatus
            }
        }
        .padding(.horizontal)
    }
    
    private var batchModeToggle: some View {
        HStack {
            Spacer()
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isBatchMode.toggle()
                    selectedSeats.removeAll()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isBatchMode ? "checkmark.square.fill" : "square.on.square")
                        .font(.system(size: 16, weight: .medium))
                    Text(isBatchMode ? "Exit Batch" : "Batch Mode")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(isBatchMode ? .blue : .modernTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(batchModeBackground)
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()
        }
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
                }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.red)
            
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
            // Checkbox for batch mode
            if isBatchMode {
                batchCheckbox(for: index)
            }
            
            // Seat number badge
            seatBadge(for: index)
            
            // Seat details
            seatDetails(for: index)
            
            Spacer()
            
            // Edit button (when not in batch mode)
            if !isBatchMode {
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
                Text("Seat \(index + 1)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.modernText)
                
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
            
            if let note = concert.seats[index].note, !note.isEmpty {
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
            selectedSeatIndex = index
            showingSeatOptions = true
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
}

// MARK: - Interactive Fire Suite View
struct InteractiveFireSuiteView: View {
    @Binding var concert: Concert
    @ObservedObject var concertManager: ConcertDataManager
    @ObservedObject var settingsManager: SettingsManager
    @State private var pulseFirepit = false
    @State private var showingSeatOptions = false
    @State private var selectedSeatIndex: Int?
    @State private var priceInput: String = ""
    @State private var showingParkingOptions = false
    
    // Batch operation states (now bindings from parent)
    @Binding var isBatchMode: Bool
    @Binding var selectedSeats: Set<Int>
    @Binding var showingBatchOptions: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Title and instructions
            VStack(spacing: 12) {
                Text("Seating")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.modernText)
                
                Text(isBatchMode ? "Select multiple seats for batch operations" : "Tap seats to manage tickets")
                    .font(.system(size: 14))
                    .foregroundColor(.modernTextSecondary)
                
                // Batch mode toggle
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isBatchMode.toggle()
                            selectedSeats.removeAll()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isBatchMode ? "checkmark.square.fill" : "square.on.square")
                                .font(.system(size: 16, weight: .medium))
                            Text(isBatchMode ? "Exit Batch" : "Batch Mode")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(isBatchMode ? .blue : .modernTextSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isBatchMode ? Color.blue.opacity(0.1) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isBatchMode ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
                
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
                    .frame(width: 350, height: 280) // Made taller to fit seats properly
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                VStack(spacing: 8) {
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
                    
                    // Fire Suite Layout with firepit in center - CORRECT seat positions
                    ZStack {
                        // Bottom row: Seats 6, 5, 4, 3 (left to right) 
                        VStack {
                            Spacer()
                            HStack(spacing: 6) {
                                InteractiveSeatView(
                                    seatNumber: 6,
                                    seat: concert.seats[5],
                                    isSelected: selectedSeats.contains(5),
                                    isBatchMode: isBatchMode,
                                    onTap: { handleSeatTap(5) }
                                )
                                InteractiveSeatView(
                                    seatNumber: 5,
                                    seat: concert.seats[4],
                                    isSelected: selectedSeats.contains(4),
                                    isBatchMode: isBatchMode,
                                    onTap: { handleSeatTap(4) }
                                )
                                InteractiveSeatView(
                                    seatNumber: 4,
                                    seat: concert.seats[3],
                                    isSelected: selectedSeats.contains(3),
                                    isBatchMode: isBatchMode,
                                    onTap: { handleSeatTap(3) }
                                )
                                InteractiveSeatView(
                                    seatNumber: 3,
                                    seat: concert.seats[2],
                                    isSelected: selectedSeats.contains(2),
                                    isBatchMode: isBatchMode,
                                    onTap: { handleSeatTap(2) }
                                )
                            }
                        }
                        
                        // Side seats positioned to align with bottom row seats
                        HStack {
                            // Left side: Seats 8, 7 aligned above seat 6
                            VStack(spacing: 6) {
                                InteractiveSeatView(
                                    seatNumber: 8,
                                    seat: concert.seats[7],
                                    isSelected: selectedSeats.contains(7),
                                    isBatchMode: isBatchMode,
                                    onTap: { handleSeatTap(7) }
                                )
                                .offset(y: -24) // Move seat 8 up for consistent spacing
                                InteractiveSeatView(
                                    seatNumber: 7,
                                    seat: concert.seats[6],
                                    isSelected: selectedSeats.contains(6),
                                    isBatchMode: isBatchMode,
                                    onTap: { handleSeatTap(6) }
                                )
                                .offset(y: -32) // Move seat 7 up more to prevent text overlap
                                Spacer()
                                    .frame(height: 38) // Space for bottom seat alignment
                            }
                            .offset(x: 19) // Align with seat 6 position
                            
                            Spacer()
                            
                            // Right side: Seats 1, 2 aligned above seat 3  
                            VStack(spacing: 6) {
                                InteractiveSeatView(
                                    seatNumber: 1,
                                    seat: concert.seats[0],
                                    isSelected: selectedSeats.contains(0),
                                    isBatchMode: isBatchMode,
                                    onTap: { handleSeatTap(0) }
                                )
                                .offset(y: -24) // Move seat 1 up for consistent spacing
                                InteractiveSeatView(
                                    seatNumber: 2,
                                    seat: concert.seats[1],
                                    isSelected: selectedSeats.contains(1),
                                    isBatchMode: isBatchMode,
                                    onTap: { handleSeatTap(1) }
                                )
                                .offset(y: -32) // Move seat 2 up more to prevent text overlap
                                Spacer()
                                    .frame(height: 38) // Space for bottom seat alignment
                            }
                            .offset(x: -19) // Align with seat 3 position
                        }
                        
                        // Firepit centered among all seats
                        DynamicFirepitView(isPulsing: pulseFirepit)
                            .scaleEffect(1.3)
                            .offset(y: -24) // Move firepit up about an inch
                    }
                }
                .padding(20)
                .offset(y: -20) // Adjusted offset for better centering
            }
            
            // Revenue display
            VStack(spacing: 8) {
                Text("Revenue: $\(Int(concert.totalRevenue))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.green)
                
                HStack(spacing: 15) {
                    Text("\(concert.ticketsSold) sold")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                    
                    Text("\(concert.ticketsReserved) reserved")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                    
                    Text("\(8 - concert.ticketsSold - concert.ticketsReserved) available")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
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
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .onAppear {
            startPulseAnimation()
        }
        .sheet(item: Binding<SelectedSeat?>(
            get: { 
                if let index = selectedSeatIndex {
                    return SelectedSeat(index: index)
                }
                return nil
            },
            set: { _ in 
                selectedSeatIndex = nil
                showingSeatOptions = false
            }
        )) { selectedSeat in
            SeatOptionsView(
                seatNumber: selectedSeat.index + 1,
                seat: concert.seats[selectedSeat.index],
                onUpdate: { updatedSeat in
                    concert.seats[selectedSeat.index] = updatedSeat
                    concertManager.updateConcert(concert)
                },
                onUpdateAll: { templateSeat in
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
    
    private func handleSeatTap(_ index: Int) {
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
            // Normal single seat selection - the sheet will present automatically when selectedSeatIndex is set
            selectedSeatIndex = index
            priceInput = concert.seats[index].price != nil ? String(concert.seats[index].price!) : ""
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever()) {
            pulseFirepit.toggle()
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
    @State private var isPressed = false
    @State private var isAnimating = false
    @State private var isHovering = false
    
    var seatColor: LinearGradient {
        if isBatchMode && isSelected {
            // Selected seats in batch mode get a blue gradient
            return LinearGradient(colors: [Color.blue, Color.blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        
        switch seat.status {
        case .available:
            return LinearGradient(colors: [Color.seatAvailable, Color.seatAvailable.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .reserved:
            return LinearGradient(colors: [Color.seatReserved, Color.seatReserved.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .sold:
            return LinearGradient(colors: [Color.seatSold, Color.seatSold.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var body: some View {
        VStack(spacing: 3) {
            Button(action: {
                // Haptic feedback
                HapticManager.shared.impact(style: .light)
                
                // Animate press
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                    isAnimating = true
                }
                
                onTap()
                
                // Reset animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
                
                // Additional animation for status change
                withAnimation(.easeInOut(duration: 0.5)) {
                    isAnimating = false
                }
            }) {
                ZStack {
                    // Background circle with gradient
                    Circle()
                        .fill(seatColor)
                        .frame(width: 42, height: 42)
                        .scaleEffect(isPressed ? 1.2 : (isAnimating ? 1.1 : (isHovering ? 1.05 : 1.0)))
                        .shadow(
                            color: seat.status != .available ? Color.black.opacity(0.2) : Color.clear, 
                            radius: isHovering ? 6 : 4, 
                            x: 0, 
                            y: isHovering ? 3 : 2
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    isHovering ? Color.white.opacity(0.6) : Color.white.opacity(0.3), 
                                    lineWidth: isHovering ? 2 : 1
                                )
                                .scaleEffect(isPressed ? 1.2 : (isHovering ? 1.02 : 1.0))
                        )
                        .overlay(
                            // Pulse effect on hover
                            Circle()
                                .stroke(Color.white.opacity(isHovering ? 0.4 : 0), lineWidth: 3)
                                .scaleEffect(isHovering ? 1.3 : 1.0)
                                .opacity(isHovering ? 0.3 : 0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isHovering)
                        )
                    
                    ZStack {
                        // Always show seat number
                        Text("\(seatNumber)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        // Show batch selection indicator in top-left corner
                        if isBatchMode && isSelected {
                            VStack {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.blue).frame(width: 16, height: 16))
                                        .scaleEffect(isSelected ? 1.2 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                        // Show status icon in top-right corner for sold/reserved (only if not in batch mode or not selected)
                        else if seat.status == .sold {
                            VStack {
                                HStack {
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.green).frame(width: 12, height: 12))
                                }
                                Spacer()
                            }
                        } else if seat.status == .reserved {
                            VStack {
                                HStack {
                                    Spacer()
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.orange).frame(width: 12, height: 12))
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
            
            // Fixed-height container for text to prevent layout shifts
            VStack(spacing: 1) {
                if seat.status == .sold {
                    Text(seat.price != nil ? "$\(Int(seat.price!))" : "SOLD")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(seat.status.color)
                    
                    Text(displayTextForSeat(seat))
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(seat.status.color.opacity(0.8))
                        .lineLimit(1)
                        .frame(height: 10) // Fixed height for consistent spacing
                } else if seat.status == .reserved && seat.note != nil {
                    Text("RESERVED")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(seat.status.color)
                    
                    Text(seat.note!)
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(seat.status.color.opacity(0.8))
                        .lineLimit(1)
                        .frame(height: 10) // Fixed height for consistent spacing
                } else {
                    Text(seat.status.displayText)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(seat.status.color)
                    
                    // Empty space to maintain consistent height
                    Text("")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .frame(height: 10)
                }
            }
            .frame(width: 52, height: 32) // Smaller text area with fixed dimensions
            .multilineTextAlignment(.center)
        }
        .frame(width: 55, height: 78) // Smaller overall container
    }
    
    private func displayTextForSeat(_ seat: Seat) -> String {
        if seat.source == .family, let personName = seat.familyPersonName, !personName.isEmpty {
            return personName
        }
        return seat.source?.rawValue ?? ""
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
    
    init(seatNumber: Int, seat: Seat, onUpdate: @escaping (Seat) -> Void, onUpdateAll: ((Seat) -> Void)? = nil) {
        self.seatNumber = seatNumber
        self.seat = seat
        self.onUpdate = onUpdate
        self.onUpdateAll = onUpdateAll
        self._selectedStatus = State(initialValue: seat.status)
        self._priceInput = State(initialValue: seat.price != nil ? String(seat.price!) : "")
        // Use the seat's actual cost, or fallback to 0.0 if nil (for older seats)
        self._costInput = State(initialValue: String(seat.cost ?? 0.0))
        self._noteInput = State(initialValue: seat.note ?? "")
        self._selectedSource = State(initialValue: seat.source ?? .facebook)
        self._dateSold = State(initialValue: seat.dateSold ?? Date())
        self._datePaid = State(initialValue: seat.datePaid ?? Date())
        self._familyPersonName = State(initialValue: seat.familyPersonName ?? "")
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
                                .fill(seat.status.color.opacity(0.1))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text("\(seatNumber)")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(seat.status.color)
                                )
                            
                            Text("Seat \(seatNumber)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.modernText)
                            
                            HStack {
                                Circle()
                                    .fill(seat.status.color)
                                    .frame(width: 8, height: 8)
                                Text(seat.status.rawValue.capitalized)
                                    .font(.system(size: 16))
                                    .foregroundColor(seat.status.color)
                            }
                        }
                        .padding(.top, 20)
                    
                        // Status selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Seat Status")
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
                                            
                                            Text(status.rawValue.capitalized)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.modernText)
                                            
                                            Spacer()
                                            
                                            if selectedStatus == status {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(status.color)
                                            }
                                        }
                                        .padding(16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(selectedStatus == status ? status.color.opacity(0.2) : Color.modernSecondary)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(selectedStatus == status ? status.color.opacity(0.3) : Color.clear, lineWidth: 1)
                                                )
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    
                        // Price and Source input (only for sold status)
                        if selectedStatus == .sold {
                            VStack(spacing: 20) {
                                // Price input
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Sale Price")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.modernTextSecondary)
                                    
                                    HStack {
                                        Text("$")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.modernText)
                                        
                                        TextField("", text: $priceInput)
                                            .font(.system(size: 16))
                                            .foregroundColor(.modernText)
                                            .padding(16)
                                            .padding(.leading, -10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.modernSecondary)
                                            )
                                            .keyboardType(.decimalPad)
                                    }
                                }
                                
                                // Source dropdown
                                VStack(alignment: .center, spacing: 8) {
                                    Text("Ticket Source")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.modernTextSecondary)
                                    
                                    Picker("", selection: $selectedSource) {
                                        ForEach(TicketSource.allCases, id: \.self) { source in
                                            Text(source.rawValue)
                                                .tag(source)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(.modernText)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.modernSecondary)
                                    )
                                    .onChange(of: selectedSource) { newSource in
                                        // Auto-set price for family tickets
                                        if newSource == .family {
                                            priceInput = String(format: "%.0f", settingsManager.familyTicketPrice)
                                        }
                                    }
                                }
                                
                                // Family person name field (only for family source)
                                if selectedSource == .family {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Person's Name")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.modernTextSecondary)
                                        
                                        TextField("Enter person's name", text: $familyPersonName)
                                            .font(.system(size: 16))
                                            .foregroundColor(.modernText)
                                            .padding(12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.modernSecondary)
                                            )
                                            .autocapitalization(.words)
                                    }
                                }
                                
                                // Date fields (only for sold status)
                                VStack(spacing: 16) {
                                    // Date Sold
                                    VStack(alignment: .center, spacing: 8) {
                                        Text("Date Sold")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.modernTextSecondary)
                                        
                                        HStack {
                                            Spacer()
                                            DatePicker("", selection: $dateSold, displayedComponents: .date)
                                                .datePickerStyle(.compact)
                                                .colorScheme(.dark)
                                                .padding(12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.modernSecondary)
                                                )
                                                .fixedSize()
                                            Spacer()
                                        }
                                    }
                                    
                                    // Date Paid
                                    VStack(alignment: .center, spacing: 8) {
                                        Text("Date Paid")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.modernTextSecondary)
                                        
                                        HStack {
                                            Spacer()
                                            DatePicker("", selection: $datePaid, displayedComponents: .date)
                                                .datePickerStyle(.compact)
                                                .colorScheme(.dark)
                                                .padding(12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.modernSecondary)
                                                )
                                                .fixedSize()
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                    
                        // Note input (only for reserved status)
                        if selectedStatus == .reserved {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Reservation Note")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.modernTextSecondary)
                                
                                Text("Maximum 5 words")
                                    .font(.system(size: 12))
                                    .foregroundColor(.modernTextSecondary.opacity(0.8))
                                
                                TextField("Enter note...", text: $noteInput)
                                    .font(.system(size: 16))
                                    .foregroundColor(.modernText)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.modernSecondary)
                                    )
                                    .onChange(of: noteInput) { newValue in
                                        let words = newValue.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                                        if words.count > 5 {
                                            noteInput = words.prefix(5).joined(separator: " ")
                                        }
                                    }
                            }
                        }
                    
                        Spacer()
                        
                        // Cost input (less prominent)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Ticket Cost")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.modernTextSecondary.opacity(0.7))
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Text("$")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.modernTextSecondary.opacity(0.7))
                                    
                                    TextField("25", text: $costInput)
                                        .font(.system(size: 14))
                                        .foregroundColor(.modernText)
                                        .frame(width: 50)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.modernSecondary.opacity(0.7))
                                        )
                                        .keyboardType(.decimalPad)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            Button {
                                var updatedSeat = seat
                                updatedSeat.status = selectedStatus
                                
                                if selectedStatus == .sold {
                                    updatedSeat.price = priceInput.isEmpty ? nil : Double(priceInput)
                                    updatedSeat.cost = Double(costInput) ?? settingsManager.defaultSeatCost
                                    updatedSeat.note = nil
                                    updatedSeat.source = selectedSource
                                    updatedSeat.familyPersonName = selectedSource == .family ? (familyPersonName.isEmpty ? nil : familyPersonName) : nil
                                    updatedSeat.dateSold = dateSold
                                    updatedSeat.datePaid = datePaid
                                    // Play ding sound effect
                                    playDingSound()
                                } else if selectedStatus == .reserved {
                                    updatedSeat.price = nil
                                    updatedSeat.cost = Double(costInput) ?? settingsManager.defaultSeatCost
                                    updatedSeat.note = noteInput.isEmpty ? nil : noteInput
                                    updatedSeat.source = nil
                                    updatedSeat.familyPersonName = nil
                                    updatedSeat.dateSold = nil
                                    updatedSeat.datePaid = nil
                                } else {
                                    updatedSeat.price = nil
                                    updatedSeat.cost = Double(costInput) ?? settingsManager.defaultSeatCost
                                    updatedSeat.note = nil
                                    updatedSeat.source = nil
                                    updatedSeat.familyPersonName = nil
                                    updatedSeat.dateSold = nil
                                    updatedSeat.datePaid = nil
                                }
                                
                                // Apply to current seat only
                                onUpdate(updatedSeat)
                                
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Update Seat")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedStatus.color)
                                )
                            }
                            
                            Button {
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                    Text("Cancel")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarHidden(true)
            .onAppear {
                // If seat is sold and source is family, set the price to family ticket price
                if selectedStatus == .sold && selectedSource == .family && priceInput.isEmpty {
                    priceInput = String(format: "%.0f", settingsManager.familyTicketPrice)
                }
            }
            .overlay(
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                            )
                    }
                }
                .padding()
                .padding(.top, 44)
                , alignment: .topTrailing
            )
        }
    }
    
    private func playDingSound() {
        AudioServicesPlaySystemSound(1054) // System ding sound
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
                                    .onChange(of: noteInput) { newValue in
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
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
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
                            }
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
    @State private var includeFutureConcerts = false
    
    private var hasSelectedElements: Bool {
        includeProfitAnalysis || includeConcertData || includePerformanceRankings || includeExecutiveSummary
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
    @State private var tempSuiteName: String = ""
    @State private var tempVenueLocation: String = ""
    @State private var tempFamilyTicketPrice: String = ""
    @State private var tempDefaultSeatCost: String = ""
    @State private var activeSheet: SheetType?
    @State private var joinSuiteId: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background that adapts to light/dark mode
                Color(.systemBackground)
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Settings")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.modernText)
                            
                            Text("Customize your suite experience")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.modernTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                        
                        // Suite Customization Section
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader("Suite Information")
                            
                            ConsistentCard(padding: 24) {
                                VStack(spacing: 24) {
                                // Suite Name
                                SettingsField(
                                    title: "Suite Name",
                                    subtitle: nil,
                                    placeholder: "Enter suite name",
                                    text: $tempSuiteName
                                ) {
                                    settingsManager.suiteName = tempSuiteName
                                }
                                
                                // Venue Location
                                SettingsField(
                                    title: "Venue Location",
                                    subtitle: nil,
                                    placeholder: "Enter venue location",
                                    text: $tempVenueLocation
                                ) {
                                    settingsManager.venueLocation = tempVenueLocation
                                }
                                
                                // Family Ticket Price
                                SettingsField(
                                    title: "Family Ticket Price",
                                    subtitle: "Default price automatically populated when 'Family' is selected as the ticket sale type",
                                    placeholder: "50",
                                    text: $tempFamilyTicketPrice,
                                    keyboardType: .numberPad,
                                    prefix: "$"
                                ) {
                                    if let price = Double(tempFamilyTicketPrice), price > 0 {
                                        settingsManager.familyTicketPrice = price
                                    }
                                }
                                .onChange(of: tempFamilyTicketPrice) { newValue in
                                    // Only allow numeric input
                                    let filtered = newValue.filter { "0123456789".contains($0) }
                                    if filtered != newValue {
                                        tempFamilyTicketPrice = filtered
                                    }
                                }
                                
                                // Default Seat Cost with integrated Apply button
                                SettingsField(
                                    title: "Default Seat Cost",
                                    subtitle: "Default price for new seats (still editable per seat)",
                                    placeholder: "25",
                                    text: $tempDefaultSeatCost,
                                    keyboardType: .numberPad,
                                    prefix: "$",
                                    actionButton: {
                                        AnyView(
                                            Button(action: {
                                                guard let newCost = Double(tempDefaultSeatCost), newCost >= 0 else { return }
                                                
                                                // Update all existing seats across all concerts
                                                for i in 0..<concertManager.concerts.count {
                                                    for j in 0..<concertManager.concerts[i].seats.count {
                                                        concertManager.concerts[i].seats[j].cost = newCost
                                                    }
                                                }
                                                
                                                // Save concerts to persist the changes
                                                concertManager.saveConcerts()
                                                
                                                // Also update the settings manager default
                                                settingsManager.defaultSeatCost = newCost
                                                
                                                // Haptic feedback
                                                HapticManager.shared.notification(type: .success)
                                            }) {
                                                VStack(spacing: 2) {
                                                    Image(systemName: "arrow.triangle.2.circlepath")
                                                        .font(.system(size: 16, weight: .semibold))
                                                    Text("Apply")
                                                        .font(.system(size: 11, weight: .semibold))
                                                    Text("to All")
                                                        .font(.system(size: 11, weight: .semibold))
                                                }
                                                .foregroundColor(.white)
                                                .frame(width: 60, height: 50)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(tempDefaultSeatCost.isEmpty || Double(tempDefaultSeatCost) == nil ? Color.gray.opacity(0.3) : Color.modernAccent)
                                                )
                                            }
                                            .disabled(tempDefaultSeatCost.isEmpty || Double(tempDefaultSeatCost) == nil)
                                        )
                                    }
                                ) {
                                    if let cost = Double(tempDefaultSeatCost), cost >= 0 {
                                        settingsManager.defaultSeatCost = cost
                                    }
                                }
                                .onChange(of: tempDefaultSeatCost) { newValue in
                                    // Only allow numeric input
                                    let filtered = newValue.filter { "0123456789".contains($0) }
                                    if filtered != newValue {
                                        tempDefaultSeatCost = filtered
                                    }
                                }
                                
                                }
                            }
                        }
                        
                        // Save Button
                        Button(action: {
                            settingsManager.suiteName = tempSuiteName
                            settingsManager.venueLocation = tempVenueLocation
                            if let price = Double(tempFamilyTicketPrice), price > 0 {
                                settingsManager.familyTicketPrice = price
                            }
                            if let cost = Double(tempDefaultSeatCost), cost >= 0 {
                                settingsManager.defaultSeatCost = cost
                            }
                            HapticManager.shared.notification(type: .success)
                            // Navigate back to dashboard
                            selectedTab = 0
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                Text("Save All Changes")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal)
                        
                        // Suite Sharing Section - Coming Soon
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Suite Sharing")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.modernText)
                                
                                Spacer()
                                
                                // Coming Soon Badge
                                Text("Coming Soon")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.orange)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Multi-investor collaboration")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.modernText)
                                
                                Text("Share your fire suite with co-investors, business partners, or investment group members. Coordinate ticket sales, track revenue distribution, and manage seat allocations across your investor network in real-time.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.modernTextSecondary)
                                    .multilineTextAlignment(.leading)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Real-time revenue tracking across all devices")
                                            .font(.system(size: 14))
                                            .foregroundColor(.modernTextSecondary)
                                    }
                                    
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Investor permissions (Owner, Partner, Viewer)")
                                            .font(.system(size: 14))
                                            .foregroundColor(.modernTextSecondary)
                                    }
                                    
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Secure investment data with iCloud protection")
                                            .font(.system(size: 14))
                                            .foregroundColor(.modernTextSecondary)
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.modernSecondary)
                        )
                        
                        // Data Storage Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Data Storage")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.modernText)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "iphone")
                                            .foregroundColor(.modernAccent)
                                        Text("Local Storage")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.modernText)
                                    }
                                    Text("Your concert data is stored locally on this device using secure UserDefaults with automatic backups")
                                        .font(.system(size: 14))
                                        .foregroundColor(.modernTextSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "icloud")
                                            .foregroundColor(.blue)
                                        Text("iCloud Sync")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.modernText)
                                    }
                                    Text("Data automatically syncs across all your Apple devices using your iCloud account. No data leaves Apple's ecosystem.")
                                        .font(.system(size: 14))
                                        .foregroundColor(.modernTextSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "lock.shield")
                                            .foregroundColor(.green)
                                        Text("Privacy & Security")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.modernText)
                                    }
                                    Text("All data remains private to you. We don't collect, access, or share any of your concert or suite information.")
                                        .font(.system(size: 14))
                                        .foregroundColor(.modernTextSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.modernSecondary)
                            )
                        }
                        
                        // Backup & Restore Section
                        BackupRestoreSection(concertManager: concertManager, settingsManager: settingsManager)
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("About")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.modernText)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Version")
                                        .font(.system(size: 14))
                                        .foregroundColor(.modernTextSecondary)
                                    Spacer()
                                    Text("1.0.0")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.modernText)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Developer")
                                        .font(.system(size: 14))
                                        .foregroundColor(.modernTextSecondary)
                                    Spacer()
                                    Text("Mike Myers")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.modernText)
                                }
                                
                                Divider()
                                
                                Button(action: {
                                    if let url = URL(string: "https://suitekeepsupport.netlify.app") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack {
                                        Text("Support & Manual")
                                            .font(.system(size: 14))
                                            .foregroundColor(.modernTextSecondary)
                                        Spacer()
                                        HStack(spacing: 4) {
                                            Text("Help Center")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.modernAccent)
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.modernAccent)
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.orange)
                                        Text("Disclaimer")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.modernText)
                                    }
                                    Text("This app is provided \"as is\" without any warranties. The developer makes no guarantees about the accuracy, reliability, or functionality of this software. Use at your own risk.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.modernTextSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.modernSecondary)
                            )
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                tempSuiteName = settingsManager.suiteName
                tempVenueLocation = settingsManager.venueLocation
                tempFamilyTicketPrice = String(format: "%.0f", settingsManager.familyTicketPrice)
                tempDefaultSeatCost = String(format: "%.0f", settingsManager.defaultSeatCost)
            }
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
        }
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
                        
                        Text("Enter the suite ID or paste a sharing link to join an existing shared suite.")
                            .font(.system(size: 16))
                            .foregroundColor(.modernTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suite ID or Sharing Link")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.modernText)
                        
                        TextField("Enter suite ID or paste link", text: $suiteId)
                            .font(.system(size: 16))
                            .foregroundColor(.modernText)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.modernSecondary)
                            )
                            .onChange(of: suiteId) { newValue in
                                // Extract suite ID from sharing link if needed
                                if newValue.hasPrefix("suitekeeper://join/") {
                                    suiteId = String(newValue.dropFirst("suitekeeper://join/".count))
                                }
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
        
        Task {
            do {
                try await sharedSuiteManager.joinSharedSuiteFromCloud(
                    suiteId: suiteId.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
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
                                            Text(suiteInfo.ownerId == sharedSuiteManager.currentUserId ? "You" : "Owner")
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
    let includeFutureConcerts: Bool
    
    static let all = ReportOptions(
        includeProfitAnalysis: true,
        includeConcertData: true,
        includePerformanceRankings: true,
        includeExecutiveSummary: true,
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
            let seatRevenue = concert.seats.compactMap { $0.price }.reduce(0.0, +)
            let parkingRevenue = concert.parkingTicket?.price ?? 0.0
            return total + seatRevenue + parkingRevenue
        }
        
        let totalCosts = analysisConcerts.reduce(0.0) { total, concert in
            let seatCosts = concert.seats.reduce(0.0) { $0 + ($1.cost ?? 0.0) }
            let parkingCost = concert.parkingTicket?.cost ?? 0.0
            return total + seatCosts + parkingCost
        }
        
        let netProfit = totalRevenue - totalCosts
        let occupancyRate = pastTotalSeats > 0 ? Double(pastTotalSoldSeats) / Double(pastTotalSeats) * 100.0 : 0.0
        let profitMargin = totalCosts > 0 ? (netProfit / totalCosts) * 100.0 : 0.0
        
        let analysisScope = includeFutureConcerts ? "all concerts (past and future)" : "past concerts only"
        csv += "Note: Financial metrics (Revenue/Costs/Profit/ROI/Averages) include \(analysisScope)\n"
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
            let seatRevenue = concert.seats.compactMap { $0.price }.reduce(0.0, +)
            let parkingRevenue = concert.parkingTicket?.price ?? 0.0
            let totalRevenue = seatRevenue + parkingRevenue
            
            let seatCosts = concert.seats.reduce(0.0) { $0 + ($1.cost ?? 0.0) }
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
                let profit = (seat.price ?? 0.0) - (seat.cost ?? 0.0)
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
            let seatRevenue = concert.seats.compactMap { $0.price }.reduce(0.0, +)
            let parkingRevenue = concert.parkingTicket?.price ?? 0.0
            let totalRevenue = seatRevenue + parkingRevenue
            
            let seatCosts = concert.seats.reduce(0.0) { $0 + ($1.cost ?? 0.0) }
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
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.white)
                            Text("Create Backup")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                    }
                    .disabled(backupInfo.count == 0)
                    
                    // Restore Backup Button
                    Button(action: { showingFilePicker = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.white)
                            Text("Restore from Backup")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange)
                        )
                    }
                    
                    // Clear All Data Button
                    Button(action: { showingClearDataAlert = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.white)
                            Text("Clear All Data")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red)
                        )
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
    }
}

#Preview {
    DynamicFireSuiteApp()
}
