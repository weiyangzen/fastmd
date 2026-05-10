# FastMD Stage 1 Mobile Blueprint

本文档是 FastMD 移动端 Stage 1 的 PRD + 工程蓝图。范围同时覆盖 Android 与 iOS：

- Android 实现放在 `./android/`
- iOS 实现放在 `./ios/`
- 移动端产品、兼容性、渲染、性能、安全、测试与验收文档放在 `./Docs/`

Stage 1 Mobile 的目标不是把桌面悬浮窗口缩到手机上，而是把 FastMD 的核心能力重做成移动端最稳的形式：**打开 Markdown、快速完整渲染、四档字体阅读、搜索、轻量编辑、保存，并在低版本 Android 与 iPhone 12 这一代设备上保持高性能。**

## 0. Product Decision

FastMD Mobile Stage 1 采用一个统一产品目标：

> A maximum-compatibility, high-performance Markdown reader/editor for mobile devices, with complete rich Markdown coverage and predictable local-file behavior.

移动端统一支持：

- 本地或其他 App 交给 FastMD 的 `.md` / Markdown-like 文档
- 单屏自适应布局
- 四档字体大小
- rich Markdown 全面渲染
- 搜索
- 复制代码块
- 全文源码编辑
- 最小 Markdown block 级编辑
- 安全保存
- 最近文档
- 低风险权限模型

移动端不复制桌面特有能力：

- 不做 Finder / Explorer / Nautilus hover
- 不做桌面浮动 preview window
- 不做桌面四档窗口宽度
- 不做桌面 tray / menu bar monitoring toggle
- 不用高权限模拟全局文件管理器监听

## 1. Compatibility Baseline

### Android

Android Stage 1 的最低支持版本锁定为：

```kotlin
minSdk = 27        // Android 8.1
targetSdk = 35
compileSdk = 35
```

选择 Android 8.1 / API 27 的原因：

- 覆盖展锐 W377E、Unisoc 8541 这类全安卓手表和低功耗设备的公开主流底线。
- 同时覆盖骁龙 865 / 888 时代的 OPPO 手机，不牺牲高性能手机体验。
- FastMD 的核心功能相对简单，主要压力在 Markdown 解析、渲染虚拟化、滚动和 IO，不依赖 Android 10+ 才有的高级能力。
- SAF / `ACTION_OPEN_DOCUMENT` 在 API 19 起可用，API 27 可满足 Stage 1 的本地文件闭环。

Android Stage 1 必须用同一个产品核心覆盖：

| Device Class | Minimum Expectation |
| --- | --- |
| Android 8.1 watch / small device | 小文档阅读、搜索、复制、轻量编辑，自动启用 compact performance profile |
| Android 8.1 low-memory phone | 100KB-1MB 文档可流畅打开和滚动 |
| Snapdragon 865 / 888 phone | rich Markdown、大文档、代码/表格/搜索/编辑全能力 |
| Android tablet / foldable | 自适应宽度，内容最大宽度约束，保持同一 reader state |

### iOS

iOS Stage 1 的设备兼容目标锁定为：

```text
Minimum validated device generation: iPhone 12 family
Minimum recommended deployment target: iOS 14.1
Preferred build target: latest stable iOS SDK available in Xcode
```

解释：

- iPhone 12 / 12 mini / 12 Pro / 12 Pro Max 是 A14 这一代，性能足够承载完整 Markdown reader。
- iPhone 12 出厂系统是 iOS 14.x，因此 Stage 1 的兼容设计不应依赖 iOS 16+ 独占能力。
- 如果当前 Xcode / SwiftUI 工具链导致 iOS 14.1 维护成本异常，可把工程 deployment target 提到 iOS 15.0，但 PRD 的性能验收设备仍以 iPhone 12 作为最低实机档。
- iOS 实现必须优先使用 `UIDocumentPickerViewController`、security-scoped resource、SwiftUI / UIKit 混合中最稳的方案。

## 2. Reference Pull Result

用户要求先拉取相邻目录下的 `alphane-android`。实际执行结果：

- `https://github.com/alphane-ai/alphane-android.git` 返回 `Repository not found`
- 可访问的 Android 参考仓库是 `https://github.com/alphane-ai/alphane-mobile-android.git`
- 已拉取到 `../alphane-android`
- 参考提交：`f0dfc56 update`
- 参考 rootProject：`alphane-mobile-android`

FastMD Mobile 不复制 Alphane 的产品 UI，但 Android 工程纪律参考它：

- Gradle Kotlin DSL
- `app -> feature:* -> core` 多模块方向
- AGP / Kotlin / JDK 版本集中管理
- Compose + Material 3
- `lint`、`build`、unit test、assemble gate
- 安全存储、日志、错误映射的分层方式

FastMD Android 会在这个参考上调整：

- `minSdk` 从参考仓库的 26 改为 **27 / Android 8.1**
- 不默认引入网络、推送、登录、Firebase、计费
- 不复制紫粉玻璃社交产品视觉
- 重点转向本地文档性能、渲染完整性、低权限文件访问

## 3. Stage 1 Scope

### In Scope

- Android app skeleton under `./android`
- iOS app skeleton under `./ios`
- Native Android implementation in Kotlin / Jetpack Compose
- Native iOS implementation in Swift / SwiftUI/UIKit
- Shared product rules documented under `./Docs`
- Markdown file open/import/share
- Recent documents
- Rich Markdown render coverage
- Four font tiers
- Search
- Copy code block
- Full source edit
- Block source edit
- Save writable documents
- Read-only fallback
- Low-memory performance profile
- Android 8.1 compatibility
- iPhone 12 generation iOS compatibility
- Manual and automated validation reports

### Out Of Scope

- Desktop hover parity on mobile
- Background daemon monitoring
- File-manager overlay or accessibility scraping
- Cloud sync
- Account/login
- Push notifications
- Collaborative editing
- Full Git client behavior
- Arbitrary HTML/JS execution
- Remote image auto-fetch by default
- WYSIWYG arbitrary text selection editing
- Play Store / App Store final release operations

## 4. Mobile User Stories

