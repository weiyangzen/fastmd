# Stage 1 iOS L11 WKWebView Request Policy Root Hardening - 2026-05-06

## Scope

Ran one bounded iOS-owned implementation batch for the earliest still-open iOS-owned checklist cluster in `Docs/Stage1_Mobile_Blueprint.md`: L11 conditional local renderer and WKWebView request-blocking gates.

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, renderer assets, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or production WebKit renderer code.

## Implementation

- Hardened `IOSRichRendererRequestBlockingPolicy` so a request to the bundled renderer root directory itself is blocked. Only file URLs strictly below the bundled renderer root may be allowed.
- Added XCTest coverage for two local-file bypass cases:
  - direct request to the renderer root directory;
  - `..` traversal from the renderer root toward a sibling directory.
- Existing policy coverage continues to block remote subresources, external navigation, `javascript:` URLs, `data:` URLs, iframes, unsupported schemes, missing URLs, and non-bundled file URLs.

## Changed Files

- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-wkwebview-request-policy-root-hardening-20260506.md`

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSRichRendererRequestBlockingPolicy` from `ios/` | PASS | Executed 2 focused request-policy tests with 0 failures. |
| `swift test` from `ios/` | PASS | Executed 158 XCTest cases with 0 failures. |
| `rg -n "[ \t]+$" ios/Sources/FastMDMobileCore/FastMDMobileCore.swift ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift ios/docs/reports/stage1-ios-l11-wkwebview-request-policy-root-hardening-20260506.md` from repository root | PASS | Empty output. No trailing whitespace found in touched files. |
| `find ios -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer assets are currently vendored under `ios/`. |
| `rg -n "^\s*import\s+WebKit\b|\bWKWebView\s*\(" ios/Sources` from repository root | PASS | Empty output. No production iOS source imports WebKit or constructs `WKWebView`. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`

Supporting evidence:

- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-wkwebview-request-policy-root-hardening-20260506.md`

Still supported by existing iOS evidence, with no new assets introduced:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Reason: this batch did not have a connected iPhone 12-family physical device and did not attempt a real-device manual flow.
