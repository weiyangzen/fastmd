# Stage 1 iOS L11 Conditional Renderer Evidence Path Hardening - 2026-05-06 11:03 +0800

## Scope

Bounded iOS live-lane batch for the earliest still-open iOS-owned checklist rows in L11:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

This batch stayed under `ios/**`. No Android files, root `Docs/**` checklist files, or `.cron/**` files were edited.

## Implementation

- Hardened `IOSCurrentSourceConditionalRendererCompletionEvidence.evidencePathIsIOSLocalReport` so supervisor completion evidence paths must remain plain iOS-local Markdown report paths and reject query strings, fragments, and Markdown table delimiters.
- Extended the focused XCTest coverage to reject `ios/docs/reports/*.md?cache=1`, `ios/docs/reports/*.md#row`, and `ios/docs/reports/*|*.md` evidence paths.

The current iOS renderer mode remains native fallback only:

- No production JS/CSS/font/HTML renderer assets were discovered under `ios/` outside ignored validation/build/report/screenshot paths.
- No production `WebKit` import or `WKWebView` rich renderer construction was found under `ios/Sources`.
- Mermaid, math, details, generic HTML fallback, and other rich fallback surfaces remain native Swift safe-card/fallback presentations.

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11CurrentSourceConditionalRendererCompletionEvidenceRequiresMarkdownReportFile` from `ios/` | PASS | 1 XCTest, 0 failures. |
| `swift test` from `ios/` | PASS | 201 XCTest cases, 0 failures, 0 unexpected failures. |
| `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print \| sort` | PASS | Empty output; no production iOS renderer assets discovered. |
| `rg -n "^[[:space:]]*import[[:space:]]+(@[A-Za-z0-9_]+[[:space:]]+)*(typealias\|class\|enum\|func\|let\|protocol\|struct\|var[[:space:]]+)?WebKit\\b\|\\bWKWebView[[:space:]]*(\\(\|\\.)" ios/Sources --glob '*.swift'` | PASS | Exit 1 with empty output; no production WebKit/WKWebView rich renderer source found. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | PASS | Found available simulator: `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |

## Supervisor Completion Recommendations

The supervisor can mark these L11 rows complete for the current iOS native-fallback renderer mode:

| Blueprint checklist item | Status | Evidence |
| --- | --- | --- |
| Add local renderer packaging/offline tests if JS renderer assets are used. | COMPLETE | Current production inventory has no JS/CSS/font/HTML renderer assets; Swift tests cover native-fallback not-applicable mode and future vendored asset mode. |
| Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | COMPLETE | Current production source has no WebKit/WKWebView rich renderer surface; Swift tests cover future WKWebView request-blocking requirements. |
| Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | COMPLETE | Current production inventory has no renderer assets; Swift tests require exact local paths, bundled resource declarations, byte counts, and SHA-256 hashes when assets exist. |
| Record validation reports under `ios/docs/reports/`. | COMPLETE FOR THIS BATCH | This report is the iOS-local evidence path for the batch. |

## Open Items Preserved

- iOS iPhone 12 simulator build/test rows are not claimed by this batch; only simulator availability was probed.
- iOS iPhone 12-class real-device validation remains open unless separate physical-device evidence exists.
- iOS performance, iOS security audit, and rich fixture render report rows should be reconciled from their dedicated reports, not from this L11 evidence-path hardening batch alone.
