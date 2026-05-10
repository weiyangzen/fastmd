# Stage 1 iOS L11 Renderer Bundle Path Gates - 2026-05-05

## Scope

Ran one bounded iOS-owned L11 validation-hardening batch for the conditional local renderer gates.

Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l11-renderer-bundle-path-gates-20260505.md`

## Implementation Notes

- Added explicit bundled renderer resource path validation for future iOS JS/CSS/font/HTML rich renderer assets.
- Accepted bundled renderer roots:
  - `ios/Resources/FastMDRenderers/`
  - `ios/Sources/FastMDMobileCore/Resources/FastMDRenderers/`
- Tightened renderer manifest/hash verification so discovered renderer assets must be platform-local and under a bundled renderer resource path.
- Tightened conditional local renderer packaging/offline gate status so loose local renderer files under paths such as `ios/docs/**` do not satisfy the gate even when hash metadata exists.
- Added scanner coverage proving the inventory detects actual vendored bundle assets and WebKit source imports in a temporary iOS package root.
- Current iOS runtime remains native fallback-only. No WebKit, JavaScript, CSS, font, HTML renderer asset, CDN dependency, network renderer, Info.plist, entitlement, privacy manifest, or background mode was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 26 focused L11 tests with 0 failures, including new bundle-path acceptance, loose-path rejection, inventory asset discovery, and WebKit-source detection coverage. |
| `swift test` from `ios/` | PASS | Executed 126 tests with 0 failures. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`; current native fallback runtime keeps conditional renderer asset packaging not applicable. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

Evidence:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-renderer-bundle-path-gates-20260505.md`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Residual blocker:

- No connected iPhone 12-family physical device was validated in this batch, so the real-device parity-complete release claim remains open.
