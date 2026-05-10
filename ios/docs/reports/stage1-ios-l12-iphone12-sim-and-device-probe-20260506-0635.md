# Stage 1 iOS L12 iPhone 12 Simulator And Device Probe - 2026-05-06 06:35 CST

Worker: FastMD Stage 1 Mobile iOS live lane

Scope: one bounded iOS-only validation batch. No Android files, root Docs checklist files, or `.cron/**` files were edited.

## Batch Selection

`Docs/todos_20260505.md` shows L1-L10 reconciled complete and the open iOS-owned work concentrated in L11 conditional renderer gates plus L12 platform validation. Current iOS source already includes executable L11 conditional renderer coverage for:

- local renderer packaging/offline gate when JS renderer assets are used;
- WKWebView request-blocking gate when local JS renderer surfaces are used;
- renderer asset manifest/hash verification gate when JS/CSS/font assets are vendored.

This batch therefore refreshed the next iOS-owned L12 platform validation evidence:

- `Run iOS iPhone 12 simulator build.`
- `Run iOS iPhone 12 simulator tests.`
- `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

## Validation Results

| Command | Result |
| --- | --- |
| `swift test` from `ios/` | PASS. 175 tests executed, 0 failures, 0 unexpected failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS. Available destination found: `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcodebuild -list` from `ios/` | PASS. Workspace exposes scheme `FastMDMobile`. Xcode also emitted `IDERunDestination: Supported platforms for the buildables in the current scheme is empty`, but the scheme resolved and subsequent iPhone 12 simulator build/test succeeded. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS. Build ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS. 175 tests executed, 0 failures, 0 unexpected failures. Test ended with `** TEST SUCCEEDED **`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_06-33-40-+0800.xcresult`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family validation. Connected physical-device section listed only offline devices, including `Turbulence (26.1) (00008130-001935383CBA001C)` and `王威扬的iPad (26.3.1) (00008112-000A49960CA3C01E)`. The simulator list included an `iPhone 12 (26.4.1)` destination, but simulator evidence does not satisfy the real-device gate. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family validation. Command outcome was success, but physical candidates were unavailable and not iPhone 12-family hardware: `Turbulence`, `iPhone 15 Pro`, product type `iPhone16,1`, hardware model `D83AP`; and `王威扬的iPad`, `iPad Pro (11-inch) (4th generation)`, product type `iPad14,4`, hardware model `J618AP`. |

## Current Renderer Runtime Cross-Check

The full `swift test` run included the current L11 conditional renderer tests. Relevant passing coverage includes:

- `testIOSL11ConditionalLocalRendererGatesAreNotApplicableForNativeFallbackRuntime`
- `testIOSL11ConditionalRendererEvidenceBuilderAuditsCurrentSourceTreeFromMarkdownSource`
- `testIOSL11ConditionalRendererWKWebViewGateAcceptsRequestBlockedLocalSurface`
- `testIOSL11RendererAssetManifestHashAuditAcceptsExactLocalManifest`
- `testIOSL11RendererAssetManifestHashAuditRejectsMissingTamperedOrRemoteEntries`

Current production iOS runtime remains native Swift/SwiftUI/UIKit with native safe-card fallback for rich Mermaid/math blocks. No production WKWebView rich surface or bundled JS/CSS/font renderer assets are required by the current runtime.

## Supervisor Checklist Recommendations

The supervisor can use this report as fresh iOS evidence for:

- L12: `Run iOS iPhone 12 simulator build.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed.

- L12: `Run iOS iPhone 12 simulator tests.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 175 tests and 0 failures.

- L13: `Record validation reports under ios/docs/reports/.`
  - Evidence: this platform-local report.

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
  - Blocker: no connected, available physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present for the manual open, render, search, edit, save, and rotate flow.

