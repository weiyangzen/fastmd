# Stage 1 iOS Core Contracts Report - 2026-05-05

## Scope

Advanced the earliest open iOS-owned L2 core contracts after the L1 fixture matrix.
Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-core-contracts-20260505.md`

## Implementation Notes

- Reworked `MobileDocumentHandle` into a metadata/access handle. It stores a stable identifier, display name, source origin, write access, and optional bookmark data, but not Markdown document contents.
- Added `MarkdownLoadResult` with handle, file metadata, source buffer, detected text encoding, detected line ending, and load timestamp.
- Added render model contracts: `MarkdownSourceRange`, `MarkdownRenderBlockKind`, `MarkdownBlockID`, `MarkdownRenderBlock`, and `MarkdownRenderDocument`.
- Stable block IDs are derived from block kind, source range, and ordinal so inline style changes do not change block identity.
- Corrected iOS font tier sizes to the blueprint values: Compact `14pt`, Default `16pt`, Large `18pt`, Reader `21pt`, with line-height multiples `1.48`, `1.52`, `1.56`, and `1.60`.
- Kept the reader UI state model aligned with the Stage 1 state machine.
- Added structured error code/category contracts covering open, read, parse, render, search, edit, save, link, permission, and security failures.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 10 tests with 0 failures. New contract tests covered font tiers, document handles, load result metadata/source, render block identity/source ranges, and error categories. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | BLOCKED | Exit 70. Xcode reported: `Unable to find a device matching the provided destination specifier: { platform:iOS Simulator, OS:latest, name:iPhone 12 }`. The local simulator set still has no iPhone 12 destination. |
| `xcodebuild -scheme FastMDMobile -destination 'id=63DAFAF1-789A-4206-8B3C-6B87048AFDF1' test` from `ios/` | PASS | Ran on available `Stage1 iPhone 15 Pro` simulator, iOS 18.6. Executed 10 tests with 0 failures. Xcode ended with `** TEST SUCCEEDED **`. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Supervisor can mark complete:

- L2: `Define shared mobile document handle model for platform document references.`
- L2: `Define Markdown load result model with file metadata, write capability, and source origin.`
- L2: `Define render model with stable block ids and source ranges.`
- L2: `Define four font tier model: Compact, Default, Large, Reader.`
- L2: `Define reader UI state model covering Empty, Loading, Rendering, Ready, Searching, EditingSource, EditingBlock, Saving, ReadOnly, PermissionLost, and Error.`
- L2: `Define structured error codes for open, read, parse, render, search, edit, save, link, permission, and security failures.`

Evidence:

- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `swift test` passed.
- `xcodebuild` test passed on the available iOS simulator destination.

Keep open:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Blocker:

- The exact iPhone 12 simulator destination is not installed locally, so the mandatory iPhone 12 build/test gates cannot run in this environment yet.