| ID | Story | Acceptance |
| --- | --- | --- |
| M1 | As a user, I can open a Markdown file from FastMD. | File picker opens, `.md` is selectable, preview renders. |
| M2 | As a user, I can open Markdown from another app. | Android `ACTION_VIEW` / iOS document open routes into reader. |
| M3 | As a user, I can share Markdown text into FastMD. | Shared text becomes a temporary Markdown document. |
| M4 | As a user, I can read on small and large screens. | Layout fills screen, max width applied on tablet, no horizontal page overflow. |
| M5 | As a user, I can choose one of four font sizes. | Four tiers persist per app and optionally per document. |
| M6 | As a user, I can search inside a document. | Query highlights matches and supports previous/next. |
| M7 | As a user, I can copy a code block. | Code block copy works without selecting line by line. |
| M8 | As a user, I can edit the whole Markdown source. | Full editor opens, dirty state is tracked, save/cancel are explicit. |
| M9 | As a user, I can edit one rendered block. | Long press / context action opens source for the smallest mapped block. |
| M10 | As a user, I do not lose edits. | Back, rotation, app background, and save failure preserve unsaved text. |
| M11 | As a user on Android 8.1, I can still use core reading. | Performance profile falls back gracefully on older/low-memory devices. |
| M12 | As a user on iPhone 12, I can use the full Stage 1 flow. | Open, render, search, edit, save, and rotate pass on iPhone 12-class validation. |

## 5. Core Mobile Interaction Model

### Document Entry

Android:

- Launcher opens FastMD home / recent documents.
- `ACTION_OPEN_DOCUMENT` opens local Markdown through SAF.
- `ACTION_VIEW` accepts `content://` and safe `file://` fallback.
- `ACTION_SEND` accepts `text/plain` and single-document URI.
- Persistable URI permission is taken when available.

iOS:

- `UIDocumentPickerViewController` opens Markdown documents.
- Files app / share sheet routes supported document URLs into FastMD.
- Security-scoped resources are opened only for the active load/save window.
- Recently opened security bookmarks are stored when allowed.

### Reader

- First usable screen is reader / recent documents, not marketing.
- Top bar contains file name, open, search, font tier, theme, more.
- Body is a virtualized block list.
- Tables and code blocks scroll horizontally inside their block only.
- Back / navigation closes transient UI before leaving the document.

### Editing

- Full edit mode uses a source editor.
- Block edit mode uses source line mapping from rendered block to Markdown block.
- Save always writes the whole document from current in-memory source.
- Read-only documents still allow temporary editing and copy, but save is hidden or converted to "Save As" when platform supports it.
- Dirty state survives rotation and app background.

## 6. Four Font Tiers

Mobile Stage 1 has **four font-size tiers only**. It does not inherit desktop's four window-width tiers.

| Tier | Android Body | iOS Body | Line Height | Target |
| --- | ---: | ---: | ---: | --- |
| Compact | `14sp` | `14pt` | `1.48` | watch / small phone / dense notes |
| Default | `16sp` | `16pt` | `1.52` | default phone reading |
| Large | `18sp` | `18pt` | `1.56` | long-form reading |
| Reader | `21sp` | `21pt` | `1.60` | accessibility / comfortable reading |

Rules:

- System font scale / Dynamic Type must still apply.
- The tier is a base scale, not a hard override of accessibility settings.
- Tables and code may use a slightly smaller monospace size per tier to prevent unusable wrapping.
- No continuous viewport-based font scaling.
- Pinch zoom, if implemented, snaps to one of the four tiers.
- Font tier must be part of performance tests because it changes layout work.

## 7. Rich Markdown Coverage

Stage 1 must cover the rich fixture surface in `Tests/Fixtures/Markdown/rich-preview.md`. The acceptance target is about 20 render categories, listed explicitly here.

| # | Render Type | Stage 1 Requirement |
| ---: | --- | --- |
| 1 | H1-H6 headings | Native text styles with stable anchors |
| 2 | Paragraphs | CJK/English mixed wrapping |
| 3 | Bold | Inline styled spans |
| 4 | Italic | Inline styled spans |
| 5 | Bold italic | Combined inline style |
| 6 | Strikethrough | Inline decoration |
| 7 | Inline code | Monospace chip/span |
| 8 | Highlight / mark | Safe inline background |
| 9 | Subscript | Baseline-shift fallback acceptable |
| 10 | Superscript | Baseline-shift fallback acceptable |
| 11 | Links | Safe external link policy |
| 12 | Autolinks / email | Render and route safely |
| 13 | Blockquote | Nested quote visual treatment |
| 14 | Unordered list | Nested list indentation |
| 15 | Ordered list | Stable numbering |
| 16 | Task list | Checked/unchecked visual state |
| 17 | Tables | Horizontal block scroll, header styling |
| 18 | Fenced code blocks | Language label, copy, horizontal scroll |
| 19 | Syntax highlighting | Best-effort tokenizer; no JS requirement |
| 20 | Mermaid blocks | Render as safe diagram-source card in Stage 1; native diagram rendering can be Stage 2 |
| 21 | Inline math | Render readable math text or lightweight parser fallback |
| 22 | Block math | Render readable math block or lightweight parser fallback |
| 23 | Images | Local images supported; remote images manual-open by default |
| 24 | Video HTML | Safe media placeholder; no arbitrary HTML execution |
| 25 | Horizontal rule | Native divider |
| 26 | Footnotes | Render references and footnote section |
| 27 | Details / summary HTML | Safe native disclosure fallback, no raw script |
| 28 | Generic HTML blocks | Sanitized text/card fallback |
| 29 | Mixed CJK / English / Japanese / Korean | Stable wrapping and font fallback |
| 30 | Escaped marker characters | Must remain literal where escaped |

Renderer principle:

- Parse once into a structured document model.
- Preserve source range per block.
- Render each block natively on the platform.
- Never execute Markdown-provided scripts.
- Degrade unsupported rich elements into readable safe cards, not blank output.
- Prefer native rendering for ordinary Markdown blocks.
- JS renderers are allowed only for rich blocks that are impractical to render natively in Stage 1, such as Mermaid or math, and only under the local/offline renderer rules below.

### Local Rich Renderer Rule

Markdown rendering dependencies are allowed, but Stage 1 must not depend on network rendering.

- Any JS/CSS/font renderer dependency must be vendored into the app bundle/repository.
- No CDN, remote script, remote stylesheet, or remote font may be required for Markdown rendering.
- A JS renderer may run only inside an isolated local render surface for a specific rich block or generated safe HTML fragment.
- The renderer must receive sanitized generated input, not raw untrusted Markdown HTML.
- Network access from the render surface must be disabled or intercepted.
- `javascript:`, `data:`, unknown schemes, remote images, iframes, and external script references must be blocked.
- JS renderer output must degrade to a readable source card if the local asset is missing or execution fails.
- Local renderer assets must be covered by packaging tests so release builds do not accidentally omit them.
- Android and iOS should use the same vendored asset versions where practical, recorded in platform reports.

### Native Implementation Guardrails

