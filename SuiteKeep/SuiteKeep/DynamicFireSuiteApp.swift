//
//  DynamicFireSuiteApp.swift
//  SuiteKeep
//
//  Created by Mike Myers on 7/30/25.
//

import SwiftUI
import AVFoundation

struct DynamicFireSuiteApp: View {
    @State private var selectedTab = 0
    @State private var animateFlames = true
    @StateObject private var concertManager = ConcertDataManager()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DynamicDashboard(concerts: $concertManager.concerts)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "flame.fill" : "flame")
                    Text("Suite")
                }
                .tag(0)
            
            DynamicConcerts(concertManager: concertManager)
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "music.note.house.fill" : "music.note.house")
                    Text("Concerts")
                }
                .tag(1)
            
            DynamicAnalytics()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "chart.bar.xaxis" : "chart.bar")
                    Text("Analytics")
                }
                .tag(2)
            
            DynamicPortfolio()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "dollarsign.circle.fill" : "dollarsign.circle")
                    Text("Portfolio")
                }
                .tag(3)
        }
        .accentColor(.orange)
        .onAppear {
            startFlameAnimation()
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
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic gradient background
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.9),
                        Color.orange.opacity(0.3),
                        Color.red.opacity(0.2),
                        Color.black.opacity(0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Suite Overview Summary
                        SuiteSummaryView(concerts: concerts)
                        
                        // Performance Metrics
                        PerformanceMetricsView(concerts: concerts)
                        
                        // Recent Activity
                        RecentActivityFeed(concerts: concerts)
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                startPulseAnimation()
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
    
    var averageOccupancy: Int {
        guard !concerts.isEmpty else { return 0 }
        let totalOccupancy = concerts.reduce(0) { $0 + $1.ticketsSold }
        return Int((Double(totalOccupancy) / Double(concerts.count * 8)) * 100)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
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
            
            // Key Metrics Cards
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 2), spacing: 15) {
                MetricCard(
                    title: "Total Sold",
                    value: "\(totalTicketsSold)",
                    subtitle: "tickets",
                    color: .green,
                    icon: "ticket.fill"
                )
                
                MetricCard(
                    title: "Revenue",
                    value: "$\(Int(totalRevenue))",
                    subtitle: "total",
                    color: .blue,
                    icon: "dollarsign.circle.fill"
                )
                
                MetricCard(
                    title: "Upcoming",
                    value: "\(upcomingConcerts)",
                    subtitle: "concerts",
                    color: .orange,
                    icon: "calendar"
                )
                
                MetricCard(
                    title: "Occupancy",
                    value: "\(averageOccupancy)%",
                    subtitle: "average",
                    color: .purple,
                    icon: "chart.bar.fill"
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

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isPressed.toggle()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPressed.toggle()
                }
            }
        }
    }
}

// MARK: - Fire Suite Hero View
struct FireSuiteHeroView: View {
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
                    .frame(width: 350, height: 220)
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
                            VStack(spacing: 15) {
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
                            VStack(spacing: 15) {
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
                        HStack(spacing: 20) {
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
}

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
            
            Text("$25")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 30)
                .multilineTextAlignment(.center)
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


// MARK: - Performance Metrics View
struct PerformanceMetricsView: View {
    let concerts: [Concert]
    @State private var showChart = false
    
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
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Performance")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.green)
            }
            
            if showChart {
                // Concert performance chart
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<12, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.green, .orange],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 20, height: max(20, CGFloat(chartData[index])))
                            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(Double(index) * 0.1), value: showChart)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).delay(0.8)) {
                showChart = true
            }
        }
    }
}

// MARK: - Recent Activity Feed
struct RecentActivityFeed: View {
    let concerts: [Concert]
    
    var recentActivities: [(String, String, String, String, Color)] {
        let sortedConcerts = concerts.sorted { $0.date > $1.date }.prefix(4)
        return sortedConcerts.map { concert in
            let timeAgo = timeAgoString(from: concert.date)
            let emoji = concert.ticketsSold == 8 ? "🎵" : (concert.ticketsSold > 0 ? "🔥" : "🎸")
            let subtitle = concert.ticketsSold == 8 ? "Sold out!" : "Tickets sold: \(concert.ticketsSold)/8"
            let color: Color = concert.ticketsSold == 8 ? .green : (concert.ticketsSold > 0 ? .orange : .gray)
            
            return (emoji, concert.artist, subtitle, timeAgo, color)
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
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.orange)
            }
            
            if recentActivities.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "music.note")
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No recent activity")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(recentActivities.enumerated()), id: \.offset) { index, activity in
                        ActivityRow(
                            emoji: activity.0,
                            title: activity.1,
                            subtitle: activity.2,
                            time: activity.3,
                            color: activity.4
                        )
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: index)
                    }
                }
            }
        }
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let emoji: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(color)
            }
            
            Spacer()
            
            Text(time)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Concert Management
