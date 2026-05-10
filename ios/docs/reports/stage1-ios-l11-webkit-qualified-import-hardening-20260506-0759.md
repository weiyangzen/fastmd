# Stage 1 iOS L11 WebKit Import Inventory Hardening

- Batch: iOS live lane bounded implementation batch
- Generated: 2026-05-06 07:59 Asia/Shanghai
- Scope: `ios/**` only
- Blueprint source: `Docs/Stage1_Mobile_Blueprint.md`
- Todo snapshot: `Docs/todos_20260505.md`

## Implementation

Hardened the L11 conditional renderer inventory scanner so WebKit rich-renderer detection does not rely only on a plain `import WebKit` statement.

Changed files:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

The scanner now detects:

- plain WebKit imports, including whitespace-tolerant forms
- scoped Swift imports such as `import class WebKit.WKWebView`
- attributed scoped imports such as `@_implementationOnly import class WebKit.WKWebView`
- direct `WKWebView` construction outside comments and string literals

Added test:

- `testIOSL11RendererAssetInventoryDetectsQualifiedAndAttributedWebKitImports`

The regression test creates a temporary iOS-like source tree containing:

```swift
@_implementationOnly import class WebKit.WKWebView
```

and verifies that `IOSRendererAssetInventory.discover(iosRoot:)` reports `importsWebKitRichRendererCode == true` and does not allow a native-fallback inventory claim.

## Validation

Commands run from `/Users/wangweiyang/GitHub/fastmd/ios` unless noted otherwise.

```bash
swift test --filter FastMDMobileCoreTests/testIOSL11
```

Result: pass. Executed 59 tests, 0 failures.

```bash
swift test
```

Result: pass. Executed 186 tests, 0 failures.

```bash
git -C .. diff --check -- ios
```

Result: pass. No whitespace errors reported.

## Supervisor Completion Recommendations

The supervisor can continue to mark these L11 iOS conditional renderer items complete, with this report as additional hardening evidence:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

Evidence paths:

- `ios/docs/reports/stage1-ios-l11-webkit-qualified-import-hardening-20260506-0759.md`
- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

## Platform Validation Notes

This was an L11 automated test gate hardening batch. It does not claim the L12 physical iPhone 12-family real-device validation gate.
