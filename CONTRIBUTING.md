# Contributing

FastMD is still an early macOS prototype. Small, focused pull requests are easier to review and validate than broad refactors.

## Before You Start

- Open an issue or discussion first for behavior changes, larger refactors, or new feature work.
- Keep changes narrow and explain the user-facing effect clearly.
- Avoid mixing unrelated cleanup with functional changes.

## Local Development

```bash
swift build
swift test
```

For repository-local validation helpers:

```bash
Scripts/run_local_checks.sh
```

For Finder-specific behavior changes, also run the manual smoke flow described in `Docs/Manual_Test_Plan.md`.

## Pull Request Expectations

- Include a short summary of what changed and why.
- Call out macOS version and toolchain version for behavior-sensitive fixes.
- Mention any manual validation you ran, especially Finder hover and preview behavior.
- Update documentation when behavior, setup, or limits change.

## Scope

Please do not commit local automation directories, editor state, logs, or build artifacts. The repository `.gitignore` is set up to keep those out of version control.