struct DynamicConcerts: View {
    @ObservedObject var concertManager: ConcertDataManager
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
                // Background
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.9),
                        Color.orange.opacity(0.3),
                        Color.red.opacity(0.2),
                        Color.black.opacity(0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Action Buttons
                        HStack(spacing: 15) {
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
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                showingAllConcerts = true
                            }) {
                                HStack {
                                    Image(systemName: "list.bullet")
                                    Text("View All")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(12)
                            }
                        }
                        
                        // Section Header
                        HStack {
                            Text("Next 2 Weeks")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(upcomingConcerts.count) concerts")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Upcoming Concerts
                        if upcomingConcerts.isEmpty {
                            VStack(spacing: 15) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.3))
                                
                                Text("No concerts in the next 2 weeks")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Text("Add a concert to get started")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            LazyVStack(spacing: 15) {
                                ForEach(upcomingConcerts) { concert in
                                    NavigationLink(destination: ConcertDetailView(concert: concert, concertManager: concertManager)) {
                                        ConcertRowView(concert: concert)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Concerts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddConcert = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.orange)
                    }
                }
            }
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
        case .available: return "$25"
        case .reserved: return "RESV"
        case .sold: return "SOLD"
        }
    }
}

// MARK: - Seat Model
struct Seat: Codable {
    var status: SeatStatus
    var price: Double?
    var note: String? // For reserved seats - max 5 words
    
    init(status: SeatStatus = .available, price: Double? = nil, note: String? = nil) {
        self.status = status
        self.price = price
        self.note = note
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
    private let concertsKey = "SavedConcerts"
    
    init() {
        loadConcerts()
    }
    
    func loadConcerts() {
        if let data = userDefaults.data(forKey: concertsKey),
           let decodedConcerts = try? JSONDecoder().decode([Concert].self, from: data) {
            concerts = decodedConcerts
        }
    }
    
    func saveConcerts() {
        if let encoded = try? JSONEncoder().encode(concerts) {
            userDefaults.set(encoded, forKey: concertsKey)
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
    
    var body: some View {
        HStack(spacing: 15) {
            // Concert Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "music.note")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            // Concert Info
            VStack(alignment: .leading, spacing: 4) {
                Text(concert.artist)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(concert.date, style: .date)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("\(concert.ticketsSold)/8 tickets sold")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(concert.ticketsSold == 8 ? .green : .orange)
            }
            
            Spacer()
            
            // Status indicator
            Circle()
                .fill(concert.ticketsSold == 8 ? .green : (concert.ticketsSold > 0 ? .orange : .gray))
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
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
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // Artist field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Artist")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        TextField("Enter artist name", text: $artist)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 16))
                    }
                    
                    // Date field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Concert Date")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        DatePicker("Select date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .accentColor(.orange)
                            .colorScheme(.dark)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.2))
                            )
                    }
                    
                    Spacer()
                    
                    // Save button
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
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .disabled(artist.isEmpty)
                    .opacity(artist.isEmpty ? 0.6 : 1.0)
                }
                .padding()
            }
            .navigationTitle("Add Concert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
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
                Color.black.ignoresSafeArea()
                
                if concertManager.concerts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.house")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("No Concerts Yet")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Add your first concert to get started")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Button(action: {
                            showingAddConcert = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Concert")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(sortedConcerts) { concert in
                                NavigationLink(destination: ConcertDetailView(concert: concert, concertManager: concertManager)) {
                                    ConcertRowView(concert: concert)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("All Concerts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddConcert = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.orange)
                    }
                }
            }
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
    @State private var showingAllConcerts = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color.black.opacity(0.9),
                    Color.orange.opacity(0.3),
                    Color.red.opacity(0.2),
                    Color.black.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Concert Header
                    VStack(spacing: 10) {
                        Text(concert.artist)
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text(concert.date, style: .date)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(concert.ticketsSold)/8 tickets sold")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(concert.ticketsSold == 8 ? .green : .orange)
                    }
                    
                    // Interactive Fire Suite Layout for seat selection
                    InteractiveFireSuiteView(concert: $concert, concertManager: concertManager)
                }
                .padding()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Concert List") {
                    showingAllConcerts = true
                }
                .foregroundColor(.orange)
            }
        }
        .sheet(isPresented: $showingAllConcerts) {
            AllConcertsView(concertManager: concertManager)
        }
    }
}

// MARK: - Interactive Fire Suite View
struct InteractiveFireSuiteView: View {
    @Binding var concert: Concert
    @ObservedObject var concertManager: ConcertDataManager
    @State private var pulseFirepit = false
    @State private var showingSeatOptions = false
    @State private var selectedSeatIndex: Int?
    @State private var priceInput: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            VStack(spacing: 5) {
                Text("FIRE SUITE SEATING")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1)
                
                Text("Tap seats to purchase/refund tickets")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
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
                    .frame(width: 350, height: 220)
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
                            VStack(spacing: 15) {
                                InteractiveSeatView(
                                    seatNumber: 8,
                                    seat: concert.seats[7],
                                    onTap: { selectSeat(7) }
                                )
                                InteractiveSeatView(
                                    seatNumber: 7,
                                    seat: concert.seats[6],
                                    onTap: { selectSeat(6) }
                                )
                            }
                            
