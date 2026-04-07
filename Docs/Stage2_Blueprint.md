# FastMD Stage 2 Blueprint

This document defines the Stage 2 cross-platform direction for FastMD.

Stage 2 is not a vague "make it cross-platform" phase. It is a controlled architecture transition from a macOS-only Finder prototype into a shared-core desktop product with explicit host-surface boundaries.

## Fixed Stage 2 Product Scope

These targets are in scope for Stage 2 and should be treated as the only supported desktop surfaces unless this document is updated:

- macOS 14+ with Finder
- Windows 11 with Explorer
- Ubuntu 24.04 with GNOME Files (`Files` / `Nautilus`)

These are explicitly out of scope for the first Stage 2 pass:

- Kubuntu / Dolphin
- Xubuntu / Thunar
- Ubuntu MATE / Caja
- generic "all Linux file managers"
- iOS implementation work
- Android implementation work

## Core Stage 2 Decision

Stage 2 should use Rust plus Tauri, but not as a fake "one code path for everything" promise.

The correct architecture is:

- Tauri provides the shared desktop shell, shared frontend, tray/window orchestration, and Rust-to-web IPC.
- Rust provides the shared product logic, state machines, contracts, rendering policy, and platform-neutral behavior rules.
- Platform adapters provide the real OS-specific integrations for Finder, Explorer, and Ubuntu 24.04 GNOME Files.

Tauri is the unifying shell. It is not the layer that makes Finder AX, Windows UI Automation, and Linux accessibility APIs magically behave the same.

## What Must Be Unified

Stage 2 must unify product semantics across all supported desktop targets:

- 1-second hover trigger opens preview
- a different hovered Markdown file replaces the existing preview
- left/right controls step through the same four width tiers
- `Tab` toggles the same background modes
- `(⇧+) Space` pages through content using the same motion model
- mouse wheel and touchpad scrolling operate on the preview when it is hot
- double-clicking a rendered block enters source editing for the smallest matching block
- edit mode locks replacement and dismissal until save or cancel
- outside click, app switch, and Escape follow the same close policy
- the top-right preview chrome stays collapsed into one compact hint chip
- the visual language, motion timings, and width-tier model stay consistent across desktop targets

## What Will Not Be Unified

The following implementation details are platform-specific by definition and must be isolated behind adapters:

- frontmost file-manager detection
- hovered item resolution
- accessibility and automation permissions
- global mouse monitoring
- monitor and coordinate conversion
- window focus and no-steal-focus behavior
- tray/menu-bar/system-status integration
- signing, packaging, and installer workflows

Stage 2 should unify behavior, not pretend that system integration is identical on all three OSes.

## Ubuntu Clarification

For Stage 2, "Ubuntu support" means:

- Ubuntu 24.04
- GNOME desktop
- GNOME Files, also known as `Files` / `Nautilus`

Stage 2 must not say merely "Ubuntu" in code, docs, or issue tracking when it really means Ubuntu 24.04 plus GNOME Files.

## Why Tauri Is The Right Shell

Tauri is appropriate for Stage 2 because it gives FastMD:

- a shared desktop window and tray model
- a shared frontend built once for macOS, Windows, and Linux
- Rust-native backend code instead of a JavaScript-only desktop shell
- a clear command/event bridge between UI and system adapters
- practical plugin support for global shortcuts and window positioning

Tauri does not eliminate platform differences in file-manager integration, but it is a good place to centralize:

- app lifecycle
- preview window lifecycle
- shared settings
- diagnostics
- shared UI rendering
- shared command routing

## Stage 2 Technical Boundary

The current Swift/AppKit app should remain shippable during the transition. Stage 2 is therefore a migration phase, not a stop-the-world rewrite.

The repository should support this temporary reality:

- the existing macOS Swift app continues to build and validate Layer 1 behavior
- the repository layout starts making room for Rust and Tauri shared-core work
- cross-platform logic is designed first, then implemented incrementally

## Target Runtime Architecture

Stage 2 should converge toward the following layered architecture:

1. Shared frontend
2. Shared Rust contracts
3. Shared Rust product logic
4. Shared Rust rendering policy
5. Platform adapter crates
6. Tauri desktop shell
7. Legacy macOS Swift app kept alive during migration

