# Stage 1 iOS L11 Renderer Manifest Path Hardening - 2026-05-06

## Scope

Ran one bounded iOS-owned implementation batch for the earliest still-open iOS-owned checklist cluster in `Docs/Stage1_Mobile_Blueprint.md`: L11 conditional local renderer packaging/offline and renderer asset manifest/hash verification tests.

This batch only touched `ios/**`. It did not edit Android files, root `Docs/**`, `.cron/**`, renderer assets, WebKit runtime code, entitlements, Info.plist, privacy manifests, or background modes.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Tests:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l11-renderer-manifest-path-hardening-20260506.md`

## Implementation Notes

- Tightened `IOSRendererAssetManifestEntry.isPlatformLocalIOSPath` so renderer manifest paths now reject query strings, fragments, leading/trailing whitespace, and embedded whitespace in addition to remote URLs, traversal, and backslashes.
- Tightened `IOSRendererAssetManifestEntry.isBundledRendererResourcePath` so bundled-resource status requires a valid iOS-local path first.
- Mirrored the same path checks in `IOSLocalRendererConditionalGateAudit.rendererAssetPathsArePlatformLocal`, so manually supplied/discovered renderer paths with query, fragment, or whitespace fail the conditional packaging gate.
- Added XCTest coverage for unsafe manifest paths such as:
  - `ios/Resources/FastMDRenderers/renderer.js?cache=1`
  - `ios/Resources/FastMDRenderers/renderer.js#hash`
  - `ios/Resources/FastMDRenderers/renderer .js`
  - ` ios/Resources/FastMDRenderers/renderer.js`
- The current iOS runtime remains native-fallback only for Mermaid/math rich Markdown blocks. No JS/CSS/font/HTML renderer assets are present in production iOS paths, and no production iOS source imports WebKit or constructs `WKWebView`.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11RendererAssetManifest` from `ios/` | PASS | Built `FastMDMobileCore` and executed 6 focused renderer manifest tests with 0 failures, including the new query/fragment/whitespace rejection case. |
| `swift test` from `ios/` | PASS | Executed 176 XCTest cases with 0 failures. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported after the implementation and report were written. |
| `find ios \( -path 'ios/.build' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print \| sort` from repository root | PASS | Empty output. No production JS/CSS/font/HTML renderer assets were found under `ios/`. |
| `rg -n "^\s*import\s+WebKit\b|\bWKWebView\s*\(" ios/Sources` from repository root | PASS | Exit 1 with empty output. No production iOS source imports WebKit or constructs `WKWebView`. |

## Checklist Evidence

Supervisor can mark complete or keep complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: no production JS/CSS/font/HTML renderer assets are present; existing conditional renderer tests cover native fallback and future vendored local asset mode; this batch hardens local asset path validation.
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: manifest/hash tests now reject missing, duplicate, tampered, remote, loose, query-string, fragment, and whitespace-tainted manifest paths.
- L13: `Record validation reports under ios/docs/reports/.`
  - Evidence: this iOS-local report records implementation and validation results.

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
  - Reason: this batch did not run or complete physical iPhone 12-family hardware validation.