The app is native on both platforms. JS is a renderer dependency escape hatch, not the app architecture.

- Android app code must be native Kotlin with Jetpack Compose and Android platform APIs. Do not introduce React Native, Flutter, Cordova, a remote WebView shell, or any web app runtime as the primary implementation.
- iOS app code must be native Swift with SwiftUI/UIKit and Apple platform APIs. Do not introduce React Native, Flutter, Cordova, a remote WKWebView shell, or any web app runtime as the primary implementation.
- Use JS renderers only where they materially improve rich Markdown fidelity and can be isolated safely, for example Mermaid or math. Do not use JS for ordinary paragraphs, headings, lists, tables, code fences, links, images, or editor UI.
- Android vendored renderer assets must live under a platform-local app/module asset path such as `android/app/src/main/assets/fastmd-renderers/` and be loaded through local asset APIs only.
- iOS vendored renderer assets must live under a platform-local resource path such as `ios/Resources/FastMDRenderers/` or the Xcode target's bundled resources and be loaded through bundle URLs only.
- Each platform must record the renderer asset names, upstream versions, license notes, and hashes in a platform-local report or lock file before using them in release builds.
- If a local JS renderer is absent, broken, or blocked by policy, the app must still render a readable native fallback card and keep the rest of the document interactive.

## 8. Platform Performance Best Practices

FastMD Mobile should feel like a local utility, not a heavy document app.

### Shared Performance Contract

- IO must never run on the main thread.
- Markdown parsing must never run on the main thread.
- Render models are immutable after creation.
- Rendering is virtualized by Markdown block.
- Scroll never reparses Markdown.
- Font tier switch never rereads the file.
- Remote resources are not auto-loaded.
- Performance must be measured with release-like builds, not only debug builds.

### Android Runtime Profiles

Android has the widest device spread. The same APK must select a profile at runtime:

| Profile | Trigger | Behavior |
| --- | --- | --- |
| Watch Compact | small screen, low RAM, Android 8.1 watch-like device | Disable heavy previews, stricter file limits, compact spacing |
| Legacy Efficient | Android 8.1-9 phone/tablet | Native block virtualization, remote media disabled, conservative animations |
| Modern Standard | Android 10+ phone | Full Stage 1 rich render coverage |
| Large Screen | tablet / foldable / landscape | Max content width, split source/preview optional later |

Android detection inputs:

- API level
- `ActivityManager.isLowRamDevice`
- available memory class
- screen width/height and smallest width
- hardware acceleration availability
- renderer timing history from the current session

### Android Performance Targets

| Scenario | Target |
| --- | --- |
| 50KB document | first render < `180ms` on Snapdragon 865-class device |
| 100KB document | first render < `300ms` on Android 8.1 mid/low device |
| 1MB document | open and scroll without main-thread IO |
| 5MB document | show large-file confirmation; render progressively |
| Search 1MB document | first index < `500ms` on modern phone; background on legacy |
| Font tier switch | no file reread; re-layout only |
| Rotation | no reparse unless process was killed |

### Android Best Practices

- Use Kotlin coroutines with explicit `Dispatchers.IO` for file streams and `Dispatchers.Default` for parsing/search indexing.
- Keep Compose items coarse-grained: one composable per Markdown block or grouped small inline blocks, not one composable per token.
- Use stable keys in `LazyColumn`; block id must derive from source range plus block type, not list index alone.
- Avoid nested lazy layouts except for tables/code where local horizontal scroll is required.
- Disable expensive transitions, animated syntax effects, and live rich previews in Watch Compact and Legacy Efficient profiles.
- Use bounded LRU caches: parsed document cache max 3 documents on modern devices, max 1 on low-RAM devices, disabled on watch compact if needed.
- Use file size gates: small direct render, medium background render, large confirmation/progressive render, huge read-only/source fallback.
- Decode local images with `BitmapFactory.Options.inJustDecodeBounds` first, then sample to screen-bounded dimensions.
- Represent remote images as metadata cards; do not include image-loading dependencies in the critical path for Stage 1.
- Search index is built incrementally and cancellably; typing debounce starts at `150ms`, slower devices may raise it to `250ms`.
- For syntax highlighting, use a lightweight tokenizer and cap highlighted lines per block before falling back to plain monospace.
- Use Android Baseline Profiles only if they prove useful without breaking API 27 support.
- Add Macrobenchmark or instrumentation timing tests for open, parse, render, search, font-tier switch, and scroll jank on at least one modern device.
- On API 27, guard every newer API call and keep dependency versions verified against Android 8.1.

### Android Anti-Patterns

- Do not use WebView as the default renderer.
- Do not parse Markdown inside composables.
- Do not load whole huge images into memory.
- Do not create thousands of `Text` composables for one huge paragraph.
- Do not use broad storage scans to build a library.
- Do not let table width force full-page horizontal scroll.

### iOS Performance Targets

| Scenario | Target |
| --- | --- |
| 50KB document | first render < `160ms` on iPhone 12-class device |
| 100KB document | first render < `240ms` on iPhone 12-class device |
| 1MB document | open/search/edit without blocking the main actor |
| 5MB document | confirmation/progressive render; no UI freeze |
| Font tier switch | no file reread; re-layout only |
| Rotation | no reparse unless process was killed |

### iOS Best Practices

- Use Swift concurrency or GCD so security-scoped file reads/writes and Markdown parse work never run on the main actor.
- Use SwiftUI for the app shell and reader composition, but use UIKit/TextKit-backed editor components if SwiftUI text editing is unstable on iOS 14/15 for large source files.
- Use lazy containers for block rendering and stable block identity.
- Keep parsed document and render model as value-like immutable data passed into the UI.
- Use `NSCache` or explicit bounded in-memory caches for parsed documents and decoded local images.
- Decode images with downsampling through ImageIO to the target display size.
- Use `os_signpost` / Instruments for parse/render/search/save timings during validation.
- Use XCTest performance tests for parser/search/render-model generation and XCUITest smoke tests for UI flows.
- Keep iPhone 12-class device as the minimum real-device performance gate even if the simulator passes.

### iOS Anti-Patterns

- Do not keep a security-scoped resource open longer than needed.
- Do not read/write document URLs on the main actor.
- Do not render one SwiftUI view per token in long documents.
- Do not trust simulator performance as release evidence.
- Do not auto-sync or duplicate document content into iCloud.

## 9. Platform Security And Privacy Best Practices

### Shared Security Contract

- No document正文持久化缓存 by default.
- Recent documents store metadata and access handles only.
- No arbitrary JavaScript execution from Markdown.
- No automatic remote resource fetch.
- External links route through platform browser/open-url mechanism.
- Block dangerous schemes: `javascript:`, `data:`, unknown custom schemes by default.
- Logs must not include document content.
- Crash reports, if added later, must redact file paths and content.

