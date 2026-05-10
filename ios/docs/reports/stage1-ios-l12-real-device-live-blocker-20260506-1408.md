# Stage 1 iOS L12 Real-Device Live Blocker - 2026-05-06 14:08 CST

## Scope

- Worker ownership: `ios/**`
- Blueprint item advanced: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Shared Docs edited: no
- Android edited: no

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 207 XCTest cases with 0 failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS | An available `iPhone 12` simulator destination was listed. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | SwiftPM-generated `FastMDMobile` scheme built for the iPhone 12 simulator destination. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Executed 207 XCTest cases on the iPhone 12 simulator with 0 failures and 1 skipped test. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family validation | Connected device section listed the Mac only. Physical iOS devices appeared only in the offline section; the `iPhone 12` entry was under simulators. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family validation | Command outcome was `success`, but discovered physical iOS devices were unavailable and not iPhone 12-family hardware: one unavailable iPhone 15 Pro-class device and one unavailable iPad Pro-class device. Device names, identifiers, serials, ECIDs, hostnames, and full local paths are intentionally omitted. |

## Current L12 Result

The L12 physical-device validation gate remains open.

This machine can run the SwiftPM tests and the iPhone 12 simulator build/test gate, but the blueprint requires a connected physical iPhone 12-family device before the parity-complete release claim. No connected physical iPhone 12, iPhone 12 mini, iPhone 12 Pro, or iPhone 12 Pro Max was available during this batch.

## Required Manual Physical-Device Flow Still Open

| Required real-device flow | Result |
| --- | --- |
| Open Markdown document on physical iPhone 12-family hardware | OPEN |
| Render rich Markdown fixture on physical iPhone 12-family hardware | OPEN |
| Search within document on physical iPhone 12-family hardware | OPEN |
| Full source edit on physical iPhone 12-family hardware | OPEN |
| Block source edit on physical iPhone 12-family hardware | OPEN |
| Save writable document on physical iPhone 12-family hardware | OPEN |
| Rotate reader on physical iPhone 12-family hardware | OPEN |

## Supervisor Reconciliation Guidance

Can mark complete:

- None from the remaining iOS L12 open row. This batch refreshes validation evidence and confirms the blocker, but it does not complete physical iPhone 12-family validation.

Keep open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence path:

- `ios/docs/reports/stage1-ios-l12-real-device-live-blocker-20260506-1408.md`