### Shared Frontend Responsibilities

The shared frontend should own:

- preview shell UI
- toolbar and compact hint chip
- rendering host container
- inline editing UI
- settings surfaces
- diagnostics surfaces
- state presentation
- animation presentation

The frontend should not own:

- file-manager resolution
- automation permission logic
- platform-specific hover capture

### Shared Rust Responsibilities

The shared Rust core should own:

- preview state machine
- width-tier state
- background-mode state
- paging physics
- edit-mode locking rules
- preview replacement rules
- capability negotiation
- settings model
- structured diagnostics model
- cross-platform command and event contracts

### Platform Adapter Responsibilities

Each platform adapter should own:

- current front surface detection
- hovered item resolution
- permission checks and permission requests
- system coordinate translation
- file-manager-specific fallbacks
- native edge-case handling

## Required Stage 2 Traits

Stage 2 should define platform interfaces before implementing platform ports.

The exact Rust names may change, but the separation should look like this:

```rust
pub trait HostSurface {
    fn platform_id(&self) -> PlatformId;
    fn capabilities(&self) -> HostCapabilities;
    fn permission_state(&self) -> Result<PermissionState, HostError>;
    fn request_permissions(&self) -> Result<PermissionState, HostError>;
    fn current_front_surface(&self) -> Result<FrontSurface, HostError>;
    fn hovered_item(&self, cursor: ScreenPoint) -> Result<Option<HoveredItem>, HostError>;
}

pub trait PreviewWindowHost {
    fn show_preview(&self, request: PreviewWindowRequest) -> Result<(), HostError>;
    fn move_preview(&self, request: PreviewWindowRequest) -> Result<(), HostError>;
    fn hide_preview(&self) -> Result<(), HostError>;
}

pub trait DocumentHost {
    fn load_markdown(&self, path: &DocumentPath) -> Result<LoadedDocument, HostError>;
    fn save_markdown(&self, path: &DocumentPath, content: &str) -> Result<(), HostError>;
}
```

These traits must keep product logic detached from Finder, Explorer, and Nautilus implementation details.

## Required Shared Crates

Stage 2 should add the following Rust workspaces or equivalent modules:

- `fastmd-contracts`
  Shared commands, events, DTOs, capability flags, and error envelopes.
- `fastmd-core`
  Preview lifecycle state machine and product rules.
- `fastmd-render`
  Shared Markdown rendering policy, block mapping, preview model generation, and theme semantics.
- `fastmd-platform`
  Traits and shared platform abstractions only.
- `fastmd-platform-macos`
  Finder integration and macOS-specific host code.
- `fastmd-platform-windows`
  Explorer integration and Windows-specific host code.
- `fastmd-platform-linux-nautilus`
  Ubuntu 24.04 GNOME Files integration.

## Required App Surfaces

The repository should support these app-level surfaces:

- `apps/macos`
  Existing Swift/AppKit implementation kept alive during migration.
- `apps/desktop-tauri`
  Future shared desktop shell for Rust + Tauri.
- `ui`
  Shared frontend assets and app-shell presentation code.

## Stage 2 Repository Layout

The desired repository direction is:

```text
Docs/
  Layer_1_Blueprint.md
  Stage2_Blueprint.md
apps/
  macos/
    Sources/
    Tests/
  desktop-tauri/
crates/
  fastmd-contracts/
  fastmd-core/
  fastmd-render/
  fastmd-platform/
  fastmd-platform-macos/
  fastmd-platform-windows/
  fastmd-platform-linux-nautilus/
ui/
ios/
android/
Tests/
  Fixtures/
Scripts/
```

`Tests/Fixtures/` stays at the repository root because the same Markdown, HTML, and host-resolution fixtures should remain usable by both the legacy Swift app and future Rust/Tauri work.

## Stage 2 Support Matrix

### macOS

Stage 2 target:

- Finder
- Accessibility-based item resolution
- parity with current Layer 1 behavior

Migration rule:

- keep the Swift app compiling while Rust/Tauri abstractions are introduced

### Windows

Stage 2 target:

- Windows 11
- Explorer
- Windows-native automation path

