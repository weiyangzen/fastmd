# Stage 1 iOS L13 Itemized Reconciliation Paths - 2026-05-06 10:47 +0800

## Scope

Ran one bounded iOS-owned implementation batch for L13 reconciliation evidence hardening.

This batch stayed inside `ios/**`. It did not edit Android files, root `Docs/**`, `.cron/**`, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Changed Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l13-itemized-reconciliation-paths-20260506-1047.md`

## Implementation

Added item-specific report path support to `IOSStageOneReconciliationChecklistEvidence`.

The reconciliation model now:

- stores `reportPathsByChecklistItem`;
- requires every completable iOS checklist item to have an iOS-local Markdown evidence path under `ios/docs/reports/`;
- rejects whitespace, non-Markdown, non-iOS, URL, parent-directory, and backslash report paths through the same `pathsStayIOSLocalReports` gate;
- renders each checklist row with its own evidence path instead of falling back to one primary report for every row;
- keeps the iPhone 12-family physical-device validation row open unless real-device evidence completes the flow.

Added XCTest coverage:

- `testIOSL13ReconciliationEvidenceMapsCurrentIOSChecklistCompletionAndRealDeviceBlocker`
- `testIOSL13ReconciliationEvidenceRequiresItemSpecificReportPaths`

The existing negative path test also continues to reject non-iOS report paths and missing real-device completion evidence.

## Itemized Evidence Paths

The current L13 model can point the supervisor at these platform-local report anchors:

| Checklist item | Evidence path |
| --- | --- |
| `Add local renderer packaging/offline tests if JS renderer assets are used.` | `ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-iphone12-refresh-20260506.md` |
| `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.` | `ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-iphone12-refresh-20260506.md` |
| `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.` | `ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-iphone12-refresh-20260506.md` |
| `Run iOS iPhone 12 simulator build.` | `ios/docs/reports/stage1-ios-l12-iphone12-simulator-live-validation-20260506.md` |
| `Run iOS iPhone 12 simulator tests.` | `ios/docs/reports/stage1-ios-l12-iphone12-simulator-live-validation-20260506.md` |
| `Run iOS iPhone 12-class real-device validation before parity-complete release claim.` | `ios/docs/reports/stage1-ios-l12-real-device-devicectl-probe-20260506.md` |
| `Capture iOS performance report.` | `ios/docs/reports/stage1-ios-l12-performance-report-20260505.md` |
| `Capture iOS security audit report.` | `ios/docs/reports/stage1-ios-l12-security-rich-render-report-20260505.md` |
| `Capture rich fixture render report.` | `ios/docs/reports/stage1-ios-l12-security-rich-render-report-20260505.md` |
| `Update ios/README.md with final build/test commands after iOS skeleton lands.` | `ios/docs/reports/stage1-ios-l13-readme-validation-refresh-20260506.md` |
| `Record validation reports under ios/docs/reports/.` | `ios/docs/reports/stage1-ios-l13-reconciliation-evidence-20260506.md` |

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL13Reconciliation` from `ios/` | PASS | Built successfully and executed 3 selected tests with 0 failures. |

Full SwiftPM validation and iOS-only diff validation are run after this report is written and should be recorded in the worker final response.

## Supervisor Can Mark Complete

This batch provides additional evidence for:

- L13: `Record validation reports under ios/docs/reports/.`
- L13: `Keep this authoritative checklist synchronized with actual implementation status.`

Evidence path:

- `ios/docs/reports/stage1-ios-l13-itemized-reconciliation-paths-20260506-1047.md`

## Keep Open

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Reason:

- This batch did not run on a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max. The reconciliation model still keeps that row open without complete physical-device flow evidence.
