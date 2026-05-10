# Stage 1 iOS L7 Save Integrity Report - 2026-05-05

## Scope

Advanced one bounded iOS-owned L7 save-integrity batch after existing full-source editor, block-source editor, dirty-state, background draft, and process-recovery evidence.

Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSDocumentEntry.swift`
- `ios/Sources/FastMDMobileCore/IOSSourceEditor.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l7-save-integrity-20260505.md`

## Implementation Notes

- Added `IOSDocumentSavePlanner` to validate save eligibility before write and build the complete destination payload in memory.
- Save planning rejects read-only documents and unsupported legacy encodings before any destination write.
- UTF-8 with BOM is preserved by emitting exactly one leading UTF-8 BOM when the loaded document was BOM encoded, even if the edit buffer contains a leading Unicode BOM character.
- CRLF and LF line endings are preserved from the loaded document when possible. Mixed and no-line-ending documents keep the edited buffer's current line-ending shape.
- Added `IOSDocumentFileIO.saveDocument(editedSource:for:to:)` to write the prebuilt payload atomically inside a balanced security-scoped access window.
- Added `IOSDocumentSaveError`, `IOSDocumentSavePlan`, and `IOSDocumentSaveResult` for explicit save-path outcomes.
- Added `IOSSourceEditorEngine.saveFullSourceEdit(...)` so successful saves clear the dirty source-edit session and failed writes keep the editor open with the unsaved buffer intact.
- Added save-failure state metadata to the source editor state so the native UI can surface a save failure while preserving the dirty buffer.
- No Android files, top-level Docs files, WebKit renderer, JS/CSS/font asset, CDN dependency, or network renderer was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 74 tests with 0 failures. New tests covered BOM preservation without duplicate BOM, CRLF/LF preservation, read-only save rejection, unsupported encoding save rejection, complete-output file writes, successful source-editor save dirty-state cleanup, and failed-save dirty-buffer retention. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | BLOCKED | Exit 70. Xcode reported: `Unable to find a device matching the provided destination specifier: { platform:iOS Simulator, OS:latest, name:iPhone 12 }`. The requested iPhone 12 simulator is not installed. The `FastMDMobile` scheme resolves and lists available destinations including `Stage1 iPhone 15 Pro`, iPhone 16 family, iPhone 17 family, iPhone Air, iPhone SE, and iPads. |

## Checklist Evidence

Supervisor can mark complete:

- L7: `Detect UTF-8 BOM and avoid duplicate BOM on save.`
- L7: `Preserve CRLF/LF line endings where possible.`
- L7: `Fail read-only on unsupported legacy encoding instead of corrupting saves.`
- L7: `Build complete output before writing to destination.`
- L7: `Keep dirty buffer intact after failed save.`

Evidence:

- `ios/Sources/FastMDMobileCore/IOSDocumentEntry.swift`
- `ios/Sources/FastMDMobileCore/IOSSourceEditor.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l7-save-integrity-20260505.md`
- `swift test` passed.

Keep open:

- L7: `Detect external document mutation before save.`
- L7: `Block blind overwrite after external mutation.`
- L9/L11/L12 gates not directly covered by this batch.
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Blocker:

- The exact iPhone 12 simulator destination required by the blueprint is not installed locally, so mandatory iPhone 12 build/test gates remain blocked in this environment.
