# Stage 1 iOS L11 Renderer Automation Report - 2026-05-05

## Scope

Advanced one bounded iOS-owned L11 automated-test batch after existing iOS L6, L7, L9, and L10 evidence.

Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Golden snapshot placeholders:

- `ios/docs/screenshots/golden/rich-preview-light-compact.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-light-default.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-light-large.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-light-reader.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-dark-compact.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-dark-default.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-dark-large.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-dark-reader.snapshot.txt`

Report:

- `ios/docs/reports/stage1-ios-l11-renderer-automation-20260505.md`

## Implementation Notes

- Added `IOSParserContractAudit` to make parser contract checks testable for valid source ranges, monotonic block ranges, unique block identities, source byte counts, and required canonical Markdown block kinds.
- Added `IOSSourceRangeMappingAudit` to validate that every parser source range maps back to a non-empty Swift `String` slice and that mapped slice byte counts match the recorded UTF-8 range length.
- Added `IOSRendererSnapshotSignatureBuilder` for deterministic native renderer snapshot signatures across light/dark themes and all four iOS font tiers. These are textual SwiftPM skeleton golden placeholders, not iPhone simulator screenshots.
- Added `IOSLayoutSafetyAudit` to assert no page-level horizontal overflow for table/code blocks, stable block identity, bounded content width, labelled icon-only controls, and 44pt minimum tappable control posture.
- Added four L11 XCTest gates covering parser contracts, source-range mapping, light/dark four-tier golden signatures, and layout safety.
- No Android files, top-level Docs files, WebKit renderer, JS/CSS/font asset, CDN dependency, network renderer, Info.plist, entitlement, privacy manifest, or background mode was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 4 focused L11 tests with 0 failures: parser contract, source-range mapping, light/dark four-tier snapshot signatures, and layout safety. |
| `swift test` from `ios/` | PASS | Executed 95 tests with 0 failures. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | BLOCKED | Exit 70. Xcode reported: `Unable to find a device matching the provided destination specifier: { platform:iOS Simulator, OS:latest, name:iPhone 12 }`. The requested iPhone 12 simulator is not installed. The scheme resolves and available destinations include `Stage1 iPhone 15 Pro`, iPhone 16 family, iPhone 17 family, iPhone Air, iPhone SE, iPads, and a connected iPad, but no iPhone 12 simulator. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add parser contract tests.`
- L11: `Add source range mapping tests.`
- L11: `Add rich renderer golden/snapshot tests for light theme across four font tiers.`
- L11: `Add rich renderer golden/snapshot tests for dark theme across four font tiers.`
- L11: `Add layout safety tests for overlap, horizontal overflow, and tappable controls.`

Evidence:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/screenshots/golden/rich-preview-*.snapshot.txt`
- `ios/docs/reports/stage1-ios-l11-renderer-automation-20260505.md`
- `swift test --filter FastMDMobileCoreTests/testIOSL11` passed.
- `swift test` passed.

Keep open:

- L11 remaining gates not directly completed by this batch: file access tests, save integrity tests, malicious HTML fixture tests, malicious link fixture tests, remote image privacy tests, local renderer packaging/offline tests if JS renderer assets are used, WKWebView request-blocking tests if local JS renderer surfaces are used, renderer asset manifest/hash verification tests if assets are vendored, log redaction tests, performance tests, memory stress tests, accessibility smoke tests, and process recovery tests.
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Blocker:

- The exact iPhone 12 simulator destination required by the blueprint is not installed locally, so mandatory iPhone 12 build/test gates remain blocked in this environment.
