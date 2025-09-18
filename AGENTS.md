# Repository Guidelines

## Project Structure & Module Organization
- `SuiteKeep/SuiteKeep`: App source (SwiftUI views, models), `Assets.xcassets`, `*.entitlements`.
- `SuiteKeep/SuiteKeepTests`: Unit tests (XCTest).
- `SuiteKeep/SuiteKeepUITests`: UI tests (XCUITest).
- `SuiteKeep/support`: Static support site (HTML/CSS/JS, assets).

## Build, Test, and Development Commands
- Build (Debug): `xcodebuild -project SuiteKeep/SuiteKeep.xcodeproj -scheme SuiteKeep -configuration Debug build`
- Clean: `xcodebuild -project SuiteKeep/SuiteKeep.xcodeproj -scheme SuiteKeep clean`
- Unit/UI tests: `xcodebuild -project SuiteKeep/SuiteKeep.xcodeproj -scheme SuiteKeep test`
- Run in Xcode: open the project and press `Cmd+R` (choose device/simulator). For macOS target, example: `xcodebuild -project SuiteKeep/SuiteKeep.xcodeproj -scheme SuiteKeep -destination 'platform=macOS' run`

## Coding Style & Naming Conventions
- Language: Swift 5, SwiftUI.
- Indentation: 2 spaces; keep lines < 120 chars.
- Naming: Types `UpperCamelCase`, methods/vars `lowerCamelCase`, enums `UpperCamelCase` with `lowerCamelCase` cases.
- Files: One primary type per file; app files end in `.swift`; tests end with `Tests.swift` or `UITests.swift`.
- Prefer `struct` over `class` unless reference semantics are required; avoid force-unwrapping; mark types `final` when appropriate.

## Testing Guidelines
- Frameworks: XCTest for unit and UI tests.
- Location: Add unit tests in `SuiteKeepTests`, UI tests in `SuiteKeepUITests`.
- Naming: Test classes end with `Tests`; methods start with `test...` and assert one behavior.
- Running: `xcodebuild ... test` (above) or `Cmd+U` in Xcode. Target a test in Xcode via the gutter diamond; keep tests independent and deterministic.

## Commit & Pull Request Guidelines
- Commits: Use short, imperative messages (e.g., "Fix seat color legend mismatch"). Group related changes; avoid noisy reformat-only commits.
- PRs: Include a clear description, linked issue (if any), testing notes, and screenshots for UI changes. Keep PRs focused and small; update/add tests when modifying logic or UI flows.

## Architecture Notes & Tips
- SwiftUI app with observable state managers (e.g., settings, persistence). Keep business logic testable and views declarative.
- Assets live in `Assets.xcassets`; do not commit secrets. Keep entitlements minimal and review before changes.