                            // Center Firepit
                            DynamicFirepitView(isPulsing: pulseFirepit)
                            
                            // Right side: Seats 1 (top) and 2 (bottom)
                            VStack(spacing: 15) {
                                InteractiveSeatView(
                                    seatNumber: 1,
                                    seat: concert.seats[0],
                                    onTap: { selectSeat(0) }
                                )
                                InteractiveSeatView(
                                    seatNumber: 2,
                                    seat: concert.seats[1],
                                    onTap: { selectSeat(1) }
                                )
                            }
                        }
                        
                        // Bottom row: Seats 3, 4, 5, 6 in line
                        HStack(spacing: 20) {
                            InteractiveSeatView(
                                seatNumber: 3,
                                seat: concert.seats[2],
                                onTap: { selectSeat(2) }
                            )
                            InteractiveSeatView(
                                seatNumber: 4,
                                seat: concert.seats[3],
                                onTap: { selectSeat(3) }
                            )
                            InteractiveSeatView(
                                seatNumber: 5,
                                seat: concert.seats[4],
                                onTap: { selectSeat(4) }
                            )
                            InteractiveSeatView(
                                seatNumber: 6,
                                seat: concert.seats[5],
                                onTap: { selectSeat(5) }
                            )
                        }
                    }
                }
                .padding()
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
        VStack(spacing: 2) {
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
                        .frame(width: 30, height: 30)
                        .scaleEffect(isPressed ? 1.2 : 1.0)
                        .shadow(color: seatColor.opacity(0.5), radius: seat.status != .available ? 8 : 4)
                    
                    if seat.status == .sold {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else if seat.status == .reserved {
                        Image(systemName: "clock")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(seatNumber)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(spacing: 1) {
                if seat.status == .sold {
                    Text(seat.price != nil ? "$\(Int(seat.price!))" : "SOLD")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(seat.status.color)
                } else if seat.status == .reserved && seat.note != nil {
                    Text(seat.note!)
                        .font(.system(size: 6, weight: .medium, design: .monospaced))
                        .foregroundColor(seat.status.color)
                        .lineLimit(2)
                } else {
                    Text(seat.status.displayText)
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(seat.status.color)
                }
            }
            .frame(width: 30)
            .multilineTextAlignment(.center)
        }
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
    @State private var noteInput: String
    
    init(seatNumber: Int, seat: Seat, onUpdate: @escaping (Seat) -> Void) {
        self.seatNumber = seatNumber
        self.seat = seat
        self.onUpdate = onUpdate
        self._selectedStatus = State(initialValue: seat.status)
        self._priceInput = State(initialValue: String(seat.price ?? 25.0))
        self._noteInput = State(initialValue: seat.note ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // Seat info
                    VStack(spacing: 10) {
                        Text("Seat \(seatNumber)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Current Status: \(seat.status.rawValue.capitalized)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(seat.status.color)
                    }
                    
                    // Status selection
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Set Status")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        ForEach(SeatStatus.allCases, id: \.self) { status in
                            Button(action: {
                                selectedStatus = status
                            }) {
                                HStack {
                                    Circle()
                                        .fill(status.color)
                                        .frame(width: 20, height: 20)
                                    
                                    Text(status.rawValue.capitalized)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if selectedStatus == status {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(status.color)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedStatus == status ? status.color.opacity(0.2) : Color.gray.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedStatus == status ? status.color : Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Price input (only for sold status)
                    if selectedStatus == .sold {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sale Price")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("$")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                TextField("25.00", text: $priceInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.system(size: 16))
                                    .keyboardType(.decimalPad)
                            }
                        }
                    }
                    
                    // Note input (only for reserved status)
                    if selectedStatus == .reserved {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reservation Note")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("(Max 5 words)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            TextField("Enter note...", text: $noteInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 16))
                                .onChange(of: noteInput) { _, newValue in
                                    let words = newValue.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                                    if words.count > 5 {
                                        noteInput = words.prefix(5).joined(separator: " ")
                                    }
                                }
                        }
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 15) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        
                        Button("Update Seat") {
                            var updatedSeat = seat
                            updatedSeat.status = selectedStatus
                            
                            if selectedStatus == .sold {
                                updatedSeat.price = Double(priceInput) ?? 25.0
                                updatedSeat.note = nil
                                // Play ding sound effect
                                playDingSound()
                            } else if selectedStatus == .reserved {
                                updatedSeat.price = nil
                                updatedSeat.note = noteInput.isEmpty ? nil : noteInput
                            } else {
                                updatedSeat.price = nil
                                updatedSeat.note = nil
                            }
                            
                            onUpdate(updatedSeat)
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [selectedStatus.color, selectedStatus.color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
        }
    }
    
    private func playDingSound() {
        AudioServicesPlaySystemSound(1054) // System ding sound
    }
}

struct DynamicAnalytics: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                Text("📊 Analytics Coming Soon")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .navigationTitle("Analytics")
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

#Preview {
    DynamicFireSuiteApp()
}