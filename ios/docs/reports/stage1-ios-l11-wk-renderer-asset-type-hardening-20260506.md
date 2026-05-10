# Stage 1 iOS L11 WK Renderer Asset-Type Hardening - 2026-05-06

## Scope

Ran one bounded iOS-only implementation batch for the earliest still-open iOS-owned L11 conditional renderer cluster.

This batch did not edit Android files, root `Docs/**`, `.cron/**`, app entitlements, Info.plist files, privacy manifests, background modes, renderer assets, CDN dependencies, or network renderer behavior.

## Changed Files

- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-wk-renderer-asset-type-hardening-20260506.md`

## Implementation

- Added `unsupportedRendererAssetType` to `IOSRichRendererRequestBlockReason`.
- Hardened `IOSRichRendererRequestBlockingPolicy` so a future local WK renderer may load only bundled renderer file types appropriate to the request context:
  - main documents: `.html`, `.htm`
  - scripts: `.js`, `.mjs`
  - stylesheets: `.css`
  - fonts: `.woff`, `.woff2`, `.ttf`, `.otf`
  - images: `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.svg`
- Kept existing denials for network requests, external navigation, `javascript:` URLs, `data:` URLs, iframes, non-file schemes, non-bundled files, and path traversal outside the renderer bundle.
- Expanded request-blocking tests to prove allowed bundled context/file-type pairs and blocked unknown or mismatched bundled file types.

The current iOS renderer remains native Swift/SwiftUI/UIKit fallback. No production JS/CSS/font/HTML renderer assets or active WKWebView rich renderer source were introduced.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSRichRendererRequestBlockingPolicy` from `ios/` | PASS | Executed 3 focused request-blocking tests with 0 failures. |
| `swift test` from `ios/` | PASS | Executed 172 tests with 0 failures. |
| `find ios \( -path 'ios/.build' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print \| sort` from repository root | PASS | Empty output. No production-side JS/CSS/font/HTML renderer assets are present under `ios/`; SwiftPM build outputs, reports, and screenshot placeholders are excluded. |
| `rg -n "^\s*import\s+WebKit\b\|\bWKWebView\s*(\|\.)" ios/Sources` from repository root | PASS | Exit 1 with no matches. No production WebKit rich renderer import or constructor-style source was found. |

## Checklist Evidence For Supervisor

The supervising session can use this report as additional evidence for:

- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Evidence: request-blocking policy now rejects unknown bundled file types and context/file-type mismatches in addition to remote requests, external navigation, `javascript:`, `data:`, iframes, and non-bundled files.

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: current production inventory is empty, and future local renderer requests are constrained to known bundled renderer asset types.

- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: current production inventory is empty; full `swift test` still passes existing manifest/hash exact-match, duplicate rejection, tamper rejection, remote path rejection, loose path rejection, and bundled-resource discovery coverage.

## Still Open

- L12 iOS iPhone 12-class real-device validation remains open unless separate physical-device evidence exists. This batch ran SwiftPM validation and static renderer-surface checks only.
