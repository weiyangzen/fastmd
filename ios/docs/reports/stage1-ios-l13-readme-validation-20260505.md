# Stage 1 iOS L13 README Validation - 2026-05-05

## Scope

Advanced one bounded iOS-owned L13 documentation-reconciliation batch.

Changes are limited to `ios/**`.

## Changed Files

Documentation:

- `ios/README.md`

Report:

- `ios/docs/reports/stage1-ios-l13-readme-validation-20260505.md`

## Implementation Notes

- Updated `ios/README.md` with the final local iOS Stage 1 build and test commands for the current SwiftPM skeleton.
- Documented `swift test` as the minimum local SwiftPM validation gate.
- Documented `git -C .. diff --check -- ios` as the iOS-only whitespace gate.
- Documented the iPhone 12 simulator `xcodebuild` build/test commands that match the blueprint.
- Added the one-time `xcrun simctl create 'iPhone 12'` command used when the exact simulator destination is absent but the device type and runtime are installed.
- Clarified that validation evidence stays under `ios/docs/reports/` for supervisor reconciliation.
- No Android files, top-level Docs files, WebKit renderer, JS/CSS/font asset, CDN dependency, network renderer, Info.plist, entitlement, privacy manifest, or background mode was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 111 tests with 0 failures. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `xcrun simctl list devices available \| rg -n "iPhone 12"` from repository root | PASS | Local CoreSimulator currently lists an available `iPhone 12` simulator destination. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Built `FastMDMobileCore` for `arm64-apple-ios14.0-simulator` against the iPhone Simulator 26.4 SDK. Xcode ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Executed 111 `FastMDMobileCoreTests` tests with 0 failures on the `iPhone 12` simulator destination. Xcode ended with `** TEST SUCCEEDED **`. |

Xcode test result bundle:

```text
/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.05_22-12-11-+0800.xcresult
```

## Checklist Evidence

Supervisor can mark complete:

- L13: `Update ios/README.md with final build/test commands after iOS skeleton lands.`
- L13: `Record validation reports under ios/docs/reports/.`

Evidence:

- `ios/README.md`
- `ios/docs/reports/stage1-ios-l13-readme-validation-20260505.md`
- `swift test` passed with 111 tests and 0 failures.
- `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed.
- `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 111 tests and 0 failures.

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Remaining blocker:

- No iPhone 12-family physical device validation was performed in this batch. Simulator validation can cover build/test gates, but the real-device parity-complete gate remains open until an iPhone 12 / 12 mini / 12 Pro / 12 Pro Max class device is available and exercised through the Stage 1 flow.
