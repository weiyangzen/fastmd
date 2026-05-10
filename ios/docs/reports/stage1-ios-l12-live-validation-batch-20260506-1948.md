# Stage 1 iOS L12 Live Validation Batch - 2026-05-06 19:48 CST

## Scope

One bounded iOS-only live-lane batch for the remaining iOS-owned L12 validation surface.

Authoritative inputs read:

- `Docs/Stage1_Mobile_Blueprint.md`
- `Docs/todos_20260506.md`

Files changed by this batch:

- `ios/docs/reports/stage1-ios-l12-live-validation-batch-20260506-1948.md`

No Android files, shared Docs checklists, or cron files were edited.

## Batch Selection

The blueprint and daily todo snapshot show the iOS implementation lanes through L11 complete, and the iOS-owned open L12 item is:

- `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

This batch revalidated the iOS SwiftPM test suite and iPhone 12 simulator gates, then probed connected physical-device availability. The physical iPhone 12-family gate remains blocked because no connected iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 216 XCTest cases with 0 failures in 15.449 seconds. Includes the canonical fixture matrix, native renderer, L11 validation gates, and L12 real-device guard tests. |
| `xcrun simctl list devices 'iOS' available` from repo root | PASS | Current CoreSimulator inventory includes an available `iPhone 12` simulator under iOS 26.4. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Built `FastMDMobileCore` for iPhone Simulator arm64 with `target arm64-apple-ios14.0-simulator`; Xcode ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Ran on the `iPhone 12` simulator. Executed 216 XCTest cases, with 1 simulator-only command-parity skip and 0 failures; Xcode ended with `** TEST SUCCEEDED **`. Result bundle: `~/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_19-46-22-+0800.xcresult`. |
| `xcrun devicectl list devices` from repo root | BLOCKED for physical iPhone 12-family completion | Command returned device inventory, but only unavailable non-iPhone-12-family physical iOS-family devices were present: one `iPhone16,1` and one `iPad14,4`. Device names, hostnames, serials, identifiers, and local paths are intentionally omitted. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family completion | Connected devices section listed the Mac only. Offline physical iOS-family devices were not iPhone 12-family validation candidates, and the `iPhone 12` entry appeared under simulators. |

## Real-Device Gate Status

The L12 physical-device gate remains open.

Reasons:

- No connected physical `iPhone13,1`, `iPhone13,2`, `iPhone13,3`, or `iPhone13,4` hardware signal was available in `devicectl`.
- No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max appeared in `xctrace`.
- The available `iPhone 12` is a simulator destination and cannot satisfy the blueprint's real-device validation requirement.
- The required manual Stage 1 flow was not run on physical iPhone 12-family hardware in this batch: open Markdown, render canonical rich fixture, search, full source edit, block source edit, save writable document, and rotate reader.

## Checklist Evidence

Supervisor can treat this report as fresh validation evidence for already-complete simulator rows:

- L12: `Run iOS iPhone 12 simulator build.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed in this batch.
- L12: `Run iOS iPhone 12 simulator tests.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed in this batch.

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
  - Evidence path: `ios/docs/reports/stage1-ios-l12-live-validation-batch-20260506-1948.md`
  - Blocker: no connected eligible physical iPhone 12-family device is available to run the full Stage 1 manual validation flow.

No newly open iOS checklist item can be marked complete from this batch.
