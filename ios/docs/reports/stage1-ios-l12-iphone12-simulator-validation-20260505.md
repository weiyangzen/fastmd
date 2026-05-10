# Stage 1 iOS L12 iPhone 12 Simulator Validation - 2026-05-05

## Scope

Advanced one bounded iOS-owned L12 platform-validation batch for the exact iPhone 12 simulator gates in the Stage 1 Mobile blueprint.

Changes are limited to `ios/**`.

## Changed Files

Report:

- `ios/docs/reports/stage1-ios-l12-iphone12-simulator-validation-20260505.md`

## Environment Preparation

Initial validation confirmed that no available simulator instance named `iPhone 12` existed, so the blueprint destination failed before build execution:

```text
xcodebuild: error: Unable to find a device matching the provided destination specifier:
{ platform:iOS Simulator, OS:latest, name:iPhone 12 }
```

CoreSimulator did include the iPhone 12 device type and installed iOS runtimes:

```text
iPhone 12 (com.apple.CoreSimulator.SimDeviceType.iPhone-12)
iOS 26.4 (26.4.1 - 23E254a) - com.apple.CoreSimulator.SimRuntime.iOS-26-4
```

Created a local simulator instance for the required destination name:

```bash
xcrun simctl create 'iPhone 12' \
  com.apple.CoreSimulator.SimDeviceType.iPhone-12 \
  com.apple.CoreSimulator.SimRuntime.iOS-26-4
```

Result:

```text
1B6FEADC-308B-4069-B734-3C9C207E633F
```

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 111 tests with 0 failures. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Built `FastMDMobileCore` for `arm64-apple-ios14.0-simulator` against the iPhone Simulator 26.4 SDK. Xcode ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Executed 111 `FastMDMobileCoreTests` tests with 0 failures on the `iPhone 12` simulator destination. Xcode ended with `** TEST SUCCEEDED **`. |

The Xcode test result bundle was written to:

```text
/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.05_22-05-33-+0800.xcresult
```

## Checklist Evidence

Supervisor can mark complete:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Evidence:

- `ios/docs/reports/stage1-ios-l12-iphone12-simulator-validation-20260505.md`
- `swift test` passed with 111 tests and 0 failures.
- `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed.
- `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 111 tests and 0 failures.

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Remaining blocker:

- No iPhone 12-family physical device validation was performed in this batch. Simulator validation now passes, but the real-device parity-complete gate remains open until an iPhone 12 / 12 mini / 12 Pro / 12 Pro Max class device is available and exercised through the Stage 1 flow.
