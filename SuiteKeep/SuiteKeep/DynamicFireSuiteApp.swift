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
    
    private var iCloudObserver: NSObjectProtocol?
    
    init() {
        // Load from local first
        self.suiteName = UserDefaults.standard.string(forKey: "suiteName") ?? "Fire Suite"
        self.venueLocation = UserDefaults.standard.string(forKey: "venueLocation") ?? "Ford Amphitheater"
        
        // Check iCloud for newer values
        if let iCloudSuiteName = NSUbiquitousKeyValueStore.default.string(forKey: "suiteName") {
            self.suiteName = iCloudSuiteName
        }
        if let iCloudVenueLocation = NSUbiquitousKeyValueStore.default.string(forKey: "venueLocation") {
            self.venueLocation = iCloudVenueLocation
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
    }
}

// MARK: - Vibrant Color Theme
extension Color {
    // Beautiful gradient backgrounds
    static let primaryGradientStart = Color(red: 0.2, green: 0.1, blue: 0.9) // Deep purple
    static let primaryGradientEnd = Color(red: 0.8, green: 0.2, blue: 0.9) // Magenta
    static let secondaryGradientStart = Color(red: 0.0, green: 0.7, blue: 1.0) // Bright blue
    static let secondaryGradientEnd = Color(red: 0.0, green: 0.9, blue: 0.6) // Teal
    
