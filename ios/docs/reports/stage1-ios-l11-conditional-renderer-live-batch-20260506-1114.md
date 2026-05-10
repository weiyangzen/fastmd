# Stage 1 iOS L11 Conditional Renderer Live Batch

- Generated: 2026-05-06T11:14:22+08:00
- Lane: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**` only
- Blueprint source: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo source: `Docs/todos_20260505.md`

## Batch Summary

This batch refreshes the earliest open iOS-owned L11 automated test gate evidence:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

The current iOS Stage 1 implementation remains native Swift/SwiftUI/UIKit. Ordinary Markdown is rendered natively, and Mermaid/math rich blocks use safe native fallback presentations. The current production iOS source tree does not vendor JS/CSS/font/HTML renderer assets and does not import WebKit or construct a WKWebView rich-renderer surface under `ios/Sources`.

## Implementation Evidence

The SwiftPM test suite already contains concrete automation for the conditional renderer gates, including:

- Current native-fallback posture: no vendored renderer assets, no WKWebView rich surface, and checklist rows satisfied as not applicable.
- Future vendored-asset posture: JS/CSS/font/HTML asset inventory, SwiftPM bundle resource declarations, manifest byte counts, SHA-256 hashes, and path hardening.
- Future WKWebView posture: request blocking for network URLs, external navigation, `javascript:` URLs, `data:` URLs, iframes, remote subresources, unsupported bundled asset types, and context mismatches.
- Current-source closeout evidence: renderer asset inventory command parity, no WebKit rich-renderer import/construction, and iOS-local markdown evidence-path requirements.

Key test names exercised by `swift test` include:

- `testIOSL11ConditionalLocalRendererGatesAreNotApplicableForNativeFallbackRuntime`
- `testIOSL11RendererAssetInventoryScansPackageForConditionalGateInputs`
- `testIOSL11RendererAssetInventoryMatchesDocumentedCommandForCurrentTree`
- `testIOSL11ConditionalRendererEvidenceBuilderAuditsCurrentSourceTreeFromMarkdownSource`
- `testIOSL11CurrentNativeFallbackEvidenceClosesAllConditionalRendererChecklistItems`
- `testIOSL11ConditionalRendererEvidenceBuilderAcceptsRequestBlockedWKWebViewMode`
- `testIOSL11ConditionalRendererWKWebViewGateRequiresExplicitRequestPolicy`
- `testIOSL11ConditionalRendererWKWebViewGateAcceptsRequestBlockedLocalSurface`
- `testIOSL11ConditionalRendererWKWebViewGateBlocksUnsafeRichSurfaces`
- `testIOSL11ConditionalRendererPackagingGateRequiresSwiftPMBundleResourceDeclaration`
- `testIOSL11ConditionalRendererPackagingGateRequiresDeclaredAssetsToMatchDiscoveredBundleAssets`
- `testIOSL11ConditionalRendererManifestGateRequiresHashAuditWhenAssetsExist`
- `testIOSL11CurrentSourceConditionalRendererCloseoutReportCapturesValidationCommands`
- `testIOSL11CurrentSourceConditionalRendererCompletionEvidenceRequiresIOSReportPath`

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | 201 tests executed, 0 failures, 0 unexpected failures. Full L11 conditional renderer test cluster passed. |
| `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print \| sort` | PASS | No production renderer asset paths printed. |
| `rg -n "^[[:space:]]*import[[:space:]]+(@[A-Za-z0-9_]+[[:space:]]+)*(typealias\|class\|enum\|func\|let\|protocol\|struct\|var[[:space:]]+)?WebKit\\b\|\\bWKWebView[[:space:]]*(\\(\|\\.)" ios/Sources --glob '*.swift'` | PASS | Exit code 1 with no matches; expected for native-fallback iOS lane. |
| `find ios -maxdepth 4 \( -name '*.xcodeproj' -o -name '*.xcworkspace' \) -print \| sort` | BLOCKED for Xcode project validation | No Xcode project or workspace printed under `ios/`; SwiftPM validation remains the available local gate. |
| `xcodebuild -version` | PASS | Xcode 26.4.1, build version 17E202. |
| `xcodebuild -list -package .` from `ios/` | BLOCKED | Local `xcodebuild` reports `invalid option '-package'`; this Xcode CLI does not support package listing through that option. |
| `xcrun simctl list devices available \| rg -n "iPhone 12\|iPhone 15 Pro"` | INFO | Available simulators include `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F)` and `Stage1 iPhone 15 Pro (63DAFAF1-789A-4206-8B3C-6B87048AFDF1)`, both shutdown. Simulator build/test still requires an iOS app project or workspace, which is absent in this SwiftPM skeleton. |

## Supervisor Checklist Recommendations

The supervisor can mark these iOS L11 rows complete using this report and the passing `swift test` suite:

| Blueprint checklist item | Recommended status | Evidence path |
| --- | --- | --- |
| Add local renderer packaging/offline tests if JS renderer assets are used. | Complete | `ios/docs/reports/stage1-ios-l11-conditional-renderer-live-batch-20260506-1114.md` |
| Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | Complete | `ios/docs/reports/stage1-ios-l11-conditional-renderer-live-batch-20260506-1114.md` |
| Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | Complete | `ios/docs/reports/stage1-ios-l11-conditional-renderer-live-batch-20260506-1114.md` |

## Still Open

- iOS simulator app build/test validation remains blocked by the absence of an Xcode project or workspace under `ios/`, despite an iPhone 12 simulator being available locally.
- iOS iPhone 12-family physical-device validation remains open until a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completes the Stage 1 open, render, search, edit, save, and rotate flow with recorded manual evidence.
- Android-owned L12 rows remain outside this lane's ownership.