Migration rule:

- do not start Windows work until the shared contracts and state machine are stable

### Ubuntu

Stage 2 target:

- Ubuntu 24.04
- GNOME desktop
- GNOME Files / Nautilus

Migration rule:

- do not generalize to all Linux file managers
- document Wayland/X11 limitations explicitly as evidence is gathered

## Stage 2 Interaction Contract

The following behaviors must be locked before adding new platform adapters:

- hover debounce duration
- preview replacement policy
- close policy
- width-tier definitions
- background-mode definitions
- paging rules
- edit-mode locking rules
- hint-chip copy and icon grammar
- diagnostic event names

No platform adapter should be free to improvise product semantics.

## Stage 2 Windowing Rules

Stage 2 should keep one shared preview window model across the desktop targets:

- floating preview window
- non-disruptive activation behavior
- width/height chosen from the same 4:3 tier model
- reposition before shrinking when the chosen tier still fits on the current screen
- multi-monitor placement as a first-class requirement

The exact native API calls can differ, but the window policy must not diverge by platform without an explicit blueprint change.

## Stage 2 Rendering Rules

Stage 2 should keep one shared rendering contract:

- same Markdown support surface
- same block-to-source mapping rules
- same inline editor semantics
- same theme variables
- same width-tier breakpoints
- same compact top-right hint chip

Pixel-perfect visual equality across WebView engines is not required. Semantic and structural parity is required.

## Stage 2 Test Strategy

Testing must be split by layer rather than by wishful thinking.

### Shared Tests

These should be cross-platform and mandatory:

- state-machine tests
- width-tier tests
- paging tests
- edit-lock tests
- rendering contract tests
- block mapping tests
- event contract tests

### Platform Tests

These should be platform-specific:

- Finder fixtures and AX resolution tests
- Explorer resolution fixtures and automation tests
- Nautilus resolution fixtures and Linux accessibility tests

### UI Tests

These should verify:

- compact hint chip
- editing UI states
- width-tier UI state
- background-mode UI state

### End-To-End Tests

These must remain platform-specific and evidence-driven:

- macOS Finder
- Windows Explorer
- Ubuntu 24.04 GNOME Files

Stage 2 should not pretend that one end-to-end test rig can fully validate all three host surfaces.

## Stage 2 Migration Order

The order of execution matters.

1. Freeze Layer 1 semantics in contracts and docs.
2. Extract shared product rules and state machines into Rust.
3. Define platform traits and event contracts.
4. Create the Tauri shell and shared frontend.
5. Integrate the shared core with the current macOS behavior expectations.
6. Add Windows Explorer support.
7. Add Ubuntu 24.04 GNOME Files support.
8. Decide later whether the legacy macOS Swift shell should be retired.

This order is intentionally conservative. It avoids rewriting macOS, inventing Windows support, and inventing Linux support all at once.

## Stage 2 Anti-Goals

These are explicitly bad ideas for Stage 2:

- declaring support for "Linux" without naming Ubuntu 24.04 plus Nautilus
- rewriting the whole app before contracts exist
- moving all logic into the web frontend
- letting each platform drift into different interaction rules
- forcing the current macOS app to stop building while scaffolding is added
- assuming Tauri alone solves file-manager integration

## Stage 2 Authoritative Execution Checklist

This checklist is the single execution source for Stage 2.

If a future cron, tmux worker set, or manual execution loop is used, it must derive work from the checklist below rather than inventing a second requirement source.

Checklist reset rule:

- All checklist items below are intentionally reset to `[ ]`.
- Existing scaffolding, prototypes, or local experiments do not count as done until they are integrated into the main repository and validated against the parity gates below.
- The reference implementation is the current macOS app under `apps/macos`.
- Windows 11 and Ubuntu 24.04 work is successful only when it reproduces the same user-visible behavior as the current macOS app.
- No Stage 2 task may regress the current macOS app behavior while adding shared-core, Tauri, Windows, or Ubuntu support.

### Layer 0 — Reference Freeze And Repository Boundary

