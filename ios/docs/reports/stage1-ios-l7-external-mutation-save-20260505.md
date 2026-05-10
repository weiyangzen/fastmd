# Stage 1 iOS L7 External Mutation Save Report - 2026-05-05

## Scope

Advanced one bounded iOS-owned L7 save-integrity batch after existing full-source editor, block-source editor, dirty-state, recovery, and save-normalization evidence.

Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSDocumentEntry.swift`
- `ios/Sources/FastMDMobileCore/IOSSourceEditor.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l7-external-mutation-save-20260505.md`

## Implementation Notes

- Added a pre-write destination freshness check to `IOSDocumentFileIO.saveDocument(editedSource:for:to:)`.
- The save path now builds the complete output first, enters a balanced security-scoped access window, re-reads the destination document, decodes UTF-8 or UTF-8 BOM content, and compares the current destination source, encoding, and byte count to the originally loaded document before writing.
- If the destination has changed since load, save fails closed with `IOSDocumentSaveError.externalMutation(retainedDirtyBuffer:)` and does not overwrite the destination.
- The full-source editor maps external mutation failures to `FastMDErrorCode.externalMutation`, keeps the native editor open, and preserves the dirty edit buffer for retry or manual conflict handling.
- Existing successful save tests now seed the destination with the loaded source, matching the real document-save path instead of treating save as a blind create.
- No Android files, top-level Docs files, WebKit renderer, JS/CSS/font asset, CDN dependency, or network renderer was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 76 tests with 0 failures. New tests covered pre-write external mutation detection and full-source editor blind-overwrite blocking with dirty-buffer retention. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | BLOCKED | Exit 70. Xcode reported: `Unable to find a device matching the provided destination specifier: { platform:iOS Simulator, OS:latest, name:iPhone 12 }`. The requested iPhone 12 simulator is not installed. The `FastMDMobile` scheme resolves and available iOS simulator destinations include `Stage1 iPhone 15 Pro`, iPhone 16 family, iPhone 17 family, iPhone Air, iPhone SE, and iPads, but no iPhone 12. |

## Checklist Evidence

Supervisor can mark complete:

- L7: `Detect external document mutation before save.`
- L7: `Block blind overwrite after external mutation.`

Evidence:

- `ios/Sources/FastMDMobileCore/IOSDocumentEntry.swift`
- `ios/Sources/FastMDMobileCore/IOSSourceEditor.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l7-external-mutation-save-20260505.md`
- `swift test` passed.

Keep open:

- L9/L10/L11/L12 gates not directly covered by this batch.
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Blocker:

- The exact iPhone 12 simulator destination required by the blueprint is not installed locally, so mandatory iPhone 12 build/test gates remain blocked in this environment.
