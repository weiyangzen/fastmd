# Stage 1 iOS L12 devicectl CoreDevice Key Hardening

- Generated: 2026-05-10 00:40 CST
- Lane: FastMD Stage 1 Mobile iOS live lane
- Authoritative blueprint: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo snapshot: `Docs/todos_20260506.md`
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

## Scope

This bounded batch stayed inside `ios/**` and advanced the still-open iOS L12
physical-device validation gate by hardening the local CoreDevice probe parser.

No Android files, root `Docs/**` files, `.cron/**` files, renderer assets,
entitlements, privacy manifests, or WebKit surfaces were edited.

## Changed iOS Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-devicectl-coredevice-key-hardening-20260510-0040.md`

## Implementation Evidence

The iOS real-device gate already required both local physical probe sources:

- `xcrun xctrace list devices`
- `xcrun devicectl list devices --json-output -`

This batch expanded `IOSDevicectlDeviceListParser` to recognize additional
CoreDevice JSON shapes while keeping the gate fail-closed:

- Hardware identifiers now consider `hardwareIdentifier`, `productIdentifier`,
  `modelIdentifier`, `modelCode`, and `deviceClass` before falling back to
  marketing/device strings.
- Physical/simulator reality now considers `deviceReality`, `targetType`, and
  `platformType` from hardware/device property dictionaries.
- Connection state now accepts state/availability fields nested under
  `deviceProperties` and `connectionProperties`, in addition to top-level state.
- OS version parsing now accepts `productVersion`, `buildVersion`,
  `systemVersion`, and top-level OS version dictionaries.
- Simulator evidence still wins over physical-looking model strings when
  CoreSimulator/runtime markers are present.

Added focused XCTest:

- `testIOSL12DevicectlJSONParserAcceptsAdditionalCoreDeviceHardwareAndRealityKeys`

The new test covers three additional connected physical iPhone 12-family JSON
shapes and one simulator-marked near miss. The near miss remains blocked as a
simulator destination even though it carries an iPhone 12-family hardware class.

## Validation

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12DevicectlJSONParserAcceptsAdditionalCoreDeviceHardwareAndRealityKeys` | `ios/` | PASS | Built the SwiftPM package and executed 1 focused XCTest with 0 failures. |
| `swift test` | `ios/` | PASS | Executed 232 XCTest cases with 0 failures and 0 unexpected failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Found an available `iPhone 12` simulator destination in `Shutdown` state. This does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0. It listed the Mac host, two offline physical iOS devices, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning. The physical inventory contained one unavailable iPhone 15 Pro-class record and one paired iPad Pro 11-inch 4th generation-class record that was not connected through a live tunnel. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |

Device names, UUIDs, serial numbers, ECIDs, hostnames, local user paths, and
simulator identifiers are intentionally omitted from this report. Retained
hardware signals are limited to model classes needed to explain the L12 blocker.

## Current L12 Result

The L12 physical iPhone 12-family real-device validation gate remains open.

The local environment supports SwiftPM validation, iPhone 12 simulator inventory
checks, and both required physical-device probe commands. It does not currently
provide a connected physical iPhone 12, iPhone 12 mini, iPhone 12 Pro, or
iPhone 12 Pro Max. Because eligible hardware was absent, no physical-device
install/test run and no manual open-render-search-edit-save-rotate validation
flow was attempted or claimed.

## Required Physical Flow Still Open

| Required physical iPhone 12-family flow | Status |
| --- | --- |
| Open Markdown document on physical iPhone 12-family hardware | OPEN |
| Render rich Markdown fixture on physical iPhone 12-family hardware | OPEN |
| Search within document on physical iPhone 12-family hardware | OPEN |
| Full source edit on physical iPhone 12-family hardware | OPEN |
| Block source edit on physical iPhone 12-family hardware | OPEN |
| Save writable document on physical iPhone 12-family hardware | OPEN |
| Rotate reader on physical iPhone 12-family hardware | OPEN |

## Supervisor Checklist Recommendation

Keep open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Can mark complete from this batch:

- None. This batch improves validation implementation and records fresh blocker
  evidence, but it does not complete the physical iPhone 12-family validation
  item.