- [ ] Freeze the current macOS app under `apps/macos` as the Stage 2 behavioral reference surface
- [x] Record the exact macOS validation commands that must stay green during all Stage 2 work
- [ ] Keep the current macOS Swift package building after every Stage 2 batch
- [ ] Keep the current macOS Xcode project building after every Stage 2 batch
- [ ] Keep `Tests/Fixtures/` shared at the repository root for all desktop targets
- [ ] Keep `apps/macos`, `apps/desktop-tauri`, `crates`, and `ui` as the only active Stage 2 implementation roots
- [x] Add root-level ignore rules for Rust, Tauri, frontend, and platform-specific build artifacts
- [x] Update root workspace documentation so the repository layout is explicit and stable
- [ ] Keep `ios` and `android` as reserved placeholders only and out of Stage 2 execution scope

### Layer 1 — Shared Rust Workspace And Contracts

- [x] Add a root Cargo workspace that includes `fastmd-contracts`, `fastmd-core`, `fastmd-render`, `fastmd-platform`, `fastmd-platform-macos`, `fastmd-platform-windows`, and `fastmd-platform-linux-nautilus`
- [x] Create buildable crate manifests for all Stage 2 Rust crates
- [x] Define `PlatformId`
- [x] Define `PermissionState`
- [x] Define `FrontSurface`
- [x] Define `ScreenPoint`
- [x] Define `ScreenRect`
- [x] Define monitor metadata contracts
- [x] Define `HoveredItem`
- [x] Define `ResolvedDocument`
- [x] Define `LoadedDocument`
- [x] Define `HostCapabilities`
- [x] Define `PreviewWindowRequest`
- [x] Define `PreviewState`
- [x] Define sub-state DTOs for hover, preview visibility, paging, editing, and close reasons
- [x] Define shared `AppCommand` messages
- [x] Define shared `AppEvent` messages
- [x] Define a stable Rust error envelope for platform adapters and shell integration
- [x] Add serde-based round-trip tests for all shared contracts

### Layer 2 — Shared Product Semantics Derived From macOS

- [x] Encode the 1-second hover trigger rule in the shared core
- [x] Encode the “different hovered Markdown file replaces current preview” rule in the shared core
- [x] Encode the “same file does not repeatedly reopen while stationary” rule in the shared core
- [x] Encode the frontmost-file-manager gating rule in the shared core
- [x] Encode the “local `.md` only” acceptance rule in the shared core
- [x] Encode the four explicit preview width tiers in the shared core
- [x] Encode the 4:3 preview aspect-ratio rule in the shared core
- [x] Encode the “reposition before shrinking when the selected tier still fits” rule in the shared core
- [x] Encode the pure white / pure black background toggle rule in the shared core
- [x] Encode the compact top-right hint-chip contract in the shared core
- [x] Encode the hot interaction-surface rule in the shared core
- [x] Encode mouse-wheel and touchpad scrolling semantics in the shared core
- [x] Encode `Space`, `Shift+Space`, `Page Up`, and `Page Down` paging semantics in the shared core
- [x] Encode sticky eased paging motion in the shared core
- [x] Encode outside-click close semantics in the shared core
- [x] Encode app-switch close semantics in the shared core
- [x] Encode `Escape` close semantics in the shared core
- [x] Encode edit-mode lock semantics in the shared core
- [x] Encode “double-click smallest source block to edit” semantics in the shared core
- [x] Encode save and cancel edit semantics in the shared core
- [x] Add unit tests for all core semantic rules above

### Layer 3 — Shared Rendering And Editing Contract

- [x] Define the Stage 2 Markdown rendering contract in `fastmd-render`
- [x] Define the block-to-source mapping contract in `fastmd-render`
- [x] Define shared theme variables and width-tier constants in `fastmd-render`
- [x] Define the compact hint-chip contract in `fastmd-render`
- [x] Define preview model DTOs passed into the desktop frontend
- [x] Define the inline-editor model passed into the desktop frontend
- [x] Encode heading rendering parity
- [x] Encode paragraph rendering parity
- [x] Encode emphasis and strong rendering parity
- [x] Encode fenced-code rendering parity
- [x] Encode syntax-highlighted code rendering parity
- [ ] Encode blockquote rendering parity
- [x] Encode task-list rendering parity
- [ ] Encode table rendering parity
- [ ] Encode Mermaid rendering parity
- [ ] Encode math rendering parity
- [ ] Encode image rendering parity
- [ ] Encode footnote rendering parity
- [ ] Encode HTML-block rendering parity
- [ ] Encode compact top-right hint-chip visual parity
- [ ] Add snapshot or fixture tests for rendering DTOs and block mappings

