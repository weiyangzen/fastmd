# Stage 1 iOS L12 iPhone 12 Simulator Refresh - 2026-05-05

## Scope

Advanced one bounded iOS-owned L12 validation batch for the current local Xcode destination set.

Changes are limited to `ios/**`.

## Changed Files

Report:

- `ios/docs/reports/stage1-ios-l12-iphone12-simulator-refresh-20260505.md`

No Swift implementation files were changed in this batch.

## Environment Probe

| Probe | Result | Evidence |
| --- | --- | --- |
| `xcrun simctl list devices available \| rg 'iPhone 12\|iPhone 15\|Stage1'` from repository root | PASS | Available simulator destination now includes `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)` and `Stage1 iPhone 15 Pro (63DAFAF1-789A-4206-8B3C-6B87048AFDF1) (Shutdown)`. |
| `xcrun simctl list runtimes available` from repository root | PASS | Available iOS runtimes include iOS 18.3, iOS 18.6, iOS 26.3, and iOS 26.4 variants. |
| `xcodebuild -list` from `ios/` | PASS | SwiftPM workspace resolves the `FastMDMobile` scheme. |
| `xcrun xctrace list devices` from repository root | BLOCKED for real device | No connected physical iPhone 12-family hardware was listed. Connected physical devices were absent; two non-iPhone-12 devices were listed offline. |

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 126 tests with 0 failures on `x86_64-apple-macos14.0`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Built `FastMDMobileCore` for `arm64-apple-ios14.0-simulator` using the iPhone 12 simulator destination. Xcode ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Executed 126 XCTest cases with 0 failures on the iPhone 12 simulator destination. Xcode ended with `** TEST SUCCEEDED **` and produced `Test-FastMDMobile-2026.05.05_23-30-41-+0800.xcresult`. |

## Checklist Evidence

Supervisor can mark complete:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`
- L13: `Record validation reports under ios/docs/reports/.`

Evidence:

- `ios/docs/reports/stage1-ios-l12-iphone12-simulator-refresh-20260505.md`
- `swift test` passed.
- `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed.
- `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed.

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Residual blocker:

- No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available in this batch, so the real-device parity-complete release claim remains blocked.
