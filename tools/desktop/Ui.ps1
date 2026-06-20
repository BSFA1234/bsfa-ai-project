# BSFA desktop control helper (screen capture + mouse/keyboard + window activation)
# Purpose: let Claude "see" and operate Windows desktop apps like TIA Portal.
# Coordinates are physical pixels (SetProcessDPIAware => capture px == cursor px).
# Usage: . "C:\Users\<user>\Desktop\bsfa-tia-test\tools\desktop\Ui.ps1"  then call functions.
# NOTE: kept ASCII-only on purpose so PowerShell 5.1 reads it correctly under any code page.

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

if (-not ("WinUI" -as [type])) {
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinUI {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, int extra);
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, int dwExtraInfo);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int n);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    const uint LDOWN=0x02, LUP=0x04, RDOWN=0x08, RUP=0x10;
    public static void Move(int x,int y){ SetCursorPos(x,y); }
    public static void Click(int x,int y){ SetCursorPos(x,y); System.Threading.Thread.Sleep(40); mouse_event(LDOWN,0,0,0,0); mouse_event(LUP,0,0,0,0); }
    public static void DblClick(int x,int y){ SetCursorPos(x,y); System.Threading.Thread.Sleep(40); mouse_event(LDOWN,0,0,0,0); mouse_event(LUP,0,0,0,0); System.Threading.Thread.Sleep(70); mouse_event(LDOWN,0,0,0,0); mouse_event(LUP,0,0,0,0); }
    public static void RClick(int x,int y){ SetCursorPos(x,y); System.Threading.Thread.Sleep(40); mouse_event(RDOWN,0,0,0,0); mouse_event(RUP,0,0,0,0); }
    // Force a window to the foreground, bypassing Windows' foreground lock (works from child processes too)
    public static void ForceForeground(IntPtr hWnd){
        if (hWnd == IntPtr.Zero) return;
        uint pid;
        uint fgThread = GetWindowThreadProcessId(GetForegroundWindow(), out pid);
        uint thisThread = GetCurrentThreadId();
        keybd_event(0x12, 0, 0, 0);          // ALT down -> unlock foreground
        bool attached = false;
        if (fgThread != thisThread) { attached = AttachThreadInput(fgThread, thisThread, true); }
        ShowWindow(hWnd, 9);                  // 9 = SW_RESTORE
        BringWindowToTop(hWnd);
        SetForegroundWindow(hWnd);
        if (attached) { AttachThreadInput(fgThread, thisThread, false); }
        keybd_event(0x12, 0, 0x0002, 0);     // ALT up
    }
    public static void Maximize(IntPtr hWnd){ ShowWindow(hWnd, 3); }   // 3 = SW_MAXIMIZE
}
"@
}
[void][WinUI]::SetProcessDPIAware()

# --- Draw a coordinate grid (labels are ORIGINAL screen coords) ---
# OffX/OffY = crop origin in original coords (0,0 for full screen), Scale = zoom factor
function Draw-Grid {
    param($Graphics, [int]$OffX, [int]$OffY, [int]$W, [int]$H, [double]$Scale, [int]$Step)
    $pen   = New-Object System.Drawing.Pen       -ArgumentList ([System.Drawing.Color]::FromArgb(120,255,0,0)), 1
    $font  = New-Object System.Drawing.Font      -ArgumentList "Consolas", 8
    $brush = New-Object System.Drawing.SolidBrush -ArgumentList ([System.Drawing.Color]::Red)
    $bg    = New-Object System.Drawing.SolidBrush -ArgumentList ([System.Drawing.Color]::FromArgb(150,255,255,255))
    $startX = [int]([math]::Ceiling($OffX / [double]$Step) * $Step)
    for ($ox = $startX; $ox -le ($OffX + $W); $ox += $Step) {
        $px = [single](($ox - $OffX) * $Scale)
        $Graphics.DrawLine($pen, $px, [single]0, $px, [single]($H * $Scale))
        $Graphics.FillRectangle($bg, $px + 1, [single]1, [single]30, [single]12)
        $Graphics.DrawString("$([int]$ox)", $font, $brush, $px + 1, [single]0)
    }
    $startY = [int]([math]::Ceiling($OffY / [double]$Step) * $Step)
    for ($oy = $startY; $oy -le ($OffY + $H); $oy += $Step) {
        $py = [single](($oy - $OffY) * $Scale)
        $Graphics.DrawLine($pen, [single]0, $py, [single]($W * $Scale), $py)
        $Graphics.FillRectangle($bg, [single]1, $py + 1, [single]30, [single]12)
        $Graphics.DrawString("$([int]$oy)", $font, $brush, [single]1, $py)
    }
    $pen.Dispose(); $font.Dispose(); $brush.Dispose(); $bg.Dispose()
}

# --- Full-screen capture (-Grid adds a 100px coordinate grid) ---
function Capture-Screen {
    param([string]$Path = "$env:TEMP\bsfa_screen.png", [switch]$Grid, [int]$Step = 100)
    $s = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object System.Drawing.Bitmap $s.Width, $s.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($s.X, $s.Y, 0, 0, $bmp.Size)
    if ($Grid) { Draw-Grid -Graphics $g -OffX 0 -OffY 0 -W $s.Width -H $s.Height -Scale 1 -Step $Step }
    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Output "CAPTURED $Path ($($s.Width)x$($s.Height))$(if($Grid){' +grid'})"
}