### Layer 4 — Shared Frontend And Tauri Shell

- [x] Add a real Tauri app manifest under `apps/desktop-tauri`
- [x] Add a Rust entrypoint for the Tauri shell
- [x] Add a shared frontend app shell under `ui`
- [x] Implement the preview shell UI in the shared frontend
- [x] Implement the compact hint chip in the shared frontend
- [x] Implement width-tier UI state in the shared frontend
- [x] Implement background-mode UI state in the shared frontend
- [x] Implement inline block editing UI in the shared frontend
- [x] Implement the command/event bridge between Tauri and the Rust core
- [x] Integrate Tauri window positioning behavior needed for the preview window
- [x] Integrate Tauri global shortcut support needed by the shared desktop shell
- [x] Expose host capability state to the shared frontend
- [x] Add UI tests for the hint chip, width tiers, background mode, and editing states

### Layer 5 — macOS Reference Parity And Regression Protection

- [x] Create `fastmd-platform-macos` as a buildable crate
- [x] Mirror the current Finder-frontmost rule in the shared contracts
- [x] Mirror the current Finder list-view hover resolution rule in the shared contracts
- [x] Mirror the current multi-display coordinate handling rule in the shared contracts
- [x] Mirror the current four-width-tier behavior in the shared contracts
- [x] Mirror the current 4:3 placement and resize policy in the shared contracts
- [x] Mirror the current hot interaction-surface behavior in the shared contracts
- [x] Mirror the current `Tab` background toggle behavior in the shared contracts
- [x] Mirror the current scrolling and paging behavior in the shared contracts
- [x] Mirror the current inline block editing behavior in the shared contracts
- [x] Mirror the current compact hint-chip behavior in the shared contracts
- [x] Preserve the current macOS rendering behavior while introducing shared-core wiring
- [x] Preserve the current macOS edit-mode lock behavior while introducing shared-core wiring
- [x] Preserve the current macOS close behavior while introducing shared-core wiring
- [x] Add explicit parity tests or validation evidence that macOS behavior did not regress
- [x] Keep the Swift shell or Tauri-backed macOS shell behaviorally identical to the current app until a later blueprint change explicitly says otherwise

### Layer 6 — One-To-One Windows 11 Explorer Parity

