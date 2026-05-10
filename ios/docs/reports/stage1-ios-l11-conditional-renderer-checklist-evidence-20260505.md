# Stage 1 iOS L11 Conditional Renderer Checklist Evidence - 2026-05-05

## Scope

Advanced one bounded iOS-owned L11 automated-test/evidence batch for the earliest still-open iOS-owned checklist cluster in the root blueprint:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
- `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l11-conditional-renderer-checklist-evidence-20260505.md`

## Implementation Notes

- Added `IOSConditionalRendererChecklistEvidence.Item`, a stable native Swift evidence row that preserves the exact blueprint checklist text for each conditional renderer gate.
- Extended `IOSConditionalRendererChecklistEvidence.checklistItems` to expose each gate's status, checklist-satisfied flag, and concise evidence summary.
- Extended `IOSConditionalRendererGateReport.markdown` with a second table keyed by the exact blueprint checklist item text, so the supervising reconciliation pass does not need to infer abbreviated report labels.
- Added focused L11 tests for the current native-fallback/no-assets path and for a future vendored-asset path that requires local packaging and manifest/hash verification.
- The current iOS renderer remains native Swift fallback-only. No WebKit renderer, `WKWebView` rich surface, JavaScript, CSS, font, HTML renderer asset, CDN dependency, network renderer, Info.plist, entitlement, privacy manifest, background mode, Android change, or top-level Docs change was introduced.

## Conditional Gate Evidence

| Blueprint checklist item | Current iOS status | Checklist satisfied | Evidence |
| --- | --- | --- | --- |
| `Add local renderer packaging/offline tests if JS renderer assets are used.` | `notApplicableNativeFallback` | `true` | `find ios ...` discovered no JS/CSS/font/HTML renderer assets; native Mermaid/math fallback cards do not require local JS packaging. Future vendored assets are covered by tests requiring packaged local assets. |
| `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.` | `notApplicableNativeFallback` | `true` | `IOSRendererAssetInventory` scans Swift sources for WebKit rich-renderer code; current rich fallbacks use `.nativeSafeCard`, not `.localWKWebView`. Future WKWebView use remains gated by `IOSReleaseSecurityPosture.richRendererStatus`. |
| `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.` | `notApplicableNativeFallback` | `true` | No renderer assets are discovered today. Future discovered assets require platform-local manifest entries with matching byte counts and SHA-256 hashes before the conditional gate is satisfied. |

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 22 focused L11 tests with 0 failures. New tests: `testIOSL11ConditionalRendererChecklistItemsMatchBlueprintOpenLines` and `testIOSL11ConditionalRendererChecklistItemsExposeFutureRequiredAssetGates`. |
| `swift test` from `ios/` | PASS | Executed 122 tests with 0 failures. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `xcrun simctl list devices available \| rg -n "iPhone 12"` from repository root | PASS | Local CoreSimulator lists `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

Evidence paths:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-conditional-renderer-checklist-evidence-20260505.md`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Residual blocker:

- This batch did not run a physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max device flow. The real-device parity-complete release gate must remain open until eligible hardware completes open, render, search, edit, save, and rotate validation.
