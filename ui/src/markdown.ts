import MarkdownIt from "markdown-it";
import markdownItFootnote from "markdown-it-footnote";
import markdownItTaskLists from "markdown-it-task-lists";
import hljs from "highlight.js";
import mermaid from "mermaid";
import renderMathInElement from "katex/contrib/auto-render";

import type { BackgroundMode } from "./types";

const md = createMarkdownIt();

function createMarkdownIt() {
  const instance = new MarkdownIt({
    html: true,
    linkify: true,
    typographer: true,
    highlight(source, language) {
      if (language && hljs.getLanguage(language)) {
        try {
          return hljs.highlight(source, { language }).value;
        } catch (_) {
          // Fall through to auto highlighting.
        }
      }

      try {
        return hljs.highlightAuto(source).value;
      } catch (_) {
        return instance.utils.escapeHtml(source);
      }
    },
  });

  instance.use(markdownItFootnote);
  instance.use(markdownItTaskLists, {
    enabled: true,
    label: true,
    labelAfter: true,
  });

  const defaultFenceRule = instance.renderer.rules.fence
    ? instance.renderer.rules.fence.bind(instance.renderer)
    : null;
  const defaultCodeBlockRule = instance.renderer.rules.code_block
    ? instance.renderer.rules.code_block.bind(instance.renderer)
    : null;
  const defaultHtmlBlockRule = instance.renderer.rules.html_block
    ? instance.renderer.rules.html_block.bind(instance.renderer)
    : null;
  const defaultHrRule = instance.renderer.rules.hr
    ? instance.renderer.rules.hr.bind(instance.renderer)
    : null;

  annotateTopLevelBlocks(instance);
  wrapSelfClosingBlocks(instance, "fence", (tokens, index, options, env, self) => {
    const token = tokens[index];
    const info = (token.info || "").trim().split(/\s+/)[0].toLowerCase();

    if (info === "mermaid") {
      return `<div class="mermaid">${instance.utils.escapeHtml(token.content)}</div>`;
    }

    if (defaultFenceRule) {
      return defaultFenceRule(tokens, index, options, env, self);
    }

    return `<pre><code>${instance.utils.escapeHtml(token.content)}</code></pre>`;
  });
  wrapSelfClosingBlocks(instance, "code_block", (tokens, index, options, env, self) => {
    if (defaultCodeBlockRule) {
      return defaultCodeBlockRule(tokens, index, options, env, self);
    }

    const token = tokens[index];
    return `<pre><code>${instance.utils.escapeHtml(token.content)}</code></pre>`;
  });
  wrapSelfClosingBlocks(instance, "html_block", (tokens, index, options, env, self) => {
    if (defaultHtmlBlockRule) {
      return defaultHtmlBlockRule(tokens, index, options, env, self);
    }

    return tokens[index].content;
  });
  wrapSelfClosingBlocks(instance, "hr", (tokens, index, options, env, self) => {
    if (defaultHrRule) {
      return defaultHrRule(tokens, index, options, env, self);
    }

    return "<hr>";
  });

  return instance;
}

function annotateTopLevelBlocks(instance: MarkdownIt) {
  const defaultRenderToken = instance.renderer.renderToken.bind(instance.renderer);
  const openTypes = new Set([
    "heading_open",
    "paragraph_open",
    "blockquote_open",
    "bullet_list_open",
    "ordered_list_open",
    "table_open",
  ]);

  instance.renderer.renderToken = function renderToken(tokens, index, options) {
    const token = tokens[index] as any;
    const blockMeta = token.meta?.fastmdBlock;
    const html = defaultRenderToken(tokens, index, options);

    if (token.level === 0 && token.nesting === 1 && blockMeta && openTypes.has(token.type)) {
      const attrs = [
        'class="md-block"',
        `data-block-id="${blockMeta.blockId}"`,
        `data-start-line="${blockMeta.startLine}"`,
        `data-end-line="${blockMeta.endLine}"`,
      ].join(" ");
      return `<section ${attrs}>${html}`;
    }

    if (
      token.level === 0 &&
      token.nesting === -1 &&
      blockMeta &&
      openTypes.has(token.type.replace("_close", "_open"))
    ) {
      return `${html}</section>`;
    }

    return html;
  };
}

function wrapSelfClosingBlocks(
  instance: MarkdownIt,
  ruleName: string,
  renderer: (tokens: any[], index: number, options: any, env: any, self: any) => string,
) {
  instance.renderer.rules[ruleName] = function renderRule(tokens, index, options, env, self) {
    const token = tokens[index] as any;
    const blockMeta = token.meta?.fastmdBlock;
    const innerHtml = renderer(tokens, index, options, env, self);

    if (!blockMeta) {
      return innerHtml;
    }

    return `<section class="md-block" data-block-id="${blockMeta.blockId}" data-start-line="${blockMeta.startLine}" data-end-line="${blockMeta.endLine}">${innerHtml}</section>`;
  };
}

function assignBlockMetadata(tokens: any[]) {
  const stack: Array<{ blockId: number; startLine: number; endLine: number }> = [];
  let nextBlockId = 0;

  for (const token of tokens) {
    token.meta = token.meta || {};

    if (token.level === 0 && token.block && token.nesting === 1 && Array.isArray(token.map)) {
      const blockMeta = {
        blockId: nextBlockId++,
        startLine: token.map[0],
        endLine: token.map[1],
      };
      token.meta.fastmdBlock = blockMeta;
      stack.push(blockMeta);
      continue;
    }

    if (token.level === 0 && token.block && token.nesting === -1 && stack.length > 0) {
      token.meta.fastmdBlock = stack.pop();
      continue;
    }

    if (token.level === 0 && token.block && token.nesting === 0 && Array.isArray(token.map)) {
      token.meta.fastmdBlock = {
        blockId: nextBlockId++,
        startLine: token.map[0],
        endLine: token.map[1],
      };
    }
  }
}

export function escapeHtml(value: string): string {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

export function sourceLines(markdown: string): string[] {
  return String(markdown).split("\n");
}

export function blockSource(markdown: string, startLine: number, endLine: number): string {
  return sourceLines(markdown).slice(startLine, endLine).join("\n");
}

export async function renderMarkdownDocument(
  root: HTMLElement,
  markdown: string,
  backgroundMode: BackgroundMode,
): Promise<void> {
  try {
    const env = {};
    const tokens = md.parse(markdown, env);
    assignBlockMetadata(tokens as any[]);
    root.innerHTML = md.renderer.render(tokens, md.options, env);
  } catch (error) {
    root.innerHTML = `<div class="fallback md-block"><pre>${escapeHtml(markdown)}</pre></div>`;
    console.warn("FastMD shared renderer fallback engaged.", error);
    return;
  }

  try {
    renderMathInElement(root, {
      delimiters: [
        { left: "$$", right: "$$", display: true },
        { left: "\\[", right: "\\]", display: true },
        { left: "$", right: "$", display: false },
        { left: "\\(", right: "\\)", display: false },
      ],
      throwOnError: false,
      ignoredTags: ["script", "noscript", "style", "textarea", "pre", "code"],
    });
  } catch (error) {
    console.warn("FastMD shared renderer skipped KaTeX enhancement.", error);
  }

  try {
    mermaid.initialize({
      startOnLoad: false,
      securityLevel: "loose",
      theme: backgroundMode === "black" ? "dark" : "default",
    });
    await mermaid.run({
      querySelector: ".mermaid",
    });
  } catch (error) {
    console.warn("FastMD shared renderer skipped Mermaid enhancement.", error);
  }
}
