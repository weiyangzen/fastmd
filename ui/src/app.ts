import {
  adjustWidthTier,
  bootstrapShell,
  listenToCloseRequests,
  listenToHostCapabilities,
  listenToShellState,
  replacePreviewMarkdown,
  requestPreviewClose,
  setEditingState,
  toggleBackgroundMode,
} from "./bridge";
import { WIDTH_TIERS } from "./constants";
import { demoBootstrapPayload } from "./fixtures";
import { blockSource, escapeHtml, renderMarkdownDocument, sourceLines } from "./markdown";
import type { BootstrapPayload, HostCapabilities, ShellState } from "./types";

const PAGE_HEIGHT_FACTOR = 0.92;
const OVERSHOOT_DISTANCE_LIMIT = 34;
const EDIT_LOCK_MESSAGE = "Edit mode is locked until you save or cancel.";
const MEMORY_SAVE_MESSAGE =
  "This shell scaffold keeps inline block saves in memory until a real hovered source file is attached.";

export class PreviewShellApp {
  private container: HTMLElement;
  private shellState: ShellState;
  private hostCapabilities: HostCapabilities;
  private renderRoot!: HTMLElement;
  private documentTitleNode!: HTMLElement;
  private widthLabelNode!: HTMLElement;
  private statusBannerNode!: HTMLElement;
  private capabilitySummaryNode!: HTMLElement;
  private shellNode!: HTMLElement;
  private editing = false;
  private saving = false;
  private currentEdit: { startLine: number; endLine: number } | null = null;
  private pendingMarkdown: string | null = null;
  private transientStatus: string | null = null;
  private activeScrollFrame = 0;
  private unlistenFns: Array<() => void> = [];
  private readonly onDoubleClick = (event: MouseEvent) => {
    const target = event.target;
    if (!(target instanceof Element)) {
      return;
    }

    const blockNode = target.closest(".md-block");
    if (!(blockNode instanceof HTMLElement) || this.editing || this.saving) {
      return;
    }

    void this.enterEdit(blockNode);
  };
  private readonly onKeyDown = (event: KeyboardEvent) => {
    if (this.editing || this.saving) {
      return;
    }

    if (event.key === "ArrowLeft") {
      event.preventDefault();
      void this.handleWidthDelta(-1);
      return;
    }

    if (event.key === "ArrowRight") {
      event.preventDefault();
      void this.handleWidthDelta(1);
      return;
    }

    if (event.key === "Tab") {
      event.preventDefault();
      void this.handleBackgroundToggle();
      return;
    }

    if (event.key === "Escape") {
      event.preventDefault();
      void requestPreviewClose("escape");
      return;
    }

    if (event.key === "PageUp") {
      event.preventDefault();
      this.pageBy(-1);
      return;
    }

    if (event.key === "PageDown") {
      event.preventDefault();
      this.pageBy(1);
      return;
    }

    if (event.code === "Space") {
      event.preventDefault();
      this.pageBy(event.shiftKey ? -1 : 1);
      return;
    }

    if (event.key === "ArrowUp") {
      event.preventDefault();
      this.scrollByDelta(-84);
      return;
    }

    if (event.key === "ArrowDown") {
      event.preventDefault();
      this.scrollByDelta(84);
    }
  };

  constructor(container: HTMLElement, bootstrapPayload: BootstrapPayload = demoBootstrapPayload) {
    this.container = container;
    this.shellState = { ...bootstrapPayload.shellState };
    this.hostCapabilities = { ...bootstrapPayload.hostCapabilities };
    this.container.innerHTML = this.template();
    this.captureDom();
    this.installEventHandlers();
    void this.render(false);
  }

  async connect(): Promise<void> {
    const bootstrapPayload = await bootstrapShell();
    if (bootstrapPayload) {
      await this.applyBootstrapPayload(bootstrapPayload, false);
    }

    this.unlistenFns.push(await listenToShellState((payload) => void this.applyShellState(payload, true)));
    this.unlistenFns.push(
      await listenToHostCapabilities((payload) => {
        this.hostCapabilities = payload;
        this.syncCapabilitySummary();
        this.syncStatus();
      }),
    );
    this.unlistenFns.push(
      await listenToCloseRequests((payload) => {
        this.transientStatus = `Preview close requested: ${payload.reason}.`;
        this.syncStatus();
      }),
    );
  }

  destroy(): void {
    this.renderRoot.removeEventListener("dblclick", this.onDoubleClick);
    window.removeEventListener("keydown", this.onKeyDown);

    for (const unlisten of this.unlistenFns.splice(0)) {
      unlisten();
    }

    if (this.activeScrollFrame) {
      cancelAnimationFrame(this.activeScrollFrame);
      this.activeScrollFrame = 0;
    }
  }