- [x] Restrict Windows support target to Windows 11 plus Explorer only
- [x] Create `fastmd-platform-windows` as a buildable crate
- [x] Implement Windows frontmost Explorer detection with the same gating semantics as macOS Finder
- [x] Identify the authoritative Windows host API stack for frontmost Explorer detection
- [x] Resolve the active Explorer surface to a stable Explorer identity instead of a generic foreground-window check
- [x] Reject non-Explorer foreground windows with the same strict gating semantics as macOS Finder
- [ ] Record validation evidence for frontmost Explorer detection on a real Windows 11 machine
- [x] Implement Windows hovered-item resolution so the actual hovered `.md` item is resolved rather than a nearby or first visible candidate
- [x] Identify the authoritative Windows host API stack for hovered Explorer item resolution
- [x] Resolve the exact hovered Explorer item rather than the first visible or nearest plausible candidate
- [x] Preserve the macOS rule that three or more visible Markdown files must still resolve the actually hovered item
- [x] Reconstruct or retrieve an absolute filesystem path for the hovered Explorer item
- [x] Validate that the hovered-item path exists and points to a regular file before preview opens
- [ ] Record validation evidence for exact hovered-item resolution on a real Windows 11 machine
- [x] Reject non-Markdown files, directories, and unsupported items with the same semantics as macOS
- [x] Wire the current crate-local Markdown acceptance filter into the real Explorer hovered-item pipeline
- [x] Reject directories with the same semantics as macOS once the real Explorer probe is wired
- [x] Reject missing or stale paths with the same semantics as macOS once the real Explorer probe is wired
- [x] Reject unsupported hovered item kinds with the same semantics as macOS once the real Explorer probe is wired
- [x] Implement Windows multi-monitor coordinate handling with the same placement semantics as macOS
- [x] Enumerate Windows monitor work areas in a way that preserves the current macOS visible-frame semantics
- [x] Convert pointer coordinates into the same desktop-space model used by shared core placement logic
- [x] Prefer the containing monitor and fall back to the nearest monitor only when the pointer is outside every work area
- [ ] Record validation evidence for multi-monitor coordinate handling on a real Windows 11 machine
- [x] Implement preview opening on 1-second hover with the same semantics as macOS
- [x] Wire Windows host signals into the shared 1-second hover debounce lifecycle
- [x] Prevent repeated reopen while the pointer stays stationary over the same Markdown item
- [x] Ensure preview opening is blocked while the foreground surface is not Explorer
- [x] Implement preview replacement on a different hovered `.md` with the same semantics as macOS
- [x] Ensure replacement happens only when the resolved document actually changes
- [x] Ensure ordinary pointer motion does not dismiss the preview if the hovered Markdown target did not change
- [x] Implement the same four width tiers as macOS
- [x] Bind Windows preview sizing to the same 560 / 960 / 1440 / 1920 tier model as macOS
- [x] Implement the same 4:3 placement and “reposition before shrink” policy as macOS
- [x] Apply the same edge inset and pointer offset rules as macOS
- [x] Preserve requested tier size by repositioning before any size reduction
- [x] Reduce size only when the requested 4:3 tier truly cannot fit the current monitor work area
- [x] Implement the same compact hint-chip behavior as macOS
- [x] Keep the Windows preview chrome free of Windows-only helper text that would diverge from macOS
- [x] Implement the same hot interaction-surface behavior as macOS
- [x] Keep the preview keyboard-hot without forcing the user to re-hover inside the preview
- [x] Implement the same `Tab` background toggle behavior as macOS
- [x] Implement the same mouse-wheel and touchpad scrolling behavior as macOS
- [x] Implement the same `Space`, `Shift+Space`, `Page Up`, and `Page Down` paging behavior as macOS
- [x] Implement the same sticky eased paging motion as macOS
- [x] Implement the same inline block editing entry rule as macOS
- [x] Implement the same edit source mapping behavior as macOS
- [x] Implement the same edit save and cancel behavior as macOS
- [x] Implement the same edit-mode lock behavior as macOS
- [x] Implement the same close-on-outside-click behavior as macOS
- [x] Implement the same close-on-app-switch behavior as macOS
- [x] Implement the same close-on-Escape behavior as macOS
- [x] Implement the same Markdown rendering surface as macOS
- [x] Implement the same runtime diagnostics coverage as macOS where host APIs permit
- [x] Emit Windows-side diagnostics for frontmost gating, hovered-item resolution, monitor selection, preview placement, and edit lifecycle
- [x] Validate the full Windows preview loop end-to-end against the macOS feature list
- [ ] Record Windows-specific validation evidence proving one-to-one parity with macOS for each feature above

### Layer 7 — One-To-One Ubuntu 24.04 GNOME Files Parity

