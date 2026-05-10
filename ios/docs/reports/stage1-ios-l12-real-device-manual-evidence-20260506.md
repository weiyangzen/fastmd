# Stage 1 iOS L12 Real-Device Manual Evidence Guard - 2026-05-06

## Scope

Ran one bounded iOS-owned implementation and validation batch for the earliest iOS-owned checklist item that remains open after iPhone 12 simulator validation:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l12-real-device-manual-evidence-20260506.md`

## Implementation Notes

- Added `IOSStageOneRealDeviceFlowEvidence`, a per-step evidence row for real-device validation.
- Added `IOSStageOneRealDeviceManualFlowAudit`, which requires completion evidence for every required Stage 1 real-device flow step.
- Tightened `IOSStageOneRealDeviceValidationReport.status` so a physical iPhone 12-family device plus a completed step set is not enough to pass. The report now also requires non-empty, timestamped manual evidence for:
  - Open Markdown
  - Render rich fixture
  - Search document
  - Full source edit
  - Block source edit
  - Save writable document
  - Rotate reader
- Kept the previous fail-closed behavior for missing physical iPhone 12-family hardware and simulator-only iPhone 12 entries.
- Kept custom-named physical hardware support from the prior batch: a connected device can satisfy the family guard by supplied `hardwareModel`, not only visible device name.
- The report markdown now includes both declared flow results and manual evidence rows.

## Current Local Device Probe

`xcrun xctrace list devices` reports:

- Connected physical devices: `Mac` only.
- Offline physical iOS devices: `Turbulence` and `王威扬的iPad`.
- Simulators: includes `iPhone 12 (26.4.1) (1B6FEADC-308B-4069-B734-3C9C207E633F)`.
- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max devices: `0`.

The available `iPhone 12` entry is under the simulator section. It cannot satisfy the physical-device validation gate.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | Executed 11 focused L12 tests with 0 failures. New coverage includes `testIOSL12RealDeviceValidationRequiresManualEvidenceForEveryCompletedStep`. |
| `swift test` from `ios/` | PASS | Executed 128 XCTest cases with 0 failures. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `xcrun simctl list devices available \| rg -n "iPhone 12\|Stage1"` from `ios/` | PASS | Local CoreSimulator lists `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)` and `Stage1 iPhone 15 Pro (63DAFAF1-789A-4206-8B3C-6B87048AFDF1) (Shutdown)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Build resolved the SwiftPM `FastMDMobile` scheme for `arm64-apple-ios14.0-simulator` and ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Ran on the iPhone 12 simulator destination and executed 128 tests with 0 failures. Xcode ended with `** TEST SUCCEEDED **`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_00-18-47-+0800.xcresult`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | No connected physical iPhone 12-family device was listed. The only connected device was `Mac`; the `iPhone 12` entry appeared under simulators. |

## Checklist Evidence

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence paths for the open blocker:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-real-device-manual-evidence-20260506.md`

No L12 real-device completion claim should be made from this batch. Completion still requires a connected physical iPhone 12-family device and timestamped manual evidence for the full Stage 1 open, render, search, full source edit, block source edit, save writable document, and rotate reader flow.