  private template(): string {
    return `
      <div class="shell">
        <header class="toolbar">
          <div class="toolbar-title">
            <span class="eyebrow">FastMD Preview</span>
            <strong data-role="doc-title"></strong>
            <span class="toolbar-caption" data-role="capability-summary"></span>
          </div>
          <div class="toolbar-actions" aria-label="Preview controls">
            <span class="hint-chip">
              <span data-role="width-label" class="hint-item hint-item-width">← 1/4 →</span>
              <span class="hint-separator" aria-hidden="true"></span>
              <span class="hint-item">
                <span class="hint-icon hint-icon-theme" aria-hidden="true"></span>
                <span class="hint-text">Tab</span>
              </span>
              <span class="hint-separator" aria-hidden="true"></span>
              <span class="hint-item">
                <span class="hint-icon hint-icon-page" aria-hidden="true"></span>
                <span class="hint-text">(⇧+) Space</span>
              </span>
            </span>
          </div>
        </header>
        <div class="status-banner" data-role="status-banner" hidden></div>
        <main class="render-root" data-role="render-root"></main>
      </div>
    `;
  }

  private captureDom(): void {
    this.shellNode = this.container.querySelector(".shell") as HTMLElement;
    this.renderRoot = this.container.querySelector('[data-role="render-root"]') as HTMLElement;
    this.documentTitleNode = this.container.querySelector('[data-role="doc-title"]') as HTMLElement;
    this.widthLabelNode = this.container.querySelector('[data-role="width-label"]') as HTMLElement;
    this.statusBannerNode = this.container.querySelector('[data-role="status-banner"]') as HTMLElement;
    this.capabilitySummaryNode = this.container.querySelector(
      '[data-role="capability-summary"]',
    ) as HTMLElement;
  }

  private installEventHandlers(): void {
    this.renderRoot.addEventListener("dblclick", this.onDoubleClick);
    window.addEventListener("keydown", this.onKeyDown);
  }

  private async applyBootstrapPayload(
    bootstrapPayload: BootstrapPayload,
    pulseWidth: boolean,
  ): Promise<void> {
    this.hostCapabilities = bootstrapPayload.hostCapabilities;
    await this.applyShellState(bootstrapPayload.shellState, pulseWidth);
  }

  private async applyShellState(nextState: ShellState, pulseWidth: boolean): Promise<void> {
    const previousWidthTier = this.shellState.selectedWidthTierIndex;
    this.shellState = {
      ...nextState,
      widthTiers: Array.isArray(nextState.widthTiers) && nextState.widthTiers.length > 0
        ? nextState.widthTiers
        : WIDTH_TIERS,
    };

    await this.render(pulseWidth && previousWidthTier !== this.shellState.selectedWidthTierIndex);
  }

  private async render(pulseWidth: boolean): Promise<void> {
    this.documentTitleNode.textContent = this.shellState.documentTitle;
    this.syncCapabilitySummary();
    this.syncWidthChrome();
    this.applyBackgroundMode();
    this.syncStatus();
    if (pulseWidth) {
      this.pulseWidthTransition();
    }
    await renderMarkdownDocument(
      this.renderRoot,
      this.shellState.markdown,
      this.shellState.backgroundMode,
    );
  }

  private syncCapabilitySummary(): void {
    const platform =
      this.hostCapabilities.platformId === "shell"
        ? "browser shell fallback"
        : `${this.hostCapabilities.platformId} shell bridge`;
    const shortcut = this.hostCapabilities.globalShortcutRegistered
      ? "global re-open shortcut wired"
      : "global shortcut pending";
    this.capabilitySummaryNode.textContent = `${platform} · ${shortcut}`;
  }

  private syncWidthChrome(): void {
    const clampedIndex = Math.max(
      0,
      Math.min(
        this.shellState.selectedWidthTierIndex,
        this.shellState.widthTiers.length - 1,
      ),
    );
    this.shellState.selectedWidthTierIndex = clampedIndex;
    const width = this.shellState.widthTiers[clampedIndex] || 0;
    const label = `← ${clampedIndex + 1}/${this.shellState.widthTiers.length} →`;
    this.widthLabelNode.textContent = label;
    this.widthLabelNode.title = `${clampedIndex + 1}/${this.shellState.widthTiers.length} · ${width}px`;
    this.widthLabelNode.setAttribute(
      "aria-label",
      `Width tier ${clampedIndex + 1} of ${this.shellState.widthTiers.length}, target width ${width}px`,
    );
  }

