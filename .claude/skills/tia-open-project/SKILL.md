---
name: tia-open-project
description: Open a project in Siemens TIA Portal (launch TIA if needed, then open a recent project, handling the missing-products dialog). Use when the user asks to open a TIA Portal project — e.g. "TIA 프로젝트 열어줘", "티아포탈 프로젝트 열어줘", "open the PANELTEST project in TIA".
---

# Open a TIA Portal project

Drives the TIA Portal **desktop GUI** via PowerShell helpers (screen capture + clicks).
All steps are **read-only** — never save / modify / download.

Scripts are under the project's `tools/` folder (paths relative to the project root; Claude resolves the absolute path for this machine). Screen coordinates are centralized in `tools/tia/Coords.ps1` — edit only that file to re-calibrate on a different display.
Helpers: `tools/desktop/Ui.ps1` (capture/click/activate/grid), `tools/tia/Start-Tia.ps1`, `tools/tia/Open-Project.ps1`, `tools/tia/Coords.ps1`

## Procedure
1. **Launch/activate**: run `tools\tia\Start-Tia.ps1 -Grid`. Opens TIA to the Portal "Open existing project" start screen (or activates+maximizes if already running). Wait until the start screen shows.
2. **Pick the project (vision-guided)**: the recent-project list order is NOT fixed, so do NOT trust a fixed row index. Run `Capture-Screen -Grid` (and `Save-Crop ... -Grid` on the list), read which row matches the target project name, and double-click it at `x=800, y=<that row's Y>`. Rows are ~30px apart starting ~y=180.
3. **Missing-products (HSP) dialog**: projects with SCALANCE / other missing packages show an "Open project: optional products are missing" dialog ~15-20s after the double-click. Click its green **Open** at ~(1125, 672).
4. **Wait ~50s** for load. If the Portal "First steps" page appears, click **Project view** at ~(60, 1016). (Opening via the Project menu's recent list, available only once in Project view, jumps straight to Project view.)
5. **Verify**: the project tree shows the PLC (e.g. `A2_CC01_CPU`), not just "Online access"/"Card Reader". The window title shows the `.ap20` path.

## Notes
- Coordinates are for a **maximized 1920x1080** window — re-read with the grid if the layout differs.
- This is GUI automation (fragile). The robust long-term path is **Openness (API)**, currently blocked by the missing STEP 7 license and HSP0398. See `context.md`.
