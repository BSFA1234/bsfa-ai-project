---
name: tia-export-tags
description: Export a PLC tag table from Siemens TIA Portal to an XML file. Use when the user asks to export or extract TIA Portal PLC tags — e.g. "태그 내보내줘", "태그 테이블 추출해줘", "export the PLC tag table to XML".
---

# Export a TIA Portal PLC tag table to XML

**Read-only.** Produces the canonical tag-table XML (one `<Tag ...>name</Tag>` per row inside `<Tagtable>`).

Scripts are under the project's `tools/` folder (relative to the project root; Claude resolves the absolute path). Screen coordinates are centralized in `tools/tia/Coords.ps1`.
Helpers: `tools/desktop/Ui.ps1`, `tools/tia/Export-TagTable.ps1`, `tools/tia/Coords.ps1`

## Procedure
1. **Ensure a project is open** in Project view. If not, use the **tia-open-project** skill first.
2. **Open a tag table (vision-guided)**: in the project tree, expand the PLC (click its ▶ ~ (49,239)), expand **PLC tags** (~ (69,391)), then double-click a tag table — e.g. "Default tag table" ~ (160,448). Re-read positions with `Save-Crop -Grid`; tree positions depend on expansion/scroll state.
3. **Export**: run `tools\tia\Export-TagTable.ps1 -OutPath "<full path>.xml"`. It clicks the Export icon (352,135), pastes the path (clipboard, Korean-safe), clicks OK (1054,623), and dismisses the success dialog (1085,562), then prints the file size.
4. **Verify**: the printed `RESULT: OK | ... (NNN bytes)` shows a non-zero size. (The file is only flushed to disk after the success dialog closes.)

## Output format (verified, TIA Portal V20)
```xml
<?xml version='1.0' encoding='utf-8'?>
<Tagtable name='Default tag table'>
  <Tag type='DInt' hmiVisible='True' hmiWriteable='True' hmiAccessible='True' retain='False' remark='' addr='%MD1000'>Zero</Tag>
</Tagtable>
```
One table row = one `<Tag>`; name is the element text, the rest are attributes (type/addr/retain/remark/hmi*). Reference sample: `tia-projects\sample_tags.xml`.

## Notes
- Coordinates are for a **maximized 1920x1080** window.
- Tree navigation (opening the right table) is vision-guided; the export-dialog steps are fully scripted.
