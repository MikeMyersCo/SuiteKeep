import SwiftUI

// MARK: - Platform Detection Content View
struct ContentView: View {
    var body: some View {
        DynamicFireSuiteApp()
    }
}

// MARK: - Notification Names for Mac Commands
extension Notification.Name {
    static let newConcertRequested = Notification.Name("newConcertRequested")
    static let importDataRequested = Notification.Name("importDataRequested")
    static let exportDataRequested = Notification.Name("exportDataRequested")
    static let toggleSidebarRequested = Notification.Name("toggleSidebarRequested")
    static let navigateToDashboard = Notification.Name("navigateToDashboard")
    static let navigateToConcerts = Notification.Name("navigateToConcerts")
    static let navigateToAnalytics = Notification.Name("navigateToAnalytics")
    static let navigateToSettings = Notification.Name("navigateToSettings")
    static let syncNowRequested = Notification.Name("syncNowRequested")
    static let inviteMemberRequested = Notification.Name("inviteMemberRequested")
    static let suiteSettingsRequested = Notification.Name("suiteSettingsRequested")
}

#Preview {
    ContentView()
}