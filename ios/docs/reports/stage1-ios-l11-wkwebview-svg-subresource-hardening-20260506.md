# Stage 1 iOS L11 WKWebView SVG Subresource Hardening

- Generated: 2026-05-06 09:01:04 CST +0800
- Worker: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**` only
- Batch type: bounded implementation + validation evidence

## Implementation

This batch tightens the future local WKWebView rich-renderer request policy. Stage 1 currently uses native safe-card fallbacks for Mermaid/math and does not bundle WebKit renderer assets, but the conditional WKWebView gate must remain safe if a later isolated renderer is enabled.

Changed behavior:

- `IOSRichRendererRequestBlockingPolicy` no longer allows `.svg` files as image subresources.
- Bundled image subresources remain limited to inert bitmap formats: `png`, `jpg`, `jpeg`, `gif`, and `webp`.
- The request-blocking XCTest now confirms:
  - bundled `.webp` image subresources are allowed;
  - bundled `.svg` image subresources are blocked with `.unsupportedRendererAssetType`.

Rationale:

- SVG can carry active content when rendered inside a WebKit surface.
- Blocking SVG keeps the Stage 1 WKWebView escape hatch aligned with the rule to block JavaScript execution and unsafe rich-renderer subresources.
- Ordinary Markdown image rendering remains native and unaffected by this conditional WKWebView policy.

## Changed iOS Files

- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-wkwebview-svg-subresource-hardening-20260506.md`

## Validation

Commands were run from `ios/` unless noted otherwise.

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` | PASS | Built successfully; `FastMDMobileCoreTests` executed 189 tests with 0 failures. |
| `git -C .. diff --check -- ios` | PASS | No whitespace errors reported for iOS changes. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | PASS | SwiftPM-derived `FastMDMobile` scheme built for iPhone 12 simulator; output ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | PASS | `FastMDMobileCoreTests` executed 189 tests with 0 failures; output ended with `** TEST SUCCEEDED **`. |

## Supervisor Checklist Candidates

The supervising session can use this report as additional evidence for these iOS-owned blueprint rows:

- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Evidence: request policy blocks network, external navigation, JavaScript URLs, data URLs, iframes, non-bundled files, wrong-context assets, and now active SVG image subresources.
  - Evidence files: `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`, `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`, this report.
- L12: `Run iOS iPhone 12 simulator build.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed in this batch.
- L12: `Run iOS iPhone 12 simulator tests.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed in this batch with 189 tests and 0 failures.
- L13: `Record validation reports under ios/docs/reports/.`
  - Evidence: this platform-local report.

This report does not claim completion of the iPhone 12-family physical-device validation gate.
