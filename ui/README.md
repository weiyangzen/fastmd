This directory now contains the shared Stage 2 desktop frontend for FastMD.

Current scope of the shared frontend:

- parity-focused preview shell visuals carried over from the macOS implementation
- compact hint-chip, width tiers, background toggle state, paging motion, and inline block editing UI
- Tauri bridge adapters for bootstrap state, host capabilities, geometry, and close requests
- browser fallback data so the shell can still be developed and tested outside Tauri