### Android Security Best Practices

Android Stage 1 should start with the smallest permission set:

- No `MANAGE_EXTERNAL_STORAGE`
- No `READ_EXTERNAL_STORAGE`
- No `READ_MEDIA_*`
- No `POST_NOTIFICATIONS`
- No default `INTERNET` unless a later feature explicitly needs it
- `android:allowBackup="false"` unless a backup plan exists
- `android:usesCleartextTraffic="false"`
- Only launcher/open/share entry activities exported
- Non-entry components `exported=false`

Android file and IPC rules:

- Use SAF and `ContentResolver` streams instead of raw filesystem access where possible.
- Persist URI permissions only after explicit user document selection/open intent.
- Treat `file://` as legacy read-only compatibility input unless the app owns the file.
- Validate MIME type and display name, but do not trust either as proof of safe content.
- Never expose internal files through exported providers in Stage 1.
- Add manifest tests that fail on broad storage, notification, unexpected network, or exported non-entry components.
- Keep `android:allowBackup="false"` for Stage 1 because recent document handles and recovery drafts are sensitive.
- If recovery drafts are implemented, store them in app-private storage and clear them after successful user decision.
- If future token/network features appear, use `EncryptedSharedPreferences` / AndroidX Security only for secrets; do not use it for whole Markdown documents by default.

Android link/resource policy:

- Allow `https://` external links through explicit browser handoff.
- For `http://`, show a confirmation or use a visible insecure-link affordance.
- Block `javascript:`, `data:`, `intent:`, `content:`, `file:`, and custom schemes by default unless a future allowlist is documented.
- Remote image URLs render as placeholders with manual open action.

Android release hardening:

- Release builds must be non-debuggable.
- R8/shrinking should be enabled for release unless a validation report documents why it is temporarily disabled.
- ProGuard/R8 keep rules must be minimal.
- Dependency audit must be part of release validation because Android 8.1 support can pull old transitive APIs.

### iOS Security Best Practices

- Use security-scoped URLs for file access.
- Store bookmarks only for recent documents when user intent exists.
- Do not sync content to iCloud by default.
- Do not request photos/library permissions for Markdown reading.
- Do not fetch remote images by default.

iOS file access rules:

- Call `startAccessingSecurityScopedResource()` only around active read/write operations and always balance it with `stopAccessingSecurityScopedResource()`.
- Store security-scoped bookmarks only for user-selected recent documents.
- Handle stale bookmarks by entering `PermissionLost`, not by silently dropping the recent item.
- Do not store document contents in `UserDefaults`, Keychain, iCloud key-value storage, or analytics.
- Recovery drafts, if implemented, must live in app-private storage and be user-visible before restore or deletion.

iOS link/resource policy:

- Use `UIApplication.open` / `SFSafariViewController` policy for allowed web links.
- Block or confirm non-HTTPS and unknown schemes.
- Remote images render as placeholders with manual open.
- Raw HTML is rendered through native sanitized fallback, not WebKit script execution.

iOS release hardening:

- Keep app sandbox expectations explicit; no broad Photos/Documents permissions for Stage 1.
- Use App Transport Security defaults; no arbitrary loads.
- Validate privacy manifest entries before any release claim.
- Do not add background modes unless a future feature justifies them.

## 10. UX State Machine

FastMD Mobile looks simple, but the UX risk is state confusion: file permission expires, a save fails, the user rotates the device, a block editor is open, search is active, or the OS kills the app. Stage 1 must define those states explicitly instead of relying on ad hoc screen behavior.

### App-Level States

| State | Meaning | Required UI |
| --- | --- | --- |
| Empty | No active document | Open button, recent documents, no fake sample content |
| Loading | A document stream is being read | Non-blocking progress, cancel allowed where platform supports it |
| Rendering | Markdown has loaded and render model is being built | Keep previous safe UI; do not show half-mutated document |
| Ready | Rendered document is visible | Reader controls enabled |
| Searching | Search UI is active | Query field, count, previous/next, clear |
| EditingSource | Full source editor is active | Save, cancel, dirty indicator |
| EditingBlock | Block editor is active | Save block, cancel, source range context |
| Saving | Writable document is being written | Disable duplicate save; keep dirty buffer |
| ReadOnly | Active handle cannot write | Hide save or show Save As; never imply persistence |
| PermissionLost | Recent URI/bookmark no longer opens | Recovery action; remove/reopen choices |
| Error | Load/render/save failed | Human-readable reason and retry/reopen path |

### Navigation Rules

- Back closes search first.
- Back closes block editor second, with dirty confirmation if needed.
- Back closes full source editor third, with dirty confirmation if needed.
- Back from reader returns to recent documents.
- Rotation must preserve active document, scroll, font tier, search query, and dirty edit buffer.
- App background must preserve dirty text in a short-lived recovery draft.
- Process death recovery must offer to restore unsaved edits before reopening the old file.
- A save failure must leave the editor open with the unsaved buffer intact.

### Layout Rules

- The reader is a layout product first: whitespace, hit targets, scroll physics, and error states matter more than decorative color.
- Stage 1 ships only light and dark themes. High-contrast foreground/background configuration is reserved for a later explicit accessibility pass.
- No text may overlap at any supported font tier.
- Buttons must remain at least `44dp` / `44pt` hit targets where screen size permits; watch compact mode may use smaller visual density but must keep tappable rows practical.
- Code/table/image blocks cannot force whole-page horizontal scroll.
- Top app bar actions collapse into overflow before truncating the document title into unreadability.
- Long file names, CJK names, emoji names, and paths without display names must render gracefully.

## 11. Data Integrity And Save Model

The highest-risk operation in FastMD Mobile is not rendering; it is writing a user's document without corruption.

### Encoding

- Stage 1 reads UTF-8 first.
- UTF-8 with BOM must be accepted and saved without duplicating BOM.
- CRLF / LF line endings must be detected and preserved when possible.
- If decoding fails, show a read-only error with an "open as text fallback" option only if it cannot corrupt saves.
- Stage 1 must not guess and write back unknown legacy encodings.

### Save Safety

- Never stream partially generated text directly from the editor into the destination.
- Build the complete output in memory or a temp buffer first.
- On Android, write through `ContentResolver.openOutputStream(uri, "wt")` only after the full output is ready.
- On iOS, write within a security-scoped access window and keep the dirty buffer until the write succeeds.
- After save, verify by checking stream close success and updating document metadata.
- If the platform supports atomic replace for the current handle, use it; if not, document the limitation in the save result.
- Do not auto-save over the original file in Stage 1.
- Auto-recovery drafts may exist, but they must be clearly separate from the original document.

