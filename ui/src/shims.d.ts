import type { DesktopShellDebugApi } from "./types";

declare module "markdown-it-footnote";
declare module "markdown-it-task-lists";

declare global {
  interface Window {
    __FASTMD_DESKTOP__?: DesktopShellDebugApi;
  }
}

declare module "katex/contrib/auto-render" {
  interface Delimiter {
    left: string;
    right: string;
    display: boolean;
  }

  interface RenderMathOptions {
    delimiters?: Delimiter[];
    throwOnError?: boolean;
    ignoredTags?: string[];
  }

  const renderMathInElement: (element: HTMLElement, options?: RenderMathOptions) => void;
  export default renderMathInElement;
}

export {};
