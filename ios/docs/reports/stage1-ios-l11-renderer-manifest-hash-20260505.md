# Stage 1 iOS L11 Renderer Manifest Hash Report - 2026-05-05

## Scope

Advanced one bounded iOS-owned L11 validation-hardening batch for conditional local renderer gates.

Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l11-renderer-manifest-hash-20260505.md`

## Implementation Notes

- Added `IOSRendererAssetManifestEntry`, a platform-local renderer asset manifest row with path, byte count, and SHA-256 hash.
- Extended `IOSRendererAssetInventory` to compute SHA-256 hashes for discovered JS/CSS/font/HTML renderer asset files under `ios/`.
- Added `IOSRendererAssetManifestHashAudit` to require exact manifest-to-discovery path matching, no duplicate manifest paths, positive byte counts, valid SHA-256 hex, platform-local iOS paths, and hash equality.
- Tightened `IOSLocalRendererConditionalGateAudit.rendererAssetManifestHashGateStatus` so discovered renderer assets require a passing manifest/hash audit before the conditional manifest/hash gate can be satisfied.
- The current iOS runtime remains native fallback-only. No WebKit, JavaScript, CSS, font, HTML renderer asset, CDN dependency, network renderer, Info.plist, entitlement, privacy manifest, or background mode was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 20 focused L11 tests with 0 failures, including new manifest/hash acceptance, tamper rejection, remote-path rejection, and conditional manifest-gate tests. |
| `swift test` from `ios/` | PASS | Executed 116 tests with 0 failures. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`; current native fallback runtime keeps conditional renderer asset packaging not applicable. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | `** BUILD SUCCEEDED **`; package built for `arm64-apple-ios14.0-simulator` with the `FastMDMobile` SwiftPM scheme. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | `** TEST SUCCEEDED **`; executed 116 XCTest cases with 0 failures and produced `Test-FastMDMobile-2026.05.05_22-23-41-+0800.xcresult`. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Evidence:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-renderer-manifest-hash-20260505.md`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Residual blocker:

- No connected iPhone 12-family real device was validated in this batch, so the real-device parity-complete release claim remains open.
