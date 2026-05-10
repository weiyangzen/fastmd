# Stage 1 iOS L9 TextKit Editor Fallback Report - 2026-05-05

## Scope

Advanced one bounded iOS-owned L9 performance batch after existing iOS L9 off-main, lazy-rendering, and security-posture evidence.

Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSSourceEditor.swift`
- `ios/Sources/FastMDMobileCore/IOSReaderScreen.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l9-textkit-editor-fallback-20260505.md`

## Implementation Notes

- Added `IOSSourceEditorRuntimePolicy`, `IOSSourceEditorRuntimeProfile`, and `IOSSourceEditorSurface` as native Swift contracts for selecting the source editor runtime.
- The policy keeps SwiftUI `TextEditor` for stable small-source editing and selects UIKit/TextKit when the source is large, SwiftUI input latency is observed above threshold, dropped input frames cross threshold, or the user/runtime explicitly forces the fallback.
- `IOSSourceEditorState` and `IOSBlockSourceEditorState` now expose the selected editor surface, so full-source and block-source editor flows can make the same fallback decision.
- Added a guarded iOS-only `FastMDTextKitSourceEditor` backed by `UITextView` and TextKit. It is compiled only when UIKit is available and remains native Swift/UIKit, with no WebKit, JavaScript, remote renderer, or web runtime.
- Wired the SwiftUI reader editor surface to use the policy and switch to the TextKit-backed view on iOS builds when the fallback surface is selected. Non-UIKit builds keep the SwiftUI `TextEditor` fallback.
- No Android files, top-level Docs files, WebKit renderer, JS/CSS/font asset, CDN dependency, network renderer, Info.plist, entitlement, privacy manifest, or background mode was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 86 tests with 0 failures. New tests covered stable small-source SwiftUI selection, large/unstable/user-forced TextKit fallback selection, and source/block editor state exposure of the selected editor surface. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | BLOCKED | Exit 70. Xcode reported: `Unable to find a device matching the provided destination specifier: { platform:iOS Simulator, OS:latest, name:iPhone 12 }`. The requested iPhone 12 simulator is not installed. |
| `xcodebuild -scheme FastMDMobile -destination 'id=63DAFAF1-789A-4206-8B3C-6B87048AFDF1' test` from `ios/` | PASS | Ran on available `Stage1 iPhone 15 Pro` simulator, iOS 18.6. Executed 86 tests with 0 failures and ended with `** TEST SUCCEEDED **`. This iOS simulator run compiled the UIKit/TextKit bridge. |

## Checklist Evidence

Supervisor can mark complete:

- L9: `Use UIKit/TextKit editor fallback if SwiftUI editor performance is unstable.`

Evidence:

- `ios/Sources/FastMDMobileCore/IOSSourceEditor.swift`
- `ios/Sources/FastMDMobileCore/IOSReaderScreen.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l9-textkit-editor-fallback-20260505.md`
- `swift test` passed.
- Available-simulator `xcodebuild test` passed and compiled the iOS-only UIKit/TextKit bridge.

Keep open:

- L10/L11/L12 gates not directly covered by this batch.
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Blocker:

- The exact iPhone 12 simulator destination required by the blueprint is not installed locally, so mandatory iPhone 12 simulator gates remain blocked in this environment.
