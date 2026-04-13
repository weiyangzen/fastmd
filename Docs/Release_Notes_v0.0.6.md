# FastMD macOS Native v0.0.6

This release ships the current native macOS app as `v0.0.6`.

The headline change is a major rendering-performance upgrade for large Markdown previews.

## Highlights

- Preview loading now keeps a warmed web shell alive and updates document payloads in place instead of rebuilding a fresh full HTML document for every preview change.
- Rendered preview content now uses an in-memory cache keyed by file fingerprint and background mode, which cuts repeated render cost when reopening or revisiting the same Markdown file.
- Large Markdown documents now switch into adaptive render modes. Expensive enhancement passes are deferred or gated instead of running on the hottest path every time.
- Syntax highlighting now uses lazy, viewport-driven activation with small eager budgets, which reduces initial render pressure on long code-heavy documents.
- Math and Mermaid enhancement work now runs after paint, and very large documents can keep those heavy passes paused until explicitly requested.
- Paging, scrolling, and width transitions now mark performance-critical interaction windows so the preview chrome avoids extra visual effects during fast navigation.
- The native preview bridge now reports render, cache-hit, code-highlight, page-transition, and width-transition timing metrics back to the host for runtime diagnostics.

## User-facing effect

- Faster first useful paint for heavy Markdown files.
- Smoother width-tier changes and preview paging.
- Less jank while scrolling code-heavy or diagram-heavy documents.
- Better repeat-open performance when moving across recently previewed files.