# --- Crop + zoom a region (-Grid overlays ORIGINAL-coord ruler) ---
function Save-Crop {
    param([int]$X, [int]$Y, [int]$W, [int]$H, [double]$Scale = 2,
          [string]$Src = "$env:TEMP\bsfa_screen.png", [string]$Out = "$env:TEMP\bsfa_crop.png",
          [switch]$Grid, [int]$Step = 50)
    $img = [System.Drawing.Image]::FromFile($Src)
    $ow = [int]($W * $Scale); $oh = [int]($H * $Scale)
    $crop = New-Object System.Drawing.Bitmap $ow, $oh
    $g = [System.Drawing.Graphics]::FromImage($crop)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.DrawImage($img, (New-Object System.Drawing.Rectangle 0,0,$ow,$oh), (New-Object System.Drawing.Rectangle $X,$Y,$W,$H), [System.Drawing.GraphicsUnit]::Pixel)
    if ($Grid) { Draw-Grid -Graphics $g -OffX $X -OffY $Y -W $W -H $H -Scale $Scale -Step $Step }
    $crop.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $crop.Dispose(); $img.Dispose()
    Write-Output "CROP $Out (orig x$X~$($X+$W), y$Y~$($Y+$H), ${Scale}x)$(if($Grid){' +grid'})"
}

# --- Find the TIA Portal main window process ---
function Get-TiaProcess {
    Get-Process -Name "Siemens.Automation.Portal" -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
}

# --- Bring a window reliably to the front (AppActivate + ForceForeground) ---
function Ui-Activate {
    param([System.Diagnostics.Process]$Proc, [string]$TitleContains, [switch]$Maximize)
    if (-not $Proc) {
        if ($TitleContains) { $Proc = Get-Process | Where-Object { $_.MainWindowTitle -like "*$TitleContains*" } | Select-Object -First 1 }
        else { $Proc = Get-TiaProcess }
    }
    if (-not $Proc) { Write-Output "ACTIVATE: target window not found"; return }
    try { $ws = New-Object -ComObject WScript.Shell; [void]$ws.AppActivate($Proc.Id) } catch {}
    Start-Sleep -Milliseconds 300
    [WinUI]::ForceForeground($Proc.MainWindowHandle)
    if ($Maximize) { [WinUI]::Maximize($Proc.MainWindowHandle) }
    Start-Sleep -Milliseconds 700
    Write-Output "ACTIVATED pid $($Proc.Id)"
}

# --- Input actions (each click waits briefly afterwards) ---
function Ui-Click       { param([int]$X,[int]$Y) [WinUI]::Click($X,$Y);    Start-Sleep -Milliseconds 400 }
function Ui-DoubleClick { param([int]$X,[int]$Y) [WinUI]::DblClick($X,$Y); Start-Sleep -Milliseconds 400 }
function Ui-RightClick  { param([int]$X,[int]$Y) [WinUI]::RClick($X,$Y);   Start-Sleep -Milliseconds 400 }
function Ui-Move        { param([int]$X,[int]$Y) [WinUI]::Move($X,$Y) }
function Ui-Type        { param([string]$Text) [System.Windows.Forms.SendKeys]::SendWait($Text) }
function Ui-Key         { param([string]$Keys) [System.Windows.Forms.SendKeys]::SendWait($Keys) }
# Korean text is unreliable via SendKeys, so use clipboard paste instead
function Ui-Paste       { param([string]$Text) Set-Clipboard -Value $Text; Start-Sleep -Milliseconds 150; [System.Windows.Forms.SendKeys]::SendWait("^v") }

# --- Keyboard via keybd_event (RELIABLE: works in TIA where SendKeys / double-click / right-click FAIL) ---
# Lesson 2026-06-16: SendKeys arrows did NOT reach the TIA tree; keybd_event DOES. Prefer these for navigation.
# Resolution-independent (no coordinates) -> portable across machines.
# Virtual keys: Enter=0x0D Esc=0x1B Up=0x26 Down=0x28 Left=0x25 Right=0x27 Tab=0x09 F2=0x71
function Ui-Press {
    param([int]$Vk, [int]$Repeat = 1)
    for ($i = 0; $i -lt $Repeat; $i++) {
        [WinUI]::keybd_event([byte]$Vk, [byte]0, [uint32]0, 0)   # key down
        Start-Sleep -Milliseconds 40
        [WinUI]::keybd_event([byte]$Vk, [byte]0, [uint32]2, 0)   # key up (KEYEVENTF_KEYUP=0x02)
        Start-Sleep -Milliseconds 220
    }
}
function Ui-Enter    { Ui-Press 0x0D }
function Ui-Esc      { Ui-Press 0x1B }
function Ui-Down     { param([int]$N = 1) Ui-Press 0x28 $N }
function Ui-Up       { param([int]$N = 1) Ui-Press 0x26 $N }
function Ui-Expand   { Ui-Press 0x27 }   # Right arrow: expand a collapsed tree folder
function Ui-Collapse { Ui-Press 0x25 }   # Left arrow: collapse
# IMPORTANT: before sending keys to the project tree, single-click the target row FIRST to put
# keyboard focus on the tree. Otherwise Enter may hit a toolbar button (e.g. opens "New project").
function Ui-FocusClick { param([int]$X, [int]$Y) [WinUI]::Click($X, $Y); Start-Sleep -Milliseconds 350 }
