# Stage 1 iOS L11 SwiftPM Renderer Resource Declaration Hardening

- Generated: 2026-05-06 07:54 CST
- Worker: FastMD Stage 1 Mobile iOS live lane
- Scope: one bounded iOS-owned implementation batch
- Ownership: `ios/**` only

## Implementation

This batch tightened the iOS conditional local renderer gates for any future vendored JS/CSS/font/HTML renderer mode.

- `IOSRendererAssetInventory` now removes Swift comments before scanning `Package.swift` for `.process(...)` or `.copy(...)` declarations that mention `FastMDRenderers`.
- String literals remain intact during the scan, so real SwiftPM resource declarations still count.
- Commented-out declarations no longer satisfy the bundle resource coverage requirement for local renderer packaging/offline validation.
- The current production iOS runtime remains native fallback-only: no vendored renderer assets are present and no WKWebView rich renderer surface is active.

## Changed Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-swiftpm-commented-resource-declaration-hardening-20260506.md`

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11RendererAssetInventoryIgnoresCommentedSwiftPMRendererResourceDeclarations` from `ios/` | PASS | 1 test, 0 failures |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | 58 tests, 0 failures |
| `swift test` from `ios/` | PASS | 185 tests, 0 failures |
| `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print \| sort` from repo root | PASS | Empty output; no production iOS renderer assets found |
| `xcrun xctrace list devices` from repo root | BLOCKED for real-device parity | Physical devices are offline; iPhone 12 appears only as a simulator |
| `xcrun devicectl list devices --json-output -` from repo root | BLOCKED for real-device parity | Command succeeded with a provisioning provider warning; listed physical devices are unavailable and not iPhone 12-family hardware |

## Supervisor Checklist Recommendations

The supervisor can continue to treat the following iOS L11 checklist items as complete for the current native-fallback runtime, with this batch adding stricter future-mode evidence:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: future vendored asset mode now requires an actual SwiftPM bundled resource declaration, not a commented-out declaration.
  - Evidence path: `ios/docs/reports/stage1-ios-l11-swiftpm-commented-resource-declaration-hardening-20260506.md`

- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: the L11 focused suite passes with manifest/hash coverage and the tightened bundle resource declaration scan.
  - Evidence path: `ios/docs/reports/stage1-ios-l11-swiftpm-commented-resource-declaration-hardening-20260506.md`

- `Record validation reports under ios/docs/reports/.`
  - Evidence: this platform-local report records implementation and validation for the batch.
  - Evidence path: `ios/docs/reports/stage1-ios-l11-swiftpm-commented-resource-declaration-hardening-20260506.md`

Keep iPhone 12-class physical real-device validation open. This batch did not run on connected physical iPhone 12-family hardware.
