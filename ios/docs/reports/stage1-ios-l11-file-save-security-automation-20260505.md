# Stage 1 iOS L11 File, Save, And Security Automation Report - 2026-05-05

## Scope

Advanced one bounded iOS-owned L11 automated-test batch after existing iOS L11 renderer automation evidence.

Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l11-file-save-security-automation-20260505.md`

## Implementation Notes

- Added `IOSFileAccessAutomationAudit` to make iOS L11 file access coverage explicit for readable document open, read-only save fail-closed behavior, stale bookmark `PermissionLost` mapping, recent-document metadata-only storage, and off-main file IO.
- Added `IOSSaveIntegrityAutomationAudit` to make iOS L11 save integrity coverage explicit for UTF-8 BOM preservation without duplicate BOM, CRLF preservation, read-only and unsupported-encoding rejection, complete output writes, failed-save dirty-buffer retention, and external mutation overwrite blocking.
- Added `IOSHostileMarkdownFixtureAudit` to validate malicious HTML and malicious link fixtures through native renderer output, sanitized HTML fallbacks, blocked external/subresource surfaces, dangerous-scheme blocking, and HTTPS confirmation.
- Added `IOSRemoteImagePrivacyAudit` to validate remote image fixtures render as manual-open placeholders and do not trigger automatic remote decode/fetch behavior.
- Added five focused XCTest gates covering iOS file access, save integrity, malicious HTML fixtures, malicious link fixtures, and remote image privacy fixtures.
- No Android files, top-level Docs files, WebKit renderer, JS/CSS/font asset, CDN dependency, network renderer, Info.plist, entitlement, privacy manifest, or background mode was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 9 focused L11 tests with 0 failures. New tests covered file access, save integrity, malicious HTML, malicious links, and remote image privacy in addition to the existing parser/source-range/snapshot/layout L11 tests. |
| `swift test` from `ios/` | PASS | Executed 100 tests with 0 failures. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | BLOCKED | Exit 70. Xcode reported: `Unable to find a device matching the provided destination specifier: { platform:iOS Simulator, OS:latest, name:iPhone 12 }`. Available iOS simulator destinations include `Stage1 iPhone 15 Pro`, iPhone 16 family, iPhone 17 family, iPhone Air, iPhone SE, and iPads, but no iPhone 12 simulator. |
| `xcodebuild -scheme FastMDMobile -destination 'id=63DAFAF1-789A-4206-8B3C-6B87048AFDF1' test` from `ios/` | PASS | Ran on available `Stage1 iPhone 15 Pro` simulator, iOS 18.6. Executed 100 tests with 0 failures. Xcode ended with `** TEST SUCCEEDED **`. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add file access tests for open, read, write, read-only, permission-lost, and stale bookmark/URI flows.`
- L11: `Add save integrity tests for BOM, CRLF/LF, external mutation, and write failure.`
- L11: `Add malicious HTML fixture tests.`
- L11: `Add malicious link fixture tests.`
- L11: `Add remote image privacy tests.`

Evidence:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/Tests/Fixtures/Markdown/readonly-document.md`
- `ios/Tests/Fixtures/Markdown/encoding-utf8-bom.md`
- `ios/Tests/Fixtures/Markdown/line-endings-crlf.md`
- `ios/Tests/Fixtures/Markdown/external-change-before-save.md`
- `ios/Tests/Fixtures/Markdown/malicious-html.md`
- `ios/Tests/Fixtures/Markdown/malicious-links.md`
- `ios/Tests/Fixtures/Markdown/remote-image.md`
- `ios/docs/reports/stage1-ios-l11-file-save-security-automation-20260505.md`
- `swift test --filter FastMDMobileCoreTests/testIOSL11` passed.
- `swift test` passed.
- Available-simulator `xcodebuild test` passed.

Keep open:

- L11: Local renderer packaging/offline tests if JS renderer assets are used.
- L11: WKWebView request-blocking tests if local JS renderer surfaces are used.
- L11: Renderer asset manifest/hash verification tests if assets are vendored.
- L11: Log redaction tests.
- L11: Performance tests for parse, render, search, font tier switch, and save.
- L11: Memory stress tests for huge table, huge code block, huge image metadata, and large document.
- L11: Accessibility smoke tests.
- L11: Process recovery tests where platform lifecycle permits.
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Blocker:

- The exact iPhone 12 simulator destination required by the blueprint is not installed locally, so mandatory iPhone 12 simulator gates remain blocked in this environment.
