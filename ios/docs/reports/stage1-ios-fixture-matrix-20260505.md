# Stage 1 iOS Fixture Matrix Report - 2026-05-05

## Scope

Closed the iOS-owned L1 canonical Markdown fixture matrix under `ios/**` only.

## Changed Files

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

iOS Markdown fixtures:

- `ios/Tests/Fixtures/Markdown/basic.md`
- `ios/Tests/Fixtures/Markdown/cjk.md`
- `ios/Tests/Fixtures/Markdown/encoding-utf8-bom.md`
- `ios/Tests/Fixtures/Markdown/external-change-before-save.md`
- `ios/Tests/Fixtures/Markdown/huge-code-block.md`
- `ios/Tests/Fixtures/Markdown/huge-table.md`
- `ios/Tests/Fixtures/Markdown/large-5mb.md`
- `ios/Tests/Fixtures/Markdown/line-endings-crlf.md`
- `ios/Tests/Fixtures/Markdown/local-image.md`
- `ios/Tests/Fixtures/Markdown/long-1mb.md`
- `ios/Tests/Fixtures/Markdown/long-filename.md`
- `ios/Tests/Fixtures/Markdown/malformed-markdown.md`
- `ios/Tests/Fixtures/Markdown/malicious-html.md`
- `ios/Tests/Fixtures/Markdown/malicious-links.md`
- `ios/Tests/Fixtures/Markdown/readonly-document.md`
- `ios/Tests/Fixtures/Markdown/remote-image.md`
- `ios/Tests/Fixtures/Markdown/rich-preview.md`
- `ios/Tests/Fixtures/Markdown/rtl-and-emoji.md`

Report:

- `ios/docs/reports/stage1-ios-fixture-matrix-20260505.md`

## Implementation Notes

- Seeded the iOS Markdown fixture directory with the full mobile fixture matrix currently mirrored by Android.
- Replaced the shorter iOS `rich-preview.md` seed with the shared canonical fixture content from `Tests/Fixtures/Markdown/rich-preview.md`.
- Added SwiftPM tests that assert every iOS fixture filename exists and is non-empty.
- Added a SwiftPM test that asserts `ios/Tests/Fixtures/Markdown/rich-preview.md` byte-for-byte matches the shared canonical rich fixture.

## Fixture Evidence

`ios/Tests/Fixtures/Markdown/` contains these 18 Markdown fixtures:

```text
basic.md
cjk.md
encoding-utf8-bom.md
external-change-before-save.md
huge-code-block.md
huge-table.md
large-5mb.md
line-endings-crlf.md
local-image.md
long-1mb.md
long-filename.md
malformed-markdown.md
malicious-html.md
malicious-links.md
readonly-document.md
remote-image.md
rich-preview.md
rtl-and-emoji.md
```

Canonical rich fixture SHA-256:

```text
61e25081b06970a70a788fc24807bbb4afe53d605d74d2becb29737167bd90a5  Tests/Fixtures/Markdown/rich-preview.md
61e25081b06970a70a788fc24807bbb4afe53d605d74d2becb29737167bd90a5  ios/Tests/Fixtures/Markdown/rich-preview.md
```

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 6 tests, with 0 failures in 0.009 seconds. New fixture tests `testCanonicalMarkdownFixtureMatrixExistsAndIsSeeded` and `testRichPreviewFixtureMatchesSharedCanonicalFixture` passed. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | BLOCKED | Exit 70. Xcode reported: `Unable to find a device matching the provided destination specifier: { platform:iOS Simulator, OS:latest, name:iPhone 12 }`. No iPhone 12 simulator is installed in this environment. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=Stage1 iPhone 15 Pro' build` from `ios/` | BLOCKED | Exit 70. Name-based destination resolution failed with `Unable to find a device matching the provided destination specifier`, even though Xcode listed `Stage1 iPhone 15 Pro` as an available simulator. |
| `xcodebuild -scheme FastMDMobile -destination 'id=63DAFAF1-789A-4206-8B3C-6B87048AFDF1' build` from `ios/` | PASS | Built `FastMDMobileCore` for iOS Simulator arm64 with iOS deployment target 14.0. Xcode ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'id=63DAFAF1-789A-4206-8B3C-6B87048AFDF1' test` from `ios/` | PASS | Ran on `Stage1 iPhone 15 Pro` simulator, OS 18.6. Executed 6 tests, with 0 failures. Xcode ended with `** TEST SUCCEEDED **`. |

## Checklist Evidence

Supervisor can mark complete:

- L1: `Create iOS fixture directory and seed canonical Markdown fixtures.`

Evidence:

- Fixture matrix exists under `ios/Tests/Fixtures/Markdown/`.
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift` validates the matrix and canonical rich fixture copy.
- `swift test` passed.
- `xcodebuild` build/test passed on an available iOS simulator by destination UUID.

Keep open:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Blocker:

- The local Xcode simulator set does not include an `iPhone 12` destination. The exact blueprint destination command fails before build selection with exit 70.
