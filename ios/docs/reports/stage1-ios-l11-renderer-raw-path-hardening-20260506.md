# Stage 1 iOS L11 Renderer Raw Path Hardening - 2026-05-06

## Scope

One bounded iOS-owned implementation batch for the earliest open iOS checklist cluster:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

No Android files, root `Docs/**`, `.cron/**`, entitlements, Info.plist files, privacy manifests, background modes, WebKit renderer code, CDN dependencies, or renderer assets were edited.

## Implementation

- Tightened `IOSLocalRendererConditionalGateAudit.rendererAssetPathsArePlatformLocal` so raw discovered renderer asset paths must:
  - start with `ios/`
  - avoid URL schemes such as `https://`
  - avoid `..` traversal
  - avoid backslash-separated paths
- Added `testIOSL11ConditionalRendererAuditRejectsUnsafeRawAssetPaths` to prove traversal, remote, and backslash raw asset paths cannot satisfy the local renderer packaging gate, while a bundled iOS renderer path remains accepted for the future vendored-asset case.

The current iOS runtime remains native fallback-only. Mermaid/math render as native safe-card fallback blocks. No JS/CSS/font/HTML renderer assets are present under `ios/`, and no production WebKit rich renderer implementation is present.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | 34 focused L11 XCTest cases executed, 0 failures. Includes new `testIOSL11ConditionalRendererAuditRejectsUnsafeRawAssetPaths`. |
| `swift test` from `ios/` | PASS | 149 XCTest cases executed, 0 failures. |
| `git -C .. diff --check -- ios` from `ios/` | PASS | No whitespace errors reported. |
| `find ios -path 'ios/.build' -prune -o -type f \( -iname '*.js' -o -iname '*.css' -o -iname '*.html' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.woff' -o -iname '*.woff2' \) -print \| sort` from repository root | PASS | Empty output; no vendored JS/CSS/font/HTML renderer assets are currently present under `ios/`. |
| `rg -n "^import WebKit$|WKWebView\(" ios/Sources ios/Tests` from repository root | REVIEWED | No production `ios/Sources/**` WebKit import or construction was found. The only match was an XCTest method name containing `WKWebView`, not a WebKit import or rich renderer construction. |

## Checklist Evidence

The supervisor can mark these iOS L11 checklist items complete for the current native-fallback Stage 1 iOS runtime:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Current status: satisfied as not applicable because no renderer assets are used.
  - Future asset-present path: covered by tests requiring bundled local iOS paths and rejecting loose, remote, traversal, duplicate, missing, and tampered asset evidence.
- `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Current status: satisfied as not applicable because no WKWebView rich-rendering surface is active.
  - Future WKWebView path: covered by request-policy tests that block network subresources, external navigation, `javascript:`, `data:`, iframe contexts, and non-bundled file loads.
- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Current status: satisfied as not applicable because no JS/CSS/font assets are vendored.
  - Future asset-present path: covered by manifest/hash tests that require exact bundled resource paths, byte counts, and SHA-256 hashes.

## Evidence Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-renderer-raw-path-hardening-20260506.md`
