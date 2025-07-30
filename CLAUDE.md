# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SuiteKeep is a SwiftUI-based concert management application with a modern, clean design. It features customizable suite names and venue locations, tracks ticket sales, manages seat reservations, and provides analytics for concert performances. The app targets multiple Apple platforms (iOS, macOS, visionOS).

## Development Commands

### Building the Project
- Open `SuiteKeep/SuiteKeep.xcodeproj` in Xcode
- Build: `Cmd+B` or use `xcodebuild -project SuiteKeep/SuiteKeep.xcodeproj -scheme SuiteKeep -configuration Debug build`
- Clean: `Cmd+Shift+K` or use `xcodebuild -project SuiteKeep/SuiteKeep.xcodeproj -scheme SuiteKeep clean`

### Running Tests
- Unit Tests: `Cmd+U` or use `xcodebuild -project SuiteKeep/SuiteKeep.xcodeproj -scheme SuiteKeep test`
- Run a single test: Click the diamond icon next to the test method in Xcode
- UI Tests: Select the SuiteKeepUITests scheme and run tests

### Running the App
- Select target device/simulator in Xcode
- Run: `Cmd+R` or use `xcodebuild -project SuiteKeep/SuiteKeep.xcodeproj -scheme SuiteKeep -destination 'platform=macOS' run`

## Code Architecture

### Core Components

The app consists of four main tabs:
1. **Dashboard**: Modern overview with key metrics, performance trends, and recent activity
2. **Concerts**: Concert management with seat selection and ticket tracking
3. **Analytics**: Performance analytics (coming soon)
4. **Settings**: Customizable suite name, venue location, and app information

### Key Models and Data Flow

- **Concert**: Core model containing artist, date, and array of 8 Seat objects
- **Seat**: Represents each suite seat with status (available/reserved/sold), price, note, and ticket source
- **ConcertDataManager**: ObservableObject that manages concert persistence using UserDefaults
- **SettingsManager**: ObservableObject that manages user preferences like suite name and venue location

### Suite Layout

The suite has a unique 8-seat configuration around a central firepit:
- Seats 1, 2 (right side) and 7, 8 (left side) arranged around the firepit
- Seats 3, 4, 5, 6 in a row at the bottom
- Interactive seat selection with visual feedback and status management
- Fire theme retained only for the seating visualization area

### Key Files

- **SuiteKeepApp.swift**: App entry point
- **DynamicFireSuiteApp.swift**: Main app implementation with all views and business logic
  - Modern UI theme with clean design patterns and contemporary styling
  - Contains TabView structure, dashboard metrics, concert management, seat selection, and settings
  - Implements customizable suite settings with SettingsManager
  - Features interactive suite visualization with animated firepit (fire theme only in seating area)
  - Handles seat status updates (available → reserved → sold) with pricing and source tracking

### Data Persistence

- Uses UserDefaults with Codable models for local storage
- Keys: "SavedConcerts" (Concert objects), "suiteName", "venueLocation" (settings)
- Automatic saving on any concert/seat updates or settings changes

### Testing Approach
- Unit tests use the modern Swift Testing framework with `@Test` attributes
- UI tests use XCTest with XCUIApplication for app automation
- Tests are organized in separate targets for unit and UI testing