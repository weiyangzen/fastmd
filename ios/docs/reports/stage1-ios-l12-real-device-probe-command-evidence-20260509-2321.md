# Stage 1 iOS L12 Real-Device Probe Command Evidence

- Generated: 2026-05-09T15:21:00Z
- Local lane: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**`
- Batch type: bounded L12 validation evidence hardening

## Implementation Evidence

This batch tightened the iOS real-device validation report model so the generated Markdown report now includes a per-required-command table for physical-device probes:

| Required physical probe command | Status | Observed at |
| --- | --- | --- |
| `xcrun xctrace list devices` | PASS/STALE/MISSING in report output | current report model |
| `xcrun devicectl list devices --json-output -` | PASS/STALE/MISSING in report output | current report model |

The related unit coverage now asserts:

- required physical probe commands are rendered as report rows
- missing required probe commands render as `MISSING`
- stale required probe command evidence renders as `STALE`
- current required probe command evidence renders as `PASS`

## Current Probe Results

Current `xcrun xctrace list devices` result:

- Command completed successfully.
- Connected devices section listed only the local Mac.
- Devices offline listed `Turbulence` on iOS 26.1 and `王威扬的iPad` on iOS 26.3.1.
- Simulator list included an `iPhone 12 (26.4.1)` simulator.
- No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present.

Current `xcrun devicectl list devices --json-output -` result:

- Command completed with JSON `outcome: success`.
- stderr/stdout included Apple tooling warning: `Failed to load provisioning paramter list due to error: Error Domain=com.apple.dt.CoreDeviceError Code=1002 "No provider was found."`
- Device table/JSON listed `Turbulence`, an iPhone 15 Pro / `iPhone16,1`, with `tunnelState: unavailable`.
- Device table/JSON listed `王威扬的iPad`, an iPad Pro / `iPad14,4`, with `tunnelState: unavailable`.
- No connected physical iPhone 12-family hardware was present.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationReport` from `ios/` | PASS | 6 tests, 0 failures |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationBlocksStaleRequiredPerCommandEvidence` from `ios/` | PASS | 1 test, 0 failures |
| `swift test` from `ios/` | PASS | 225 tests, 0 failures |
| `xcrun xctrace list devices` | PASS, gate still blocked | Probe ran; no connected physical iPhone 12-family device found |
| `xcrun devicectl list devices --json-output -` | PASS with Apple tooling warning, gate still blocked | Probe ran; no connected physical iPhone 12-family device found |

## Checklist Impact

The supervisor should keep this blueprint item open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Reason: current physical probes captured fresh evidence, but they did not find a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max. The Stage 1 open, render, search, edit, save, and rotate manual flow therefore did not run on eligible connected hardware in this batch.

This report provides additional evidence for:

- L12 real-device blocker freshness and command coverage
- L13 iOS-local reconciliation evidence under `ios/docs/reports/`

