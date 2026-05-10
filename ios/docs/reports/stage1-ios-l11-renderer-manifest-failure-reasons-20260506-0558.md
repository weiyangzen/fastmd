# Stage 1 iOS L11 Renderer Manifest Failure Reasons - 2026-05-06 05:58 CST

## Batch Scope

- Lane: FastMD Stage 1 Mobile iOS live lane.
- Ownership: `ios/**` only.
- Blueprint source: `Docs/Stage1_Mobile_Blueprint.md`.
- Todo source: `Docs/todos_20260505.md`.
- Selected batch: tighten the earliest open iOS-owned L11 conditional renderer gate for `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

## Implementation Evidence

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
  - Added `IOSRendererAssetManifestHashAudit.failureReasons`.
  - The audit now exposes exact blocked-manifest causes for no assets, duplicate paths, path mismatch, non-iOS-local paths, non-bundled renderer resource paths, invalid hashes or byte counts, and hash/byte-count mismatches.
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
  - Extended exact-manifest, tampered-manifest, remote-manifest, and duplicate-manifest tests to assert the reported failure reasons.

## Current Renderer Runtime Evidence

- Production iOS renderer asset inventory command:

```bash
find ios \( -path 'ios/.build' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print | sort
```

- Result: PASS, empty output. No production iOS JS/CSS/font/HTML renderer assets are present.
- WebKit source scan command:

```bash
rg -n '^\s*import\s+WebKit\b|\bWKWebView\s*\(' ios/Sources
```

- Result: PASS, no matches. `rg` exited 1 because no production iOS source imports WebKit or constructs `WKWebView`.

## Validation

| Command | Result |
| --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11RendererAssetManifestHashAudit` from `ios/` | PASS: 4 tests executed, 0 failures, 0 unexpected failures. |
| `swift test --filter FastMDMobileCoreTests/testIOSL11ConditionalRenderer` from `ios/` | PASS: 16 tests executed, 0 failures, 0 unexpected failures. |
| `swift test` from `ios/` | PASS: 169 tests executed, 0 failures, 0 unexpected failures. |
| `git diff --check -- ios` from repository root | PASS: no whitespace errors. |

## Supervisor Checklist Recommendations

The supervisor can use this report as additional iOS evidence for:

- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Current runtime remains native fallback, so no manifest is required now.
  - Future asset-present mode now has executable tests for exact platform-local bundled resource paths, SHA-256 hash matches, byte counts, duplicate manifests, remote paths, loose local paths, missing manifests, and tampered hashes.

This report also preserves current evidence for keeping the other two conditional renderer gates satisfied in native fallback mode:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - No production renderer assets are discovered.
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - No production WebKit rich renderer code is present.

## Remaining Boundary

- This batch did not run iPhone 12 simulator build/test or physical-device validation.
- Physical iPhone 12-family real-device validation remains open until a connected real iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completes the Stage 1 manual open, render, search, edit, save, and rotate flow.
