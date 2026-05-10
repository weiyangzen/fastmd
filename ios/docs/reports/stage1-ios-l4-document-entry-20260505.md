# Stage 1 iOS L4 Document Entry Report - 2026-05-05

## Scope

Advanced one bounded iOS-owned L4 document-entry batch after the completed L1 fixture matrix and L2 core contracts. Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSDocumentEntry.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l4-document-entry-20260505.md`

## Implementation Notes

- Added `IOSDocumentEntryPoint`, `IOSDocumentEntryRequest`, `IOSDocumentEntryAction`, and `IOSDocumentEntryCoordinator` for launcher, document picker, Files app open, shared text, and shared document URL routes.
- Added `IOSMarkdownDocumentTypePolicy` for Markdown-like file extensions: `md`, `markdown`, `mdown`, and `mkd`.
- Added temporary shared-text load-result creation that produces a read-only `.shareText` document handle, carries source only in the active load result, and does not create bookmark data.
- Added `IOSSecurityScopedAccess.withAccess(to:_:)`, which balances `startAccessingSecurityScopedResource()` with `stopAccessingSecurityScopedResource()` when access is started.
- Added `IOSDocumentFileIO` load/save operations that read and write Markdown through the security-scoped access helper, preserve UTF-8 BOM detection, detect line endings, and carry file metadata.
- Added `IOSRecentDocumentStore` and `IOSRecentDocumentRecord` for user-selected bookmark-backed recents. Records store identifier, display name, bookmark data, content type, open time, and optional byte count, but no Markdown document content.
- Added `IOSBookmarkResolver`, which maps stale or unresolved bookmarks to `.permissionLost`.
- Added a UIKit-gated `IOSDocumentPickerConfiguration` wrapper for `UIDocumentPickerViewController` when UIKit and UniformTypeIdentifiers are available.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 26 tests with 0 failures. New tests covered launcher routing, document picker routing, Files app open routing, share-text routing, share-document URL routing, unsupported file rejection, temporary shared-text load results, security-scoped Markdown load/save, recent bookmark metadata storage, missing bookmark rejection, stale bookmark permission loss, and security-scoped access helper execution. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | BLOCKED | Exit 70. Xcode reported: `Unable to find a device matching the provided destination specifier: { platform:iOS Simulator, OS:latest, name:iPhone 12 }`. Available iOS simulators include `Stage1 iPhone 15 Pro`, but no `iPhone 12`. |
| `xcodebuild -scheme FastMDMobile -destination 'id=63DAFAF1-789A-4206-8B3C-6B87048AFDF1' test` from `ios/` | PASS | Ran on available `Stage1 iPhone 15 Pro` simulator, iOS 18.6. Executed 26 tests with 0 failures. Xcode ended with `** TEST SUCCEEDED **`. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Supervisor can mark complete:

- L4: `Implement iOS launcher entry.`
- L4: `Implement iOS document picker for Markdown-like files.`
- L4: `Implement iOS Files app open path.`
- L4: `Implement iOS share text path.`
- L4: `Implement iOS share document URL path.`
- L4: `Use security-scoped access for iOS read/write operations.`
- L4: `Store iOS bookmarks only for user-selected recent documents.`
- L4: `Handle stale iOS bookmarks with PermissionLost state.`
- L4: `Store iOS recent document metadata without storing document content.`

Evidence:

- `ios/Sources/FastMDMobileCore/IOSDocumentEntry.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `swift test` passed.
- `xcodebuild` test passed on the available iOS simulator destination.

Keep open:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Blocker:

- The exact iPhone 12 simulator destination required by the blueprint is not installed locally, so the mandatory iPhone 12 build/test gates still cannot run in this environment.
