# Stage 1 iOS L11 Conditional Renderer Revalidation - 2026-05-06 04:28 CST

## Scope

Ran one bounded iOS-owned L11 validation batch for the earliest still-open iOS checklist items in `Docs/Stage1_Mobile_Blueprint.md`:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
- `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, Swift source, XCTest source, renderer assets, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, WebKit renderer code, or network renderer behavior.

## Implementation Evidence

No new Swift implementation was required in this batch. The current iOS implementation already contains native Swift evidence models and XCTest coverage for the conditional renderer gates:

- `IOSRendererAssetInventory` discovers only platform-local bundled renderer resources under accepted `FastMDRenderers` roots and scans iOS Swift sources for WebKit rich-renderer usage.
- `IOSLocalRendererConditionalGateAudit` maps the three L11 conditional checklist lines to not-applicable, required-and-satisfied, missing, or blocked states.
- `IOSRendererAssetManifestHashAudit` verifies exact platform-local manifest paths, byte counts, SHA-256 hashes, and duplicate-path rejection when renderer assets exist.
- `IOSRichRendererRequestBlockingPolicy` blocks remote subresources, external navigation, `javascript:` URLs, `data:` URLs, iframes, and non-bundled file URLs for any future local rich renderer surface.
- `MarkdownNativeRenderer` currently renders Mermaid, math, and generic unsafe rich blocks as native safe cards or sanitized native fallback payloads, so no JS/CSS/font/HTML renderer asset or WKWebView surface is active.

Evidence files:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`
- `ios/Sources/FastMDMobileCore/MarkdownNativeRenderer.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 39 focused L11 XCTest cases with 0 failures. Covered native-fallback conditional renderer gates, future vendored asset gates, WKWebView safe/unsafe policy cases, renderer asset inventory, manifest/hash verification, parser/source range, rich snapshots, layout, file/save, security, performance, memory, accessibility, diagnostics, and recovery gates. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `swift test` from `ios/` | PASS | Executed 156 XCTest cases with 0 failures. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

Completion rationale:

- The current iOS runtime is native fallback-only, so the three conditional gates are not applicable for the active implementation.
- The package still implements and tests the asset-present path: vendored assets must live under accepted iOS bundled resource roots, load offline, and match exact manifest SHA-256 entries.
- The package implements and tests the WKWebView-present path: any future local WKWebView rich surface must use vendored local assets and block network requests, external navigation, dangerous URL schemes, iframes, and non-bundled file URLs.
- The live repository scan found no JS/CSS/font/HTML renderer assets under `ios/`.
- Focused L11 tests and full SwiftPM tests passed in this batch.

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Reason:

- This batch did not run a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max flow. Simulator and SwiftPM validation do not satisfy the real-device gate.
