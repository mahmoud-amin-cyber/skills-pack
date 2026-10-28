#requires -Version 5.1
<#
  pc.ps1 - small, auditable desktop driver for AI agents.

  One action per invocation. Prints a single result line (or JSON for
  -Action windows). Every call is appended to %LOCALAPPDATA%\pc-control\actions.log.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('screenshot', 'click', 'move', 'type', 'keys', 'open', 'windows', 'focus', 'clipboard', 'sleep')]
    [string]$Action,

    [int]$X = -1,
    [int]$Y = -1,

    [string]$Text = '',
    [string]$Target = '',
    [string]$Title = '',
    [string]$OutDir = '',
    [int]$Seconds = 1,

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# Arabic window titles and text must survive the trip back to the agent's console.
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if (-not ('PcControlNative' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class PcControlNative {
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, IntPtr extra);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int max);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, IntPtr extra);
    [DllImport("user32.dll")] public static extern IntPtr SetFocus(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint attach, uint attachTo, bool on);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();

    public static void KeyDown(byte vk) { keybd_event(vk, 0, 0, IntPtr.Zero); }
    public static void KeyUp(byte vk) { keybd_event(vk, 0, 2, IntPtr.Zero); }

    // Windows blocks SetForegroundWindow from a background process. Attaching to the
    // foreground thread's input queue removes that restriction for the duration of the call.
    public static void ForceForeground(IntPtr hWnd) {
        IntPtr fg = GetForegroundWindow();
        uint unused = 0;
        uint fgThread = GetWindowThreadProcessId(fg, out unused);
        uint myThread = GetCurrentThreadId();
        bool attached = AttachThreadInput(myThread, fgThread, true);
        try {
            ShowWindow(hWnd, SW_RESTORE);
            SetForegroundWindow(hWnd);
            SetFocus(hWnd);
        } finally {
            if (attached) { AttachThreadInput(myThread, fgThread, false); }
        }
    }

    public const uint LEFTDOWN = 0x0002;
    public const uint LEFTUP = 0x0004;
    public const int SW_RESTORE = 9;

    public static void LeftClick() {
        mouse_event(LEFTDOWN, 0, 0, 0, IntPtr.Zero);
        System.Threading.Thread.Sleep(60);
        mouse_event(LEFTUP, 0, 0, 0, IntPtr.Zero);
    }
}
'@
}

# Physical pixel coordinates regardless of display scaling.
try { [void][PcControlNative]::SetProcessDPIAware() } catch { }

# ---------------------------------------------------------------- logging ----
$logDir = Join-Path $env:LOCALAPPDATA 'pc-control'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logPath = Join-Path $logDir 'actions.log'

function Write-AuditLog {
    param([hashtable]$Entry)
    $Entry['time'] = (Get-Date).ToString('s')
    $Entry['action'] = $Action
    $Entry['dryRun'] = [bool]$DryRun
    try {
        ($Entry | ConvertTo-Json -Compress) | Add-Content -LiteralPath $logPath -Encoding UTF8
    } catch {
        # Logging must never break the action itself.
    }
}

function Fail {
    param([string]$Message)
    Write-AuditLog @{ ok = $false; error = $Message }
    Write-Output "ERROR: $Message"
    exit 1
}

# ---------------------------------------------------------------- helpers ----
function Get-TargetWindow {
    param([string]$Fragment)
    $procs = Get-Process | Where-Object {
        $_.MainWindowHandle -ne [IntPtr]::Zero -and $_.MainWindowTitle -ne ''
    } | Where-Object {
        $_.MainWindowTitle -like "*$Fragment*" -or $_.ProcessName -like "*$Fragment*"
    }
    return @($procs)
}

function Get-ForegroundInfo {
    $h = [PcControlNative]::GetForegroundWindow()
    $sb = New-Object System.Text.StringBuilder 512
    [void][PcControlNative]::GetWindowText($h, $sb, 512)
    $procId = 0
    [void][PcControlNative]::GetWindowThreadProcessId($h, [ref]$procId)
    $name = ''
    try { $name = (Get-Process -Id $procId -ErrorAction Stop).ProcessName } catch { }
    return [pscustomobject]@{ handle = $h; title = $sb.ToString(); pid = $procId; process = $name }
}