### Conflict Handling

- Record `loadedAt`, byte size, and a fast content hash when the document is loaded.
- Before saving, detect whether the document likely changed externally.
- If external change is detected, block blind overwrite and offer: reload, save copy, or continue only after explicit confirmation.
- Block editing must fail closed if source ranges no longer match the current document.

## 12. Threat Model

FastMD opens files it does not control. Treat Markdown as untrusted input.

| Threat | Risk | Required Mitigation |
| --- | --- | --- |
| Malicious raw HTML | Script execution / UI spoofing | Escape or sanitize into native safe fallback; no arbitrary script |
| `javascript:` / `data:` links | Code execution / phishing | Block by default |
| `intent:` / custom schemes | App launching abuse | Block unknown schemes; allowlist only |
| Huge Markdown file | OOM / UI freeze | File size gates, progressive parsing, cancellation |
| Deeply nested Markdown | Parser blowup | Max nesting depth and parser time budget |
| Giant table | Layout blowup | Horizontal virtualized/scrollable table block, row/column limits for preview |
| Huge local image | OOM | Decode to bounded size; show metadata fallback on failure |
| Remote image URL | Privacy leak | Do not auto-fetch |
| Log leakage | Private notes exposed | Redact content, query strings, and full paths |
| Stale URI permission | Broken save/open | PermissionLost state and recovery |
| External file mutation | Silent data loss | Conflict detection before save |
| Clipboard copy | Sensitive content exposure | User-initiated only; no automatic clipboard writes |

Security tests must include malicious fixture files, not only happy-path Markdown.

## 13. Accessibility And Internationalization

Stage 1 does not need broad localization, but it does need accessible interaction.

- All icon-only controls require Android content descriptions / iOS accessibility labels.
- Reader block order must match visual reading order for TalkBack / VoiceOver.
- Search result count must be announced when it changes.
- Dirty edit warnings must be accessible alerts, not only color changes.
- Four font tiers must compose with Android font scale and iOS Dynamic Type.
- CJK, Japanese, Korean, emoji, RTL snippets, and long unbroken URLs must not break layout.
- High-contrast foreground/background configuration is out of Stage 1 implementation but must not be blocked by the theme architecture.
- Light/dark theme tokens should be semantic: background, foreground, muted, border, code background, quote border, link, danger, success.

## 14. Observability And Diagnostics

FastMD should be diagnosable without leaking user content.

- Add a local diagnostics screen or report export by Stage 1 validation.
- Include app version, platform version, device class, renderer profile, file size bucket, render timing, parse timing, save timing, and last error category.
- Exclude document content, full file path, full URI, query strings, and clipboard content.
- Use structured error codes for open/read/parse/render/search/save/link/security failures.
- Validation reports should include these diagnostics snapshots for failed cases.

## 15. Platform Engineering Layout

### Docs

```text
Docs/
  Stage1_Mobile_Blueprint.md
  ...
```

### Android

```text
android/
  README.md
  settings.gradle.kts
  build.gradle.kts
  gradle.properties
  gradle/
  app/
  core/
  feature/
    reader/
    library/
    settings/
  docs/
    reports/
    screenshots/
```

Module direction:

```text
app -> feature:reader -> core
app -> feature:library -> core
app -> feature:settings -> core
feature:* does not depend on another feature
core does not depend on app or feature
```

Android stack:

- Kotlin
- Jetpack Compose
- Material 3
- Coroutines
- DataStore
- CommonMark or equivalent structured parser
- JUnit / Kotlin test
- Instrumentation smoke tests
- Optional local WebView renderer only for isolated rich blocks, using vendored assets and no network dependency

### iOS

```text
ios/
  README.md
  FastMDMobile.xcodeproj or Package.swift
  FastMDMobile/
    App/
    Core/
      Document/
      Markdown/
      Render/
      Settings/
      Security/
    Features/
      Reader/
      Library/
      Settings/
  Tests/
  docs/
    reports/
    screenshots/
```

iOS stack:

- Swift
- SwiftUI shell
- UIKit/TextKit where needed for source editor performance
- `UIDocumentPickerViewController`
- Security-scoped resources
- XCTest
- Real-device validation on iPhone 12-class hardware
- Optional local WKWebView renderer only for isolated rich blocks, using vendored assets and no network dependency

## 16. Android Implementation Blueprint

### Gradle Baseline

```kotlin
android {
    compileSdk = 35

    defaultConfig {
        minSdk = 27
        targetSdk = 35
    }
}
```

JDK / Kotlin:

- JDK 17
- Kotlin `1.9.24` initially, aligned with `../alphane-android`
- AGP `8.13.2` initially, aligned with `../alphane-android`
- Compose BOM with versions tested against API 27
- Android implementation language is native Kotlin. JavaScript is permitted only as vendored local renderer code inside isolated rich-block rendering surfaces.

### Android Entry Points

Manifest supports:

- launcher
- `ACTION_VIEW` for Markdown-like mime types and `.md`
- `ACTION_SEND` for `text/plain`
- `ACTION_SEND` for single file URI

Android file handling:

- SAF first
- `ContentResolver` streams
- Persist URI permission if flags allow
- `file://` accepted only as compatibility fallback and normalized into read-only handle

### Android Low-Version Handling

API 27-specific requirements:

- No reliance on Android 10 scoped-storage-only behavior.
- No APIs that require API 29+ without guards.
- Runtime feature checks for document flags.
- Small-screen/watch profile available from first build.
- Compose previews and animations must degrade gracefully on older GPUs.
- If Android WebView is used for Mermaid/math, it must load local bundled assets only and block network requests.

## 17. iOS Implementation Blueprint

### Compatibility

- Minimum validated device: iPhone 12 family.
- Preferred deployment target: iOS 14.1.
- If project tooling forces iOS 15.0, document the reason in `ios/docs/reports/`.
- iOS implementation language is native Swift. JavaScript is permitted only as vendored local renderer code inside isolated rich-block rendering surfaces.

### iOS Entry Points

- App launcher opens recent documents.
- Document picker imports/opens Markdown.
- Files app opens supported document types into FastMD.
- Share sheet accepts text and Markdown document URLs.

### iOS File Handling

- Security-scoped resource access wraps load/save.
- Bookmark storage only for recent documents.
- If bookmark fails, recent item stays visible but shows permission recovery.
- Write failures never discard dirty editor content.

