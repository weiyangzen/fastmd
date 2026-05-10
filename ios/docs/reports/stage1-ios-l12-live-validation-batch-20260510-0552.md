# Stage 1 iOS L12 Live Validation Batch - 2026-05-10 05:52 CST

## Scope

- Worker lane: FastMD Stage 1 Mobile iOS live lane.
- Ownership: iOS-only. This batch changed only `ios/docs/reports/`.
- Batch selected from authoritative checklist: L12, "Run iOS iPhone 12-class real-device validation before parity-complete release claim."
- Reason: all earlier iOS-owned implementation, fixture, core-contract, document-entry, renderer, reader, editing, performance/security, accessibility/diagnostics, automated test, simulator validation, performance, security, and rich fixture rows are already marked complete in the authoritative blueprint. The daily todo snapshot also shows the only unfinished iOS-owned item is physical iPhone 12-family real-device validation.

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | Pass | 249 tests, 0 failures, completed at 2026-05-10 05:50:06 CST. |
| `xcodebuild -list` from `ios/` | Pass | Scheme `FastMDMobile` is present. Xcode also printed `Supported platforms for the buildables in the current scheme is empty`, which is expected for the current SwiftPM library skeleton and did not block scheme discovery. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | Pass | `** BUILD SUCCEEDED **`, completed at 2026-05-10 05:52 CST using iPhoneSimulator 26.4 SDK and iOS 14.0 simulator deployment target. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | Pass | `** TEST SUCCEEDED **`, 249 tests executed, 1 skipped, 0 failures, completed at 2026-05-10 05:52 CST. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.10_05-52-01-+0800.xcresult`. |
| `xcrun xctrace list devices` from repo root | Probe pass, real-device gate still blocked | Physical device section listed only the local Mac as connected. Offline device section listed an unavailable iPhone 15 Pro-class device and an iPad. Simulator section included an `iPhone 12` simulator, not physical hardware. |
| `xcrun devicectl list devices --json-output -` from repo root | Probe pass, real-device gate still blocked | JSON outcome was `success`. Parsed physical inventory contained an unavailable iPhone 15 Pro-class device and an available paired iPad Pro 11-inch 4th generation. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. The command also emitted `Failed to load provisioning parameter list due to error: ... No provider was found.`, but still returned JSON with outcome `success`. |

## Physical Device Gate Status

The physical iPhone 12-family validation gate remains **blocked/open**.

Exact blocker:

- No connected physical iPhone 12-family device was available during this batch.
- The only iPhone 12 evidence in `xctrace` was a simulator row.
- The connected/known physical-device inventory did not contain iPhone 12-family hardware.
- No physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completed the required Stage 1 manual flow: open, render, search, edit, save, and rotate.

This report is validation evidence and must not be used to mark the physical iPhone 12-family real-device row complete. It is suitable evidence for keeping that row open with a fresh, command-backed blocker.

## Checklist Recommendation

Supervisor can keep the following row open with this report as current blocker evidence:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

No new blueprint checklist row should be marked complete from this batch because the only selected iOS-owned open row requires a completed physical-device flow, and that hardware was not connected.
