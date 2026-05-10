# Stage 1 iOS L2 Policy And Profile Contracts Report - 2026-05-05

## Scope

Advanced one bounded iOS-owned L2 core-contract batch after the fixture matrix and initial core contracts. Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l2-policy-profiles-20260505.md`

## Implementation Notes

- Added `MobileLinkPolicy`, `MobileLinkPolicyDecision`, `MobileLinkDecisionKind`, and `MobileLinkBlockReason`.
- Default link policy allows `mailto:`, requires confirmation for `http:` / `https:`, blocks dangerous `data:`, `file:`, and `javascript:` schemes, and blocks remote resource loads by default.
- Added platform performance profile contracts covering Android and iOS with explicit flags for file IO off-main, parse/search off-main, lazy block rendering, bounded local image decode, and expensive animation reduction.
- Added concrete profiles for `androidLegacyEfficient`, `iOSPhone12Standard`, and `iOSMemoryConstrained`.
- Added `LocalRichRendererAssetPolicy` for native fallback and vendored local renderer bundles.
- Renderer asset policy defaults to offline native fallback, limits rich renderer scope to Mermaid/math fallbacks, and keeps network requests, CDN resources, external navigation, `data:` URLs, and iframes disabled even when a vendored local bundle is configured.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 15 tests with 0 failures. New tests covered link allow/confirm/block decisions, remote resource blocking, Android/iOS performance profile contract flags, native fallback renderer policy, and vendored local renderer policy. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | BLOCKED | Exit 70. Xcode reported: `Unable to find a device matching the provided destination specifier: { platform:iOS Simulator, OS:latest, name:iPhone 12 }`. Available destinations include `Stage1 iPhone 15 Pro`, but no `iPhone 12` simulator. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Supervisor can mark complete:

- L2: `Define link policy model with allowed, confirm, and blocked decisions.`
- L2: `Define platform performance profile model for Android and iOS.`
- L2: `Define local/offline rich renderer asset policy for any JS/CSS/font dependencies.`

Evidence:

- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l2-policy-profiles-20260505.md`
- `swift test` passed.

Keep open:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Blocker:

- The local Xcode simulator set does not include an `iPhone 12` destination, so the exact required iPhone 12 build/test gates cannot run in this environment.
