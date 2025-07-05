$debug = $fales

# Define the path to the file that stores the last execution time
$timeFilePath = "$env:USERPROFILE\Documents\PowerShell\LastExecutionTime.txt"
$directory = Split-Path $timeFilePath

if (-not (Test-Path $directory)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
}

if (-not (Test-Path $timeFilePath)) {
    New-Item -ItemType File -Path $timeFilePath -Force | Out-Null
}

# Define the update interval in days, set to -1 to always check
$updateInterval = 7

if ($debug) {
    Write-Host "══════════════════════════════════════" -ForegroundColor White
    Write-Host "▗▄▄▄ ▗▄▄▄▖▗▄▄▖ ▗▖ ▗▖ ▗▄▄▖   ▗▄▖ ▗▖  ▗▖" -ForegroundColor Red
    Write-Host "▐▌  █▐▌   ▐▌ ▐▌▐▌ ▐▌▐▌     ▐▌ ▐▌▐▛▚▖▐▌" -ForegroundColor DarkGray
    Write-Host "▐▌  █▐▛▀▀▘▐▛▀▚▖▐▌ ▐▌▐▌▝▜▌  ▐▌ ▐▌▐▌ ▝▜▌" -ForegroundColor Red
    Write-Host "▐▙▄▄▀▐▙▄▄▖▐▙▄▞▘▝▚▄▞▘▝▚▄▞▘  ▝▚▄▞▘▐▌  ▐▌" -ForegroundColor DarkGray
    Write-Host "══════════════════════════════════════" -ForegroundColor White
}

<#
WARNING:
DO NOT MODIFY THIS FILE. THIS FILE IS HASHED AND UPDATED AUTOMATICALLY.
ANY CHANGES MADE TO THIS FILE WILL BE OVERWRITTEN BY COMMITS TO
https://github.com/o9-9/powershell-profile.git.

IF YOU WANT TO MAKE CHANGES, USE THE Edit-Profile FUNCTION
AND SAVE YOUR CHANGES IN THE FILE CREATED.
#>

# opt-out of telemetry before doing anything, only if PowerShell is run as admin
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
    [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}

# Initial GitHub.com connectivity check with 1 second timeout
$global:canConnectToGitHub = Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1

# Import Modules and External Profiles
# Ensure Terminal-Icons module is installed before importing
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module -Name Terminal-Icons
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

# Check for Profile Updates
function Update-Profile {
    try {
        $url = "https://raw.githubusercontent.com/o9-9/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
        $oldhash = Get-FileHash $PROFILE
        Invoke-RestMethod $url -OutFile "$env:temp/Microsoft.PowerShell_profile.ps1"
        $newhash = Get-FileHash "$env:temp/Microsoft.PowerShell_profile.ps1"
        if ($newhash.Hash -ne $oldhash.Hash) {
            Copy-Item -Path "$env:temp/Microsoft.PowerShell_profile.ps1" -Destination $PROFILE -Force
            Write-Host "✔ o9  > Restart" -ForegroundColor Gray
        } else {
            Write-Host "o9" -ForegroundColor Gray
        }
    } catch {
        Write-Error "Unable Check `$profile updates: $_"
    } finally {
        Remove-Item "$env:temp/Microsoft.PowerShell_profile.ps1" -ErrorAction SilentlyContinue
    }
}

# Check if not in debug mode AND (updateInterval is -1 OR file doesn't exist OR time difference is greater than the update interval)
if (-not $debug -and `
    ($updateInterval -eq -1 -or `
      -not (Test-Path $timeFilePath) -or `
      ((Get-Date) - [datetime]::ParseExact((Get-Content -Path $timeFilePath), 'yyyy-MM-dd', $null)).TotalDays -gt $updateInterval)) {

    Update-Profile
    $currentTime = Get-Date -Format 'yyyy-MM-dd'
    $currentTime | Out-File -FilePath $timeFilePath

} elseif ($debug) {
    #Write-Warning "Skip Profile Update check"
}

function Update-PowerShell {
    try {
        Write-Host "Check PowerShell Update..." -ForegroundColor Cyan
        $updateNeeded = $false
        $currentVersion = $PSVersionTable.PSVersion.ToString()
        $gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
        $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl
        $latestVersion = $latestReleaseInfo.tag_name.Trim('v')
        if ($currentVersion -lt $latestVersion) {
            $updateNeeded = $true
        }

        if ($updateNeeded) {
            Write-Host "Updating PowerShell..." -ForegroundColor Yellow
            Start-Process powershell.exe -ArgumentList "-NoProfile -Command winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow
            Write-Host "✔ PowerShell > Restart" -ForegroundColor Gray
        } else {
            Write-Host "PowerShell Up Date." -ForegroundColor Green
        }
    } catch {
        Write-Error "Failed to Update PowerShell. Error: $_"
    }
}

# skip in debug mode
# Check if not in debug mode AND (updateInterval is -1 OR file doesn't exist OR time difference is greater than the update interval)
if (-not $debug -and `
    ($updateInterval -eq -1 -or `
     -not (Test-Path $timeFilePath) -or `
     ((Get-Date).Date - [datetime]::ParseExact((Get-Content -Path $timeFilePath), 'yyyy-MM-dd', $null).Date).TotalDays -gt $updateInterval)) {

    Update-PowerShell
    $currentTime = Get-Date -Format 'yyyy-MM-dd'
    $currentTime | Out-File -FilePath $timeFilePath
} elseif ($debug) {
    #Write-Warning "Skip Profile Update check"
}

