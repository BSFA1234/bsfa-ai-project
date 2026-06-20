# extract_blocks.ps1 -- TIA Openness PLC block extractor (SimaticML XML)
# Policy: AUTO-COMPILE what can be compiled so it becomes extractable; for blocks that
#         still fail, write a human-friendly error report (location + description).
# Verified on this PC: TIA V20, attach to a running instance, Export consistent blocks.
# Read-only on disk/device: never saves the project, never downloads. (Compile changes
# only the in-memory state of the attached GUI instance; close without saving to discard.)
# Skips 05_Safety by default. ASCII-only body (hard-lock B2): Korean is passed as runtime params.
[CmdletBinding()]
param(
  [string]$ProjMatch  = "",                                              # substring of the project path to pick the TIA instance (empty = first visible)
  [string]$GroupPath  = "",                                              # block-group path filter, exact or prefix (empty = all). e.g. 02_<...>/03_<...>
  [string]$NameRegex  = ".*",                                           # block-name regex filter. e.g. ^OP[0-9]+$
  [string]$OutDir     = "C:\Users\user\Desktop\bsfa-extract-test\blocks_out",
  [switch]$IncludeSafety,                                                # if set, also export 05_Safety (read-only). Default: skip Safety entirely.
  [bool]$AutoCompile  = $true                                            # default ON: inconsistent blocks are compiled first; real errors -> _extract_errors.txt
)
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$base   = "C:\Program Files\Siemens\Automation\Portal V20"
$V20    = Join-Path $base "PublicAPI\V20"
$BIN    = Join-Path $base "Bin\PublicAPI"
$EngDll = Join-Path $V20 "Siemens.Engineering.dll"
if (-not (Test-Path $EngDll)) { Write-Error "Openness DLL not found (need TIA V20): $EngDll"; exit 1 }

