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

### Layer 0 — Bootstrap And Repository Boundary

- [x] Add `Docs/Stage2_Blueprint.md`
- [x] Refactor repository layout so Stage 2 directories exist without breaking the current macOS build
- [x] Move the current macOS Swift sources under `apps/macos/Sources/`
- [x] Move the current macOS Swift tests under `apps/macos/Tests/`
- [x] Move the macOS Swift package to `apps/macos/Package.swift`
- [x] Move the checked-in Xcode project to `apps/macos/FastMD.xcodeproj`
- [x] Keep the current Swift package building after the folder refactor
- [x] Keep the checked-in Xcode project generation path working after the folder refactor
- [x] Keep `Tests/Fixtures/` shared at the repository root
- [x] Add repository scaffolding for `apps/desktop-tauri`
- [x] Add repository scaffolding for the future Rust crates
- [x] Reserve `ios/` and `android/` as local future target directories only
- [x] Create an explicit support matrix for macOS Finder, Windows Explorer, and Ubuntu 24.04 GNOME Files inside this blueprint
- [ ] Add root-level ignore rules for future Rust/Tauri build artifacts beyond the current macOS `.build` path
- [ ] Add a root-level workspace README section that explains `apps/macos`, `apps/desktop-tauri`, `crates`, `ui`, `Tests/Fixtures`, `ios`, and `android`

### Layer 1 — Shared Rust Contracts

- [ ] Add a root Cargo workspace that includes `fastmd-contracts`, `fastmd-core`, `fastmd-render`, `fastmd-platform`, `fastmd-platform-macos`, `fastmd-platform-windows`, and `fastmd-platform-linux-nautilus`
- [ ] Create buildable crate manifests for all Stage 2 Rust crates
- [ ] Define `PlatformId`
- [ ] Define `PermissionState`
- [ ] Define `FrontSurface`
- [ ] Define `ScreenPoint`, `ScreenRect`, and monitor metadata contracts
- [ ] Define `HoveredItem`
- [ ] Define `ResolvedDocument`
- [ ] Define `LoadedDocument`
- [ ] Define `HostCapabilities`
- [ ] Define `PreviewWindowRequest`
- [ ] Define `PreviewState` and sub-state DTOs
- [ ] Define shared `AppCommand` messages
- [ ] Define shared `AppEvent` messages
- [ ] Define a stable Rust error envelope for platform adapters and shell integration
- [ ] Add serde-based serialization tests for all shared contracts

### Layer 2 — Shared Core State Machine

- [ ] Implement the preview lifecycle state machine in `fastmd-core`
- [ ] Implement the hover debounce rule in the shared core
- [ ] Implement the preview replacement rule in the shared core
- [ ] Implement the width-tier state in the shared core
- [ ] Implement the background-mode state in the shared core
- [ ] Implement the paging physics contract in the shared core
- [ ] Implement the edit-mode lock contract in the shared core
- [ ] Implement the close policy for outside click, app switch, and Escape in the shared core
- [ ] Implement capability negotiation between shell and host adapters
- [ ] Add unit tests for width-tier transitions
- [ ] Add unit tests for paging behavior
- [ ] Add unit tests for edit-lock behavior
- [ ] Add unit tests for close-policy behavior
- [ ] Add unit tests for replacement behavior across successive hovered files

### Layer 3 — Shared Rendering Contract

- [ ] Define the Stage 2 Markdown rendering contract in `fastmd-render`
- [ ] Define the block-to-source mapping contract in `fastmd-render`
- [ ] Define shared theme variables and width-tier constants in `fastmd-render`
- [ ] Define the compact top-right hint-chip contract in `fastmd-render`
- [ ] Define the shared preview model payload passed into the desktop frontend
- [ ] Add snapshot or fixture tests for rendering-contract DTOs
- [ ] Add tests for block mapping and edit-boundary selection rules

### Layer 4 — Shared Frontend And Tauri Shell

- [ ] Add a real Tauri app manifest under `apps/desktop-tauri`
- [ ] Add a Rust entrypoint for the Tauri shell
- [ ] Add a shared frontend app shell under `ui`
- [ ] Implement the preview shell UI in the shared frontend
- [ ] Implement the compact hint chip in the shared frontend
- [ ] Implement width-tier UI state in the shared frontend
- [ ] Implement background-mode UI state in the shared frontend
- [ ] Implement inline block editing UI in the shared frontend
- [ ] Implement the command/event bridge between Tauri and the Rust core
- [ ] Integrate Tauri window positioning behavior needed for the preview window
- [ ] Integrate Tauri global shortcut support needed by the shared desktop shell
- [ ] Expose host capability state to the shared frontend
- [ ] Add UI tests for the hint chip, width tiers, background mode, and editing states

### Layer 5 — macOS Contract Parity