function Clear-Cache {
    # add clear cache logic here
    Write-Host "Clearing Cache..." -ForegroundColor Cyan

    # Clear Prefetch
    Write-Host "Clearing Prefetch..." -ForegroundColor Yellow
    Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue
    Write-Host "✔ Clear Prefetch Completed." -ForegroundColor Green

    # Clear Windows Temp
    Write-Host "Clearing Windows Temp..." -ForegroundColor Yellow
    Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✔ Clear Windows Temp Completed." -ForegroundColor Green

    # Clear User Temp
    Write-Host "Clearing User Temp..." -ForegroundColor Yellow
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✔ Clear User Temp Completed." -ForegroundColor Green

    # Clear Internet Cache
    Write-Host "Clearing Internet Cache..." -ForegroundColor Yellow
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✔ Clear Internet Cache Completed." -ForegroundColor Green
}
Set-Alias -Name cc -Value Clear-Cache

# Admin Check and Prompt Customization
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
function prompt {
    if ($isAdmin) { "[" + (Get-Location) + "] # " } else { "[" + (Get-Location) + "] $ " }
}
$adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix" -f $PSVersionTable.PSVersion.ToString()

# Utility Functions
function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

# Editor Configuration
$EDITOR = if (Test-CommandExists code) { 'code' }
          elseif (Test-CommandExists notepad++) { 'notepad++' }
          elseif (Test-CommandExists sublime_text) { 'sublime_text' }
          else { 'notepad' }
Set-Alias -Name vim -Value $EDITOR

# Quick Access to Editing the Profile
function Edit-Profile {
    vim $PROFILE.CurrentUserAllHosts
}
Set-Alias -Name ep -Value Edit-Profile

function cr($file) { "" | Out-File $file -Encoding ASCII }
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