### iOS Local Renderer Handling

- If WKWebView is used for Mermaid/math, it must load local bundled JS/CSS/fonts only.
- Navigation delegates must block external navigation and remote subresource loads.
- Local renderer failures must produce safe source-card fallback instead of blank output.

## 18. Validation Plan

### Android Commands

From `./android`:

```bash
./gradlew lint
./gradlew build
./gradlew :core:testDebugUnitTest
./gradlew :feature:reader:testDebugUnitTest
./gradlew :app:assembleDebug
./gradlew :app:connectedDebugAndroidTest
git diff --check
```

Android device matrix:

| Device Class | Required |
| --- | --- |
| Android 8.1/API 27 emulator or real device | Required |
| Low-memory/small screen profile | Required |
| Snapdragon 865 or similar | Recommended |
| Snapdragon 888 or similar | Recommended |
| Android 14/15 modern device | Required before release claim |

### iOS Commands

From `./ios`:

```bash
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test
```

Real-device validation:

- iPhone 12 / 12 mini / 12 Pro / 12 Pro Max class device
- One modern iPhone
- One iPad or large simulator if tablet support is claimed

### Rich Fixture Tests

Use `Tests/Fixtures/Markdown/rich-preview.md` as the canonical rich rendering fixture. Mobile tests should create platform-local fixture copies under:

```text
android/test-fixtures/markdown/rich-preview.md
ios/Tests/Fixtures/Markdown/rich-preview.md
```

Required checks:

- all 30 render categories produce visible output or explicit safe fallback
- four font tiers apply to all text-bearing render categories
- code/table blocks remain usable at every tier
- unsupported rich blocks do not crash
- no remote resource auto-fetch occurs during fixture render
- local JS/CSS/font renderer assets are packaged and load offline if used

### Required Fixture Matrix

Both platforms should keep equivalent fixture sets:

```text
basic.md
cjk.md
rich-preview.md
long-1mb.md
large-5mb.md
huge-table.md
huge-code-block.md
malformed-markdown.md
malicious-html.md
malicious-links.md
remote-image.md
local-image.md
encoding-utf8-bom.md
line-endings-crlf.md
external-change-before-save.md
readonly-document.md
long-filename.md
rtl-and-emoji.md
```

### Required Automated Test Categories

| Category | Requirement |
| --- | --- |
| Parser contract | Blocks, source ranges, inline styles, rich fallback |
| Renderer golden | Light/dark and four font tiers for rich fixture |
| Layout safety | No overlap, no whole-page horizontal overflow, tappable controls remain usable |
| File access | Open/read/write/read-only/permission-lost flows |
| Save integrity | Encoding, line endings, external mutation, write failure |
| Security | Malicious links, raw HTML, remote image, log redaction |
| Performance | Parse/render/search/font-tier switch budgets |
| Memory | Large files and pathological blocks do not OOM |
| Accessibility | Labels, reading order, Dynamic Type/fontScale |
| Process recovery | Dirty draft survives background/process death where platform allows |

### Platform-Specific Security And Performance Gates

Android gates:

- Manifest audit fails if broad storage, notification, unexpected network, or unintended exported components are present.
- API 27 run validates open, render, search, font tier switch, edit, save/read-only fallback, and process recovery.
- Low-memory profile run validates compact rendering, disabled expensive animation, and no OOM on large fixtures.
- Macrobenchmark or instrumentation timings are recorded for parse, render, search, save, and font tier switch.
- R8/release hardening status is documented before any release claim.
- If Android local JS renderer assets are used, offline packaging and request-blocking tests must pass.

iOS gates:

- Security-scoped resource tests cover open, stale bookmark, read-only, save, and failed save recovery.
- iPhone 12 simulator build/test is mandatory; iPhone 12-class real-device validation is mandatory before parity-complete release claim.
- XCTest performance covers parser, render-model generation, search, and source-range mapping.
- Instruments or `os_signpost` timing snapshots are captured for at least one real-device validation run.
- Privacy manifest / ATS / background-mode audit is documented before any release claim.
- If iOS local JS renderer assets are used, offline packaging and WKWebView navigation-blocking tests must pass.

## 19. Stage 1 Phases

The phase list below is explanatory. It is not an execution checklist. The authoritative execution surface is `## 20. Authoritative Execution Checklist`.

### Phase A — Mobile Skeleton

- Create Android Gradle skeleton under `./android`.
- Create iOS skeleton under `./ios`.
- Add platform READMEs.
- Add shared fixture plan.
- Add validation report directories.

### Phase B — Document Open

- Android SAF open.
- Android `ACTION_VIEW`.
- Android `ACTION_SEND`.
- iOS document picker.
- iOS Files/share entry.
- Recent document metadata store.

### Phase C — Renderer Core

- Structured Markdown parser.
- Source range mapping.
- Rich render model.
- Safe fallback blocks.
- Four font tiers.
- Low-memory profile.

### Phase D — Reader UI

- Android reader screen.
- iOS reader screen.
- Code block copy.
- Table horizontal scroll.
- Link policy.
- Theme toggle.
- Search.

### Phase E — Editing

- Full source editor.
- Block source editor.
- Dirty state.
- Save writable document.
- Read-only fallback.
- Unsaved-change protection.

### Phase F — Validation

- Android API 27 validation.
- Android modern validation.
- iPhone 12 simulator validation.
- iPhone 12 real-device validation when available.
- Rich fixture render report.
- Performance report.
- Security permission audit.
- Android manifest audit.
- Android API 27 low-memory performance gate.
- iOS security-scoped resource gate.
- iOS iPhone 12 performance gate.

## 20. Authoritative Execution Checklist

This is the single authoritative execution checklist for Stage 1 Mobile. Every item starts unchecked by default. Completion must be backed by implementation and validation evidence; documentation-only progress is not enough.

Layer gate rule: do not close a parent item until all child checklist items under it are complete and the relevant validation item has passed.

### L0 — Blueprint Boundary

- [x] Confirm `Docs/Stage1_Mobile_Blueprint.md` is the only Stage 1 Mobile requirement source.
- [x] Keep Android implementation work under `android/`.
- [x] Keep iOS implementation work under `ios/`.
- [x] Keep validation reports under platform-local `docs/reports/`.
- [x] Keep screenshots or golden artifacts under platform-local `docs/screenshots/` or test artifact directories.

### L1 — Repository Skeleton

