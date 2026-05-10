# Stage 1 iOS L11 Renderer Manifest Duplicate-Path Batch - 2026-05-06

## Scope

Ran one bounded iOS-owned L11 batch for the earliest still-open iOS checklist cluster in `Docs/todos_20260505.md`: the conditional renderer gates for local renderer packaging/offline behavior, WKWebView request blocking, and renderer asset manifest/hash verification.

This batch stayed inside `ios/**`. It did not edit Android files, root `Docs/**`, `.cron/**`, renderer assets, entitlements, privacy manifests, background modes, WebKit renderer code, CDN dependencies, or network renderer behavior.

## Implementation Evidence

- Added `testIOSL11RendererAssetManifestHashAuditRejectsDuplicateManifestPaths` in `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`.
- The new XCTest directly covers duplicate manifest-path rejection for `IOSRendererAssetManifestHashAudit`.
- The test asserts that otherwise valid platform-local bundled renderer assets still fail Stage 1 manifest/hash verification when the manifest repeats a path.

This strengthens the existing future-asset coverage for the blueprint item:

- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

Current iOS runtime posture remains native fallback:

- No JS/CSS/font/HTML renderer assets are vendored under `ios/`.
- No production `ios/Sources/**` WebKit rich renderer code is present.
- Mermaid/math rich Markdown blocks remain native safe-card fallbacks and do not require vendored renderer assets or WKWebView.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 29 focused L11 tests with 0 failures, including the new duplicate manifest-path rejection test. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `rg -n "import WebKit\|WKWebView\(" ios/Sources ios/Tests` from repository root | PASS for production source posture | Matches were limited to XCTest names and temporary fixture source strings in `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`; no production `ios/Sources/**` match was reported. |
| `swift test` from `ios/` | PASS | Executed 139 XCTest cases with 0 failures and 0 unexpected failures. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |

## Supervisor Reconciliation Recommendation

Supervisor can mark the following iOS L11 checklist items complete based on existing conditional renderer implementation plus this refreshed validation evidence:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
- `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

Evidence paths:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-renderer-manifest-duplicate-path-batch-20260506.md`

No L12 real-device claim is made by this batch.