function Resolve-LaunchPath {
    param([string]$Name)
    # URLs, absolute paths and relative paths are used as given.
    if ($Name -match '^[a-zA-Z][a-zA-Z0-9+.-]*://' -or $Name -match '^[A-Za-z]:\\' -or
        $Name.StartsWith('\\') -or $Name.StartsWith('.') -or $Name.Contains('\\') -or $Name.Contains('/')) {
        return $Name
    }
    # Bare names: System32 wins over Git's usr/bin shims on this machine.
    $system32 = Join-Path $env:WINDIR 'System32'
    $names = if ($Name -match '\.(exe|cmd|bat|com|msc)$') { @($Name) } else { @("$Name.exe", "$Name.cmd", "$Name.bat") }
    foreach ($n in $names) {
        $candidate = Join-Path $system32 $n
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    foreach ($n in $names) {
        $cmd = Get-Command -Name $n -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cmd) { return $cmd.Source }
    }
    return $Name
}

$script:VirtualKeys = @{
    'ENTER' = 0x0D; 'TAB' = 0x09; 'ESC' = 0x1B; 'SPACE' = 0x20; 'BACKSPACE' = 0x08; 'DELETE' = 0x2E
    'HOME' = 0x24; 'END' = 0x23; 'UP' = 0x26; 'DOWN' = 0x28; 'LEFT' = 0x25; 'RIGHT' = 0x27
    'PGUP' = 0x21; 'PGDN' = 0x22; 'INSERT' = 0x2D
    'F1' = 0x70; 'F2' = 0x71; 'F3' = 0x72; 'F4' = 0x73; 'F5' = 0x74; 'F6' = 0x75
    'F7' = 0x76; 'F8' = 0x77; 'F9' = 0x78; 'F10' = 0x79; 'F11' = 0x7A; 'F12' = 0x7B
}

function Get-VirtualKey {
    param([string]$Name)
    $upper = $Name.ToUpperInvariant()
    if ($script:VirtualKeys.ContainsKey($upper)) { return [byte]$script:VirtualKeys[$upper] }
    if ($upper.Length -eq 1 -and $upper -match '[A-Z0-9]') { return [byte][char]$upper }
    if ($Name -match '^[A-Za-z0-9]$') { return [byte][char]$Name.ToUpperInvariant() }
    throw "unknown key name: $Name"
}

# SendKeys cannot drive menu accelerators in WinUI apps (Ctrl+S etc.) because those
# read the physical modifier state. Synthesise real key events instead.
function Send-KeyCombo {
    param([string]$Spec)
    $mods = New-Object System.Collections.Generic.List[byte]
    $rest = $Spec
    while ($rest.Length -gt 0 -and (@('^', '%', '+') -contains [string]$rest[0])) {
        switch -CaseSensitive ([string]$rest[0]) {
            '^' { $mods.Add(0x11) }
            '%' { $mods.Add(0x12) }
            '+' { $mods.Add(0x10) }
        }
        $rest = $rest.Substring(1)
    }
    $keys = New-Object System.Collections.Generic.List[byte]
    $pattern = '\{([A-Za-z0-9]+)\}|([^{])'
    foreach ($m in [regex]::Matches($rest, $pattern)) {
        if ($m.Groups[1].Success) { $keys.Add((Get-VirtualKey $m.Groups[1].Value)) }
        elseif ($m.Groups[2].Success) { $keys.Add((Get-VirtualKey $m.Groups[2].Value)) }
    }
    if ($keys.Count -eq 0) { throw "nothing to send in '$Spec'" }
    foreach ($m in $mods) { [PcControlNative]::KeyDown($m); Start-Sleep -Milliseconds 25 }
    foreach ($k in $keys) {
        [PcControlNative]::KeyDown($k); Start-Sleep -Milliseconds 25
        [PcControlNative]::KeyUp($k); Start-Sleep -Milliseconds 25
    }
    for ($i = $mods.Count - 1; $i -ge 0; $i--) { [PcControlNative]::KeyUp($mods[$i]); Start-Sleep -Milliseconds 25 }
}

function Send-KeysLiteral {
    param([string]$Value)
    # SendKeys treats + ^ % ~ ( ) { } [ ] as control characters.
    $escaped = [regex]::Replace($Value, '([+^%~(){}\[\]])', '{$1}')
    [System.Windows.Forms.SendKeys]::SendWait($escaped)
}

