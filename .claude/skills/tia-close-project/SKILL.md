---
name: tia-close-project
description: Close the currently open project in Siemens TIA Portal without saving. Use when the user asks to close the TIA Portal project — e.g. "프로젝트 닫아줘", "티아 프로젝트 닫아줘", "close the TIA project".
---

# Close the open TIA Portal project (no save)

Script is under the project's `tools/` folder (relative to the project root; Claude resolves the absolute path).
Helper: `tools/tia/Close-Project.ps1`

## Procedure
1. Run `tools\tia\Close-Project.ps1`. It activates TIA and sends **Ctrl+W** (Project > Close).
2. If a **"Save changes?"** dialog appears (only when edits were made), click **No** — never auto-save a live company project. In read-only use it closes with no prompt.
3. **Verify**: RESULT says `project closed` (window title has no `.ap20` path; tree shows only "Online access"/"Card Reader").

## Notes
- We never save automated changes to real projects (safety rule). Closing without saving keeps the original untouched.
