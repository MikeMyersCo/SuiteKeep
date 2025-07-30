# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SuiteKeep is a SwiftUI-based application targeting multiple Apple platforms (iOS, macOS, visionOS). It's built using Xcode and the Swift programming language.

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

### Project Structure
- **SuiteKeep/**: Main application code
  - `SuiteKeepApp.swift`: App entry point using SwiftUI App protocol
  - `ContentView.swift`: Main UI view
  - `Assets.xcassets/`: Asset catalog for images and colors
  - `SuiteKeep.entitlements`: App capabilities and permissions

- **SuiteKeepTests/**: Unit tests using Swift Testing framework
- **SuiteKeepUITests/**: UI tests using XCTest framework

### Key Technologies
- **SwiftUI**: Modern declarative UI framework
- **Swift Testing**: New testing framework for unit tests (note the `@Test` attribute and `#expect` syntax)
- **XCTest**: UI testing framework
- **Multi-platform Support**: Configured for iOS 18.5+, macOS 15.5+, visionOS 2.5+

### Testing Approach
- Unit tests use the modern Swift Testing framework with `@Test` attributes
- UI tests use XCTest with XCUIApplication for app automation
- Tests are organized in separate targets for unit and UI testing