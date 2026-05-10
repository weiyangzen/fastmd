# Stage 1 iOS L12 Device Probe State Normalization

- Generated: 2026-05-06T07:24:00+08:00
- Scope: iOS-only L12 physical-device probe hardening and validation refresh.
- Ownership: `ios/**` only.

## Implementation

The iOS `devicectl` table parser now normalizes parenthesized availability state values before classifying connection status. This preserves the existing fail-closed behavior for unsupported states while accepting current `devicectl` table variants such as `available (paired)` and `unavailable (paired)`.

Evidence:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`: `parseTableLine` reads `rawState`, normalizes it, then checks the known state allowlist.
- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`: `normalizedTableState(_:)` strips state detail after the first whitespace token.
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`: `testIOSL12DevicectlTableParserNormalizesParenthesizedAvailabilityState` covers connected `available (paired)` iPhone 12-family hardware and disconnected `unavailable (paired)` hardware.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12DevicectlTableParserNormalizesParenthesizedAvailabilityState` | PASS | 1 XCTest executed, 0 failures. |
| `swift test` | PASS | 180 XCTest cases executed, 0 failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | PASS | iPhone 12 simulator available: `1B6FEADC-308B-4069-B734-3C9C207E633F`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | PASS | `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | PASS | `** TEST SUCCEEDED **`; 180 XCTest cases executed, 0 failures; result bundle under local DerivedData. |
| `xcrun xctrace list devices` | BLOCKED for real-device completion | No connected physical iPhone 12-family device observed; only local Mac, offline physical devices, and simulators. |
| `xcrun devicectl list devices --json-output -` | BLOCKED for real-device completion | Physical devices reported by current output are unavailable and are not connected iPhone 12-family hardware. |
| `git -C .. diff --check -- ios` | PASS | No whitespace errors reported. |

## Conditional Renderer Evidence

- No iOS JS/CSS/font/HTML renderer assets were discovered outside ignored validation/build directories.
- No WKWebView rich renderer source is used by the native fallback path.
- The current batch did not introduce any renderer assets or WebKit rendering surface.

## Supervisor Checklist Recommendations

The supervisor can mark the following iOS checklist items complete with this report plus existing iOS report anchors:

- `Run iOS iPhone 12 simulator build.`
- `Run iOS iPhone 12 simulator tests.`
- `Record validation reports under ios/docs/reports/.`

Keep the following item open:

- `Run iOS iPhone 12-class real-device validation before parity-complete release claim.` Current probes did not show a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completing the Stage 1 manual open, render, search, edit, save, and rotate flow.

