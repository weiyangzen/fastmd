import { WIDTH_TIERS } from "./constants";
import type { BootstrapPayload } from "./types";

export const DEMO_MARKDOWN = `# FastMD Stage 2 Preview Shell

This shared shell is intentionally aimed at **macOS feature parity** instead of a generic desktop wrapper.

## Active Layer 4 behaviors

- Hint chip mirrors the current macOS controls
- Width tiers stay on the same four explicit values
- \`Tab\` flips between pure white and pure black preview backgrounds
- \`Space\`, \`Shift+Space\`, \`Page Up\`, and \`Page Down\` use the same eased paging motion
- Double-clicking a rendered block returns that block to raw Markdown for inline editing

> This shell slice is real scaffolding, not a parity claim.

\`\`\`ts
export const widthTiers = [560, 960, 1440, 1920];
\`\`\`

## Editing note

Edits in this browser fallback stay in memory so the shell can be exercised without a host file attachment.
`;

export const demoBootstrapPayload: BootstrapPayload = {
  shellState: {
    documentTitle: "Stage2_Shell_Demo.md",
    markdown: DEMO_MARKDOWN,
    widthTiers: WIDTH_TIERS,
    selectedWidthTierIndex: 0,
    backgroundMode: "white",
  },
  hostCapabilities: {
    platformId: "shell",
    accessibilityPermission: "unknown",
    frontmostFileManager: "unknown",
    previewWindowPositioning: false,
    globalShortcutRegistered: false,
    closeOnBlurEnabled: false,
    canPersistPreviewEdits: false,
  },
};
