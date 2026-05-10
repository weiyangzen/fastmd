# Stage 1 iOS L12 iPhone 12 Simulator Pass - 2026-05-06 04:11 +0800

## Scope

Ran one bounded iOS-owned validation batch for the earliest remaining iOS-owned L12 platform validation gates:

- `Run iOS iPhone 12 simulator build.`
- `Run iOS iPhone 12 simulator tests.`
- Current blocker refresh for `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, Swift source, XCTest source, renderer assets, app entitlements, Info.plist files, privacy manifests, background modes, WebKit renderer code, CDN dependencies, or network renderer behavior.

## Changed Files

Report:

- `ios/docs/reports/stage1-ios-l12-iphone12-simulator-pass-live-20260506-0411.md`

No Swift implementation files or XCTest files were changed in this batch. Existing Stage 1 iOS implementation and validation models remain in:

- `ios/Sources/FastMDMobileCore/`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

## Environment

- Repository: `/Users/wangweiyang/GitHub/fastmd`
- iOS package: `/Users/wangweiyang/GitHub/fastmd/ios`
- Xcode command-line tool: `/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild`
- SwiftPM package scheme discovered by `xcodebuild -list`: `FastMDMobile`
- Available simulator destination: `iPhone 12 (26.4.1)`
- SwiftPM deployment target in `ios/Package.swift`: iOS 14.0

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 153 tests with 0 failures. Covers L1 canonical fixture matrix, L11 renderer gates, L12 simulator/report guards, security, rich fixture, performance, accessibility, file IO, save integrity, and editor tests. |
| `xcodebuild -list` from `ios/` | PASS | Resolved the SwiftPM workspace and listed scheme `FastMDMobile`. |
| `xcrun simctl list devices available \| rg -n "iPhone 12\|iPhone 15\|iPhone"` from `ios/` | PASS | Listed an available `iPhone 12` simulator. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Built `FastMDMobileCore` for the iPhone 12 simulator destination and ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Ran `FastMDMobileCoreTests` on the iPhone 12 simulator destination. Executed 153 tests with 0 failures and ended with `** TEST SUCCEEDED **`. The xcresult path was `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_04-11-14-+0800.xcresult`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | Command succeeded, but no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was listed. It listed only the Mac as connected hardware, offline physical iOS-family devices, and simulator devices including `iPhone 12 (26.4.1)`. |
| `xcrun devicectl list devices --json-output /tmp/fastmd-ios-real-device-probe-20260506-0411.json` from `ios/` | BLOCKED for real-device completion | Command completed with a CoreDevice provider warning and listed physical iOS-family devices as `unavailable`. The unavailable iPhone-class device was an iPhone 15 Pro class model, not an iPhone 12-family device. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `find ios -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |

## Checklist Evidence

Supervisor can mark complete:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Evidence:

- `ios/docs/reports/stage1-ios-l12-iphone12-simulator-pass-live-20260506-0411.md`
- `swift test` passed with 153 tests.
- `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed.
- `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 153 tests.

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Reason:

- The current local device set has no connected physical iPhone 12-family device.
- Simulator validation now passes on the required iPhone 12 simulator destination, but that does not satisfy the physical real-device gate.