# ----------------------------------------------------------------- switch ----
switch ($Action) {

    'screenshot' {
        $bounds = [System.Windows.Forms.SystemInformation]::VirtualScreen
        $dir = if ($OutDir) { $OutDir } else { Join-Path $env:TEMP 'pc-control' }
        if ($DryRun) {
            Write-AuditLog @{ ok = $true; target = $dir; bytes = 0 }
            "DRYRUN: screenshot -> $(Join-Path $dir 'shot-*.png')"
            break
        }
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $file = Join-Path $dir ('shot-{0}.png' -f (Get-Date).ToString('yyyyMMdd-HHmmss-fff'))
        $bmp = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
        $gfx = [System.Drawing.Graphics]::FromImage($bmp)
        $gfx.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
        $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
        $gfx.Dispose()
        $bmp.Dispose()
        Write-AuditLog @{ ok = $true; file = $file; width = $bounds.Width; height = $bounds.Height }
        "OK: screenshot $file ($($bounds.Width)x$($bounds.Height))"
    }

    'click' {
        if ($X -lt 0 -or $Y -lt 0) { Fail 'click needs -X and -Y (physical pixels, origin top-left).' }
        if ($DryRun) {
            Write-AuditLog @{ ok = $true; x = $X; y = $Y }
            "DRYRUN: left click at $X,$Y"
            break
        }
        $screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
        if ($X -ge $screen.Width -or $Y -ge $screen.Height) {
            Fail "point $X,$Y is outside the screen ($($screen.Width)x$($screen.Height))."
        }
        [void][PcControlNative]::SetCursorPos($X, $Y)
        Start-Sleep -Milliseconds 80
        [PcControlNative]::LeftClick()
        Write-AuditLog @{ ok = $true; x = $X; y = $Y }
        "OK: clicked $X,$Y"
    }

    'move' {
        if ($X -lt 0 -or $Y -lt 0) { Fail 'move needs -X and -Y.' }
        if ($DryRun) {
            Write-AuditLog @{ ok = $true; x = $X; y = $Y }
            "DRYRUN: move cursor to $X,$Y"
            break
        }
        [void][PcControlNative]::SetCursorPos($X, $Y)
        Write-AuditLog @{ ok = $true; x = $X; y = $Y }
        "OK: cursor at $X,$Y"
    }

    'type' {
        if (-not $Text) { Fail 'type needs -Text.' }
        $fg = Get-ForegroundInfo
        if ($Title -and ($fg.title -notlike "*$Title*" -and $fg.process -notlike "*$Title*")) {
            Fail "foreground window is '$($fg.title)' [$($fg.process)], expected a match for '$Title'. Nothing was typed."
        }
        if ($DryRun) {
            Write-AuditLog @{ ok = $true; chars = $Text.Length; into = $fg.title }
            "DRYRUN: would type $($Text.Length) chars into '$($fg.title)'"
            break
        }
        # Paste, don't keystroke: SendKeys maps characters through the active keyboard
        # layout, so Arabic or any non-Latin text comes out garbled.
        $previous = $null
        $hadPrevious = $false
        try { $previous = Get-Clipboard -Raw; $hadPrevious = $true } catch { }
        Set-Clipboard -Value $Text
        Start-Sleep -Milliseconds 150
        Send-KeyCombo '^v'
        Start-Sleep -Milliseconds 400
        if ($hadPrevious) { try { Set-Clipboard -Value $previous } catch { } }
        Write-AuditLog @{ ok = $true; chars = $Text.Length; into = $fg.title; intoPid = $fg.pid; method = 'paste' }
        "OK: typed $($Text.Length) chars into '$($fg.title)' [$($fg.process)]"
    }

    'keys' {
        if (-not $Text) { Fail 'keys needs -Text, e.g. "^s" for Ctrl+S, "%{F4}" for Alt+F4.' }
        $fg = Get-ForegroundInfo
        if ($Title -and ($fg.title -notlike "*$Title*" -and $fg.process -notlike "*$Title*")) {
            Fail "foreground window is '$($fg.title)' [$($fg.process)], expected a match for '$Title'. No keys were sent."
        }
        if ($DryRun) {
            Write-AuditLog @{ ok = $true; keys = $Text; into = $fg.title }
            "DRYRUN: would send keys $Text to '$($fg.title)'"
            break
        }
        try { Send-KeyCombo $Text } catch { Fail $_.Exception.Message }
        Write-AuditLog @{ ok = $true; keys = $Text; into = $fg.title; intoPid = $fg.pid }
        "OK: sent keys $Text to '$($fg.title)' [$($fg.process)]"
    }

    'open' {
        if (-not $Target) { Fail 'open needs -Target (app name, file path, or URL).' }
        if ($DryRun) {
            Write-AuditLog @{ ok = $true; target = $Target }
            "DRYRUN: would open $Target"
            break
        }
        $resolved = Resolve-LaunchPath -Name $Target
        try {
            $proc = Start-Process -FilePath $resolved -PassThru
        } catch {
            # Anything Start-Process cannot classify (shims, shell verbs) goes through the shell.
            Start-Process -FilePath "cmd.exe" -ArgumentList '/c', 'start', '""', "`"$resolved`"" -WindowStyle Hidden
            $proc = $null
        }
        Start-Sleep -Milliseconds 1200
        $pidInfo = if ($proc) { $proc.Id } else { 'unknown' }
        Write-AuditLog @{ ok = $true; target = $Target; resolved = $resolved; pid = $pidInfo }
        "OK: started $resolved (pid $pidInfo)"
    }

    'windows' {
        $rows = Get-Process | Where-Object {
            $_.MainWindowHandle -ne [IntPtr]::Zero -and $_.MainWindowTitle -ne ''
        } | Sort-Object ProcessName | ForEach-Object {
            [pscustomobject]@{ process = $_.ProcessName; pid = $_.Id; title = $_.MainWindowTitle }
        }
        Write-AuditLog @{ ok = $true; count = @($rows).Count }
        @($rows) | ConvertTo-Json -Compress
    }

    'focus' {
        if (-not $Target) { Fail 'focus needs -Target (window title fragment or process name).' }
        $matches = Get-TargetWindow -Fragment $Target
        if ($matches.Count -eq 0) { Fail "no visible window matching '$Target'." }
        $win = $matches[0]
        if ($DryRun) {
            Write-AuditLog @{ ok = $true; target = $Target; pid = $win.Id }
            "DRYRUN: would focus pid $($win.Id) '$($win.MainWindowTitle)'"
            break
        }
        [PcControlNative]::ForceForeground($win.MainWindowHandle)
        Start-Sleep -Milliseconds 300
        if ((Get-ForegroundInfo).pid -ne $win.Id) {
            try { Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.Interaction]::AppActivate($win.Id); Start-Sleep -Milliseconds 350 } catch { }
        }
        if ((Get-ForegroundInfo).pid -ne $win.Id) {
            [PcControlNative]::ForceForeground($win.MainWindowHandle)
            Start-Sleep -Milliseconds 350
        }
        $fg = Get-ForegroundInfo
        $focused = ($fg.pid -eq $win.Id)
        Write-AuditLog @{ ok = $focused; target = $Target; pid = $win.Id; title = $win.MainWindowTitle }
        if (-not $focused) {
            "WARN: pid $($win.Id) '$($win.MainWindowTitle)' is not in the foreground (current: '$($fg.title)'). Do not type yet."
        } else {
            "OK: focused pid $($win.Id) '$($win.MainWindowTitle)'"
        }
    }

    'clipboard' {
        if ($DryRun) {
            Write-AuditLog @{ ok = $true; mode = $(if ($Text) { 'set' } else { 'get' }) }
            "DRYRUN: clipboard $(if ($Text) { "set to $($Text.Length) chars" } else { 'read' })"
            break
        }
        if ($Text) {
            Set-Clipboard -Value $Text
            Write-AuditLog @{ ok = $true; mode = 'set'; chars = $Text.Length }
            "OK: clipboard set ($($Text.Length) chars)"
        } else {
            $value = Get-Clipboard -Raw
            Write-AuditLog @{ ok = $true; mode = 'get'; chars = "$value".Length }
            "CLIPBOARD: $value"
        }
    }

    'sleep' {
        if ($Seconds -lt 1 -or $Seconds -gt 30) { Fail 'sleep takes -Seconds between 1 and 30.' }
        Write-AuditLog @{ ok = $true; seconds = $Seconds }
        Start-Sleep -Seconds $Seconds
        "OK: slept $Seconds s"
    }
}