$cs = @'
using System;
using System.IO;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using Siemens.Engineering;
using Siemens.Engineering.HW;
using Siemens.Engineering.HW.Features;
using Siemens.Engineering.SW;
using Siemens.Engineering.SW.Blocks;
using Siemens.Engineering.Compiler;
public static class Extractor {
    static string[] Dirs;
    static StringBuilder sb, err;
    static int ok, compiled, skip, errored, fail;
    public static void Init(string[] dirs){ Dirs = dirs; AppDomain.CurrentDomain.AssemblyResolve += OnResolve; }
    static Assembly OnResolve(object s, ResolveEventArgs a){
        string n = new AssemblyName(a.Name).Name;
        foreach (Assembly x in AppDomain.CurrentDomain.GetAssemblies()) if (x.GetName().Name == n) return x;
        foreach (string d in Dirs){ string p = Path.Combine(d, n + ".dll"); if (File.Exists(p)) return Assembly.LoadFrom(p); }
        return null;
    }
    static PlcSoftware FindPlc(DeviceItem item){
        var sc = item.GetService<SoftwareContainer>();
        if (sc != null && sc.Software is PlcSoftware) return (PlcSoftware)sc.Software;
        foreach (DeviceItem di in item.DeviceItems){ var r = FindPlc(di); if (r != null) return r; }
        return null;
    }
    static string SafeName(string name){ return Regex.Replace(name, "[\\\\/:*?\"<>|]", "_"); }
    // dump only Error-state messages (location + description) to the error report
    static void DumpErr(CompilerResultMessageComposition msgs, int depth){
        if (msgs == null) return;
        string pad = new string(' ', depth * 2);
        foreach (CompilerResultMessage m in msgs){
            if (m.State.ToString() == "Error" || m.ErrorCount > 0)
                err.AppendLine(pad + "[" + m.State + "] " + m.Path + "  :  " + m.Description);
            DumpErr(m.Messages, depth + 1);
        }
    }
    static void Walk(PlcBlockGroup g, string path, string groupFilter, Regex nameRx, string outDir, bool includeSafety, bool autoCompile){
        bool isSafety = path.IndexOf("Safety", StringComparison.OrdinalIgnoreCase) >= 0;
        if (isSafety && !includeSafety) return;
        bool groupOk = (groupFilter == "") || path == groupFilter || path.StartsWith(groupFilter + "/");
        if (groupOk) {
            foreach (PlcBlock b in g.Blocks){
                if (!nameRx.IsMatch(b.Name)) continue;
                string info = path + "/" + b.Name + "  [" + b.GetType().Name + ", " + b.ProgrammingLanguage + "]";
                if (!b.IsConsistent){
                    if (!autoCompile){ skip++; sb.AppendLine("SKIP  " + info + "  (inconsistent; -AutoCompile:$false)"); continue; }
                    try {
                        ICompilable comp = b.GetService<ICompilable>();
                        CompilerResult cr = comp.Compile();
                        if (b.IsConsistent){
                            compiled++; sb.AppendLine("CMPL  " + info + "  (auto-compiled, warnings=" + cr.WarningCount + ")");
                        } else {
                            errored++; sb.AppendLine("ERR   " + info + "  (compile errors=" + cr.ErrorCount + ") -> _extract_errors.txt");
                            err.AppendLine("==== " + path + "/" + b.Name + "   (errors=" + cr.ErrorCount + ", warnings=" + cr.WarningCount + ") ====");
                            DumpErr(cr.Messages, 1);
                            err.AppendLine("");
                            continue;
                        }
                    } catch (Exception ex){
                        errored++; sb.AppendLine("ERR   " + info + "  (compile threw) -> _extract_errors.txt");
                        err.AppendLine("==== " + path + "/" + b.Name + "   COMPILE EXCEPTION ====");
                        err.AppendLine("  " + ex.Message.Split('\n')[0]);
                        err.AppendLine("");
                        continue;
                    }
                }
                string fn = Path.Combine(outDir, SafeName(b.Name) + ".xml");
                try {
                    if (File.Exists(fn)) File.Delete(fn);
                    b.Export(new FileInfo(fn), ExportOptions.WithDefaults);
                    ok++; sb.AppendLine("OK    " + info + "  -> " + Path.GetFileName(fn) + " (" + Math.Round(new FileInfo(fn).Length/1024.0,1) + " KB)");
                } catch (Exception ex){ fail++; sb.AppendLine("FAIL  " + info + "  : " + ex.Message.Split('\n')[0]); }
            }
        }
        foreach (PlcBlockGroup sub in g.Groups) Walk(sub, path == "" ? sub.Name : path + "/" + sub.Name, groupFilter, nameRx, outDir, includeSafety, autoCompile);
    }
    public static string Run(string projMatch, string groupFilter, string nameRegex, string outDir, bool includeSafety, bool autoCompile){
        sb = new StringBuilder(); err = new StringBuilder(); ok = compiled = skip = errored = fail = 0;
        TiaPortalProcess proc = null;
        foreach (var p in TiaPortal.GetProcesses()){
            string pp = ""; try { pp = p.ProjectPath != null ? p.ProjectPath.FullName : ""; } catch {}
            if (projMatch == "" || pp.IndexOf(projMatch, StringComparison.OrdinalIgnoreCase) >= 0){ proc = p; break; }
        }
        if (proc == null) return "ERROR: no matching running TIA instance (ProjMatch='" + projMatch + "'). Is TIA open with the project?";
        TiaPortal tia = proc.Attach();
        Project prj = null; foreach (Project pr in tia.Projects){ prj = pr; break; }
        if (prj == null) return "ERROR: attached but Projects.Count=0 (project not Openness-visible).";
        sb.AppendLine("PROJECT: " + prj.Name + "  (PID " + proc.Id + ")");
        PlcSoftware plc = null;
        foreach (Device d in prj.Devices){ foreach (DeviceItem di in d.DeviceItems){ var r = FindPlc(di); if (r != null){ plc = r; break; } } if (plc != null) break; }
        if (plc == null) return sb.ToString() + "\nERROR: no PLC software found in project.";
        sb.AppendLine("PLC: " + plc.Name);
        sb.AppendLine("FILTER: group='" + (groupFilter=="" ? "(all)" : groupFilter) + "'  name=/" + nameRegex + "/  safety=" + (includeSafety?"INCLUDE":"skip") + "  autoCompile=" + autoCompile);
        sb.AppendLine("OUTDIR: " + outDir);
        sb.AppendLine("----");
        Directory.CreateDirectory(outDir);
        Walk(plc.BlockGroup, "", groupFilter, new Regex(nameRegex), outDir, includeSafety, autoCompile);
        if (err.Length > 0){
            string ep = Path.Combine(outDir, "_extract_errors.txt");
            File.WriteAllText(ep, "Blocks that could NOT be made consistent (need human fix). Location : description.\r\n\r\n" + err.ToString(), new UTF8Encoding(false));
        }
        sb.AppendLine("----");
        sb.AppendLine("SUMMARY  ok=" + ok + "  auto-compiled=" + compiled + "  skip=" + skip + "  compile-error=" + errored + "  export-fail=" + fail);
        if (errored > 0) sb.AppendLine("NOTE: " + errored + " block(s) have real errors -> see _extract_errors.txt (human fix needed).");
        return sb.ToString();
    }
}
'@

# DLL must be loaded with LoadFrom (Add-Type -Path -> ReflectionTypeLoadException, hard-lock B6).
Add-Type -TypeDefinition $cs -ReferencedAssemblies $EngDll
[Extractor]::Init(@($V20, $BIN))
$result = [Extractor]::Run($ProjMatch, $GroupPath, $NameRegex, $OutDir, [bool]$IncludeSafety, [bool]$AutoCompile)
Write-Output $result

# Verify each produced XML parses (well-formed).
Write-Output "==== well-formed verify ===="
$bad = 0
Get-ChildItem -LiteralPath $OutDir -Filter *.xml -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
    try { [xml]$null = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 }
    catch { $bad++; Write-Output ("BADXML  " + $_.Name + " : " + $_.Exception.Message) }
}
if ($bad -eq 0) { Write-Output "all XML well-formed" } else { Write-Output ("WARNING: " + $bad + " malformed file(s)") }