- [x] Restrict Linux support target to Ubuntu 24.04 plus GNOME Files / Nautilus only
- [x] Create `fastmd-platform-linux-nautilus` as a buildable crate
- [x] Implement Ubuntu frontmost GNOME Files detection with the same gating semantics as macOS Finder
- [x] Identify the authoritative Ubuntu 24.04 GNOME host API stack for frontmost Nautilus detection
- [x] Resolve the active GNOME Files / Nautilus surface to a stable Nautilus identity instead of a generic active-window check
- [x] Reject non-Nautilus foreground windows with the same strict gating semantics as macOS Finder
- [ ] Validate frontmost Nautilus detection on a real Ubuntu 24.04 Wayland session
- [ ] Validate frontmost Nautilus detection on a real Ubuntu 24.04 X11 session
- [x] Implement Ubuntu hovered-item resolution so the actual hovered `.md` item is resolved rather than a nearby or first visible candidate
- [x] Identify the authoritative Ubuntu 24.04 GNOME host API stack for hovered Nautilus item resolution
- [x] Resolve the exact hovered Nautilus item rather than a nearby candidate or first visible candidate
- [x] Preserve the macOS rule that three or more visible Markdown files must still resolve the actually hovered item
- [x] Reconstruct or retrieve an absolute filesystem path for the hovered Nautilus item
- [x] Validate that the hovered-item path exists and points to a regular file before preview opens
- [ ] Validate exact hovered-item resolution on a real Ubuntu 24.04 Wayland session
- [ ] Validate exact hovered-item resolution on a real Ubuntu 24.04 X11 session
- [x] Reject non-Markdown files, directories, and unsupported items with the same semantics as macOS
- [x] Wire the current adapter-level rejection logic into the real Nautilus hovered-item pipeline
- [x] Confirm directory rejection after live Nautilus host probes are wired
- [x] Confirm missing-path rejection after live Nautilus host probes are wired
- [x] Confirm unsupported-entity rejection after live Nautilus host probes are wired
- [x] Implement Ubuntu multi-monitor coordinate handling with the same placement semantics as macOS
- [x] Enumerate GNOME monitor work areas in a way that preserves the current macOS visible-frame semantics
- [x] Convert pointer coordinates into the same desktop-space model used by shared core placement logic
- [x] Prefer the containing monitor and fall back to the nearest monitor only when the pointer is outside every work area
- [ ] Validate monitor selection and coordinate handling on a real Ubuntu 24.04 Wayland session
- [ ] Validate monitor selection and coordinate handling on a real Ubuntu 24.04 X11 session
- [x] Implement Wayland and X11 behavior handling without changing product semantics
- [x] Implement real Wayland probe plumbing behind the existing semantic guardrail
- [x] Implement real X11 probe plumbing behind the existing semantic guardrail
- [x] Confirm that Wayland/X11 backend differences do not alter user-visible FastMD semantics
- [x] Implement preview opening on 1-second hover with the same semantics as macOS
- [x] Wire Ubuntu host signals into the shared 1-second hover debounce lifecycle
- [x] Prevent repeated reopen while the pointer stays stationary over the same Markdown item
- [x] Ensure preview opening is blocked while the foreground surface is not Nautilus
- [x] Implement preview replacement on a different hovered `.md` with the same semantics as macOS
- [x] Ensure replacement happens only when the resolved document actually changes
- [x] Ensure ordinary pointer motion does not dismiss the preview if the hovered Markdown target did not change
- [x] Implement the same four width tiers as macOS
- [x] Bind Ubuntu preview sizing to the same 560 / 960 / 1440 / 1920 tier model as macOS
- [x] Implement the same 4:3 placement and “reposition before shrink” policy as macOS
- [x] Apply the same edge inset and pointer offset rules as macOS
- [x] Preserve requested tier size by repositioning before any size reduction
- [x] Reduce size only when the requested 4:3 tier truly cannot fit the current monitor work area
- [x] Implement the same compact hint-chip behavior as macOS
- [x] Keep the Ubuntu preview chrome free of Linux-only helper text that would diverge from macOS
- [x] Implement the same hot interaction-surface behavior as macOS
- [x] Keep the preview keyboard-hot without forcing the user to re-hover inside the preview
- [x] Implement the same `Tab` background toggle behavior as macOS
- [x] Implement the same mouse-wheel and touchpad scrolling behavior as macOS
- [x] Implement the same `Space`, `Shift+Space`, `Page Up`, and `Page Down` paging behavior as macOS
- [x] Implement the same sticky eased paging motion as macOS
- [x] Implement the same inline block editing entry rule as macOS
- [x] Implement the same edit source mapping behavior as macOS
- [x] Implement the same edit save and cancel behavior as macOS
- [x] Implement the same edit-mode lock behavior as macOS
- [ ] Implement the same close-on-outside-click behavior as macOS
- [ ] Implement the same close-on-app-switch behavior as macOS
- [x] Implement the same close-on-Escape behavior as macOS
- [x] Implement the same Markdown rendering surface as macOS
- [ ] Implement the same runtime diagnostics coverage as macOS where host APIs permit
- [x] Emit Ubuntu-side diagnostics for frontmost gating, hovered-item resolution, monitor selection, preview placement, and edit lifecycle
- [ ] Validate the full Ubuntu preview loop end-to-end against the macOS feature list on Wayland
- [ ] Validate the full Ubuntu preview loop end-to-end against the macOS feature list on X11
- [ ] Record Ubuntu-specific validation evidence proving one-to-one parity with macOS for each feature above

