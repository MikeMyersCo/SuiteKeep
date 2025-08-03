//
//  DynamicFireSuiteApp.swift
//  SuiteKeep
//
//  Created by Mike Myers on 7/30/25.
//

import SwiftUI
import AVFoundation


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
    
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
            NSUbiquitousKeyValueStore.default.set(isDarkMode, forKey: "isDarkMode")
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
        self.isDarkMode = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool ?? true
        
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
        if let iCloudDarkMode = NSUbiquitousKeyValueStore.default.object(forKey: "isDarkMode") as? Bool {
            self.isDarkMode = iCloudDarkMode
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
        if let iCloudDarkMode = NSUbiquitousKeyValueStore.default.object(forKey: "isDarkMode") as? Bool {
            self.isDarkMode = iCloudDarkMode
        }
    }
}

// MARK: - Vibrant Color Theme
extension Color {
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
    static let cardPink = LinearGradient(colors: [Color(red: 0.9, green: 0.1, blue: 0.5), Color(red: 1.0, green: 0.3, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardGreen = LinearGradient(colors: [Color(red: 0.1, green: 0.7, blue: 0.3), Color(red: 0.2, green: 0.8, blue: 0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardIndigo = LinearGradient(colors: [Color(red: 0.2, green: 0.3, blue: 0.8), Color(red: 0.3, green: 0.4, blue: 0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
    
    // Modern colors with engagement focus
    static let modernBackground = Color(red: 0.96, green: 0.97, blue: 1.0)
    static let modernSecondary = Color(red: 0.25, green: 0.25, blue: 0.3)
    static let modernAccent = Color(red: 0.0, green: 0.7, blue: 1.0) // Bright blue
    static let modernText = Color.white
    static let modernTextSecondary = Color(white: 0.85)
    static let modernSuccess = Color(red: 0.1, green: 0.8, blue: 0.4) // Brighter green
    static let modernWarning = Color(red: 1.0, green: 0.6, blue: 0.0) // Warmer orange
    static let modernDanger = Color(red: 1.0, green: 0.3, blue: 0.4) // Softer red
    
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
                    Text("Fire Suite")
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
                    
                    Text("Management System")
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

// Fire particle effect
struct FireParticle: View {
    @State private var offset = CGSize(width: CGFloat.random(in: -200...200), height: 600)
    let delay: Double
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.fireOrange,
                        Color.fireOrange.opacity(0.5),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 20
                )
            )
            .frame(width: CGFloat.random(in: 4...12), height: CGFloat.random(in: 4...12))
            .offset(offset)
            .blur(radius: 1)
            .onAppear {
                withAnimation(
                    .linear(duration: Double.random(in: 8...15))
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    offset = CGSize(
                        width: CGFloat.random(in: -200...200),
                        height: -700
                    )
                }
            }
    }
}

struct DynamicFireSuiteApp: View {
    @State private var selectedTab = 0
    @State private var animateFlames = true
    @State private var isShowingSplash = true
    @StateObject private var concertManager = ConcertDataManager()
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some View {
        ZStack {
            if isShowingSplash {
                SplashScreenView(isShowingSplash: $isShowingSplash)
                    .transition(.opacity)
            } else {
        TabView(selection: $selectedTab) {
            DynamicDashboard(concerts: $concertManager.concerts, concertManager: concertManager, settingsManager: settingsManager)
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
            
            SettingsView(settingsManager: settingsManager, selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.modernAccent)
        .onAppear {
            startFlameAnimation()
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
    @State private var pulseFirepit = false
    @State private var rotateValue: Double = 0
    @State private var selectedConcert: Concert?
    @Binding var concerts: [Concert]
    @ObservedObject var concertManager: ConcertDataManager
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // Consistent dark gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.12, blue: 0.2),
                        Color(red: 0.12, green: 0.1, blue: 0.18),
                        Color(red: 0.08, green: 0.08, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
            .sheet(item: $selectedConcert) { concert in
                ConcertDetailView(
                    concert: concert,
                    concertManager: concertManager,
                    settingsManager: settingsManager
                )
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
        guard !concerts.isEmpty else { return 0 }
        let totalOccupancy = concerts.reduce(0) { $0 + $1.ticketsSold }
        return Int((Double(totalOccupancy) / Double(concerts.count * 8)) * 100)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Key Metrics Cards with Beautiful Gradients
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                MetricCard(
                    title: "Total Sold",
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
        let sortedConcerts = concerts.sorted { $0.date < $1.date }
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
                    .lineLimit(1)
                
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
                .fill(LinearGradient(colors: [.white.opacity(0.1), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
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
    @ObservedObject var concertManager: ConcertDataManager
    @ObservedObject var settingsManager: SettingsManager
    @State private var showingAddConcert = false
    @State private var showingAllConcerts = false
    
    var upcomingConcerts: [Concert] {
        let twoWeeksFromNow = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
        return concertManager.concerts.filter { $0.date <= twoWeeksFromNow && $0.date >= Date() }
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Consistent dark gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.12, blue: 0.2),
                        Color(red: 0.12, green: 0.1, blue: 0.18),
                        Color(red: 0.08, green: 0.08, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Concerts")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.modernText)
                            
                            Text("Manage upcoming performances")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.modernTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                showingAddConcert = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Concert")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.modernAccent)
                                )
                            }
                            
                            Button(action: {
                                showingAllConcerts = true
                            }) {
                                HStack {
                                    Image(systemName: "list.bullet")
                                    Text("View All")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.modernAccent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.modernAccent, lineWidth: 2)
                                )
                            }
                        }
                        
                        // Section Header
                        HStack {
                            Text("Next 2 Weeks")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.modernText)
                            Spacer()
                            Text("\(upcomingConcerts.count) concerts")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.modernTextSecondary)
                        }
                        
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
            .sheet(isPresented: $showingAddConcert) {
                AddConcertView { newConcert in
                    concertManager.addConcert(newConcert)
                }
            }
            .sheet(isPresented: $showingAllConcerts) {
                AllConcertsView(concertManager: concertManager, settingsManager: settingsManager)
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
        case .available: return ""
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
    case other = "Other"
}

// MARK: - Seat Model
struct Seat: Codable {
    var status: SeatStatus
    var price: Double?
    var note: String? // For reserved seats - max 5 words
    var source: TicketSource? // For sold seats - ticket source
    var cost: Double? // Cost per ticket (default $25)
    var dateSold: Date? // Date when ticket was sold
    var datePaid: Date? // Date when payment was received
    
    init(status: SeatStatus = .available, price: Double? = nil, note: String? = nil, source: TicketSource? = nil, cost: Double? = nil, dateSold: Date? = nil, datePaid: Date? = nil) {
        self.status = status
        self.price = price
        self.note = note
        self.source = source
        self.cost = cost ?? 25.0
        self.dateSold = dateSold
        self.datePaid = datePaid
    }
}

// MARK: - Parking Ticket Model
struct ParkingTicket: Codable {
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
struct Concert: Identifiable, Codable {
    let id: Int
    var artist: String
    var date: Date
    var seats: [Seat] // Array of 8 seats
    var parkingTicket: ParkingTicket? // One parking ticket per show
    
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
            seat.status == .sold ? (seat.cost ?? 25.0) : nil
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
    
    init(id: Int, artist: String, date: Date, seats: [Seat] = Array(repeating: Seat(), count: 8), parkingTicket: ParkingTicket? = ParkingTicket()) {
        self.id = id
        self.artist = artist
        self.date = date
        self.seats = seats
        self.parkingTicket = parkingTicket
    }
}

// MARK: - Concert Data Manager
class ConcertDataManager: ObservableObject {
    @Published var concerts: [Concert] = []
    
    private let userDefaults = UserDefaults.standard
    private let iCloudStore = NSUbiquitousKeyValueStore.default
    private let concertsKey = "SavedConcerts"
    private var iCloudObserver: NSObjectProtocol?
    
    init() {
        setupiCloudSync()
        migrateDataIfNeeded()
        loadConcerts()
    }
    
    private func migrateDataIfNeeded() {
        let currentVersion = 1 // Increment this when data structure changes
        let versionKey = "dataVersion"
        let lastVersion = userDefaults.integer(forKey: versionKey)
        
        if lastVersion < currentVersion {
            print("Migrating data from version \(lastVersion) to \(currentVersion)")
            
            // Add migration logic here for future versions
            switch lastVersion {
            case 0:
                // Initial version, no migration needed
                break
            default:
                break
            }
            
            userDefaults.set(currentVersion, forKey: versionKey)
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
                print("Successfully loaded \(concerts.count) concerts")
            }
        } catch {
            print("Failed to load concerts: \(error)")
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
            
            print("Successfully saved \(concerts.count) concerts")
        } catch {
            print("Failed to save concerts: \(error)")
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
            print("Failed to save to local storage: \(error)")
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
            print("Recovered \(concerts.count) concerts from backup")
        }
    }
    
    func addConcert(_ concert: Concert) {
        concerts.append(concert)
        saveConcerts()
    }
    
    func updateConcert(_ concert: Concert) {
        if let index = concerts.firstIndex(where: { $0.id == concert.id }) {
            concerts[index] = concert
            saveConcerts()
        }
    }
    
    func deleteConcert(_ concert: Concert) {
        concerts.removeAll { $0.id == concert.id }
        saveConcerts()
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
    
    let onSave: (Concert) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Consistent dark gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.12, blue: 0.2),
                        Color(red: 0.12, green: 0.1, blue: 0.18),
                        Color(red: 0.08, green: 0.08, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
                            let newConcert = Concert(
                                id: Int.random(in: 1000...9999),
                                artist: artist,
                                date: selectedDate
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
    
    var sortedConcerts: [Concert] {
        concertManager.concerts.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Consistent dark gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.12, blue: 0.2),
                        Color(red: 0.12, green: 0.1, blue: 0.18),
                        Color(red: 0.08, green: 0.08, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
                                // Spacer for the overlay buttons (44 + padding)
                                Color.clear.frame(height: 70)
                                
                                // Header Card
                                VStack(spacing: 8) {
                                    Text("All Concerts")
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                        .foregroundColor(.modernText)
                                    
                                    Text("\(sortedConcerts.count) total concerts")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.modernTextSecondary)
                                    
                                    // Debug: Show all concert names and IDs
                                }
                                .padding(.vertical, 20)
                                .padding(.horizontal, 24)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.modernSecondary)
                                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                )
                            }
                            .padding(.top, 20)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(Array(sortedConcerts.enumerated()), id: \.offset) { index, concert in
                                    NavigationLink(destination: ConcertDetailView(concert: concert, concertManager: concertManager, settingsManager: settingsManager)) {
                                        ConcertRowView(concert: concert)
                                    }
                                    .buttonStyle(PlainButtonStyle())
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
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Done")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.modernAccent)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingAddConcert = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.modernAccent)
                    }
                    .scaleEffect(1.0)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            // Scale effect will be handled by buttonStyle
                        }
                    }
                    .buttonStyle(HoverableButtonStyle())
                }
                .padding()
                .padding(.top, 44)
                , alignment: .top
            )
            .sheet(isPresented: $showingAddConcert) {
                AddConcertView { newConcert in
                    concertManager.addConcert(newConcert)
                }
            }
        }
    }
}

// MARK: - Concert Detail View
struct ConcertDetailView: View {
    @State var concert: Concert
    @ObservedObject var concertManager: ConcertDataManager
    @ObservedObject var settingsManager: SettingsManager
    @State private var showingAllConcerts = false
    @State private var showingDeleteConfirmation = false
    @State private var isEditingDetails = false
    @State private var editedArtist = ""
    @State private var editedDate = Date()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Consistent dark gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.15, green: 0.12, blue: 0.2),
                    Color(red: 0.12, green: 0.1, blue: 0.18),
                    Color(red: 0.08, green: 0.08, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
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
                        
                        HStack(spacing: 12) {
                            Button {
                                showingAllConcerts = true
                            } label: {
                                HStack {
                                    Image(systemName: "list.bullet")
                                    Text("List")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.modernAccent)
                            }
                            
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
                    .padding(.top, 20)
                    
                    // Concert Header Card
                    VStack(spacing: 16) {
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
                            VStack(spacing: 16) {
                                TextField("Artist Name", text: $editedArtist)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.modernText)
                                    .multilineTextAlignment(.center)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
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
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.modernText)
                            
                            VStack(spacing: 8) {
                                Text(concert.date, style: .date)
                                    .font(.system(size: 16))
                                    .foregroundColor(.modernTextSecondary)
                                
                                VStack(spacing: 4) {
                                    HStack {
                                        Circle()
                                            .fill(concert.ticketsSold == 8 ? Color.modernSuccess : Color.modernWarning)
                                            .frame(width: 8, height: 8)
                                        Text("\(concert.ticketsSold)/8 tickets sold")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(concert.ticketsSold == 8 ? .modernSuccess : .modernWarning)
                                    }
                                    
                                    if concert.ticketsReserved > 0 {
                                        HStack {
                                            Circle()
                                                .fill(Color.cyan)
                                                .frame(width: 8, height: 8)
                                            Text("\(concert.ticketsReserved) reserved")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.cyan)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.modernSecondary)
                    )
                    
                    // Interactive Fire Suite Layout for seat selection
                    InteractiveFireSuiteView(concert: $concert, concertManager: concertManager, settingsManager: settingsManager)
                }
                .padding(.horizontal)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAllConcerts) {
            AllConcertsView(concertManager: concertManager, settingsManager: settingsManager)
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
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            VStack(spacing: 8) {
                Text("\(settingsManager.suiteName) Seating")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.modernText)
                
                Text("Tap seats to manage tickets")
                    .font(.system(size: 14))
                    .foregroundColor(.modernTextSecondary)
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
                                    onTap: { selectSeat(5) }
                                )
                                InteractiveSeatView(
                                    seatNumber: 5,
                                    seat: concert.seats[4],
                                    onTap: { selectSeat(4) }
                                )
                                InteractiveSeatView(
                                    seatNumber: 4,
                                    seat: concert.seats[3],
                                    onTap: { selectSeat(3) }
                                )
                                InteractiveSeatView(
                                    seatNumber: 3,
                                    seat: concert.seats[2],
                                    onTap: { selectSeat(2) }
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
                                    onTap: { selectSeat(7) }
                                )
                                .offset(y: -24) // Move seat 8 up for consistent spacing
                                InteractiveSeatView(
                                    seatNumber: 7,
                                    seat: concert.seats[6],
                                    onTap: { selectSeat(6) }
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
                                    onTap: { selectSeat(0) }
                                )
                                .offset(y: -24) // Move seat 1 up for consistent spacing
                                InteractiveSeatView(
                                    seatNumber: 2,
                                    seat: concert.seats[1],
                                    onTap: { selectSeat(1) }
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
        .sheet(isPresented: $showingSeatOptions) {
            SeatOptionsView(
                seatNumber: (selectedSeatIndex ?? 0) + 1,
                seat: selectedSeatIndex != nil ? concert.seats[selectedSeatIndex!] : Seat(),
                onUpdate: { updatedSeat in
                    if let index = selectedSeatIndex {
                        concert.seats[index] = updatedSeat
                        concertManager.updateConcert(concert)
                    }
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
    
    private func selectSeat(_ index: Int) {
        selectedSeatIndex = index
        priceInput = concert.seats[index].price != nil ? String(concert.seats[index].price!) : ""
        showingSeatOptions = true
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
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
    let onTap: () -> Void
    @State private var isPressed = false
    @State private var isAnimating = false
    @State private var isHovering = false
    
    var seatColor: LinearGradient {
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
                        
                        // Show status icon in top-right corner for sold/reserved
                        if seat.status == .sold {
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
                    
                    Text(seat.source?.rawValue ?? "")
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
}

// MARK: - Seat Options View
struct SeatOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsManager: SettingsManager
    let seatNumber: Int
    @State var seat: Seat
    let onUpdate: (Seat) -> Void
    let onUpdateAll: ((Seat) -> Void)?
    
    @State private var selectedStatus: SeatStatus
    @State private var priceInput: String
    @State private var costInput: String
    @State private var noteInput: String
    @State private var selectedSource: TicketSource
    @State private var dateSold: Date
    @State private var datePaid: Date
    @State private var applyToAllSeats = false
    
    init(seatNumber: Int, seat: Seat, onUpdate: @escaping (Seat) -> Void, onUpdateAll: ((Seat) -> Void)? = nil) {
        self.seatNumber = seatNumber
        self.seat = seat
        self.onUpdate = onUpdate
        self.onUpdateAll = onUpdateAll
        self._selectedStatus = State(initialValue: seat.status)
        self._priceInput = State(initialValue: seat.price != nil ? String(seat.price!) : "")
        self._costInput = State(initialValue: String(seat.cost ?? 25.0))
        self._noteInput = State(initialValue: seat.note ?? "")
        self._selectedSource = State(initialValue: seat.source ?? .facebook)
        self._dateSold = State(initialValue: seat.dateSold ?? Date())
        self._datePaid = State(initialValue: seat.datePaid ?? Date())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Consistent dark gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.12, blue: 0.2),
                        Color(red: 0.12, green: 0.1, blue: 0.18),
                        Color(red: 0.08, green: 0.08, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
                                VStack(alignment: .leading, spacing: 8) {
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
                                    .onChange(of: selectedSource) { _, newSource in
                                        // Auto-set price for family tickets
                                        if newSource == .family {
                                            priceInput = String(format: "%.0f", settingsManager.familyTicketPrice)
                                        }
                                    }
                                }
                                
                                // Date fields (only for sold status)
                                VStack(spacing: 16) {
                                    // Date Sold
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Date Sold")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.modernTextSecondary)
                                        
                                        DatePicker("", selection: $dateSold, displayedComponents: .date)
                                            .datePickerStyle(.compact)
                                            .colorScheme(.dark)
                                            .padding(12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.modernSecondary)
                                            )
                                    }
                                    
                                    // Date Paid
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Date Paid")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.modernTextSecondary)
                                        
                                        DatePicker("", selection: $datePaid, displayedComponents: .date)
                                            .datePickerStyle(.compact)
                                            .colorScheme(.dark)
                                            .padding(12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.modernSecondary)
                                            )
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
                                    .onChange(of: noteInput) { _, newValue in
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
                        
                        // Apply to all seats checkbox
                        if selectedStatus == .sold || selectedStatus == .reserved {
                            HStack {
                                Button(action: {
                                    applyToAllSeats.toggle()
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: applyToAllSeats ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 20))
                                            .foregroundColor(applyToAllSeats ? .modernAccent : .modernTextSecondary)
                                        
                                        Text("Apply to all seats")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.modernText)
                                        
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.modernSecondary.opacity(0.7))
                                )
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        }
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            Button {
                                var updatedSeat = seat
                                updatedSeat.status = selectedStatus
                                
                                if selectedStatus == .sold {
                                    updatedSeat.price = priceInput.isEmpty ? nil : Double(priceInput)
                                    updatedSeat.cost = Double(costInput) ?? 25.0
                                    updatedSeat.note = nil
                                    updatedSeat.source = selectedSource
                                    updatedSeat.dateSold = dateSold
                                    updatedSeat.datePaid = datePaid
                                    // Play ding sound effect
                                    playDingSound()
                                } else if selectedStatus == .reserved {
                                    updatedSeat.price = nil
                                    updatedSeat.cost = Double(costInput) ?? 25.0
                                    updatedSeat.note = noteInput.isEmpty ? nil : noteInput
                                    updatedSeat.source = nil
                                    updatedSeat.dateSold = nil
                                    updatedSeat.datePaid = nil
                                } else {
                                    updatedSeat.price = nil
                                    updatedSeat.cost = Double(costInput) ?? 25.0
                                    updatedSeat.note = nil
                                    updatedSeat.source = nil
                                    updatedSeat.dateSold = nil
                                    updatedSeat.datePaid = nil
                                }
                                
                                if applyToAllSeats && (selectedStatus == .sold || selectedStatus == .reserved), let updateAllCallback = onUpdateAll {
                                    // Apply to all seats
                                    updateAllCallback(updatedSeat)
                                } else {
                                    // Apply to current seat only
                                    onUpdate(updatedSeat)
                                }
                                
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
                                .foregroundColor(.modernTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
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
                            .foregroundColor(.modernTextSecondary)
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
        self._priceInput = State(initialValue: parkingTicket.price != nil ? String(parkingTicket.price!) : "")
        self._costInput = State(initialValue: String(parkingTicket.cost ?? 0.0))
        self._noteInput = State(initialValue: parkingTicket.note ?? "")
        self._selectedSource = State(initialValue: parkingTicket.source ?? .facebook)
        self._dateSold = State(initialValue: parkingTicket.dateSold ?? Date())
        self._datePaid = State(initialValue: parkingTicket.datePaid ?? Date())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Consistent dark gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.12, blue: 0.2),
                        Color(red: 0.12, green: 0.1, blue: 0.18),
                        Color(red: 0.08, green: 0.08, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
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
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Consistent dark gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.12, blue: 0.2),
                        Color(red: 0.12, green: 0.1, blue: 0.18),
                        Color(red: 0.08, green: 0.08, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
                            showingShareSheet: $showingShareSheet
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingShareSheet) {
                if let reportURL = generatedReportURL {
                    ShareSheet(activityItems: [reportURL])
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
    @Binding var showingShareSheet: Bool
    @State private var animateIcon = false
    
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
            
            // Report Features
            VStack(spacing: 16) {
                ReportFeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Profit Analysis",
                    description: "Detailed revenue, costs, and profit margins"
                )
                
                ReportFeatureRow(
                    icon: "tablecells",
                    title: "Concert Data",
                    description: "Complete seat-by-seat sales information"
                )
                
                ReportFeatureRow(
                    icon: "trophy",
                    title: "Performance Rankings",
                    description: "Top performing concerts and revenue sources"
                )
                
                ReportFeatureRow(
                    icon: "percent",
                    title: "Executive Summary",
                    description: "Key metrics and occupancy statistics"
                )
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
            .disabled(isGenerating || concerts.isEmpty)
            .buttonStyle(HoverableButtonStyle())
            
            if concerts.isEmpty {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)
                    Text("Add concerts to generate reports")
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
            let reportFileURL = ReportGenerator.shared.generateComprehensiveReportFile(
                concerts: concerts,
                settingsManager: settingsManager
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Small delay for UX
                self.generatedReportURL = reportFileURL
                self.isGenerating = false
                if reportFileURL != nil {
                    self.showingShareSheet = true
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
    @Binding var selectedTab: Int
    @State private var tempSuiteName: String = ""
    @State private var tempVenueLocation: String = ""
    @State private var tempFamilyTicketPrice: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Consistent dark gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.12, blue: 0.2),
                        Color(red: 0.12, green: 0.1, blue: 0.18),
                        Color(red: 0.08, green: 0.08, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
                            Text("Suite Information")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.modernText)
                            
                            VStack(spacing: 20) {
                                // Suite Name
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Suite Name")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.modernTextSecondary)
                                    
                                    TextField("Enter suite name", text: $tempSuiteName)
                                        .font(.system(size: 16))
                                        .foregroundColor(.modernText)
                                        .padding(16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.modernSecondary)
                                        )
                                        .onSubmit {
                                            settingsManager.suiteName = tempSuiteName
                                        }
                                }
                                
                                // Venue Location
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Venue Location")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.modernTextSecondary)
                                    
                                    TextField("Enter venue location", text: $tempVenueLocation)
                                        .font(.system(size: 16))
                                        .foregroundColor(.modernText)
                                        .padding(16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.modernSecondary)
                                        )
                                        .onSubmit {
                                            settingsManager.venueLocation = tempVenueLocation
                                        }
                                }
                                
                                // Family Ticket Price
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Family Ticket Price")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.modernTextSecondary)
                                    
                                    HStack {
                                        Text("$")
                                            .font(.system(size: 16))
                                            .foregroundColor(.modernTextSecondary)
                                        
                                        TextField("50", text: $tempFamilyTicketPrice)
                                            .font(.system(size: 16))
                                            .foregroundColor(.modernText)
                                            .keyboardType(.numberPad)
                                            .padding(16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.modernSecondary)
                                            )
                                            .onSubmit {
                                                if let price = Double(tempFamilyTicketPrice), price > 0 {
                                                    settingsManager.familyTicketPrice = price
                                                }
                                            }
                                            .onChange(of: tempFamilyTicketPrice) { _, newValue in
                                                // Only allow numeric input
                                                let filtered = newValue.filter { "0123456789".contains($0) }
                                                if filtered != newValue {
                                                    tempFamilyTicketPrice = filtered
                                                }
                                            }
                                    }
                                }
                                
                                // Theme Toggle
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Appearance")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.modernTextSecondary)
                                    
                                    HStack {
                                        Image(systemName: settingsManager.isDarkMode ? "moon.fill" : "sun.max.fill")
                                            .foregroundColor(settingsManager.isDarkMode ? .purple : .orange)
                                            .font(.system(size: 16))
                                        
                                        Text(settingsManager.isDarkMode ? "Dark Mode" : "Light Mode")
                                            .font(.system(size: 16))
                                            .foregroundColor(.modernText)
                                        
                                        Spacer()
                                        
                                        Toggle("", isOn: $settingsManager.isDarkMode)
                                            .labelsHidden()
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.modernSecondary)
                                    )
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.modernSecondary)
                            )
                        }
                        
                        // Save Button
                        Button(action: {
                            settingsManager.suiteName = tempSuiteName
                            settingsManager.venueLocation = tempVenueLocation
                            if let price = Double(tempFamilyTicketPrice), price > 0 {
                                settingsManager.familyTicketPrice = price
                            }
                            // Navigate back to dashboard
                            selectedTab = 0
                        }) {
                            Text("Save Changes")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.modernAccent)
                                )
                        }
                        
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
            }
        }
    }
}

// MARK: - Report Generator Service
class ReportGenerator {
    static let shared = ReportGenerator()
    
