# FastMD iOS

移动端 Stage 1 的产品与工程蓝图放在 [../Docs/Stage1_Mobile_Blueprint.md](../Docs/Stage1_Mobile_Blueprint.md)。

本目录只承载 iOS 实现。Stage 1 iOS 的兼容目标是 iPhone 12 这一代：

- 最低验证设备代际：iPhone 12 / 12 mini / 12 Pro / 12 Pro Max
- 当前 SwiftPM skeleton deployment target：iOS 14.0
- 推荐产品兼容目标：iOS 14.1
- 如果后续 Xcode / SwiftUI 工具链迫使 deployment target 提到 iOS 15.0，需要在 `ios/docs/reports/` 里记录原因

## Implementation Boundary

Stage 1 iOS is native Swift. The current package exposes `FastMDMobileCore`, implemented with Swift models that map to SwiftUI/UIKit integration points:

- document entry and security-scoped file behavior
- Markdown parsing, native presentation payloads, and rich fallback cards
- reader preferences, four font tiers, themes, search, and navigation state
- full-source and block-source edit/save integrity
- performance, accessibility, diagnostics, security, and validation evidence models

The Stage 1 native-fallback path does not bundle JavaScript, CSS, fonts, HTML renderer assets, WebKit renderer code, CDN loading, network rendering, app entitlements, privacy tracking claims, or background modes.

## Local Gates

Run commands from `ios/`.

Smallest required SwiftPM gate:

```bash
swift test
```

Focused conditional renderer gate, useful when validating the native fallback / no-WebKit path:

```bash
swift test --filter FastMDMobileCoreTests/testIOSL11
```

Focused Stage 1 validation report gates:

```bash
swift test --filter FastMDMobileCoreTests/testIOSL12
```

Focused README command audit gate:

```bash
swift test --filter FastMDMobileCoreTests/testIOSL13ReadmeDocumentsFinalBuildTestCommands
```

Whitespace gate for iOS-only changes:

```bash
git -C .. diff --check -- ios
```

iPhone 12 simulator build and test gates:

```bash
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test
```

If the exact simulator is missing but the device type and runtime are installed, create a local destination once:

```bash
xcrun simctl create 'iPhone 12' \
  com.apple.CoreSimulator.SimDeviceType.iPhone-12 \
  com.apple.CoreSimulator.SimRuntime.iOS-26-4
```

Check available destinations before running the Xcode gates:

```bash
xcrun simctl list devices available | rg 'iPhone 12'
```

Physical iPhone 12-family validation probe commands:

```bash
xcrun xctrace list devices
xcrun devicectl list devices --json-output -
```

These probes do not complete the physical-device gate by themselves. The gate stays open until a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completes the Stage 1 open, render, search, edit, save, and rotate flow with recorded manual evidence.

## Reports

Platform-local implementation and validation evidence belongs under `ios/docs/reports/`. The supervising session reconciles those reports into the root Stage 1 checklist.

Current reconciliation anchors:

- L11 conditional renderer gates: `ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-iphone12-refresh-20260506.md`
- L12 iPhone 12 simulator validation: `ios/docs/reports/stage1-ios-l12-iphone12-simulator-live-validation-20260506.md`
- L12 iPhone 12 physical-device blocker: `ios/docs/reports/stage1-ios-l12-real-device-devicectl-probe-20260506.md`
- L12 iOS performance report: `ios/docs/reports/stage1-ios-l12-performance-report-20260505.md`
- L12 iOS security and rich fixture reports: `ios/docs/reports/stage1-ios-l12-security-rich-render-report-20260505.md`
- L13 README validation: `ios/docs/reports/stage1-ios-l13-readme-validation-refresh-20260506.md`

The iPhone 12-family physical-device gate remains separate from simulator validation and should stay open until a real iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completes the Stage 1 open, render, search, edit, save, and rotate flow.
