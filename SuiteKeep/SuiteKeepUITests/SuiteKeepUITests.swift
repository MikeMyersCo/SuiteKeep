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

    // MARK: - 7. Concert Detail — Edit/Cancel Flow

    @MainActor
    func testConcertDetailEditAndCancel() throws {
        ensureConcertExists()
        navigateToConcertDetail()

        // Tap the Edit button
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3), "Edit button missing")
        editButton.tap()

        // Verify edit mode elements appear
        let artistField = app.textFields["Artist Name"]
        XCTAssertTrue(artistField.waitForExistence(timeout: 3), "Artist Name text field missing in edit mode")

        // Verify Cancel button appeared
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button missing in edit mode")

        // Verify Save button appeared (Edit becomes Save)
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.exists, "Save button missing in edit mode")

        // Cancel to revert — should return to non-edit state
        cancelButton.tap()
        sleep(1)

        // Verify we're back to display mode — Edit button should be visible again
        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: 3), "Edit button did not reappear after Cancel")
    }

    // MARK: - 8. Concert Detail — Seat Tap Opens Sheet

    @MainActor
    func testConcertDetailSeatTapOpensSheet() throws {
        ensureConcertExists()
        navigateToConcertDetail()

        // Tap seat 1 — seat numbers are rendered as static text labels
        let seat1 = app.staticTexts["1"]
        XCTAssertTrue(seat1.waitForExistence(timeout: 3), "Seat 1 not found")
        seat1.tap()

        // Verify the SeatOptionsView sheet appears with "Seat 1" header
        let seatHeader = app.staticTexts["Seat 1"]
        XCTAssertTrue(seatHeader.waitForExistence(timeout: 3), "Seat options sheet did not open")

        // Verify status buttons exist in the sheet
        let availableButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'available'"))
        XCTAssertTrue(availableButton.firstMatch.waitForExistence(timeout: 3), "Available status button missing")

        // Dismiss via Cancel button
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 3), "Cancel button missing in seat sheet")
        cancelButton.tap()
        sleep(1)
    }

    // MARK: - 9. Concert Detail — Buyer View Toggle

    @MainActor
    func testConcertDetailBuyerViewToggle() throws {
        ensureConcertExists()
        navigateToConcertDetail()

        // Verify Edit button exists before toggling buyer view
        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: 3), "Edit button should be visible before buyer view")

        // Scroll to find Buyer View button
        app.swipeUp()

        let buyerViewButton = app.staticTexts["Buyer View"]
        XCTAssertTrue(buyerViewButton.waitForExistence(timeout: 3), "Buyer View button missing")
        buyerViewButton.tap()
        sleep(1)

        // In Buyer View, the entire InteractiveFireSuiteView is replaced by ShareableBuyerView.
        // Management controls (Edit, Seat View/List View toggle) are no longer rendered.
        XCTAssertFalse(app.buttons["Edit"].exists, "Edit button should be hidden in Buyer View")
        XCTAssertFalse(app.buttons["Seat View"].exists, "Seat View toggle should be hidden in Buyer View")

        // Verify ShareableBuyerView content — seats show "OPEN" instead of "Available"
        let openSeats = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'OPEN' OR label CONTAINS 'Open'"))
        XCTAssertTrue(openSeats.firstMatch.waitForExistence(timeout: 3), "Buyer view seat status labels missing")

        // Buyer view has no toggle-off button (state resets on navigation).
        // Navigate back to All Concerts, then re-enter the concert detail.
        app.buttons["Back"].tap()
        sleep(1)

        // Re-enter concert detail — isBuyerView resets to false (@State)
        let ticketIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'tickets sold'")).firstMatch
        XCTAssertTrue(ticketIndicator.waitForExistence(timeout: 3), "Concert row not found after back navigation")
        ticketIndicator.tap()

        let backButton = app.buttons["Back"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5), "Concert detail did not reopen")

        // Verify Edit button is back (buyer view state was reset)
        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: 3), "Edit button did not reappear after re-entering concert detail")
    }

    // MARK: - 10. Concert Detail — Parking Status Sheet

    @MainActor
    func testConcertDetailParkingSheet() throws {
        ensureConcertExists()
        navigateToConcertDetail()

        // Scroll down to find the Parking button
        app.swipeUp()

        let parkingButton = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Parking'")).firstMatch
        XCTAssertTrue(parkingButton.waitForExistence(timeout: 3), "Parking status button missing")
        parkingButton.tap()

        // Verify Parking Ticket sheet appears
        let parkingHeader = app.staticTexts["Parking Ticket"]
        XCTAssertTrue(parkingHeader.waitForExistence(timeout: 3), "Parking Ticket sheet did not open")

        // Dismiss the sheet via the close button (xmark)
        let closeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Close' OR label CONTAINS 'xmark'")).firstMatch
        if closeButton.waitForExistence(timeout: 2) {
            closeButton.tap()
        } else {
            // Try tapping outside or swipe down to dismiss
            app.swipeDown()
        }
        sleep(1)
    }

    // MARK: - 11. Concert Detail — Batch Mode Toggle

    @MainActor
    func testConcertDetailBatchModeToggle() throws {
        ensureConcertExists()
        navigateToConcertDetail()

        // Scroll to batch mode button
        app.swipeUp()

        let selectMultiple = app.staticTexts["Select Multiple Seats"]
        XCTAssertTrue(selectMultiple.waitForExistence(timeout: 3), "Select Multiple Seats not found")

        // Tap to enable batch mode
        selectMultiple.tap()
        sleep(1)

        // Verify batch mode is active
        let batchActive = app.staticTexts["Batch Mode Active"]
        XCTAssertTrue(batchActive.waitForExistence(timeout: 3), "Batch Mode Active label not found after toggle")

        // Verify "selected" counter text appears
        let selectedText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'selected'"))
        XCTAssertTrue(selectedText.firstMatch.exists, "Selection counter missing in batch mode")

        // Toggle batch mode off
        batchActive.tap()
        sleep(1)

        // Verify we're back to normal
        XCTAssertTrue(app.staticTexts["Select Multiple Seats"].waitForExistence(timeout: 3), "Did not exit batch mode")
    }

    // MARK: - 12. Concert Detail — Delete Concert Dialog (Cancel)

    @MainActor
    func testConcertDetailDeleteDialogCancel() throws {
        ensureConcertExists()
        navigateToConcertDetail()

        // Find the trash/delete button
        let trashButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'trash' OR label CONTAINS 'Delete' OR label CONTAINS 'Trash'")).firstMatch
        XCTAssertTrue(trashButton.waitForExistence(timeout: 3), "Delete/trash button missing")
        trashButton.tap()

        // Verify confirmation dialog appears (confirmationDialog renders as action sheet)
        let deleteDialog = app.staticTexts["Delete Concert"]
        XCTAssertTrue(deleteDialog.waitForExistence(timeout: 3), "Delete Concert confirmation dialog did not appear")

        // Wait for action sheet animation to complete
        sleep(1)

        // Dismiss the dialog — try multiple approaches
        // On iOS, confirmationDialog Cancel can be in sheets, alerts, or top-level buttons
        var dismissed = false

        // Try sheets container first
        let sheetCancel = app.sheets.buttons["Cancel"]
        if sheetCancel.exists && sheetCancel.isHittable {
            sheetCancel.tap()
            dismissed = true
        }

        // Try alerts container
        if !dismissed {
            let alertCancel = app.alerts.buttons["Cancel"]
            if alertCancel.exists && alertCancel.isHittable {
                alertCancel.tap()
                dismissed = true
            }
        }

        // Try finding any hittable Cancel button in the entire app
        if !dismissed {
            let allCancel = app.buttons.matching(NSPredicate(format: "label == 'Cancel'"))
            for i in 0..<allCancel.count {
                let btn = allCancel.element(boundBy: i)
                if btn.isHittable {
                    btn.tap()
                    dismissed = true
                    break
                }
            }
        }

        // Last resort — tap the dimmed area above the action sheet to dismiss
        if !dismissed {
            let topOfScreen = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15))
            topOfScreen.tap()
        }

        sleep(1)

        // Verify we're still in the concert detail
        XCTAssertTrue(app.buttons["Back"].waitForExistence(timeout: 3), "Not in concert detail after cancelling delete")
    }

    // MARK: - 13. Concert Detail — Back Navigation

    @MainActor
    func testConcertDetailBackNavigation() throws {
        ensureConcertExists()
        navigateToConcertDetail()

        // Tap Back to return to All Concerts
        app.buttons["Back"].tap()

        // Verify we're back in All Concerts list
        let allConcertsHeader = app.staticTexts["All Concerts"]
        XCTAssertTrue(allConcertsHeader.waitForExistence(timeout: 5), "All Concerts header not found after back navigation")

        // Dismiss All Concerts sheet
        app.buttons["Done"].tap()
        sleep(1)

        // Verify we're back on the Concerts tab
        XCTAssertTrue(app.staticTexts["Concerts"].waitForExistence(timeout: 3), "Concerts tab not visible after dismissing sheet")
    }

    // MARK: - 14. All Concerts — Calendar Month Navigation

    @MainActor
    func testCalendarMonthNavigation() throws {
        ensureConcertExists()
        app.tabBars.buttons["Concerts"].tap()

        app.buttons["View All"].tap()
        XCTAssertTrue(app.staticTexts["All Concerts"].waitForExistence(timeout: 5))

        // Switch to Calendar view
        app.staticTexts["Calendar"].tap()
        sleep(1)

        // Tap the forward month button (chevron.right)
        let nextMonth = app.buttons.matching(NSPredicate(format: "label CONTAINS 'chevron.right' OR label CONTAINS 'Next' OR label CONTAINS 'Forward'")).firstMatch
        if nextMonth.waitForExistence(timeout: 3) {
            nextMonth.tap()
            sleep(1)

            // Navigate back
            let prevMonth = app.buttons.matching(NSPredicate(format: "label CONTAINS 'chevron.left' OR label CONTAINS 'Previous' OR label CONTAINS 'Back'")).firstMatch
            if prevMonth.exists {
                prevMonth.tap()
                sleep(1)
            }
        }

        // Switch back to List and dismiss
        app.staticTexts["List"].tap()
        sleep(1)
        app.buttons["Done"].tap()
    }

    // MARK: - 15. Analytics — Report Toggle Interactions

    @MainActor
    func testAnalyticsReportToggleInteraction() throws {
        app.tabBars.buttons["Analytics"].tap()

        // Scroll to Business Reports
        app.swipeUp()
        app.swipeUp()

        XCTAssertTrue(app.staticTexts["Report Elements"].waitForExistence(timeout: 3))

        // Find toggle switches — they should be near the report labels
        let switches = app.switches
        if switches.count > 0 {
            // Toggle the first switch off then back on
            let firstSwitch = switches.firstMatch
            let initialValue = firstSwitch.value as? String

            firstSwitch.tap()
            sleep(1)

            let newValue = firstSwitch.value as? String
            XCTAssertNotEqual(initialValue, newValue, "Toggle did not change state")

            // Toggle back to restore original state
            firstSwitch.tap()
            sleep(1)
        }
    }

    // MARK: - 16. Settings — CloudSync Toggle

    @MainActor
    func testSettingsCloudSyncToggle() throws {
        app.tabBars.buttons["Settings"].tap()

        // Scroll to Sync & Sharing section
        app.swipeUp()

        let cloudSyncText = app.staticTexts["Enable CloudSync"]
        XCTAssertTrue(cloudSyncText.waitForExistence(timeout: 3), "Enable CloudSync label missing")

        // Find the CloudSync toggle switch
        let switches = app.switches
        if switches.count > 0 {
            let cloudToggle = switches.firstMatch
            let initialValue = cloudToggle.value as? String

            // Toggle it
            cloudToggle.tap()
            sleep(1)

            // Dismiss any alert that may appear
            let okButton = app.buttons["OK"]
            if okButton.waitForExistence(timeout: 2) {
                okButton.tap()
                sleep(1)
            }

            let newValue = cloudToggle.value as? String
            XCTAssertNotEqual(initialValue, newValue, "CloudSync toggle did not change state")

            // Toggle back to restore
            cloudToggle.tap()
            sleep(1)

            // Dismiss any alert
            if okButton.waitForExistence(timeout: 2) {
                okButton.tap()
            }
        }
    }

    // MARK: - 17. Settings — Clear All Data Alert (Cancel)

    @MainActor
    func testSettingsClearAllDataAlertCancel() throws {
        app.tabBars.buttons["Settings"].tap()

        // Scroll to Clear All Data button
        app.swipeUp()
        app.swipeUp()
        app.swipeUp()

        let clearButton = app.buttons["Clear All Data"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 3), "Clear All Data button missing")
        clearButton.tap()

        // Verify the confirmation alert appears
        let alertTitle = app.staticTexts["Clear All Data"]
        XCTAssertTrue(alertTitle.waitForExistence(timeout: 3), "Clear All Data alert did not appear")

        // Cancel — do NOT clear data
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button missing in alert")
        cancelButton.tap()
        sleep(1)
    }

    // MARK: - 18. Settings — Apply to All Alert (Cancel)

    @MainActor
    func testSettingsApplyToAllAlertCancel() throws {
        app.tabBars.buttons["Settings"].tap()

        // Scroll to find Apply to All button
        app.swipeUp()

        let applyButton = app.buttons["Apply to All"]
        XCTAssertTrue(applyButton.waitForExistence(timeout: 3), "Apply to All button missing")
        applyButton.tap()

        // Verify confirmation alert appears
        let alertTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Apply'"))
        XCTAssertTrue(alertTitle.firstMatch.waitForExistence(timeout: 3), "Apply to All alert did not appear")

        // Cancel — do NOT apply
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button missing in alert")
        cancelButton.tap()
        sleep(1)
    }

    // MARK: - 19. Concert Detail — Seat Legend Verification

    @MainActor
    func testConcertDetailSeatLegend() throws {
        ensureConcertExists()
        navigateToConcertDetail()

        // Verify seat visualization elements
        XCTAssertTrue(app.staticTexts["STAGE"].waitForExistence(timeout: 3), "STAGE label missing")

        // Verify legend items
        XCTAssertTrue(app.staticTexts["Available"].exists, "Available legend missing")
        XCTAssertTrue(app.staticTexts["Reserved"].exists, "Reserved legend missing")
        XCTAssertTrue(app.staticTexts["Sold"].exists, "Sold legend missing")

        // Verify all 8 seat numbers exist
        for seatNum in 1...8 {
            XCTAssertTrue(app.staticTexts["\(seatNum)"].exists, "Seat \(seatNum) missing from visualization")
        }
    }

    // MARK: - 20. Concert Detail — Revenue Display

    @MainActor
    func testConcertDetailRevenueDisplay() throws {
        ensureConcertExists()
        navigateToConcertDetail()

        // Verify revenue display exists
        let revenueText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Revenue'"))
        XCTAssertTrue(revenueText.firstMatch.waitForExistence(timeout: 3), "Revenue display missing")

        // Verify sold/reserved/available counters
        let soldText = app.staticTexts["sold"]
        let reservedText = app.staticTexts["reserved"]
        let availableText = app.staticTexts["available"]
        XCTAssertTrue(soldText.exists || reservedText.exists || availableText.exists, "Ticket counters missing")
    }

    // MARK: - 21. Concert Detail — List View Seat Rows

    @MainActor
    func testConcertDetailListViewSeatRows() throws {
        ensureConcertExists()
        navigateToConcertDetail()

        // Scroll to toggle
        app.swipeUp()

        // Switch to List View
        let listViewButton = app.buttons["List View"]
        XCTAssertTrue(listViewButton.waitForExistence(timeout: 3))
        listViewButton.tap()
        sleep(1)

        // Verify Seating List header
        XCTAssertTrue(app.staticTexts["Seating List"].waitForExistence(timeout: 3), "Seating List header missing")

        // Verify instruction text
        let instructionText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Tap seats to manage'"))
        XCTAssertTrue(instructionText.firstMatch.waitForExistence(timeout: 3), "Seat management instruction missing")

        // Verify at least one seat row with "Seat" label
        let seatRow = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Seat'"))
        XCTAssertTrue(seatRow.count >= 1, "No seat rows found in list view")

        // Switch back
        app.buttons["Seat View"].tap()
        sleep(1)
    }

    // MARK: - 22. Add Concert — Cancel Flow

    @MainActor
    func testAddConcertCancelFlow() throws {
        app.tabBars.buttons["Concerts"].tap()

        let addButton = app.buttons["Add Concert"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()

        // Verify Add Concert sheet appears
        let headerText = app.staticTexts["Schedule a new performance"]
        XCTAssertTrue(headerText.waitForExistence(timeout: 5), "Add Concert sheet did not appear")

        // Verify form elements
        let artistField = app.textFields["Enter artist name"]
        XCTAssertTrue(artistField.exists, "Artist name field missing")

        // Verify Cancel button and tap it
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button missing in Add Concert sheet")
        cancelButton.tap()
        sleep(1)

        // Verify we returned to Concerts tab
        XCTAssertTrue(app.staticTexts["Concerts"].waitForExistence(timeout: 3), "Did not return to Concerts tab after cancel")
    }

    // MARK: - 23. Settings — Sync & Sharing Section

    @MainActor
    func testSettingsSyncAndSharingSection() throws {
        app.tabBars.buttons["Settings"].tap()

        app.swipeUp()

        // Verify Sync & Sharing elements
        XCTAssertTrue(app.staticTexts["Enable CloudSync"].waitForExistence(timeout: 3), "Enable CloudSync label missing")

        // Check for sync status indicator
        let syncStatus = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Sync' OR label CONTAINS 'sync' OR label CONTAINS 'Disabled' OR label CONTAINS 'Enabled'"))
        XCTAssertTrue(syncStatus.firstMatch.waitForExistence(timeout: 3), "Sync status indicator missing")
    }

    // MARK: - 24. Full Navigation Round Trip

    @MainActor
    func testFullNavigationRoundTrip() throws {
        // Start on Dashboard
        XCTAssertTrue(app.staticTexts["PRIVATE SUITE"].waitForExistence(timeout: 3))

        // Go to Concerts
        app.tabBars.buttons["Concerts"].tap()
        XCTAssertTrue(app.staticTexts["Concerts"].waitForExistence(timeout: 3))

        // Go to Analytics
        app.tabBars.buttons["Analytics"].tap()
        XCTAssertTrue(app.staticTexts["Analytics"].waitForExistence(timeout: 3))

        // Go to Settings
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 3))

        // Return to Dashboard
        app.tabBars.buttons["Dashboard"].tap()
        XCTAssertTrue(app.staticTexts["PRIVATE SUITE"].waitForExistence(timeout: 3), "Dashboard not restored after full round trip")

        // Verify metric cards still display
        XCTAssertTrue(app.staticTexts["TOTAL TICKETS SOLD"].exists, "Metrics lost after tab round trip")
    }
}
