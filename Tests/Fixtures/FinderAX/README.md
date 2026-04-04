# Finder Accessibility Fixtures

This directory stores real Finder AX snapshots captured from the local machine.

`test.json` is a real capture from Finder on this machine. These fixtures are intended to show the raw AX lineage plus enough surrounding context to debug why the resolver can or cannot recover a Markdown file name.

Current capture payloads include:

- The hit-tested `lineage`
- The nearest detected row subtree when Finder exposes one
- An `ancestorContext` expansion that mirrors the resolver's broader search
- A small `analysis` block with the first direct-path and Markdown-name candidates found by each strategy

Suggested future naming:

- `finder-list-row-YYYYMMDD-HHMMSS.json`
- `finder-list-row-YYYYMMDD-HHMMSS.txt`
