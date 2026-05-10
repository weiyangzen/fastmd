# Stage 1 iOS Rich Renderer Runtime Policy Report - 2026-05-05

## Scope

Closed the remaining iOS-owned L5 local rich renderer runtime policy items without adding a WebKit, JavaScript, CSS, font, CDN, or network renderer dependency.

Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`
- `ios/Sources/FastMDMobileCore/MarkdownNativeRenderer.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l5-rich-renderer-runtime-policy-20260505.md`

## Implementation Notes

- Added `RichRendererPackagingStatus` and `LocalRichRendererRuntimeAudit` so the iOS core can explicitly distinguish native fallback rendering from a vendored local renderer bundle.
- The default iOS rich renderer runtime remains `.nativeFallbackOnly`.
- Native fallback mode reports `notRequiredNativeFallback`, does not require bundled JS/CSS/font assets, and must keep network requests, CDN resources, external navigation, `data:` URLs, and iframes disabled.
- Vendored local renderer mode remains modeled for future use, but it now fails audit unless a local bundle root and asset names are declared.
- Extended Mermaid and block math presentation payloads with `NativeMarkdownRichFallbackSurface.nativeSafeCard`, `requiresVendoredRendererAssets`, `allowsExternalNavigation`, and `allowsRemoteSubresources`.
- Mermaid and block math continue to render as native safe cards in Stage 1. No `WKWebView` render surface is introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 43 tests with 0 failures. New tests `testNativeRichRendererRuntimeAuditRequiresNoBundledAssets` and `testVendoredRichRendererRuntimeAuditRequiresLocalAssets` passed. Existing Mermaid/math safe-card tests now assert native surface, no vendored assets, no network requests, no external navigation, and no remote subresources. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) | sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `rg -n "import WebKit\|WKWebView\|WKNavigationDelegate\|javaScriptEnabled\|loadHTMLString\|evaluateJavaScript" ios/Sources ios/Tests \|\| true` from repository root | PASS | No active WebKit import, WKWebView type, navigation delegate, HTML loading, or JavaScript execution API usage was found. The only match is the inert enum case `NativeMarkdownRichFallbackSurface.localWKWebView`, which is not used by the Stage 1 native fallback path. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | BLOCKED | Exit 70. Xcode reported: `Unable to find a device matching the provided destination specifier: { platform:iOS Simulator, OS:latest, name:iPhone 12 }`. Available iOS simulator destinations include `Stage1 iPhone 15 Pro`, iPhone 16 family, iPhone 17 family, iPhone Air, iPhone SE, and iPads, but no iPhone 12. |
| `xcodebuild -scheme FastMDMobile -destination 'id=63DAFAF1-789A-4206-8B3C-6B87048AFDF1' test` from `ios/` | PASS | Ran on available `Stage1 iPhone 15 Pro` simulator, iOS 18.6. Executed 43 tests with 0 failures. Xcode ended with `** TEST SUCCEEDED **`. |

## Checklist Evidence

Supervisor can mark complete:

- L5: `Use vendored local JS renderer assets for Mermaid/math only if native fallback is insufficient.`
- L5: `Ensure JS renderer assets are packaged locally and never loaded from CDN.`
- L5: `Block network and external navigation from any local render surface.`

Evidence:

- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`
- `ios/Sources/FastMDMobileCore/MarkdownNativeRenderer.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l5-rich-renderer-runtime-policy-20260505.md`
- `swift test` passed.
- Available-simulator `xcodebuild test` passed.

Keep open:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Blocker:

- The exact iPhone 12 simulator destination required by the blueprint is not installed locally, so the iPhone 12 build/test gates cannot be claimed in this environment.
