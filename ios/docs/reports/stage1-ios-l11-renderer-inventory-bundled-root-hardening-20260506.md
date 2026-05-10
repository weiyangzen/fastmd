# Stage 1 iOS L11 Renderer Inventory Bundled Root Hardening - 2026-05-06

## Scope

Advanced one bounded iOS-owned L11 conditional renderer batch.

Blueprint items covered by this evidence:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
- `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l11-renderer-inventory-bundled-root-hardening-20260506.md`

## Implementation Notes

- Tightened `IOSRendererAssetInventory.discover` so renderer-like files count as vendored renderer assets only when their normalized iOS path is under an approved bundled renderer resource root:
  - `ios/Resources/FastMDRenderers/`
  - `ios/Sources/FastMDMobile/Resources/FastMDRenderers/`
  - `ios/Sources/FastMDMobileCore/Resources/FastMDRenderers/`
- Added coverage proving loose renderer-like artifacts under `ios/docs/reports/` and `ios/docs/screenshots/` do not falsely trigger JS/CSS/font/HTML renderer gates.
- Kept positive coverage for root, app-target, and core-target bundled `FastMDRenderers` assets.
- Kept WebKit source scanning unchanged. `import WebKit` and actual `WKWebView` construction remain gate inputs for request-blocking evidence.
- No WebKit renderer, JS/CSS/font/HTML renderer asset, CDN dependency, network renderer, Info.plist, entitlement, privacy manifest, or background mode was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11RendererAssetInventory` from `ios/` | PASS | Executed 7 focused renderer inventory tests with 0 failures. New coverage includes `testIOSL11RendererAssetInventoryIgnoresLooseRendererLikeReportArtifacts`. |
| `swift test` from `ios/` | PASS | Executed 153 tests with 0 failures. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `find ios -path 'ios/.build' -prune -o -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) -print \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/` outside `.build`. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS | Found available simulator `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Xcode built `FastMDMobileCore` for `arm64-apple-ios14.0-simulator`; ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Ran on the available iPhone 12 simulator. Executed 153 tests with 0 failures and ended with `** TEST SUCCEEDED **`. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Evidence:

- `IOSRendererAssetInventory.discover` now ignores loose report/screenshot renderer-like files and only classifies approved bundled `FastMDRenderers` resource roots as vendored renderer assets.
- Existing L11 conditional renderer tests prove native fallback mode is not applicable for these conditional gates when no vendored assets or WKWebView rich surface exists.
- Existing L11 request-blocking tests prove future local WKWebView rich surfaces must block network requests, external navigation, `javascript:` URLs, `data:` URLs, iframes, and non-bundled local files.
- Existing L11 manifest/hash tests prove future vendored renderer assets require exact platform-local bundled paths, no duplicate manifest paths, valid SHA-256 hashes, positive byte counts, and exact discovered-vs-manifest matches.
- New L11 test coverage prevents validation reports or screenshot placeholders under `ios/docs/**` from being mistaken for release renderer assets.
- The local iPhone 12 simulator destination is available and both required Xcode build/test gates passed in this batch.

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Blocker:

- No real iPhone 12-family device validation was attempted in this L11-only batch.
