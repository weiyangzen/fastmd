# Stage 1 iOS L13 README Validation Refresh - 2026-05-06

## Scope

Ran one bounded iOS-owned documentation and validation batch for the iOS-owned L13 reconciliation surface:

- L13: `Update ios/README.md with final build/test commands after iOS skeleton lands.`
- L13: `Record validation reports under ios/docs/reports/.`

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, Swift source, XCTest source, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Changed Files

- `ios/README.md`
- `ios/docs/reports/stage1-ios-l13-readme-validation-refresh-20260506.md`

## README Updates

- Kept `swift test` as the minimum local SwiftPM validation gate.
- Kept focused `testIOSL11` and `testIOSL12` commands for conditional renderer and validation report gates.
- Kept the required iPhone 12 simulator `xcodebuild` build/test commands.
- Added the physical iPhone 12-family probe commands now supported by the iOS validation model:
  - `xcrun xctrace list devices`
  - `xcrun devicectl list devices --json-output -`
- Refreshed README reconciliation anchors to point at the latest iOS L11/L12 evidence reports.
- Kept the physical iPhone 12-family gate explicitly open until real hardware completes the Stage 1 open, render, search, edit, save, and rotate flow.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 136 XCTest cases with 0 failures. |
| `xcrun simctl list devices available \| rg -n "iPhone 12\|Stage1"` from `ios/` | PASS | Available simulator inventory includes `iPhone 12` and `Stage1 iPhone 15 Pro`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | Connected physical devices: Mac only. Offline physical iOS-family devices include an iPhone 15 Pro and an iPad. The `iPhone 12` entry is listed under simulators, so it cannot satisfy the physical-device gate. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for real-device completion | Parsed physical product types were iPhone 15 Pro class and iPad class, both unavailable; no connected `iPhone13,*` iPhone 12-family product type was present. Device identifiers and serial-like fields are intentionally omitted from this report. |

## Checklist Evidence

Supervisor can mark complete:

- L13: `Update ios/README.md with final build/test commands after iOS skeleton lands.`
- L13: `Record validation reports under ios/docs/reports/.`

Evidence paths:

- `ios/README.md`
- `ios/docs/reports/stage1-ios-l13-readme-validation-refresh-20260506.md`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Blocker:

- No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available in this batch. Simulator and probe evidence cannot close the physical-device gate without a real iPhone 12-family device and manual Stage 1 flow evidence.