  private applyBackgroundMode(): void {
    document.body.dataset.backgroundMode = this.shellState.backgroundMode === "black" ? "black" : "white";
  }

  private syncStatus(): void {
    let message = this.transientStatus;

    if (!message && this.saving) {
      message = "Saving Markdown block back through the preview shell…";
    }

    if (!message && this.editing) {
      message = EDIT_LOCK_MESSAGE;
    }

    if (!message && !this.hostCapabilities.canPersistPreviewEdits) {
      message = MEMORY_SAVE_MESSAGE;
    }

    if (!message) {
      this.statusBannerNode.hidden = true;
      this.statusBannerNode.textContent = "";
      return;
    }

    this.statusBannerNode.hidden = false;
    this.statusBannerNode.textContent = message;
  }

  private pulseWidthTransition(): void {
    this.shellNode.classList.remove("is-width-transition");
    requestAnimationFrame(() => {
      this.shellNode.classList.add("is-width-transition");
      window.setTimeout(() => {
        this.shellNode.classList.remove("is-width-transition");
      }, 380);
    });
  }

  private async handleWidthDelta(delta: number): Promise<void> {
    if (this.editing || this.saving) {
      return;
    }

    const remoteState = await adjustWidthTier(delta);
    if (remoteState) {
      await this.applyShellState(remoteState, true);
      return;
    }

    const nextIndex = Math.max(
      0,
      Math.min(
        this.shellState.selectedWidthTierIndex + delta,
        this.shellState.widthTiers.length - 1,
      ),
    );
    this.shellState = {
      ...this.shellState,
      selectedWidthTierIndex: nextIndex,
    };
    await this.render(true);
  }

  private async handleBackgroundToggle(): Promise<void> {
    if (this.editing || this.saving) {
      return;
    }

    const remoteState = await toggleBackgroundMode();
    if (remoteState) {
      await this.applyShellState(remoteState, false);
      return;
    }

    this.shellState = {
      ...this.shellState,
      backgroundMode: this.shellState.backgroundMode === "black" ? "white" : "black",
    };
    await this.render(false);
  }

  private cancelScrollAnimation(): void {
    if (this.activeScrollFrame) {
      cancelAnimationFrame(this.activeScrollFrame);
      this.activeScrollFrame = 0;
    }
  }

  private currentScrollTop(): number {
    return window.scrollY || document.documentElement.scrollTop || 0;
  }

  private maxScrollTop(): number {
    return Math.max(document.documentElement.scrollHeight - window.innerHeight, 0);
  }

  private setScrollTop(value: number): void {
    window.scrollTo({ top: value, behavior: "auto" });
  }

  private clamp(value: number, min: number, max: number): number {
    return Math.min(max, Math.max(min, value));
  }

  private easeOutQuint(value: number): number {
    return 1 - Math.pow(1 - value, 5);
  }

  private easeOutCubic(value: number): number {
    return 1 - Math.pow(1 - value, 3);
  }

  private animateScrollSegment(
    from: number,
    to: number,
    duration: number,
    easing: (value: number) => number,
    onDone: () => void,
  ): void {
    const startedAt = performance.now();
    const frame = (now: number) => {
      const progress = this.clamp((now - startedAt) / duration, 0, 1);
      const value = from + (to - from) * easing(progress);
      this.setScrollTop(value);

      if (progress < 1) {
        this.activeScrollFrame = requestAnimationFrame(frame);
        return;
      }

      this.activeScrollFrame = 0;
      onDone();
    };

    this.activeScrollFrame = requestAnimationFrame(frame);
  }

  private scrollByDelta(delta: number): void {
    this.cancelScrollAnimation();
    this.setScrollTop(this.clamp(this.currentScrollTop() + delta, 0, this.maxScrollTop()));
  }

  private pageBy(pages: number): void {
    this.cancelScrollAnimation();

    const start = this.currentScrollTop();
    const delta = window.innerHeight * PAGE_HEIGHT_FACTOR * pages;
    const target = this.clamp(start + delta, 0, this.maxScrollTop());
    const distance = target - start;

    if (Math.abs(distance) < 1) {
      return;
    }

    const overshootMagnitude = Math.min(
      OVERSHOOT_DISTANCE_LIMIT,
      Math.abs(distance) * 0.06,
    );
    let overshootTarget = this.clamp(
      target + Math.sign(distance) * overshootMagnitude,
      0,
      this.maxScrollTop(),
    );

    if (
      Math.abs(overshootTarget - target) < 2 ||
      target <= 0 ||
      target >= this.maxScrollTop()
    ) {
      overshootTarget = target;
    }

    this.animateScrollSegment(start, overshootTarget, 520, this.easeOutQuint.bind(this), () => {
      if (overshootTarget === target) {
        this.setScrollTop(target);
        return;
      }

      this.animateScrollSegment(
        overshootTarget,
        target,
        180,
        this.easeOutCubic.bind(this),
        () => this.setScrollTop(target),
      );
    });
  }

