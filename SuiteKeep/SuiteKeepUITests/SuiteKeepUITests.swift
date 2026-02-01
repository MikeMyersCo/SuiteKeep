//
//  SuiteKeepUITests.swift
//  SuiteKeepUITests
//
//  Created by Mike Myers on 7/30/25.
//

import XCTest

final class SuiteKeepUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()

        // Wait for splash screen to finish and tab bar to appear
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 8), "Tab bar did not appear after splash screen")
    }

    // MARK: - Helpers

    /// Scroll to bottom of current scroll view
    private func scrollToBottom(swipes: Int = 5) {
        for _ in 0..<swipes {
            app.swipeUp()
        }
    }

    /// Ensure at least one concert exists by creating one if needed.
    /// Call from the Dashboard tab (default after setUp).
    private func ensureConcertExists() {
        app.tabBars.buttons["Concerts"].tap()

        let viewAllButton = app.buttons["View All"]
        XCTAssertTrue(viewAllButton.waitForExistence(timeout: 3), "View All button not found")
        viewAllButton.tap()

        // Wait for sheet
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5), "All Concerts sheet did not appear")

        let allConcertsHeader = app.staticTexts["All Concerts"]
        if allConcertsHeader.waitForExistence(timeout: 2) {
            // Concerts already exist — dismiss and return
            doneButton.tap()
            sleep(1)
            return
        }

        // No concerts — dismiss this sheet and create one
        doneButton.tap()
        sleep(1)

        let addButton = app.buttons["Add Concert"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3), "Add Concert button not found")
        addButton.tap()

        // Wait for Add Concert sheet
        let artistField = app.textFields["Enter artist name"]
        XCTAssertTrue(artistField.waitForExistence(timeout: 5), "Add Concert sheet did not appear")

        // Type artist name and submit
        artistField.tap()
        artistField.typeText("Test Concert")

        // Dismiss keyboard, then tap the sheet's Add Concert button
        app.swipeDown()
        sleep(1)

        // The sheet has a submit button labeled "Add Concert"
        // Find it among buttons — it's the one inside the sheet (hittable)
        let submitButtons = app.buttons.matching(NSPredicate(format: "label == 'Add Concert'"))
        var tapped = false
        for i in 0..<submitButtons.count {
            let btn = submitButtons.element(boundBy: i)
            if btn.isHittable {
                btn.tap()
                tapped = true
                break
            }
        }
        XCTAssertTrue(tapped, "Could not tap Add Concert submit button")
        sleep(1)
    }

    /// Navigate to a concert detail: Concerts tab → View All → tap first concert.
    private func navigateToConcertDetail() {
        app.tabBars.buttons["Concerts"].tap()

        let viewAllButton = app.buttons["View All"]
        XCTAssertTrue(viewAllButton.waitForExistence(timeout: 3), "View All button not found")
        viewAllButton.tap()

        // Wait for sheet with concert list
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5), "All Concerts sheet did not appear")

        let allConcertsHeader = app.staticTexts["All Concerts"]
        XCTAssertTrue(allConcertsHeader.waitForExistence(timeout: 3), "All Concerts header missing — no concerts loaded")

        // Tap the first concert row — NavigationLink with PlainButtonStyle
        // Find the "tickets sold" indicator text that appears in every concert row
        let ticketIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'tickets sold'")).firstMatch
        XCTAssertTrue(ticketIndicator.waitForExistence(timeout: 3), "No concert row found in list")
        ticketIndicator.tap()

        // Wait for detail view
        let backButton = app.buttons["Back"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5), "Concert detail did not open")
    }

    // MARK: - 1. App Launch & Tab Navigation

    @MainActor
    func testTabBarHasFourTabs() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.buttons["Dashboard"].exists, "Dashboard tab missing")
        XCTAssertTrue(tabBar.buttons["Concerts"].exists, "Concerts tab missing")
        XCTAssertTrue(tabBar.buttons["Analytics"].exists, "Analytics tab missing")
        XCTAssertTrue(tabBar.buttons["Settings"].exists, "Settings tab missing")
    }

    @MainActor
    func testNavigateToEachTab() throws {
        // Dashboard is default — verify it loaded
        XCTAssertTrue(app.staticTexts["PRIVATE SUITE"].waitForExistence(timeout: 3), "Dashboard content not loaded")

        // Concerts tab
        app.tabBars.buttons["Concerts"].tap()
        XCTAssertTrue(app.staticTexts["Concerts"].waitForExistence(timeout: 3), "Concerts header not found")

        // Analytics tab
        app.tabBars.buttons["Analytics"].tap()
        XCTAssertTrue(app.staticTexts["Analytics"].waitForExistence(timeout: 3), "Analytics header not found")

        // Settings tab
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 3), "Settings header not found")
    }

    // MARK: - 2. Dashboard

    @MainActor
    func testDashboardHeaderContent() throws {
        XCTAssertTrue(app.staticTexts["PRIVATE SUITE"].exists, "PRIVATE SUITE label missing")

        let dashboardTexts = app.staticTexts
        XCTAssertTrue(dashboardTexts.count > 0, "Dashboard has no text elements")
    }

    @MainActor
    func testDashboardMetricsAndRecentActivity() throws {
        // MetricCard renders titles uppercased
        XCTAssertTrue(app.staticTexts["TOTAL TICKETS SOLD"].waitForExistence(timeout: 5), "TOTAL TICKETS SOLD metric missing")
        XCTAssertTrue(app.staticTexts["REVENUE"].exists, "REVENUE metric missing")
        XCTAssertTrue(app.staticTexts["TOTAL COST"].exists, "TOTAL COST metric missing")
        XCTAssertTrue(app.staticTexts["PROFIT"].exists, "PROFIT metric missing")

        // Scroll down to find Recent Activity
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Recent Activity"].waitForExistence(timeout: 3), "Recent Activity section missing")
    }

    // MARK: - 3. Concerts Tab

    @MainActor
    func testConcertsTabHeaderAndButtons() throws {
        app.tabBars.buttons["Concerts"].tap()

        XCTAssertTrue(app.staticTexts["Concerts"].waitForExistence(timeout: 3), "Concerts header missing")
        XCTAssertTrue(app.buttons["Add Concert"].waitForExistence(timeout: 3), "Add Concert button missing")
        XCTAssertTrue(app.buttons["View All"].exists, "View All button missing")
    }

    @MainActor
    func testAddConcertFlow() throws {
        ensureConcertExists()

        // Verify the concert now appears in View All
        app.tabBars.buttons["Concerts"].tap()
        app.buttons["View All"].tap()

        let allConcertsHeader = app.staticTexts["All Concerts"]
        XCTAssertTrue(allConcertsHeader.waitForExistence(timeout: 5), "All Concerts header missing after adding concert")

        // Verify at least one concert row exists
        let firstConcert = app.scrollViews.otherElements.buttons.firstMatch
        XCTAssertTrue(firstConcert.waitForExistence(timeout: 3), "Concert row missing after creation")

        app.buttons["Done"].tap()
    }

    @MainActor
    func testViewAllConcertsSheet() throws {
        ensureConcertExists()
        app.tabBars.buttons["Concerts"].tap()

        let viewAllButton = app.buttons["View All"]
        XCTAssertTrue(viewAllButton.waitForExistence(timeout: 3))
        viewAllButton.tap()

        // Verify All Concerts sheet with data
        XCTAssertTrue(app.staticTexts["All Concerts"].waitForExistence(timeout: 5), "All Concerts header missing")
        XCTAssertTrue(app.buttons["Done"].exists, "Done button missing")

        // Verify List/Calendar toggle
        XCTAssertTrue(app.staticTexts["List"].exists, "List toggle missing")
        XCTAssertTrue(app.staticTexts["Calendar"].exists, "Calendar toggle missing")

        app.buttons["Done"].tap()
    }

    @MainActor
    func testAllConcertsCalendarToggle() throws {
        ensureConcertExists()
        app.tabBars.buttons["Concerts"].tap()

        app.buttons["View All"].tap()
        XCTAssertTrue(app.staticTexts["All Concerts"].waitForExistence(timeout: 5))

        // Toggle to Calendar view
        app.staticTexts["Calendar"].tap()
        sleep(1)

        // Toggle back to List view
        app.staticTexts["List"].tap()
        sleep(1)

        // Dismiss the sheet
        app.buttons["Done"].tap()
    }

    // MARK: - 4. Concert Detail

    @MainActor
    func testConcertDetailElements() throws {
        ensureConcertExists()
        navigateToConcertDetail()

        // Verify Back button exists
        XCTAssertTrue(app.buttons["Back"].exists, "Back button missing")

        // Verify ticket status labels exist (at least one of sold/reserved/available)
        let textsContainingSold = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'sold'"))
        let textsContainingReserved = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'reserved'"))
        let textsContainingAvailable = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'available'"))

        let hasTicketStatus = textsContainingSold.count > 0
            || textsContainingReserved.count > 0
            || textsContainingAvailable.count > 0
        XCTAssertTrue(hasTicketStatus, "No ticket status labels found in concert detail")
    }

    @MainActor
    func testConcertDetailSeatViewIsDefault() throws {
        ensureConcertExists()
        navigateToConcertDetail()

        // Scroll down to the view mode toggle (below seat visualization)
        app.swipeUp()

        // Seat View / List View are Button elements
        XCTAssertTrue(app.buttons["Seat View"].waitForExistence(timeout: 3), "Seat View toggle missing")
        XCTAssertTrue(app.buttons["List View"].exists, "List View toggle missing")
    }

    @MainActor
    func testConcertDetailToggleToListView() throws {
        ensureConcertExists()
        navigateToConcertDetail()

        // Scroll down to the view mode toggle
        app.swipeUp()

        // Toggle to List View (Button element)
        let listViewButton = app.buttons["List View"]
        XCTAssertTrue(listViewButton.waitForExistence(timeout: 3), "List View button not found")
        listViewButton.tap()
        sleep(1)

        // Verify Seating List appears
        XCTAssertTrue(app.staticTexts["Seating List"].waitForExistence(timeout: 3), "Seating List header not found after toggling to List View")

        // Toggle back to Seat View
        app.buttons["Seat View"].tap()
        sleep(1)
    }

    @MainActor
    func testConcertDetailBatchModeButton() throws {
        ensureConcertExists()
        navigateToConcertDetail()

        // Scroll down if needed to find the batch mode button
        app.swipeUp()

        let batchButton = app.staticTexts["Select Multiple Seats"]
        XCTAssertTrue(batchButton.waitForExistence(timeout: 3), "Select Multiple Seats button missing")
    }

    // MARK: - 5. Analytics Tab

    @MainActor
    func testAnalyticsHeaderAndPerformanceTrends() throws {
        app.tabBars.buttons["Analytics"].tap()

        XCTAssertTrue(app.staticTexts["Analytics"].waitForExistence(timeout: 3), "Analytics header missing")

        // Scroll to find Performance Trends
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Performance Trends"].waitForExistence(timeout: 3), "Performance Trends section missing")
    }

    @MainActor
    func testAnalyticsBusinessReports() throws {
        app.tabBars.buttons["Analytics"].tap()

        // Scroll down to Business Reports
        app.swipeUp()
        app.swipeUp()

        XCTAssertTrue(app.staticTexts["Business Reports"].waitForExistence(timeout: 3), "Business Reports section missing")
        XCTAssertTrue(app.staticTexts["Report Elements"].waitForExistence(timeout: 3), "Report Elements label missing")

        // Verify report toggle titles
        XCTAssertTrue(app.staticTexts["Profit Analysis"].exists, "Profit Analysis toggle missing")
        XCTAssertTrue(app.staticTexts["Concert Data"].exists, "Concert Data toggle missing")
        XCTAssertTrue(app.staticTexts["Performance Rankings"].exists, "Performance Rankings toggle missing")
        XCTAssertTrue(app.staticTexts["Executive Summary"].exists, "Executive Summary toggle missing")

        // May need another swipe for Charity Report
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Charity Report"].waitForExistence(timeout: 3), "Charity Report toggle missing")
    }

    @MainActor
    func testAnalyticsGenerateReportButton() throws {
        app.tabBars.buttons["Analytics"].tap()

        // Scroll to the bottom to find the generate button
        app.swipeUp()
        app.swipeUp()
        app.swipeUp()

        let generateButton = app.buttons["Generate & Share Report"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 3), "Generate & Share Report button missing")
    }

    // MARK: - 6. Settings Tab

    @MainActor
    func testSettingsSuiteSetupFields() throws {
        app.tabBars.buttons["Settings"].tap()

        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 3), "Settings header missing")

        // Verify Suite Setup fields
        XCTAssertTrue(app.staticTexts["Suite Name"].waitForExistence(timeout: 3), "Suite Name field missing")
        XCTAssertTrue(app.staticTexts["Venue Location"].exists, "Venue Location field missing")

        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Default Family Price"].waitForExistence(timeout: 3), "Default Family Price field missing")
        XCTAssertTrue(app.staticTexts["Default Seat Cost"].exists, "Default Seat Cost field missing")
        XCTAssertTrue(app.buttons["Apply to All"].waitForExistence(timeout: 3), "Apply to All button missing")
    }

    @MainActor
    func testSettingsDataAndArchives() throws {
        app.tabBars.buttons["Settings"].tap()

        // Scroll down to Backup & Restore section
        app.swipeUp()
        app.swipeUp()

        XCTAssertTrue(app.staticTexts["Backup & Restore"].waitForExistence(timeout: 3), "Backup & Restore section missing")
        XCTAssertTrue(app.staticTexts["Backup Status"].waitForExistence(timeout: 3), "Backup Status missing")
        XCTAssertTrue(app.buttons["Create Backup"].waitForExistence(timeout: 3), "Create Backup button missing")

        app.swipeUp()

        // Check for Update 2026 Concerts (may show "Updating..." variant)
        let update2026 = app.buttons.matching(NSPredicate(format: "label CONTAINS '2026 Concerts'"))
        XCTAssertTrue(update2026.firstMatch.waitForExistence(timeout: 3), "Update 2026 Concerts button missing")

        XCTAssertTrue(app.buttons["Restore from Backup"].waitForExistence(timeout: 3), "Restore from Backup button missing")
        XCTAssertTrue(app.buttons["Clear All Data"].waitForExistence(timeout: 3), "Clear All Data button missing")
    }

    @MainActor
    func testSettingsFooter() throws {
        app.tabBars.buttons["Settings"].tap()

        // Scroll well past content to reach the footer
        scrollToBottom(swipes: 8)

        // Version text
        let versionText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Version'"))
        XCTAssertTrue(versionText.firstMatch.waitForExistence(timeout: 3), "Version text missing")

        // Support & Manual (Button element)
        let supportButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Support'"))
        XCTAssertTrue(supportButton.firstMatch.waitForExistence(timeout: 3), "Support & Manual link missing")

        // Disclaimer (Button element)
        XCTAssertTrue(app.buttons["Disclaimer"].waitForExistence(timeout: 3), "Disclaimer button missing")
    }

    @MainActor
    func testSettingsDisclaimerExpands() throws {
        app.tabBars.buttons["Settings"].tap()

        // Scroll well past content to reach the footer
        scrollToBottom(swipes: 8)

        let disclaimer = app.buttons["Disclaimer"]
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 3), "Disclaimer not found")
        disclaimer.tap()

        // Verify disclaimer text appears
        let disclaimerText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'as is'"))
        XCTAssertTrue(disclaimerText.firstMatch.waitForExistence(timeout: 3), "Disclaimer text did not expand")
    }
}