    private init() {}
    
    func generateComprehensiveReportFile(concerts: [Concert], settingsManager: SettingsManager) -> URL? {
        let csvContent = generateComprehensiveReport(concerts: concerts, settingsManager: settingsManager)
        
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
            print("Failed to write CSV file: \(error)")
            return nil
        }
    }
    
    func generateComprehensiveReport(concerts: [Concert], settingsManager: SettingsManager) -> String {
        var csv = ""
        
        // Header with report metadata
        csv += "SuiteKeep Concert Management Report\n"
        csv += "Generated: \(DateFormatter.reportHeader.string(from: Date()))\n"
        csv += "Suite: \(settingsManager.suiteName)\n"
        csv += "Venue: \(settingsManager.venueLocation)\n\n"
        
        // Executive Summary
        csv += generateExecutiveSummary(concerts: concerts)
        csv += "\n"
        
        // Concert Overview
        csv += generateConcertOverview(concerts: concerts)
        csv += "\n"
        
        // Detailed Seat Data
        csv += generateDetailedSeatData(concerts: concerts)
        csv += "\n"
        
        // Profit Analysis
        csv += generateProfitAnalysis(concerts: concerts)
        
        return csv
    }
    
    private func generateExecutiveSummary(concerts: [Concert]) -> String {
        var csv = "=== EXECUTIVE SUMMARY ===\n"
        
        // Filter to only include concerts that have already happened for financial metrics
        let currentDate = Date()
        let pastConcerts = concerts.filter { $0.date <= currentDate }
        
        // Basic counts include ALL concerts (past and future)
        let totalConcerts = concerts.count
        let totalSeats = concerts.reduce(0) { $0 + $1.seats.count }
        let totalSoldSeats = concerts.reduce(0) { $0 + $1.ticketsSold }
        let totalReservedSeats = concerts.reduce(0) { $0 + $1.ticketsReserved }
        
        let totalRevenue = pastConcerts.reduce(0.0) { total, concert in
            let seatRevenue = concert.seats.compactMap { $0.price }.reduce(0.0, +)
            let parkingRevenue = concert.parkingTicket?.price ?? 0.0
            return total + seatRevenue + parkingRevenue
        }
        
        let totalCosts = pastConcerts.reduce(0.0) { total, concert in
            let seatCosts = concert.seats.reduce(0.0) { $0 + ($1.cost ?? 0.0) }
            let parkingCost = concert.parkingTicket?.cost ?? 0.0
            return total + seatCosts + parkingCost
        }
        
        let netProfit = totalRevenue - totalCosts
        let occupancyRate = totalSeats > 0 ? Double(totalSoldSeats) / Double(totalSeats) * 100.0 : 0.0
        let profitMargin = totalCosts > 0 ? (netProfit / totalCosts) * 100.0 : 0.0
        
        csv += "Note: Financial metrics (Revenue/Costs/Profit/ROI/Averages) include past concerts only\n"
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
        csv += "Average Profit per Concert (Past Shows Only),\(formatCurrency(pastConcerts.count > 0 ? netProfit / Double(pastConcerts.count) : 0.0))\n"
        
        return csv
    }
    
