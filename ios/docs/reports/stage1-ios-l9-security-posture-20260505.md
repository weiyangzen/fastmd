# Stage 1 iOS L9 Security Posture Report - 2026-05-05

## Scope

Advanced one bounded iOS-owned L9 performance/security batch after existing L9 off-main and lazy-rendering evidence.

Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`
- `ios/Sources/FastMDMobileCore/MarkdownNativeRenderer.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l9-security-posture-20260505.md`

## Implementation Notes

- Added `IOSLocalImageDownsamplePolicy` as a testable ImageIO downsampling contract for local Markdown images. The policy requires ImageIO thumbnail creation, transform-aware thumbnails, no eager full-size image cache, and no remote image decoding.
- Connected local image render payloads to the ImageIO downsample policy while keeping remote images as manual-open placeholders with no decode policy.
- Added `IOSSecurityScopedAccessAudit` to make balanced security-scoped access and stale-bookmark `PermissionLost` handling explicit in the iOS core contracts.
- Added `IOSReleaseSecurityPosture` to document and test default Stage 1 release posture: no broad ATS arbitrary loads, no tracking privacy-manifest claim, no background modes, and native fallback-only rich rendering unless a future WKWebView path is vendored and locked down locally.
- No Android files, top-level Docs files, WebKit renderer, JS/CSS/font asset, CDN dependency, network renderer, Info.plist, entitlement, privacy manifest, or background mode was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 83 tests with 0 failures. New tests covered ImageIO local-image downsample posture, security-scoped access balancing audit, stale-bookmark permission-loss audit, ATS/privacy/background-mode release defaults, unsafe WKWebView posture blocking, and local/remote image payload policy. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | BLOCKED | Exit 70. Xcode reported: `Unable to find a device matching the provided destination specifier: { platform:iOS Simulator, OS:latest, name:iPhone 12 }`. Available iOS simulator destinations include `Stage1 iPhone 15 Pro`, iPhone 16 family, iPhone 17 family, iPhone Air, iPhone SE, iPads, and a connected iPad, but no iPhone 12 simulator. |

## Checklist Evidence

Supervisor can mark complete:

- L9: `Downsample local images through ImageIO on iOS.`
- L9: `Balance every iOS startAccessingSecurityScopedResource() with stopAccessingSecurityScopedResource().`
- L9: `Handle stale iOS security-scoped bookmarks.`
- L9: `Block iOS dangerous link schemes by default.`
- L9: `Keep iOS remote images as manual-open placeholders.`
- L9: `Audit iOS App Transport Security posture.`
- L9: `Audit iOS privacy manifest posture before release claim.`
- L9: `Confirm no iOS background modes are added for Stage 1.`
- L9: `If iOS WKWebView rich rendering is used, load vendored local assets only and block network requests.`

Evidence:

- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`
- `ios/Sources/FastMDMobileCore/MarkdownNativeRenderer.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l9-security-posture-20260505.md`
- `swift test` passed.

Keep open:

- L9: `Use UIKit/TextKit editor fallback if SwiftUI editor performance is unstable.` This batch records no instability and does not replace the SwiftUI source editor with a UIKit/TextKit fallback.
- L10/L11/L12 gates not directly covered by this batch.
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Blocker:

- The exact iPhone 12 simulator destination required by the blueprint is not installed locally, so mandatory iPhone 12 simulator gates remain blocked in this environment.
