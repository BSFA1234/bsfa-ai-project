# extract_blocks.ps1 -- TIA Openness PLC block extractor (SimaticML XML)
# Verified on this PC: TIA V20, attach to a running instance, Export consistent blocks.
# Read-only. Does NOT save/download/modify the project. Skips 05_Safety by default.
# ASCII-only body (hard-lock B2): Korean is passed in as runtime parameters, never literal in this file.
[CmdletBinding()]
param(
  [string]$ProjMatch  = "",                                              # substring of the project path to pick the TIA instance (empty = first visible)
  [string]$GroupPath  = "",                                              # block-group path filter, exact or prefix (empty = all). e.g. 01_<...>/01_<...>
  [string]$NameRegex  = ".*",                                           # block-name regex filter. e.g. ^OP[0-9]+$
  [string]$OutDir     = "C:\Users\user\Desktop\bsfa-extract-test\blocks_out",
  [switch]$IncludeSafety                                                 # if set, also export 05_Safety (read-only). Default: skip Safety entirely.
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
public static class Extractor {
    static string[] Dirs;
    static StringBuilder sb;
    static int ok, skip, fail;
    // Register the assembly resolver INSIDE C# (PowerShell scriptblock resolver -> StackOverflow).
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
    // Keep readable names (Korean OK on this FS); only replace characters illegal in a Windows filename.
    static string SafeName(string name){ return Regex.Replace(name, "[\\\\/:*?\"<>|]", "_"); }
    static void Walk(PlcBlockGroup g, string path, string groupFilter, Regex nameRx, string outDir, bool includeSafety){
        bool isSafety = path.IndexOf("Safety", StringComparison.OrdinalIgnoreCase) >= 0;
        if (isSafety && !includeSafety) return;  // skip the whole Safety subtree
        bool groupOk = (groupFilter == "") || path == groupFilter || path.StartsWith(groupFilter + "/");
        if (groupOk) {
            foreach (PlcBlock b in g.Blocks){
                if (!nameRx.IsMatch(b.Name)) continue;
                string info = path + "/" + b.Name + "  [" + b.GetType().Name + ", " + b.ProgrammingLanguage + "]";
                if (!b.IsConsistent){ skip++; sb.AppendLine("SKIP  " + info + "  (inconsistent -> human must compile first)"); continue; }
                string fn = Path.Combine(outDir, SafeName(b.Name) + ".xml");
                try {
                    if (File.Exists(fn)) File.Delete(fn);
                    b.Export(new FileInfo(fn), ExportOptions.WithDefaults);
                    ok++; sb.AppendLine("OK    " + info + "  -> " + Path.GetFileName(fn) + " (" + Math.Round(new FileInfo(fn).Length/1024.0,1) + " KB)");
                } catch (Exception ex){ fail++; sb.AppendLine("FAIL  " + info + "  : " + ex.Message); }
            }
        }
        foreach (PlcBlockGroup sub in g.Groups) Walk(sub, path == "" ? sub.Name : path + "/" + sub.Name, groupFilter, nameRx, outDir, includeSafety);
    }
    public static string Run(string projMatch, string groupFilter, string nameRegex, string outDir, bool includeSafety){
        sb = new StringBuilder(); ok = 0; skip = 0; fail = 0;
        TiaPortalProcess proc = null;
        foreach (var p in TiaPortal.GetProcesses()){
            string pp = ""; try { pp = p.ProjectPath != null ? p.ProjectPath.FullName : ""; } catch {}
            if (projMatch == "" || pp.IndexOf(projMatch, StringComparison.OrdinalIgnoreCase) >= 0){ proc = p; break; }
        }
        if (proc == null) return "ERROR: no matching running TIA instance (ProjMatch='" + projMatch + "'). Is TIA open with the project?";
        TiaPortal tia = proc.Attach();   // read-only attach; does not close the GUI
        Project prj = null; foreach (Project pr in tia.Projects){ prj = pr; break; }
        if (prj == null) return "ERROR: attached but Projects.Count=0 (project not Openness-visible).";
        sb.AppendLine("PROJECT: " + prj.Name + "  (PID " + proc.Id + ")");
        PlcSoftware plc = null;
        foreach (Device d in prj.Devices){ foreach (DeviceItem di in d.DeviceItems){ var r = FindPlc(di); if (r != null){ plc = r; break; } } if (plc != null) break; }
        if (plc == null) return sb.ToString() + "\nERROR: no PLC software found in project.";
        sb.AppendLine("PLC: " + plc.Name);
        sb.AppendLine("FILTER: group='" + (groupFilter=="" ? "(all)" : groupFilter) + "'  name=/" + nameRegex + "/  safety=" + (includeSafety?"INCLUDE":"skip"));
        sb.AppendLine("OUTDIR: " + outDir);
        sb.AppendLine("----");
        Directory.CreateDirectory(outDir);
        Walk(plc.BlockGroup, "", groupFilter, new Regex(nameRegex), outDir, includeSafety);
        sb.AppendLine("----");
        sb.AppendLine("SUMMARY  ok=" + ok + "  skip(inconsistent)=" + skip + "  fail=" + fail);
        return sb.ToString();
    }
}
'@

# DLL must be loaded with LoadFrom (Add-Type -Path -> ReflectionTypeLoadException, hard-lock B6).
Add-Type -TypeDefinition $cs -ReferencedAssemblies $EngDll
[Extractor]::Init(@($V20, $BIN))
$result = [Extractor]::Run($ProjMatch, $GroupPath, $NameRegex, $OutDir, [bool]$IncludeSafety)
Write-Output $result

# Verify each produced XML parses (well-formed). Read-only sanity check.
Write-Output "==== well-formed verify ===="
$bad = 0
Get-ChildItem -LiteralPath $OutDir -Filter *.xml -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
    try { [xml]$null = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 }
    catch { $bad++; Write-Output ("BADXML  " + $_.Name + " : " + $_.Exception.Message) }
}
if ($bad -eq 0) { Write-Output "all XML well-formed" } else { Write-Output ("WARNING: " + $bad + " malformed file(s)") }