# Network Utilities
function ip { (Invoke-WebRequest http://ifconfig.me/ip).Content }

# Open o9
function o9 {
	irm https://raw.githubusercontent.com/o9-9/o9/main/o9.ps1 | iex
}

# Open set
function set {
	irm https://raw.githubusercontent.com/o9-9/vscode-setup/main/set.ps1 | iex
}

# System Utilities
function admin {
    if ($args.Count -gt 0) {
        $argList = $args -join ' '
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $argList"
    } else {
        Start-Process wt -Verb runAs
    }
}

# Set UNIX-like aliases for the admin command, so sudo <command> will run the command with elevated rights.
Set-Alias -Name su -Value admin

function time {
    try {
        # find date/time format
        $dateFormat = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.ShortDatePattern
        $timeFormat = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.LongTimePattern

        # check powershell version
        if ($PSVersionTable.PSVersion.Major -eq 5) {
            $lastBoot = (Get-WmiObject win32_operatingsystem).LastBootUpTime
            $bootTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($lastBoot)

            # reformat lastBoot
            $lastBoot = $bootTime.ToString("$dateFormat $timeFormat")
        } else {
            $lastBoot = net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
            $bootTime = [System.DateTime]::ParseExact($lastBoot, "$dateFormat $timeFormat", [System.Globalization.CultureInfo]::InvariantCulture)
        }

        # Format the start time
        $formattedBootTime = $bootTime.ToString("dddd, MMMM dd, yyyy HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture) + " [$lastBoot]"
        Write-Host "System Started On: $formattedBootTime" -ForegroundColor DarkGray

        # calculate time
        $time = (Get-Date) - $bootTime

        # time in days, hours, minutes, and seconds
        $days = $time.Days
        $hours = $time.Hours
        $minutes = $time.Minutes
        $seconds = $time.Seconds

        # time output
        Write-Host ("time: {0} days, {1} hours, {2} minutes, {3} seconds" -f $days, $hours, $minutes, $seconds) -ForegroundColor Blue

    } catch {
        Write-Error "An Error Retrieving System Time."
    }
}

function Reload-profile {
    & $profile
}

function un ($file) {
    Write-Output("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}
function hb {
    if ($args.Length -eq 0) {
        Write-Error "No File Path."
        return
    }

    $FilePath = $args[0]

    if (Test-Path $FilePath) {
        $Content = Get-Content $FilePath -Raw
    } else {
        Write-Error "File path does not exist."
        return
    }

    $uri = "http://bin.christitus.com/documents"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $Content -ErrorAction Stop
        $hasteKey = $response.key
        $url = "http://bin.christitus.com/$hasteKey"
	    Set-Clipboard $url
        Write-Output "$url copied to clipboard."
    } catch {
        Write-Error "Failed to upload Document. Error: $_"
    }
}
function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

function df {
    get-volume
}

function rr($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function pa($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function env($name, $value) {
    set-item -force -path "env:$name" -value $value;
}

function kill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pp($name) {
    Get-Process $name
}

function fl {
  param($Path, $n = 10)
  Get-Content $Path -Head $n
}

function lf {
  param($Path, $n = 10, [switch]$f = $false)
  Get-Content $Path -Tail $n -Wait:$f
}

# Quick File Creation
function nn { param($name) New-Item -ItemType "file" -Path . -Name $name }

# Directory Management
function o { param($dir) mkdir $dir -Force; Set-Location $dir }

function trash($path) {
    $fullPath = (Resolve-Path -Path $path).Path

    if (Test-Path $fullPath) {
        $item = Get-Item $fullPath

        if ($item.PSIsContainer) {
          # Handle directory
            $parentPath = $item.Parent.FullName
        } else {
            # Handle file
            $parentPath = $item.DirectoryName
        }

        $shell = New-Object -ComObject 'Shell.Application'
        $shellItem = $shell.NameSpace($parentPath).ParseName($item.Name)

        if ($item) {
            $shellItem.InvokeVerb('delete')
            Write-Host "Item '$fullPath' Moved= to Recycle Bin."
        } else {
            Write-Host "Error: Not Find Item '$fullPath' to Trash."
        }
    } else {
        Write-Host "Error: Item '$fullPath' Does Not Exist."
    }
}

### Quality of Life Aliases

# Navigation Shortcuts
# Go to Documents
function dc {
    $dc = if(([Environment]::GetFolderPath("MyDocuments"))) {([Environment]::GetFolderPath("MyDocuments"))} else {$HOME + "\Documents"}
    Set-Location -Path $dc
}
# Go to Desktop
function dt {
    $dt = if ([Environment]::GetFolderPath("Desktop")) {[Environment]::GetFolderPath("Desktop")} else {$HOME + "\Documents"}
    Set-Location -Path $dt
}
# Go to Downloads folder
function do {
    $do = if(([Environment]::GetFolderPath("Downloads"))) {([Environment]::GetFolderPath("Downloads"))} else {$HOME + "\Downloads"}
    Set-Location -Path $do
}

# Go to Local AppData folder
function lc {
    $lc = if(([Environment]::GetFolderPath("LocalApplicationData"))) {([Environment]::GetFolderPath("LocalApplicationData"))} else {$HOME + "\AppData\Local"}
    Set-Location -Path $lc
}

# Go to Roaming AppData folder
function ro {
    $ro = if(([Environment]::GetFolderPath("ApplicationData"))) {([Environment]::GetFolderPath("ApplicationData"))} else {$HOME + "\AppData\Roaming"}
    Set-Location -Path $ro
}
# Simplified Process Management
function k9 { Stop-Process -Name $args[0] }

# Enhanced Listing
function la { Get-ChildItem | Format-Table -AutoSize }
function ll { Get-ChildItem -Force | Format-Table -AutoSize }

# Git Shortcuts
function gs { git status }

function ga { git add . }

function gc { param($m) git commit -m "$m" }

function gp { git push }

function g { __zoxide_z github }

function gcl { git clone "$args" }

function gco {
    git add .
    git commit -m "$args"
}
function lg {
    git add .
    git commit -m "$args"
    git push
}

# Quick Access to System Information
function sys { Get-ComputerInfo }

# Networking Utilities
function dns {
	Clear-DnsClientCache
	Write-Host "✔ Clean Cache DNS"
}

# Clipboard Utilities
function cp { Set-Clipboard $args[0] }

function ps { Get-Clipboard }

# Enhanced PowerShell Experience
# Enhanced PSReadLine Configuration
$PSReadLineOptions = @{
    EditMode = 'Windows'
    HistoryNoDuplicates = $true
    HistorySearchCursorMovesToEnd = $true
    Colors = @{
        Command = '#87CEEB'  # SkyBlue (pastel)
        Parameter = '#98FB98'  # PaleGreen (pastel)
        Operator = '#FFB6C1'  # LightPink (pastel)
        Variable = '#DDA0DD'  # Plum (pastel)
        String = '#FFDAB9'  # PeachPuff (pastel)
        Number = '#B0E0E6'  # PowderBlue (pastel)
        Type = '#F0E68C'  # Khaki (pastel)
        Comment = '#D3D3D3'  # LightGray (pastel)
        Keyword = '#8367c7'  # Violet (pastel)
        Error = '#FF6347'  # Tomato (keeping it close to red for visibility)
    }
    PredictionSource = 'History'
    PredictionViewStyle = 'ListView'
    BellStyle = 'None'
}
Set-PSReadLineOption @PSReadLineOptions

# Custom key handlers
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo

# Custom functions for PSReadLine
Set-PSReadLineOption -AddToHistoryHandler {
    param($line)
    $sensitive = @('password', 'secret', 'token', 'apikey', 'connectionstring')
    $hasSensitive = $sensitive | Where-Object { $line -match $_ }
    return ($null -eq $hasSensitive)
}

# Improved prediction settings
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -MaximumHistoryCount 10000

# Custom completion for common commands
$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)
    $customCompletions = @{
        'git' = @('status', 'add', 'commit', 'push', 'pull', 'clone', 'checkout')
        'npm' = @('install', 'start', 'run', 'test', 'build')
        'deno' = @('run', 'compile', 'bundle', 'test', 'lint', 'fmt', 'cache', 'info', 'doc', 'upgrade')
    }

    $command = $commandAst.CommandElements[0].Value
    if ($customCompletions.ContainsKey($command)) {
        $customCompletions[$command] | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}
Register-ArgumentCompleter -Native -CommandName git, npm, deno -ScriptBlock $scriptblock

$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)
    dotnet complete --position $cursorPosition $commandAst.ToString() |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock $scriptblock

oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json | Invoke-Expression
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
} else {
    Write-Host "zoxide command not found. Attempting to install via winget..."
    try {
        winget install -e --id ajeetdsouza.zoxide
        Write-Host "zoxide installed successfully. Initializing..."
        Invoke-Expression (& { (zoxide init powershell | Out-String) })
    } catch {
        Write-Error "Failed to install zoxide. Error: $_"
    }
}

# Help Function
function Show-ProfileShortcutsHelp {
    $archTop    = "$($PSStyle.Foreground.DarkGray)╭──────────────────────────────────────────────╮$($PSStyle.Reset)"
    $archBottom = "$($PSStyle.Foreground.DarkGray)╰──────────────────────────────────────────────╯$($PSStyle.Reset)"
    $divider    = "$($PSStyle.Foreground.DarkGray)────────────────────────────────────────────────$($PSStyle.Reset)"

    function New-SectionHeader {
        param (
            [string]$Emoji,
            [string]$Title
        )
        return "`n$archTop`n$($PSStyle.Foreground.Magenta)$Emoji  $Title$($PSStyle.Reset)`n$archBottom`n"
    }

    function New-CommandLine {
        param (
            [string]$Number,
            [string]$Alias,
            [string]$Description,
            [string]$Symbol
        )
        $aliasDisplay = if ($Alias) { "$($PSStyle.Foreground.Green)[$Alias]$($PSStyle.Reset) " } else { '' }
        return "  $($PSStyle.Foreground.Cyan)$Number$($PSStyle.Reset) $aliasDisplay$Symbol  $Description"
    }

    $helpSections = @(
        "`n$archTop"
        "$($PSStyle.Foreground.Magenta)⚡  PowerShell Profile Shortcuts$($PSStyle.Reset)"
        "$archBottom`n"

        (New-SectionHeader -Emoji "🚀" -Title "Navigation")
        (New-CommandLine "01" "dc" "Go to Documents" "📄")
        (New-CommandLine "02" "dt" "Go to Desktop" "🖥️")
        (New-CommandLine "03" "do" "Go to Downloads" "⬇️")
        (New-CommandLine "04" "lc" "Go to Local" "📁")
        (New-CommandLine "05" "ro" "Go to Roaming" "🌐")
        (New-CommandLine "06" "o"  "Change Directory" "📂")
        "`n$divider`n"

        (New-SectionHeader -Emoji "🛠️" -Title "System / Utility")
        (New-CommandLine "07" "o9"   "Run o9" "⚡")
        (New-CommandLine "08" "set"  "Run set" "🔧")
        (New-CommandLine "09" "cc"   "Clear Cache" "🧹")
        (New-CommandLine "10" "sys"  "System Info" "🖥️")
        (New-CommandLine "11" "dns"  "Clear DNS Cache" "🌐")
        (New-CommandLine "12" "kill" "Kill Process Name" "💀")
        (New-CommandLine "13" "pp"   "List Process Name" "🔎")
        (New-CommandLine "14" "k9"   "Kill Process" "🪓")
        "`n$divider`n"

        (New-SectionHeader -Emoji "📄" -Title "Files & Directories")
        (New-CommandLine "15" "la"   "List All Files" "📁")
        (New-CommandLine "16" "ll"   "List Hidden Files" "👻")
        (New-CommandLine "17" "fl"   "Show First Lines" "🔝")
        (New-CommandLine "18" "lf"   "Show Last Lines" "🔚")
        (New-CommandLine "19" "cr"   "Create Empty File" "🆕")
        (New-CommandLine "20" "nn"   "Create New File" "✏️")
        (New-CommandLine "21" "ff"   "Find Files" "🔍")
        (New-CommandLine "22" "un"   "Extract Zip File" "🗜️")
        (New-CommandLine "23" "hb"   "Upload URL" "🌐")
        (New-CommandLine "24" "df"   "Disk Free Space" "ℹ️")
        (New-CommandLine "25" "pa"   "Show Command Path" "🛤️")
        (New-CommandLine "26" "env"  "Set Environment" "🌱")
        (New-CommandLine "27" "rr"   "Replace in File" "✂️")
        "`n$divider`n"

        (New-SectionHeader -Emoji "🔎" -Title "Search & Data")
        (New-CommandLine "28" "grep" "Search Regex" "🧬")
        (New-CommandLine "29" "ip"   "Show Public IP" "🌎")
        (New-CommandLine "30" "time" "Show Uptime" "⏰")
        "`n$divider`n"

        (New-SectionHeader -Emoji "👤" -Title "Profile Management")
        (New-CommandLine "31" "up"   "Update Profile" "🔄")
        (New-CommandLine "32" "upp"  "Update PowerShell" "🔄")
        (New-CommandLine "33" "ep"   "Edit Profile" "📝")
        (New-CommandLine "34" "rpp"  "Reload Profile" "♻️")
        "`n$divider`n"

        (New-SectionHeader -Emoji "🔗" -Title "Clipboard")
        (New-CommandLine "35" "cp"   "Copy File" "📋")
        (New-CommandLine "36" "ps"   "Paste File" "📋")
        "`n$divider`n"

        (New-SectionHeader -Emoji "🌱" -Title "Git Shortcuts")
        (New-CommandLine "37" "gs"   "git status" "🟢")
        (New-CommandLine "38" "ga"   "git add ." "➕")
        (New-CommandLine "39" "gc"   "git commit -m" "💬")
        (New-CommandLine "40" "gp"   "git push" "🚀")
        (New-CommandLine "41" "g"    "GitHub Folder" "🌐")
        (New-CommandLine "42" "gco"  "Add & Commit" "📝")
        (New-CommandLine "43" "lg"   "Add-Commit-Push" "⚡")
        "`n$divider`n"
    )

    Write-Host ($helpSections -join "`n")
}

# System and Utility Shortcuts
Set-Alias hh Show-ProfileShortcutsHelp
Set-Alias -Name up -Value Update-Profile
Set-Alias -Name upp -Value Update-PowerShell


if (Test-Path "$PSScriptRoot\o9Custom.ps1") {
    Invoke-Expression -Command "& `"$PSScriptRoot\o9Custom.ps1`""
}

Write-Host "$($PSStyle.Foreground.Yellow)Use 'hh' to Display Help$($PSStyle.Reset)"