### Layer 8 — Cross-Platform macOS-Parity Validation Closure

- [ ] Add a root verification flow that runs the macOS Swift checks plus the Stage 2 Rust/Tauri checks
- [ ] Add `cargo check` coverage for the Stage 2 Rust workspace
- [ ] Add `cargo test` coverage for shared contracts, shared core, and render logic
- [ ] Add integration validation for the Tauri desktop shell
- [x] Add validation coverage that explicitly compares Windows behavior against the macOS reference feature list
- [ ] Add validation coverage that explicitly compares Ubuntu behavior against the macOS reference feature list
- [ ] Record validation evidence for macOS Finder, Windows Explorer, and Ubuntu 24.04 GNOME Files
- [ ] Update `README.md` with the Stage 2 workspace structure and cross-platform direction
- [ ] Update `Docs/Support_Matrix.md` with Stage 2 platform capability status as implementation lands
- [ ] Keep the legacy macOS Swift app buildable until shared-core parity is proven
- [ ] Declare Stage 2 complete only when macOS, Windows 11, and Ubuntu 24.04 behave the same at the product-semantic level through the shared contracts and shared core

## Stage 2 Layer Gates

Stage 2 execution must obey these gates:

1. Layer 0 must stay green before any later-layer work is accepted.
2. Layer 1 through Layer 4 must establish the shared contracts, shared core, shared render contract, and shared shell before Windows or Ubuntu can claim parity.
3. Layer 5 must protect the current macOS app from regression throughout the migration.
4. Layer 6 and Layer 7 are successful only when they match the macOS reference feature list one-to-one.
5. No Windows or Ubuntu feature may ship by weakening or removing current macOS behavior.
6. Layer 8 closure work cannot mark the phase complete while any lower-layer checklist item remains open.

## Stage 2 Worker Lane Ownership

If Stage 2 execution is later parallelized, lane ownership should default to exactly these four disjoint slices:

- `worker-1`: `crates/fastmd-contracts`, `crates/fastmd-core`, `crates/fastmd-render`, `crates/fastmd-platform`, and parity-oriented shared tests
- `worker-2`: `apps/desktop-tauri`, `ui`, and shared desktop-shell/frontend integration
- `worker-3`: `crates/fastmd-platform-windows` with explicit Windows-to-macOS parity closure
- `worker-4`: `crates/fastmd-platform-linux-nautilus` with explicit Ubuntu-to-macOS parity closure

MacOS parity work should stay coupled to `worker-1` until the shared contracts and shared core are stable enough to support a cleaner split.

## Stage 2 Parallelism Guardrail

Stage 2 may launch 4 concurrent implementation workers only when all of the following are enforced:

- all workers derive work from this blueprint and no second requirement source exists
- workers run in isolated clones or isolated write scopes
- `worker-1` owns shared contracts/core/render and no other worker edits those files in the same batch
- `worker-2` owns the Tauri shell and shared frontend and no other worker edits those files in the same batch
- `worker-3` owns Windows-specific adapter work and must target macOS feature parity rather than Windows-only invention
- `worker-4` owns Ubuntu-specific adapter work and must target macOS feature parity rather than Linux-only invention
- the main repository is not treated as complete until the parity checklist and macOS regression gates are updated honestly

## Stage 2 Completion Definition

Stage 2 is not complete when folders merely exist.

Stage 2 is complete only when:

1. A shared Rust contract layer exists.
2. A shared Rust preview-state layer exists.
3. A shared Rust rendering contract exists.
4. A Tauri desktop shell exists.
5. The current macOS app behavior is preserved without regression.
6. Windows 11 Explorer support reproduces the macOS feature list one-to-one.
7. Ubuntu 24.04 GNOME Files support reproduces the macOS feature list one-to-one.
8. The three desktop targets behave the same at the product-semantic level even though the host integrations remain platform-specific.