    private func generateConcertOverview(concerts: [Concert]) -> String {
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
        csv += "Concert,Date,Seat Number,Status,Price,Cost,Source,Date Sold,Date Paid,Profit\n"
        
        let sortedConcerts = concerts.sorted { $0.date < $1.date }
        
        for concert in sortedConcerts {
            for (index, seat) in concert.seats.enumerated() {
                let seatNumber = index + 1
                let profit = (seat.price ?? 0.0) - (seat.cost ?? 0.0)
                let source = seat.source?.rawValue ?? ""
                let dateSold = seat.dateSold.map { DateFormatter.reportDate.string(from: $0) } ?? ""
                let datePaid = seat.datePaid.map { DateFormatter.reportDate.string(from: $0) } ?? ""
                
                csv += "\"\(concert.artist)\",\(DateFormatter.reportDate.string(from: concert.date)),\(seatNumber),\(seat.status.rawValue.capitalized),\(seat.price.map(formatCurrency) ?? ""),\(formatCurrency(seat.cost ?? 0.0)),\(source),\(dateSold),\(datePaid),\(formatCurrency(profit))\n"
            }
            
            // Add parking ticket data if available
            if let parking = concert.parkingTicket {
                let profit = (parking.price ?? 0.0) - (parking.cost ?? 0.0)
                let dateSold = parking.dateSold.map { DateFormatter.reportDate.string(from: $0) } ?? ""
                let datePaid = parking.datePaid.map { DateFormatter.reportDate.string(from: $0) } ?? ""
                
                csv += "\"\(concert.artist)\",\(DateFormatter.reportDate.string(from: concert.date)),Parking,\(parking.status.rawValue.capitalized),\(parking.price.map(formatCurrency) ?? ""),\(formatCurrency(parking.cost ?? 0.0)),,\(dateSold),\(datePaid),\(formatCurrency(profit))\n"
            }
        }
        
        return csv
    }
    
    private func generateProfitAnalysis(concerts: [Concert]) -> String {
        var csv = "=== PROFIT ANALYSIS ===\n"
        csv += "Note: Analysis includes past concerts only\n\n"
        
        // Filter to only include concerts that have already happened
        let currentDate = Date()
        let pastConcerts = concerts.filter { $0.date <= currentDate }
        
        // Performance rankings
        var concertPerformance: [(String, Double, Double)] = []
        
        for concert in pastConcerts {
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
        
        for concert in concerts {
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

#Preview {
    DynamicFireSuiteApp()
}