- [x] Create Android Gradle project skeleton under `android/`.
- [x] Create Android modules `:app`, `:core`, `:feature:reader`, `:feature:library`, and `:feature:settings`.
- [x] Set Android `minSdk = 27`, `targetSdk = 35`, and `compileSdk = 35`.
- [x] Configure Android JDK 17, Kotlin, Compose, Material 3, coroutines, DataStore, and test dependencies.
- [x] Create iOS project skeleton under `ios/`.
- [x] Configure iOS target for iPhone 12-class validation and document the deployment target.
- [x] Create Android fixture directory and seed canonical Markdown fixtures.
- [x] Create iOS fixture directory and seed canonical Markdown fixtures.

### L2 — Core Contracts

- [x] Define shared mobile document handle model for platform document references.
- [x] Define Markdown load result model with file metadata, write capability, and source origin.
- [x] Define render model with stable block ids and source ranges.
- [x] Define four font tier model: Compact, Default, Large, Reader.
- [x] Define reader UI state model covering Empty, Loading, Rendering, Ready, Searching, EditingSource, EditingBlock, Saving, ReadOnly, PermissionLost, and Error.
- [x] Define structured error codes for open, read, parse, render, search, edit, save, link, permission, and security failures.
- [x] Define link policy model with allowed, confirm, and blocked decisions.
- [x] Define platform performance profile model for Android and iOS.
- [x] Define local/offline rich renderer asset policy for any JS/CSS/font dependencies.

### L3 — Android Document Entry

- [x] Implement Android launcher entry.
- [x] Implement Android SAF open through `ACTION_OPEN_DOCUMENT`.
- [x] Implement Android `ACTION_VIEW` for Markdown-like documents.
- [x] Implement Android `ACTION_SEND` for shared text.
- [x] Implement Android `ACTION_SEND` for single document URI.
- [x] Persist Android URI permission only when flags allow.
- [x] Normalize Android `file://` fallback as read-only unless app-owned.
- [x] Store Android recent document metadata without storing document content.
- [x] Handle Android stale URI permission with `PermissionLost` state.

### L4 — iOS Document Entry

- [x] Implement iOS launcher entry.
- [x] Implement iOS document picker for Markdown-like files.
- [x] Implement iOS Files app open path.
- [x] Implement iOS share text path.
- [x] Implement iOS share document URL path.
- [x] Use security-scoped access for iOS read/write operations.
- [x] Store iOS bookmarks only for user-selected recent documents.
- [x] Handle stale iOS bookmarks with `PermissionLost` state.
- [x] Store iOS recent document metadata without storing document content.

### L5 — Markdown Parser And Renderer

- [x] Implement structured Markdown parser adapter.
- [x] Preserve source range for every rendered block.
- [x] Render headings H1-H6.
- [x] Render paragraphs with mixed CJK/English wrapping.
- [x] Render bold, italic, bold italic, strikethrough, inline code, highlight, subscript, and superscript.
- [x] Render links, autolinks, and email links through safe link policy.
- [x] Render blockquotes including nested blockquotes.
- [x] Render unordered lists, ordered lists, and task lists.
- [x] Render tables with local horizontal scrolling.
- [x] Render fenced code blocks with language labels and copy action.
- [x] Implement bounded syntax highlighting or plain fallback.
- [x] Render Mermaid blocks as safe diagram-source cards.
- [x] Render inline and block math as readable safe fallback.
- [x] Use vendored local JS renderer assets for Mermaid/math only if native fallback is insufficient.
- [x] Ensure JS renderer assets are packaged locally and never loaded from CDN.
- [x] Block network and external navigation from any local render surface.
- [x] Render local images with bounded decode.
- [x] Render remote images as placeholders with manual open action.
- [x] Render video HTML as safe media placeholder.
- [x] Render horizontal rules.
- [x] Render footnotes.
- [x] Render details/summary HTML as native disclosure fallback.
- [x] Render generic HTML blocks as sanitized text/card fallback.
- [x] Preserve escaped marker characters.

### L6 — Reader UX And Layout

- [x] Implement Android reader screen.
- [x] Implement iOS reader screen.
- [x] Implement empty state with open action and recent documents.
- [x] Implement loading and rendering states without blocking the UI.
- [x] Implement four font tier controls and persistence.
- [x] Apply four font tiers across all text-bearing rich Markdown blocks.
- [x] Implement light and dark themes with semantic tokens.
- [x] Implement search with highlight, result count, previous, next, and clear.
- [x] Implement code block copy.
- [x] Keep code/table/image blocks from forcing whole-page horizontal scroll.
- [x] Ensure long filenames, CJK names, emoji names, and missing display names render gracefully.
- [x] Implement Back/navigation behavior for search, block edit, source edit, reader, and recent documents.
- [x] Preserve active document, scroll, font tier, search query, and dirty edit buffer through rotation.

### L7 — Editing And Save Integrity

- [x] Implement full source editor on Android.
- [x] Implement full source editor on iOS.
- [x] Implement block source editor on Android.
- [x] Implement block source editor on iOS.
- [x] Track dirty state consistently.
- [x] Preserve dirty buffer on app background.
- [x] Offer process death recovery for unsaved edits where platform lifecycle permits.
- [x] Detect UTF-8 BOM and avoid duplicate BOM on save.
- [x] Preserve CRLF/LF line endings where possible.
- [x] Fail read-only on unsupported legacy encoding instead of corrupting saves.
- [x] Build complete output before writing to destination.
- [x] Keep dirty buffer intact after failed save.
- [x] Detect external document mutation before save.
- [x] Block blind overwrite after external mutation.
- [x] Fail closed when block source ranges no longer match.

### L8 — Android Performance And Security

- [x] Implement Android Watch Compact profile.
- [x] Implement Android Legacy Efficient profile.
- [x] Implement Android Modern Standard profile.
- [x] Implement Android Large Screen profile.
- [x] Keep Android file IO on `Dispatchers.IO`.
- [x] Keep Android parse/search work on `Dispatchers.Default`.
- [x] Use coarse-grained Compose block rendering with stable keys.
- [x] Disable expensive animations on Android 8.1 low-memory profile.
- [x] Decode Android local images with bounded sampling.
- [x] Add Android manifest audit for broad storage, notification, unexpected network, and exported components.
- [x] Ensure Android Stage 1 has no `MANAGE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`, `READ_MEDIA_*`, or `POST_NOTIFICATIONS`.
- [x] Ensure Android Stage 1 has no default `INTERNET` permission.
- [x] Ensure Android `allowBackup` posture is documented and disabled for Stage 1 unless explicitly changed.
- [x] Block Android dangerous link schemes by default.
- [x] Document Android R8/release hardening posture.
- [x] If Android WebView rich rendering is used, load vendored local assets only and block network requests.

### L9 — iOS Performance And Security