- [ ] Create `fastmd-platform-macos` as a buildable crate
- [ ] Mirror the Stage 1 interaction semantics into explicit parity tests
- [ ] Implement Rust-side macOS platform traits or bridge stubs that match Finder behavior expectations
- [ ] Expose Finder frontmost detection through the Stage 2 host contracts
- [ ] Expose Finder hovered-item resolution through the Stage 2 host contracts
- [ ] Expose macOS monitor and coordinate conversion through the Stage 2 host contracts
- [ ] Expose macOS permission state through the Stage 2 host contracts
- [ ] Expose document load/save through the Stage 2 host contracts
- [ ] Validate that the shared core preserves current Layer 1 macOS behavior
- [ ] Decide whether macOS continues using the Swift shell during Stage 2 or moves behind the Tauri shell

### Layer 6 — Windows 11 Explorer Support

- [ ] Create `fastmd-platform-windows` as a buildable crate
- [ ] Restrict Windows support target to Windows 11 plus Explorer
- [ ] Implement frontmost Explorer detection
- [ ] Implement hovered Explorer item resolution
- [ ] Implement Windows monitor and coordinate handling
- [ ] Implement Windows document load/save host plumbing
- [ ] Implement Windows permission or capability reporting required by the product
- [ ] Integrate Windows adapter events into the shared core
- [ ] Validate width tiers, paging, editing, and close policy on Windows 11
- [ ] Add Windows-specific fixture or integration evidence for Explorer resolution

### Layer 7 — Ubuntu 24.04 GNOME Files Support

- [ ] Create `fastmd-platform-linux-nautilus` as a buildable crate
- [ ] Restrict Linux support target to Ubuntu 24.04 plus GNOME Files / Nautilus
- [ ] Implement frontmost GNOME Files detection
- [ ] Implement hovered GNOME Files item resolution
- [ ] Implement Ubuntu monitor and coordinate handling
- [ ] Implement Ubuntu document load/save host plumbing
- [ ] Implement Ubuntu capability reporting and unsupported-surface reporting
- [ ] Integrate Ubuntu adapter events into the shared core
- [ ] Document and validate Wayland versus X11 behavior boundaries
- [ ] Validate width tiers, paging, editing, and close policy on Ubuntu 24.04 GNOME Files
- [ ] Add Ubuntu-specific fixture or integration evidence for Nautilus resolution

### Layer 8 — Cross-Platform Validation And Release Closure

- [ ] Add a root verification flow that runs the macOS Swift checks plus the Stage 2 Rust/Tauri checks
- [ ] Add `cargo check` coverage for the Stage 2 Rust workspace
- [ ] Add `cargo test` coverage for shared contracts, shared core, and render logic
- [ ] Add integration validation for the Tauri desktop shell
- [ ] Record validation evidence for macOS Finder, Windows Explorer, and Ubuntu 24.04 GNOME Files
- [ ] Update `README.md` with the Stage 2 workspace structure and cross-platform direction
- [ ] Update `Docs/Support_Matrix.md` with Stage 2 platform capability status as implementation lands
- [ ] Keep the legacy macOS Swift app buildable until shared-core parity is proven
- [ ] Declare Stage 2 complete only when macOS, Windows 11, and Ubuntu 24.04 behave the same at the product-semantic level through the shared contracts and shared core

## Stage 2 Layer Gates

Stage 2 execution must obey these gates:

1. Layer 0 must stay green before any later-layer work is accepted.
2. Layer 1 must be substantially complete before Windows or Ubuntu host adapters claim product support.
3. Layer 2 and Layer 3 must define the shared semantics before platform-specific behavior is accepted as done.
4. Layer 4 must exist before any platform can claim shared-shell integration.
5. Layer 6 and Layer 7 must not invent product semantics that diverge from Layers 1 through 4.
6. Layer 8 closure work cannot mark the phase complete while any lower-layer checklist item remains open.

## Stage 2 Worker Lane Ownership

If Stage 2 execution is later parallelized, lane ownership should default to exactly these four disjoint slices:

- `worker-1`: `crates/fastmd-contracts`, `crates/fastmd-core`, `crates/fastmd-render`, and shared semantic test closure
- `worker-2`: `apps/desktop-tauri`, `ui`, and desktop-shell integration
- `worker-3`: `crates/fastmd-platform-windows`
- `worker-4`: `crates/fastmd-platform-linux-nautilus`

MacOS parity work should stay coupled to `worker-1` until the shared contracts and shared core are stable enough to support a cleaner split.

## Stage 2 Parallelism Guardrail

Stage 2 must not launch 4 concurrent implementation workers until all of the following are true:

- Layer 1 has an actual buildable Rust workspace skeleton
- Layer 1 contract definitions exist
- Layer 2 state-machine entrypoints exist
- Layer 4 shell directory contains a real Tauri app shell rather than placeholder text only

Before those conditions are true, the blueprint is a design-and-bootstrap source, not yet a safe 4-worker execution source.

## Stage 2 Completion Definition

Stage 2 is not complete when folders merely exist.

Stage 2 is complete only when:

1. A shared Rust contract layer exists.
2. A shared Rust preview-state layer exists.
3. A shared Rust rendering contract exists.
4. A Tauri desktop shell exists.
5. macOS behavior is preserved against the shared contracts.
6. Windows 11 Explorer support is implemented against the same contracts.
7. Ubuntu 24.04 GNOME Files support is implemented against the same contracts.
8. The three desktop targets behave the same at the product-semantic level even though the host integrations remain platform-specific.