  private async enterEdit(blockNode: HTMLElement): Promise<void> {
    const startLine = Number.parseInt(blockNode.dataset.startLine || "", 10);
    const endLine = Number.parseInt(blockNode.dataset.endLine || "", 10);

    if (!Number.isFinite(startLine) || !Number.isFinite(endLine) || endLine <= startLine) {
      return;
    }

    this.editing = true;
    this.currentEdit = { startLine, endLine };
    this.transientStatus = null;
    document.body.classList.add("is-editing");
    blockNode.classList.add("is-editing");
    await setEditingState(true);
    this.syncStatus();

    const originalSource = blockSource(this.shellState.markdown, startLine, endLine);
    const blockHeight = Math.ceil(blockNode.getBoundingClientRect().height);

    blockNode.innerHTML = `
      <div class="inline-editor">
        <div class="inline-editor-meta">
          <span>Editing source lines ${startLine + 1}-${endLine}</span>
          <span>Double-click returned this rendered block to raw Markdown.</span>
        </div>
        <textarea id="inline-editor-textarea">${escapeHtml(originalSource)}</textarea>
        <div class="inline-editor-actions">
          <button type="button" id="inline-editor-cancel">Cancel</button>
          <button type="button" class="primary" id="inline-editor-save">Save</button>
        </div>
      </div>
    `;

    const textarea = blockNode.querySelector("#inline-editor-textarea") as HTMLTextAreaElement;
    const saveButton = blockNode.querySelector("#inline-editor-save") as HTMLButtonElement;
    const cancelButton = blockNode.querySelector("#inline-editor-cancel") as HTMLButtonElement;

    cancelButton.addEventListener("click", () => void this.cancelEdit());
    saveButton.addEventListener("click", () => void this.saveEdit());
    textarea.addEventListener("keydown", (event) => {
      if (event.key === "Escape") {
        event.preventDefault();
        void this.cancelEdit();
        return;
      }

      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "s") {
        event.preventDefault();
        void this.saveEdit();
      }
    });

    requestAnimationFrame(() => {
      textarea.style.height = `${Math.max(48, blockHeight)}px`;
      textarea.focus();
      textarea.selectionStart = textarea.value.length;
      textarea.selectionEnd = textarea.value.length;
    });
  }

  private async cancelEdit(): Promise<void> {
    if (!this.editing || this.saving) {
      return;
    }

    this.editing = false;
    this.currentEdit = null;
    this.pendingMarkdown = null;
    this.transientStatus = null;
    document.body.classList.remove("is-editing");
    await setEditingState(false);
    await this.render(false);
  }

  private async saveEdit(): Promise<void> {
    if (!this.currentEdit || this.saving) {
      return;
    }

    const textarea = document.getElementById("inline-editor-textarea");
    if (!(textarea instanceof HTMLTextAreaElement)) {
      return;
    }

    const replacementSource = textarea.value.replaceAll("\r\n", "\n");
    const lines = sourceLines(this.shellState.markdown);
    const replacementLines = replacementSource.split("\n");
    const { startLine, endLine } = this.currentEdit;
    const newLines = lines
      .slice(0, startLine)
      .concat(replacementLines)
      .concat(lines.slice(endLine));

    this.pendingMarkdown = newLines.join("\n");
    this.saving = true;
    this.transientStatus = null;
    this.syncStatus();

    try {
      const remoteState = await replacePreviewMarkdown(this.pendingMarkdown);
      this.shellState = remoteState || {
        ...this.shellState,
        markdown: this.pendingMarkdown,
      };
      this.editing = false;
      this.saving = false;
      this.currentEdit = null;
      this.pendingMarkdown = null;
      document.body.classList.remove("is-editing");
      await setEditingState(false);
      await this.render(false);
    } catch (error) {
      this.saving = false;
      this.transientStatus =
        error instanceof Error ? error.message : "Save failed inside the preview shell.";
      this.syncStatus();
    }
  }
}

export function mountPreviewShell(
  container: HTMLElement,
  bootstrapPayload: BootstrapPayload = demoBootstrapPayload,
): PreviewShellApp {
  return new PreviewShellApp(container, bootstrapPayload);
}