- [x] Keep iOS file IO off the main actor.
- [x] Keep iOS parse/search work off the main actor.
- [x] Use lazy block rendering on iOS.
- [x] Use UIKit/TextKit editor fallback if SwiftUI editor performance is unstable.
- [x] Downsample local images through ImageIO on iOS.
- [x] Balance every iOS `startAccessingSecurityScopedResource()` with `stopAccessingSecurityScopedResource()`.
- [x] Handle stale iOS security-scoped bookmarks.
- [x] Block iOS dangerous link schemes by default.
- [x] Keep iOS remote images as manual-open placeholders.
- [x] Audit iOS App Transport Security posture.
- [x] Audit iOS privacy manifest posture before release claim.
- [x] Confirm no iOS background modes are added for Stage 1.
- [x] If iOS WKWebView rich rendering is used, load vendored local assets only and block network requests.

### L10 — Accessibility And Diagnostics

- [x] Add Android content descriptions for all icon-only controls.
- [x] Add iOS accessibility labels for all icon-only controls.
- [x] Ensure TalkBack reader order matches visual order.
- [x] Ensure VoiceOver reader order matches visual order.
- [x] Announce search result count changes accessibly.
- [x] Make dirty edit warnings accessible alerts.
- [x] Validate Android fontScale with all four font tiers.
- [x] Validate iOS Dynamic Type with all four font tiers.
- [x] Add local diagnostics report excluding document content, full path, full URI, query strings, and clipboard.
- [x] Include parse, render, search, save, device class, renderer profile, file size bucket, and last error category in diagnostics.

### L11 — Automated Test Gates

- [x] Add parser contract tests.
- [x] Add source range mapping tests.
- [x] Add rich renderer golden/snapshot tests for light theme across four font tiers.
- [x] Add rich renderer golden/snapshot tests for dark theme across four font tiers.
- [x] Add layout safety tests for overlap, horizontal overflow, and tappable controls.
- [x] Add file access tests for open, read, write, read-only, permission-lost, and stale bookmark/URI flows.
- [x] Add save integrity tests for BOM, CRLF/LF, external mutation, and write failure.
- [x] Add malicious HTML fixture tests.
- [x] Add malicious link fixture tests.
- [x] Add remote image privacy tests.
- [x] Add local renderer packaging/offline tests if JS renderer assets are used.
- [x] Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- [x] Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- [x] Add log redaction tests.
- [x] Add performance tests for parse, render, search, font tier switch, and save.
- [x] Add memory stress tests for huge table, huge code block, huge image metadata, and large document.
- [x] Add accessibility smoke tests.
- [x] Add process recovery tests where platform lifecycle permits.

### L12 — Platform Validation

- [ ] Run Android `./gradlew lint`.
- [ ] Run Android `./gradlew build`.
- [ ] Run Android `./gradlew :core:testDebugUnitTest`.
- [ ] Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- [ ] Run Android `./gradlew :app:assembleDebug`.
- [ ] Run Android `./gradlew :app:connectedDebugAndroidTest`.
- [ ] Run Android API 27 validation.
- [ ] Run Android low-memory/small-screen profile validation.
- [ ] Run Android modern device validation.
- [x] Run iOS iPhone 12 simulator build.
- [x] Run iOS iPhone 12 simulator tests.
- [ ] Run iOS iPhone 12-class real-device validation before parity-complete release claim.
- [ ] Capture Android performance report.
- [x] Capture iOS performance report.
- [x] Capture Android security audit report.
- [x] Capture iOS security audit report.
- [x] Capture rich fixture render report.

### L13 — Documentation Reconciliation

- [x] Update `android/README.md` with final build/test commands after Android skeleton lands.
- [x] Update `ios/README.md` with final build/test commands after iOS skeleton lands.
- [x] Record validation reports under `android/docs/reports/`.
- [x] Record validation reports under `ios/docs/reports/`.
- [ ] Keep this authoritative checklist synchronized with actual implementation status.

## 21. Definition Of Done

Stage 1 Mobile is complete only when all of these are true:

1. `./Docs/Stage1_Mobile_Blueprint.md` remains the source of truth.
2. Android implementation lives under `./android`.
3. iOS implementation lives under `./ios`.
4. Android builds with `minSdk = 27`, `targetSdk = 35`, `compileSdk = 35`.
5. Android 8.1/API 27 opens and renders basic Markdown.
6. Android modern device opens and renders the rich fixture.
7. iPhone 12 simulator builds and passes reader tests.
8. iPhone 12-class real device is validated before any parity-complete release claim.
9. Four font tiers work across rich Markdown categories.
10. Rich fixture produces visible output or explicit safe fallback for every listed render type.
11. Search works on a 1MB document without main-thread IO.
12. Full source editing works.
13. Block editing maps back to the correct source range.
14. Writable documents save successfully.
15. Read-only documents never pretend saving succeeded.
16. Back/rotation/background do not discard dirty edits silently.
17. Android manifest contains no broad storage permission.
18. iOS uses security-scoped resource access correctly.
19. Remote resources are not auto-fetched by default.
20. Validation reports exist under platform `docs/reports/`.
21. Android API 27 security/performance gate passes.
22. Android manifest audit proves no unexpected permissions or exported components.
23. Android low-memory profile avoids OOM on required large/pathological fixtures.
24. iOS security-scoped resource tests cover open, stale bookmark, read-only, save, and failed save.
25. iOS iPhone 12 performance gate records parse/render/search/font-tier timings.
26. iOS privacy/ATS/background-mode audit is documented.
27. Android implementation remains native Kotlin/Compose except vendored local JS renderer assets for isolated rich blocks.
28. iOS implementation remains native Swift/SwiftUI/UIKit except vendored local JS renderer assets for isolated rich blocks.
29. Any JS/CSS/font renderer assets required for rich Markdown are packaged locally and validated offline.
30. Any WebView/WKWebView renderer surface blocks external navigation and remote subresource loading.

## 22. PRD Positioning

FastMD Mobile Stage 1 should be judged by this standard:

- **Fast:** local Markdown opens quickly, scrolls smoothly, and never parses during scroll.
- **Compatible:** Android goes down to 8.1, iOS validates on iPhone 12 generation.
- **Complete enough:** rich Markdown is broadly rendered, with safe fallbacks for complex blocks.
- **Safe:** no broad file permissions, no script execution, no hidden remote loads.
- **Simple:** the product is a reader/editor first, not a social app, cloud app, or file-manager replacement.

The implementation should stay boring and disciplined. The hard part is not the screen count; it is keeping rendering complete, old-device behavior stable, and file writes trustworthy.