    // Card gradient colors
    static let cardPurple = LinearGradient(colors: [Color(red: 0.4, green: 0.2, blue: 0.8), Color(red: 0.6, green: 0.3, blue: 0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardBlue = LinearGradient(colors: [Color(red: 0.1, green: 0.4, blue: 0.9), Color(red: 0.2, green: 0.6, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardTeal = LinearGradient(colors: [Color(red: 0.0, green: 0.7, blue: 0.7), Color(red: 0.1, green: 0.8, blue: 0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardOrange = LinearGradient(colors: [Color(red: 1.0, green: 0.4, blue: 0.1), Color(red: 1.0, green: 0.6, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardPink = LinearGradient(colors: [Color(red: 0.9, green: 0.1, blue: 0.5), Color(red: 1.0, green: 0.3, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardGreen = LinearGradient(colors: [Color(red: 0.1, green: 0.7, blue: 0.3), Color(red: 0.2, green: 0.8, blue: 0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
    
    // Modern colors (keeping some for compatibility)
    static let modernBackground = Color(red: 0.96, green: 0.97, blue: 1.0)
    static let modernSecondary = Color(red: 0.25, green: 0.25, blue: 0.3)
    static let modernAccent = Color(red: 0.3, green: 0.2, blue: 0.9)
    static let modernText = Color.white
    static let modernTextSecondary = Color(white: 0.85)
    static let modernSuccess = Color(red: 0.1, green: 0.7, blue: 0.3)
    static let modernWarning = Color(red: 1.0, green: 0.5, blue: 0.0)
    static let modernDanger = Color(red: 1.0, green: 0.2, blue: 0.3)
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
            DynamicDashboard(concerts: $concertManager.concerts, settingsManager: settingsManager)
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
            
            DynamicAnalytics(concerts: $concertManager.concerts)
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
    @Binding var concerts: [Concert]
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
                        RecentActivityFeed(concerts: concerts)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
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
        VStack(spacing: 12) {
            // Icon with gradient background - centered
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .scaleEffect(animateValue ? 1.05 : 1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateValue)
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(12)
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
                            colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
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
                                .foregroundColor(.purple)
                            Text("STAGE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
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
    @State private var animateRows = false
    
    var recentActivities: [(String, String, String, String, LinearGradient)] {
        let sortedConcerts = concerts.sorted { $0.date > $1.date }.prefix(4)
        return sortedConcerts.map { concert in
            let timeAgo = timeAgoString(from: concert.date)
            let icon = concert.ticketsSold == 8 ? "checkmark.seal.fill" : (concert.ticketsSold > 0 ? "ticket.fill" : "music.note")
            let subtitle = concert.ticketsSold == 8 ? "Sold out!" : "Tickets sold: \(concert.ticketsSold)/8"
            let gradient: LinearGradient = concert.ticketsSold == 8 ? Color.cardGreen : (concert.ticketsSold > 0 ? Color.cardOrange : Color.cardPink)
            
            return (icon, concert.artist, subtitle, timeAgo, gradient)
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
                            gradient: activity.4
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
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed.toggle()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed.toggle()
                }
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
                AllConcertsView(concertManager: concertManager)
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
    
    init(status: SeatStatus = .available, price: Double? = nil, note: String? = nil, source: TicketSource? = nil, cost: Double? = nil) {
        self.status = status
        self.price = price
        self.note = note
        self.source = source
        self.cost = cost ?? 25.0
    }
}

// MARK: - Concert Model
struct Concert: Identifiable, Codable {
    let id: Int
    let artist: String
    let date: Date
    var seats: [Seat] // Array of 8 seats
    
    var ticketsSold: Int {
        seats.filter { $0.status == .sold }.count
    }
    
    var ticketsReserved: Int {
        seats.filter { $0.status == .reserved }.count
    }
    
    var totalRevenue: Double {
        seats.compactMap { seat in
            seat.status == .sold ? (seat.price ?? 25.0) : nil
        }.reduce(0, +)
    }
    
    var totalCost: Double {
        seats.compactMap { seat in
            seat.status == .sold ? (seat.cost ?? 25.0) : nil
        }.reduce(0, +)
    }
    
    var profit: Double {
        totalRevenue - totalCost
    }
    
    // Legacy compatibility for existing data
    var seatsSold: [Bool] {
        seats.map { $0.status == .sold }
    }
    
    init(id: Int, artist: String, date: Date, seats: [Seat] = Array(repeating: Seat(), count: 8)) {
        self.id = id
        self.artist = artist
        self.date = date
        self.seats = seats
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
        concert.ticketsSold == 8 ? .modernSuccess : (concert.ticketsSold > 0 ? .modernWarning : .modernTextSecondary)
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
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    Text("\(concert.ticketsSold)/8 tickets sold")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(statusColor)
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
                            VStack(alignment: .leading, spacing: 8) {
                                // Spacer for the overlay buttons (44 + padding)
                                Color.clear.frame(height: 70)
                                
                                Text("All Concerts")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(.modernText)
                                
                                Text("\(sortedConcerts.count) total concerts")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.modernTextSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 20)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(sortedConcerts) { concert in
                                    NavigationLink(destination: ConcertDetailView(concert: concert, concertManager: concertManager, settingsManager: SettingsManager())) {
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
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.modernAccent)
                    
                    Spacer()
                    
                    Button(action: {
                        showingAddConcert = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.modernAccent)
                    }
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
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button("List") {
                                showingAllConcerts = true
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.modernAccent)
                            
                            Button(action: {
                                showingDeleteConfirmation = true
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Concert Header Card
                    VStack(spacing: 16) {
                        Text(concert.artist)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.modernText)
                        
                        VStack(spacing: 8) {
                            Text(concert.date, style: .date)
                                .font(.system(size: 16))
                                .foregroundColor(.modernTextSecondary)
                            
                            HStack {
                                Circle()
                                    .fill(concert.ticketsSold == 8 ? Color.modernSuccess : Color.modernWarning)
                                    .frame(width: 8, height: 8)
                                Text("\(concert.ticketsSold)/8 tickets sold")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(concert.ticketsSold == 8 ? .modernSuccess : .modernWarning)
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
            AllConcertsView(concertManager: concertManager)
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
                            colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
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
                                .foregroundColor(.purple)
                            Text("STAGE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
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
                }
            )
        }
    }
    
    private func selectSeat(_ index: Int) {
        selectedSeatIndex = index
        priceInput = String(concert.seats[index].price ?? 25.0)
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
    
    var seatColor: Color {
        seat.status.color
    }
    
    var body: some View {
        VStack(spacing: 3) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                }
                onTap()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(seatColor)
                        .frame(width: 38, height: 38) // Smaller seats
                        .scaleEffect(isPressed ? 1.15 : 1.0)
                        .shadow(color: seatColor.opacity(0.5), radius: seat.status != .available ? 6 : 4)
                    
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
    let seatNumber: Int
    @State var seat: Seat
    let onUpdate: (Seat) -> Void
    
    @State private var selectedStatus: SeatStatus
    @State private var priceInput: String
    @State private var costInput: String
    @State private var noteInput: String
    @State private var selectedSource: TicketSource
    
    init(seatNumber: Int, seat: Seat, onUpdate: @escaping (Seat) -> Void) {
        self.seatNumber = seatNumber
        self.seat = seat
        self.onUpdate = onUpdate
        self._selectedStatus = State(initialValue: seat.status)
        self._priceInput = State(initialValue: String(seat.price ?? 25.0))
        self._costInput = State(initialValue: String(seat.cost ?? 25.0))
        self._noteInput = State(initialValue: seat.note ?? "")
        self._selectedSource = State(initialValue: seat.source ?? .family)
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
                                        selectedStatus = status
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
                                        
                                        TextField("25.00", text: $priceInput)
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
                                    
                                    Menu {
                                        ForEach(TicketSource.allCases, id: \.self) { source in
                                            Button(source.rawValue) {
                                                selectedSource = source
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(selectedSource.rawValue)
                                                .font(.system(size: 16))
                                                .foregroundColor(.modernText)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 14))
                                                .foregroundColor(.modernTextSecondary)
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
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            Button("Update Seat") {
                                var updatedSeat = seat
                                updatedSeat.status = selectedStatus
                                
                                if selectedStatus == .sold {
                                    updatedSeat.price = Double(priceInput) ?? 25.0
                                    updatedSeat.cost = Double(costInput) ?? 25.0
                                    updatedSeat.note = nil
                                    updatedSeat.source = selectedSource
                                    // Play ding sound effect
                                    playDingSound()
                                } else if selectedStatus == .reserved {
                                    updatedSeat.price = nil
                                    updatedSeat.cost = Double(costInput) ?? 25.0
                                    updatedSeat.note = noteInput.isEmpty ? nil : noteInput
                                    updatedSeat.source = nil
                                } else {
                                    updatedSeat.price = nil
                                    updatedSeat.cost = Double(costInput) ?? 25.0
                                    updatedSeat.note = nil
                                    updatedSeat.source = nil
                                }
                                
                                onUpdate(updatedSeat)
                                dismiss()
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedStatus.color)
                            )
                            
                            Button("Cancel") {
                                dismiss()
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.modernTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
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

struct DynamicAnalytics: View {
    @Binding var concerts: [Concert]
    
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
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
        }
    }
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
            }
        }
    }
}

#Preview {
    DynamicFireSuiteApp()
}