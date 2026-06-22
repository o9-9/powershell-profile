<#
.SYNOPSIS
    PowerShell Profile Refactor
    Version 9.00
    https://github.com/o9-9/powershell-profile

.DESCRIPTION
                        !!!   WARNING:   !!!
    DO NOT MODIFY THIS FILE. THIS FILE IS HASHED AND UPDATED AUTOMATICALLY.
        ANY CHANGES MADE TO THIS FILE WILL BE OVERWRITTEN BY COMMITS TO
                https://github.com/o9-9/powershell-profile.git.

    TO ADD YOUR OWN CODE OR IF YOU WANT TO OVERRIDE ANY OF THESE VARIABLES
    OR FUNCTIONS. USE ed FUNCTION TO CREATE YOUR OWN profile.ps1 FILE.
    TO OVERRIDE IN YOUR NEW profile.ps1 FILE, REWRITE VARIABLE
    OR FUNCTION, ADDING "_Override" TO NAME.

    FOLLOWING VARIABLES RESPECT _Override:
    $EDITOR_Override
    $debug_Override
    $repo_root_Override  [To point to fork, for example]
    $timeFilePath_Override
    $updateInterval_Override

    FOLLOWING FUNCTIONS RESPECT _Override:
    Debug-Message_Override
    Update-Profile_Override
    Update-PowerShell_Override
    Clear-Cache_Override
    Get-Theme_Override
    o99_Override [To call fork, for example]
    Set-PredictionSource
#>


# Handle PowerShell 7.4+ UTF-8 encoding issues
$previousOutputEncoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [Text.Encoding]::UTF8


# Debug mode
$debug = $false

if ($debug_Override){
    # If variable debug_Override is defined in profile.ps1 file. then use it instead.
    $debug = $debug_Override
} else {
    $debug = $false
}


# Define path to file that stores last execution time
if ($repo_root_Override){
    # If variable $repo_root_Override is defined in profile.ps1 file. then use it instead.
    $repo_root = $repo_root_Override
} else {
    $repo_root = "https://raw.githubusercontent.com/o9-9"
}


# Helper function for cross-edition compatibility
function Get-ProfileDir {
    if ($PSVersionTable.PSEdition -eq "Core") {
        return [Environment]::GetFolderPath("MyDocuments") + "\PowerShell"
    } elseif ($PSVersionTable.PSEdition -eq "Desktop") {
        return [Environment]::GetFolderPath("MyDocuments") + "\WindowsPowerShell"
    } else {
        Write-Error "Unsupported PowerShell edition: $($PSVersionTable.PSEdition)"
        return $null
    }
}


# Define path to file that stores last execution time
if ($timeFilePath_Override){
    # If variable $timeFilePath_Override is defined in profile.ps1 file. then use it instead.
    $timeFilePath = $timeFilePath_Override
} else {
    $profileDir = Get-ProfileDir
    $timeFilePath = "$profileDir\LastExecutionTime.txt"
}


# Define update interval in days, set to -1 to always check
if ($updateInterval_Override){
    # If variable $updateInterval_Override is defined in profile.ps1 file. then use it instead.
    $updateInterval = $updateInterval_Override
} else {
    $updateInterval = 7
}


# Debug mode message
function Debug-Message{
    # If function "Debug-Message_Override" is defined in profile.ps1 file. then call it instead.
    if (Get-Command -Name "Debug-Message_Override" -ErrorAction SilentlyContinue) {
        Debug-Message_Override
    } else {
        Write-Host "#######################################" -ForegroundColor Red
        Write-Host "#           Debug mode enabled        #" -ForegroundColor Red
        Write-Host "#          ONLY FOR DEVELOPMENT       #" -ForegroundColor Red
        Write-Host "#                                     #" -ForegroundColor Red
        Write-Host "#       IF YOU ARE NOT DEVELOPING     #" -ForegroundColor Red
        Write-Host "#       JUST RUN \`Update-Profile\`     #" -ForegroundColor Red
        Write-Host "#        to discard all changes       #" -ForegroundColor Red
        Write-Host "#   and update to latest profile  #" -ForegroundColor Red
        Write-Host "#               version               #" -ForegroundColor Red
        Write-Host "#######################################" -ForegroundColor Red
    }
}


# Check Debug mode
if ($debug) {
    Debug-Message
}


# Opt-out of telemetry before doing anything, only if PowerShell is run as admin
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
    [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}


# Opt-out of telemetry before doing anything, only if PowerShell is run as admin
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
    [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}


# Initial GitHub.com connectivity check
function Test-GitHubConnection {
    if ($PSVersionTable.PSEdition -eq "Core") {
        # If PowerShell Core, use 1 second timeout
        return Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1
    } else {
        # For PowerShell Desktop, use .NET Ping class with timeout
        $ping = New-Object System.Net.NetworkInformation.Ping
        $result = $ping.Send("github.com", 1000)  # 1 second timeout
        return ($result.Status -eq "Success")
    }
}
$global:canConnectToGitHub = Test-GitHubConnection


# Ensure Terminal-Icons module is installed before importing
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module -Name Terminal-Icons
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}


# Safely read and parse last execution date once to avoid exceptions when file is missing or empty
$lastExecRaw = if (Test-Path $timeFilePath) { (Get-Content -Path $timeFilePath -Raw).Trim() } else { $null }
$lastExec = $null
if (-not [string]::IsNullOrWhiteSpace($lastExecRaw)) {
    [datetime]$parsed = [datetime]::MinValue
    if ([datetime]::TryParseExact($lastExecRaw, 'dd-MM-yyyy', $null, [System.Globalization.DateTimeStyles]::None, [ref]$parsed)) {
        $lastExec = $parsed
    }
}


# Check for Profile Updates
function Update-Profile {
    # If function "Update-Profile_Override" is defined in profile.ps1 file. then call it instead.
    if (Get-Command -Name "Update-Profile_Override" -ErrorAction SilentlyContinue) {
        Update-Profile_Override
    }
    else {
        if (Test-Path -LiteralPath $PROFILE) {
            $profileDir = Split-Path -Path $PROFILE -Parent
            $backupName = "profile-backup-$(Get-Date -Format 'd-M-yyyy_HHmmss').ps1"
            Copy-Item -LiteralPath $PROFILE -Destination (Join-Path $profileDir $backupName) -Force
        }
        try {
            $url = "$repo_root/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
            $oldhash = Get-FileHash $PROFILE
            Invoke-RestMethod $url -OutFile "$env:temp/Microsoft.PowerShell_profile.ps1"
            $newhash = Get-FileHash "$env:temp/Microsoft.PowerShell_profile.ps1"
            if ($newhash.Hash -ne $oldhash.Hash) {
                Copy-Item -Path "$env:temp/Microsoft.PowerShell_profile.ps1" -Destination $PROFILE -Force
                Write-Host "✔ o9 Profile has been updated. Restart shell to reflect changes" -ForegroundColor DarkMagenta
            }
            else {
                Write-Host "✔ o9 Profile is up to date." -ForegroundColor DarkBlue
            }
        }
        catch {
            Write-Error "Unable to check for `$o9 profile updates: $_"
        }
        finally {
            Remove-Item "$env:temp/Microsoft.PowerShell_profile.ps1" -ErrorAction SilentlyContinue
        }
    }
}
Set-Alias -Name u1 -Value Update-Profile


# Check if not in debug mode AND (updateInterval is -1 OR file doesn't exist OR time difference is greater than update interval)
if (-not $debug -and `
    ($updateInterval -eq -1 -or `
            -not (Test-Path $timeFilePath) -or `
            $null -eq $lastExec -or `
        ((Get-Date).Date - $lastExec.Date).TotalDays -gt $updateInterval)) {
    Update-Profile
    $currentTime = Get-Date -Format 'dd-MM-yyyy'
    $currentTime | Out-File -FilePath $timeFilePath
} elseif ($debug) {
    Write-Warning "Skipping o9 profile update check in debug mode"
}


# Update PowerShell
function Update-PowerShell {
    # If function "Update-PowerShell_Override" is defined in profile.ps1 file. then call it instead.
    if (Get-Command -Name "Update-PowerShell_Override" -ErrorAction SilentlyContinue) {
        Update-PowerShell_Override
    } else {
        try {
            Write-Host "Checking for o9 PowerShell updates..." -ForegroundColor DarkCyan
            $updateNeeded = $false
            $currentVersion = $PSVersionTable.PSVersion.ToString()
            $gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
            $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl
            $latestVersion = $latestReleaseInfo.tag_name.Trim('v')
            if ($currentVersion -lt $latestVersion) {
                $updateNeeded = $true
            }
            if ($updateNeeded) {
                Write-Host "Updating o9 PowerShell..." -ForegroundColor DarkYellow
                Start-Process powershell.exe -ArgumentList "-NoProfile -Command winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow
                Write-Host "✔ o9 PowerShell has been updated. Restart shell to reflect changes" -ForegroundColor DarkMagenta
            } else {
                Write-Host "✔ o9 PowerShell is up to date." -ForegroundColor DarkBlue
            }
        } catch {
            Write-Error "Failed to update o9 PowerShell. Error: $_"
        }
    }
}
Set-Alias -Name u2 -Value Update-PowerShell


# Check if not in debug mode AND (updateInterval is -1 OR file doesn't exist OR time difference is greater than update interval)
if (-not $debug -and `
    ($updateInterval -eq -1 -or `
            -not (Test-Path $timeFilePath) -or `
            $null -eq $lastExec -or `
        ((Get-Date).Date - $lastExec.Date).TotalDays -gt $updateInterval)) {
    Update-PowerShell
    $currentTime = Get-Date -Format 'dd-MM-yyyy'
    $currentTime | Out-File -FilePath $timeFilePath
} elseif ($debug) {
    Write-Warning "Skipping o9 PowerShell update in debug mode"
}

# Clear
Set-Alias -Name c -Value clear

# Clear Cache
function cc {
    if (Get-Command -Name "Clear-Cache_Override" -ErrorAction SilentlyContinue) {
        Clear-Cache_Override
    } else {
        Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue
        cleanmgr.exe /d C: /VERYLOWDISK
        Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
        Stop-Process -Name explorer -Force
        Remove-Item -Path "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*" -Force -ErrorAction SilentlyContinue
        Start-Process explorer.exe
        Write-Host "Completed" -ForegroundColor Green
    }
}


# Restart Explorer
function rr {
        Stop-Process -Name explorer -Force
        Start-Process explorer.exe
}


# Admin Check and Prompt Customization
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
function prompt {
    if ($isAdmin) { "[" + (Get-Location) + "] # " } else { "[" + (Get-Location) + "] $ " }
}
$adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix" -f $PSVersionTable.PSVersion.ToString()


# Force Cursor as default
$EDITOR_Override = 'cursor'


# Test if command exists
function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}


# Set editor
if ($EDITOR_Override){
    $EDITOR = $EDITOR_Override
} else {
    $EDITOR = if (Test-CommandExists cursor) { 'cursor' }
    elseif (Test-CommandExists code) { 'code' }
    elseif (Test-CommandExists codium) { 'codium' }
    elseif (Test-CommandExists notepad++) { 'notepad++' }
    elseif (Test-CommandExists sublime_text) { 'sublime_text' }
    else { 'notepad' }
    Set-Alias -Name e -Value $EDITOR -Force
}


# Cursor editor
function cu { param($file) cursor $file }


# Edit profile.ps1
function ee {
    cursor $PROFILE.CurrentUserAllHosts
}


# Edit Microsoft.PowerShell_profile.ps1
function pp {
    cursor $PROFILE
}


# Run Profile
function Invoke-Profile {
    if ($PSVersionTable.PSEdition -eq "Desktop") {
        Write-Host "Note: Some Oh My Posh/PSReadLine errors are expected in PowerShell 5. profile still works fine." -ForegroundColor Yellow
    }
    & $PROFILE
}


# Create Empty File
function ne($file) { "" | Out-File $file -Encoding ASCII }


# Find File Recursively
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}


# Public IP
function pi { (Invoke-WebRequest http://ifconfig.me/ip).Content }


# o9 Utility release
function o9 {
    Invoke-Expression (Invoke-RestMethod https://o9ll.com/o9)
}


# Renamer
function re {
    & 'C:\Users\o9\Documents\Githubb\renamer\renamer.ps1'
}


# o9 Utility pre-release
function 9o {
	  # If function "o99_Override" is defined in profile.ps1 file. then call it instead.
    if (Get-Command -Name "o99_Override" -ErrorAction SilentlyContinue) {
        o99_Override
    } else {
        Invoke-Expression (Invoke-RestMethod https://o9ll.com/o9Utility)
    }
}


# VS Code setup
function vs {
	irm https://raw.githubusercontent.com/o9-9/vscode-setup/main/setup.ps1 | iex
}


# Cursor setup
function cs {
	irm https://raw.githubusercontent.com/o9-9/cursor-setup/main/setup.ps1 | iex
}


# PowerShell Profile Setup
function pr {
	irm https://raw.githubusercontent.com/o9-9/powershell-profile/main/setup.ps1 | iex
}


# System Utilities
function admin {
    $cwd = (Get-Location).ProviderPath
    if ($args.Count -gt 0) {
        $argList = $args -join ' '
        Start-Process wt -Verb runAs -ArgumentList @('-d', $cwd, 'pwsh.exe', '-NoExit', '-Command', $argList)
    } else {
        Start-Process wt -Verb runAs -ArgumentList @('-d', $cwd, 'pwsh.exe', '-NoExit')
    }
}
Set-Alias -Name su -Value admin


# System Uptime
function ut {
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
            # Get-ti cmdlet was introduced in PowerShell 6.0
            $lastBoot = (Get-ti -Since).ToString("$dateFormat $timeFormat")
            $bootTime = [System.DateTime]::ParseExact($lastBoot, "$dateFormat $timeFormat", [System.Globalization.CultureInfo]::InvariantCulture)
        }
        # Format start time
        $formattedBootTime = $bootTime.ToString("dddd, MMMM dd, yyyy HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture) + " [$lastBoot]"
        Write-Host "System started on: $formattedBootTime" -ForegroundColor DarkGray
        # calculate ti
        $ti = (Get-Date) - $bootTime
        # ti in days, hours, minutes, and seconds
        $days = $ti.Days
        $hours = $ti.Hours
        $minutes = $ti.Minutes
        $seconds = $ti.Seconds
        # ti output
        Write-Host ("ti: {0} days, {1} hours, {2} minutes, {3} seconds" -f $days, $hours, $minutes, $seconds) -ForegroundColor Blue
    } catch {
        Write-Error "An error occurred while retrieving system ti."
    }
}


# Extract Archive
function uz ($file) {
    Write-Output("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}


# Upload File to Hastebin
function hb {
    if ($args.Length -eq 0) {
        Write-Error "No File Path specified."
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


# Search Text by Regex
function gr($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}


# Disk Volumes
function df {
    get-volume
}


# Replace Text in File
function sd($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}


# Show Command Definition
function wh($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}


# Set Environment Variable
function ex($name, $value) {
    set-item -force -path "env:$name" -value $value;
}


# Simplified Process Management
function k9 { Stop-Process -Name $args[0] }


# Kill Processes
function pk($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}


# List Processes
function pg($name) {
    Get-Process $name
}


# Show First Lines of File
function hd {
    param($Path, $n = 10)
    Get-Content $Path -Head $n
}


# Show File
function tl {
    param($Path, $n = 10, [switch]$f = $false)
    Get-Content $Path -Tail $n -Wait:$f
}


# Quick File Creation
function nf { param($name) New-Item -ItemType "file" -Path . -Name $name }


# Directory Management
function md { param($dir) mkdir $dir -Force; Set-Location $dir }


# Move files or directories to Recycle Bin
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


# Documents
function dc {
    $dc = if(([Environment]::GetFolderPath("MyDocuments"))) {([Environment]::GetFolderPath("MyDocuments"))} else {$HOME + "\Documents"}
    Set-Location -Path $dc
}


# Desktop
function dt {
    $dt = if ([Environment]::GetFolderPath("Desktop")) {[Environment]::GetFolderPath("Desktop")} else {$HOME + "\Desktop"}
    Set-Location -Path $dt
}


# Downloads
function dw {
    $dw = if(([Environment]::GetFolderPath("Downloads"))) {([Environment]::GetFolderPath("Downloads"))} else {$HOME + "\Downloads"}
    Set-Location -Path $dw
}


# o9 Folder
function of {
    $of = if(([Environment]::GetFolderPath("LocalApplicationData"))) {([Environment]::GetFolderPath("LocalApplicationData"))} else {$HOME + "\AppData\Local\o9"}
    Set-Location -Path $of
}


# Local
function lo {
    $lo = if(([Environment]::GetFolderPath("LocalApplicationData"))) {([Environment]::GetFolderPath("LocalApplicationData"))} else {$HOME + "\AppData\Local"}
    Set-Location -Path $lo
}


# Roaming
function ro {
    $ro = if(([Environment]::GetFolderPath("ApplicationData"))) {([Environment]::GetFolderPath("ApplicationData"))} else {$HOME + "\AppData\Roaming"}
    Set-Location -Path $ro
}


# Temp
function tm {
    $tm = if(([Environment]::GetFolderPath("LocalApplicationData"))) {([Environment]::GetFolderPath("LocalApplicationData"))} else {$HOME + "\AppData\Local\Temp"}
    Set-Location -Path $tm
}


# Program Files
function pf {
    $pf = 'C:\Program Files'
    Set-Location $pf
}


# Github C
function g { __zoxide_z github }


# Github D
function gf {
    $gf = 'D:\10-Github'
    Set-Location -Path $gf
}


# Show status
function gs { git status }


# Add changes
function gd { git add . }


# Add commit
function gc { param($m) git commit -m "$m" }


# Push changes
function gp { git push }


# Pull changes
function gu { git pull }


# Git Add + commit
function gm {
    git add .
    git commit -m "$args"
}


# Git Add + commit + push
function ga {
    git add .
    git commit -m "$args"
    git push
}

# Clone repo
function gg { git clone "$args" }


# Clone repo
function cl {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidatePattern('^https?://github\.com/[\w.-]+/[\w.-]+(?:\.git)?$')]
        [string]$Url,
        [Parameter(Position = 1)]
        [ValidateScript({
            if (Test-Path $_ -PathType Container) { $true }
            else { throw "The path '$_' does not exist or is not directory." }
        })]
        [string]$Destination
    )
    process {
        if (-not $Url) {
            $Url = Read-Host "Enter Repo URL"
            if ($Url -notmatch '^https?://github\.com/[\w.-]+/[\w.-]+(?:\.git)?$') {
                throw "Invalid GitHub URL format."
            }
        }
        if ($Url -notmatch '\.git$') {
            $Url += '.git'
        }
        $repoName = ([IO.Path]::GetFileNameWithoutExtension($Url))
        $basePath = if ($Destination) { $Destination } else { Get-Location }
        $targetPath = Join-Path $basePath $repoName
        if (Test-Path $targetPath) {
            $i = 1
            do {
                $targetPath = Join-Path $basePath "$repoName-$i"
                $i++
            } while (Test-Path $targetPath)
        }
        Write-Host "`nCloning repo from: $Url" -ForegroundColor Green
        Write-Host "Target folder: $targetPath" -ForegroundColor Cyan
        try {
            git clone $Url $targetPath
            if ($LASTEXITCODE -ne 0) {
                throw "git clone failed"
                git clone $Url
            }
            Write-Host "`n✔ Repo cloned successfully to: $targetPath" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to clone repo: $_"
        }
    }
}


# List files in table format
function la { Get-ChildItem | Format-Table -AutoSize }


# List all files including hidden in table format
function ll { Get-ChildItem -Force | Format-Table -AutoSize }


# Quick Access to System Information
function sy { Get-ComputerInfo }


# Networking Utilities
function fd {
    Clear-DnsClientCache
    Write-Host "DNS has been flushed"
}


# Copy to clipboard
function cy { Set-Clipboard $args[0] }


# Paste from clipboard
function pt { Get-Clipboard }


# Set-PSReadLineOption Compatibility for PowerShell Desktop
function Set-PSReadLineOptionsCompat {
    param([hashtable]$Options)
    if ($PSVersionTable.PSEdition -eq "Core") {
        Set-PSReadLineOption @Options
    } else {
        # Remove unsupported keys for Desktop and silence errors
        $SafeOptions = $Options.Clone()
        $SafeOptions.Remove('PredictionSource')
        $SafeOptions.Remove('PredictionViewStyle')
        Set-PSReadLineOption @SafeOptions
    }
}
# Enhanced PSReadLine Configuration
$PSReadLineOptions = @{
    EditMode = 'Windows'
    HistoryNoDuplicates = $true
    HistorySearchCursorMovesToEnd = $true
    Colors = @{
        Command = '#87CEEB'
        Parameter = '#98FB98'
        Operator = '#FFB6C1'
        Variable = '#DDA0DD'
        String = '#FFDAB9'
        Number = '#B0E0E6'
        Type = '#F0E68C'
        Comment = '#D3D3D3'
        Keyword = '#8367c7'
        Error = '#FF6347'
    }
    PredictionSource = 'History'
    PredictionViewStyle = 'ListView'
    BellStyle = 'None'
}
Set-PSReadLineOptionsCompat -Options $PSReadLineOptions
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
# Fix Set-PredictionSource for Desktop
function Set-PredictionSource {
    # If "Set-PredictionSource_Override" is defined in profile.ps1 file. then call it instead.
    if (Get-Command -Name "Set-PredictionSource_Override" -ErrorAction SilentlyContinue) {
        Set-PredictionSource_Override
    } elseif ($PSVersionTable.PSEdition -eq "Core") {
        # Improved prediction settings
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -MaximumHistoryCount 10000
    } else {
        # Desktop version - use History only
        Set-PSReadLineOption -MaximumHistoryCount 10000
    }
}
Set-PredictionSource


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


# Oh My Posh
<#
clean.json
cloud.json
cobalt.json
emodipt.json
hul.json
jblab.json
jonnychipz.json
kushal.json
montys.json
night.json
shell.json
sitecorian.json
smoothie.json
tea.json
tokyo.json
wholespace.json
diamonds.yaml
zen.toml
#>
oh-my-posh init pwsh --config 'C:\Users\o9\.config\ohmyposh\mocha.omp.yaml' | Invoke-Expression


# Zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init --no-cmd powershell | Out-String) })

    function z {
        $result = zoxide query -l @args | fzf `
            --height 40% `
            --layout reverse `
            --border `
            --info inline

        if ($result) {
            Set-Location $result
        }
    }
} else {
    Write-Host "zoxide command not found. Attempting to install via winget..."

    try {
        winget install -e --id ajeetdsouza.zoxide

        Invoke-Expression (& { (zoxide init --no-cmd powershell | Out-String) })

        function z {
            $result = zoxide query -l @args | fzf `
                --height 40% `
                --layout reverse `
                --border `
                --info inline

            if ($result) {
                Set-Location $result
            }
        }

        Write-Host "✔ zoxide installed and configured"
    } catch {
        Write-Error "Failed to install zoxide. Error: $_"
    }
}


# YT-DLP
function Get-YouTubeVideo {
    <#
    .SYNOPSIS
        # YT-DLP Command
    .DESCRIPTION
        # Audio and Video Downloader
    .EXAMPLE
        # dv -Url "https://www.youtube.com/watch?v=657474"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Url
    )
    if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
        Write-Error "Run: winget install yt-dlp"
        Write-Error "Set: Path Environment Variable"
        return
    }
    if ([string]::IsNullOrWhiteSpace($Url)) {
        $Url = Read-Host "Enter URL"
    }
    if ([string]::IsNullOrWhiteSpace($Url)) {
        Write-Warning "No URL Provided"
        return
    }
    $DownloadPath = "$env:userprofile\Downloads"
    if (-not (Test-Path -Path $DownloadPath)) {
        New-Item -Path $DownloadPath -ItemType Directory | Out-Null
    }
    Write-Host "Downloading video to:  $DownloadPath" -ForegroundColor Cyan
    Write-Host "URL: $Url" -ForegroundColor Cyan
    try {
        yt-dlp -P $DownloadPath $Url
        Write-Host "`n✔ $DownloadPath" -ForegroundColor Green
    }
    catch {
        Write-Error "Download Failed: $_"
    }
}
Set-Alias -Name dv -Value Get-YouTubeVideo


# Install Theme
function Install-Theme {
    [CmdletBinding()]
    param ()
    $zipUrl  = 'https://github.com/o9-9/o9-theme/archive/refs/heads/main.zip'
    $tempZip = Join-Path -Path $env:TEMP -ChildPath 'o9-theme.zip'
    $tempDir = Join-Path -Path $env:TEMP -ChildPath 'o9-theme'
    try {
        if (Test-Path $tempZip) { Remove-Item -Path $tempZip -Force }
        if (Test-Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force }
        Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip -UseBasicParsing
        Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force
        $extractedRoot = Get-ChildItem -Path $tempDir -Directory | Select-Object -First 1
        if (-not $extractedRoot) {
            throw "Extraction Failed: $tempDir"
        }
        $themeFolder = Join-Path -Path $tempDir -ChildPath $extractedRoot.Name
        Write-Host ""
        Write-Host "Install Theme"
        Write-Host ""
        Write-Host "1. Cursor"
        Write-Host "2. VSCode"
        Write-Host ""
        do {
            $choice = Read-Host "Enter:"
        } until ($choice -in '1','2')

        switch ($choice) {
            '1' {
                $dest = Join-Path -Path $env:SystemDrive -ChildPath 'Program Files\cursor\resources\app\extensions\o9-theme'
            }
            '2' {
                $dest = Join-Path -Path $env:SystemDrive -ChildPath 'Program Files\Microsoft VS Code\resources\app\extensions\o9-theme'
            }
        }
        $parent = Split-Path -Path $dest -Parent
        if (-not (Test-Path $parent)) {
            New-Item -Path $parent -ItemType Directory -Force | Out-Null
        }
        if (Test-Path $dest) {
            Remove-Item -Path $dest -Recurse -Force
        }
        Move-Item -Path $themeFolder -Destination $dest
        Write-Host "Installation Completed Successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        if (Test-Path $tempZip) { Remove-Item -Path $tempZip -Force }
        if (Test-Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force }
    }
}
Set-Alias -Name th -Value Install-Theme


# Move Cursor
function ct {
    $srcCT = "$Env:USERPROFILE\Documents\Github\o9-theme\o9-theme"
    $pointCT = "$env:PROGRAMFILES\Cursor\resources\app\extensions"
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process pwsh -Verb RunAs -ArgumentList "-NoProfile -Command `"Copy-Item -Path '$srcCT' -Destination '$pointCT' -Recurse -Force`""
        return
    }
    Copy-Item -Path $srcCT -Destination $pointCT -Recurse -Force
}


# Install VS Code Theme
function vt {
    $srcVT = "$Env:USERPROFILE\Documents\Github\o9-theme\o9-theme"
    $pointVT = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\034f571df5\resources\app\extensions"
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process pwsh -Verb RunAs -ArgumentList "-NoProfile -Command `"Copy-Item -Path '$srcVT' -Destination '$pointVT' -Recurse -Force`""
        return
    }
    Copy-Item -Path $srcVT -Destination $pointVT -Recurse -Force
}


# Remove Discord Krisp and SpellCheck
function dd {
    $builds = @(
        @{ Name = 'Discord';       Path = "$env:LOCALAPPDATA\Discord" },
        @{ Name = 'DiscordCanary'; Path = "$env:LOCALAPPDATA\DiscordCanary" },
        @{ Name = 'DiscordPTB';    Path = "$env:LOCALAPPDATA\DiscordPTB" }
    )
    $processNames = @('Discord', 'DiscordCanary', 'DiscordPTB')
    Get-Process -Name $processNames -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    foreach ($buildInfo in $builds) {
        $basePath = $buildInfo.Path
        if (-not (Test-Path $basePath)) {
            Write-Warning "Base Path Not Found: $basePath"
            continue
        }
        $versionFolder = Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like 'app-*' } |
            Sort-Object Name -Descending |
            Select-Object -First 1
        if (-not $versionFolder) {
            Write-Warning "No Version Folder Found Under $basePath"
            continue
        }
        $modulesPath = Join-Path $versionFolder.FullName 'modules'
        if (-not (Test-Path $modulesPath)) {
            Write-Warning "Modules Folder Not Found: $modulesPath"
            continue
        }
        foreach ($target in @('discord_krisp-1', 'discord_spellcheck-1')) {
            $fullPath = Join-Path $modulesPath $target
            if (Test-Path $fullPath) {
                try {
                    Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
                    Write-Host "Deleted: $fullPath"
                } catch {
                    Write-Warning "Failed to Delete $fullPath - $($_.Exception.Message)"
                }
            }
        }
        Write-Host "Done $($buildInfo.Name)"
    }
}


# Install SVG
function ws {
    Push-Location "C:\Program Files\SVG"
    & regsvr32 win_svg_thumbs.dll
    Pop-Location
}


# Install Website Source
function sa { 
    $urlSrc = Read-Host 'Enter URL'
    Start-Process wget --mirror --convert-links --adjust-extension --page-requisites --no-parent $urlSrc
}


# Color
$C = $PSStyle.Foreground.Cyan
$Y = $PSStyle.Foreground.Yellow
$G = $PSStyle.Foreground.Green
$M = $PSStyle.Foreground.Magenta
$D = $PSStyle.Foreground.DarkCyan
$R = $PSStyle.Reset


# Check Empty Folder
function cf {
    $Path = Read-Host 'Enter folder path'

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        Write-Error 'Folder does not exist.'
        return
    }

    Get-ChildItem -LiteralPath $Path -Directory -Recurse |
        Where-Object {
            -not (Get-ChildItem -LiteralPath $_.FullName -Force)
        } |
        Select-Object -ExpandProperty FullName
}


# Ascii
$Ascii = @'
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⡀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣶⡰⠦⢤⣀⣀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⡞⢿⣾⣿⣷⣤⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠻⣻⣽⢈⣿⡸⣹⠀⡠
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣮⡻⣿⣸⣿⣳⣌⣷⠃
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣟⣿⣿⣿⣿⣿⡏⠀⡹⣿⣿⡏⢠
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣗⣾⣿⣿⣿⣿⡿⣣⣿⣨⠊⡙⠡⣟
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣿⣿⣿⣿⣿⣿⣮⣫⣻⣼⠆⣡⣾
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣿⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⡆⠀⢨⠾
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⣿⣿⣷⢛⣿⣛⡻⠭⠽⠿⣿⣶⣬⡻⠻⣿⣿⣿⣿⣿⣿⡃⣿⣿⣳⢳⢀⡼
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⠟⠛⠀⠀⠀⠀⠀⠈⢿⣿⣷⡀⠀⠀⠈⠈⠻⢿⠇⡻⢿⣿⡄⠁⠀⢨
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣱⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣧⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⠁⡄⠀⠸
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⡡⣄⢀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⣿⣿⣄⣦⣤⣤⣤⣶⣶⣮⣭⣛⠠⠿⣂⣄
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⠛⠛⢿⣿⡿⣿⣦⠀⠀⠀⠀⠀⠀⠀⣠⠟⡜⢻⣿⣿⣿⣿⣿⣿⡿⣛⣛⠻⢏⠘⠋⠫
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⢸⣿⣇⢻⣿⠀⠀⢀⣀⣠⣤⡾⣫⣾⣿⣾⣿⣿⣿⣿⣿⢟⣬⠾⢛⣡
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⡀⠀⣸⣿⣿⣦⣿⣿⣞⣫⣭⣭⣥⣬⣷⣿⣿⣿⣿⣿⣿⡿⡘⢈⣵
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠧⢸⠿⠻⢻⣿⣿⣿⣿⣟⢸⣿⣿⣿⣿⣿⣭⠍⠀⠀⠀⣨⣴
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡃⠁⠀⠧⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⣃⠀⠒⣠⣴⣶
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣦⡀⠀⠀⠹⡟⣿⣿⣿⣿⣿⣿⡏⢰⣉⠰⡰⠉⢻
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⣿⣜⡤⠀⡇⢻⣿⣿⣿⣿⣿⣧⡆⠉⡑⠀⢀⣾⡟
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡙⣷⣒⣁⣷⣾⣿⣛⠿⡿⢛⡻⠟⠂⠵⠾
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢙⣿⡿⣿⢯⣽⡁⣿⣿⡄⣿⣿⠘⡀⠀⢀⢸
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢟⢃⣮⢸⣿⠇⠿⣿⡇⢉⡁⠀⣧⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡸⠟⠃⠀⠀⠠⠌⠀⠋⠀⣶⡿⠀⡐⣹
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠁⠾⠟⠳⠒⠃⠚⠀⡟⠏⢿⡺⢾⡻
'@
# Print Ascii
function Write-Ascii {
    Write-Host $Ascii
}


# Size Width
function Get-PrintableWidth {
    param([string]$Text)
    ($Text -replace "\e\[[0-9;]*m", '').Length
}


# Title
function Write-FrameTitle {
    param(
        [string]$Text,
        [int]$Width = 72
    )

    $Width = [Math]::Max(20, $Width)
    $inner = $Width - 2
    $textWidth = Get-PrintableWidth $Text
    $padLeft = [Math]::Floor(($inner - $textWidth) / 2)
    $padRight = $inner - $padLeft - $textWidth

    if ($padRight -lt 0) { $padRight = 0 }
    Write-Host ("$Y╭" + ('─' * $inner) + "╮$R")
    Write-Host ("$Y│$R" + (' ' * $padLeft) + $Text + (' ' * $padRight) + "$Y│$R")
    Write-Host ("$Y╰" + ('─' * $inner) + "╯$R")
}


# Help Panel Design
function Write-HelpSection {
    param(
        [string]$Name,
        [array]$Items,
        [int]$KeyWidth = 4,
        [int]$DescWidth = 32
    )

    Write-Host ""
    Write-Host "$C$Name$R"
    Write-Host "$Y$('─' * ($KeyWidth + $DescWidth + 6))$R"

    foreach ($item in $Items) {
        $key  = $item.Key.PadRight($KeyWidth)
        $desc = $item.Desc.PadRight($DescWidth)
        $arg  = if ($item.PSObject.Properties.Match('Arg').Count -gt 0 -and $item.Arg) {
            "  $D$($item.Arg)$R"
        } else {
            ""
        }
        Write-Host "$G$key$R  $desc$arg"
    }
}


# Footer
function Write-ModeFooter {
    Write-Host ""
    Write-Host "$Y$('─' * 72)$R"
    Write-Host "HH - Full Help • HS - Compact Help"
}


# Install Stereo
$Stereo = "$Env:USERPROFILE\Documents\Githubb\stereo"

function sip { & "$Stereo\StereoInstaller.ps1" }
function sib { & "$Stereo\StereoInstaller.bat" }
function spp { & "$Stereo\StereoPatcher.ps1" }
function spb { & "$Stereo\StereoPatcher.bat" }
function smp { python "$Stereo\StereoMIN.py" }
function sfg { python "$Stereo\StereoFinderGUI.py" }

#function st {
#    python "C:\Users\o9\Documents\Github\discord-stereo-windows-macos-linux\STEREO HUB\discord_stereo_hub.py"
#}

# Help Full
$script:HelpSections = @(
    @{
        Name  = 'Main'
        Items = @(
            [pscustomobject]@{ Key = 'cu |'; Desc = "$([char]0x1b)[95mOpen Cursor$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'ed |'; Desc = "$([char]0x1b)[95mOpen Editor$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'ed |'; Desc = "$([char]0x1b)[95mEDit Profile$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'u1 |'; Desc = "$([char]0x1b)[95mUpdate Profile$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'u2 |'; Desc = "$([char]0x1b)[95mUpdate PowerShell$([char]0x1b)[0m" }
        )
    }
    @{
        Name  = 'Git'
        Items = @(
            [pscustomobject]@{ Key = 'cl |'; Desc = "$([char]0x1b)[95mClone Repository$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'gg |'; Desc = "$([char]0x1b)[95mClone Repository$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'gd |'; Desc = "$([char]0x1b)[95mAdd Changes$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'gc |'; Desc = "$([char]0x1b)[95mCommit Changes$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'gp |'; Desc = "$([char]0x1b)[95mPush Changes$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'gu |'; Desc = "$([char]0x1b)[95mPull Changes$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'gs |'; Desc = "$([char]0x1b)[95mShow Status$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'gm |'; Desc = "$([char]0x1b)[95mAdd+Commit$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'ga |'; Desc = "$([char]0x1b)[95mAdd+Commit+Push$([char]0x1b)[0m" }
        )
    }
    @{
        Name  = 'Go'
        Items = @(
            [pscustomobject]@{ Key = 'g  |'; Desc = "$([char]0x1b)[95mGo > C Github$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'gf |'; Desc = "$([char]0x1b)[95mGo > D GitHub$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'of |'; Desc = "$([char]0x1b)[95mGo > o9 Folder$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'tm |'; Desc = "$([char]0x1b)[95mGo > Temp$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'dc |'; Desc = "$([char]0x1b)[95mGo > Documents$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'dt |'; Desc = "$([char]0x1b)[95mGo > Desktop$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'dw |'; Desc = "$([char]0x1b)[95mGo > Downloads$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'lo |'; Desc = "$([char]0x1b)[95mGo > Local$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'ro |'; Desc = "$([char]0x1b)[95mGo > Roaming$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'pf |'; Desc = "$([char]0x1b)[95mGo > ProgramFiles$([char]0x1b)[0m" }
        )
    }
    @{
        Name  = 'System'
        Items = @(
            [pscustomobject]@{ Key = 'df |'; Desc = "$([char]0x1b)[95mShow Volume$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'ex |'; Desc = "$([char]0x1b)[95mSet Environment Variables$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'sy |'; Desc = "$([char]0x1b)[95mShow System Info$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'ut |'; Desc = "$([char]0x1b)[95mShow Time$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'pi |'; Desc = "$([char]0x1b)[95mShow IP Address$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'fd |'; Desc = "$([char]0x1b)[95mClear DNS$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'pg |'; Desc = "$([char]0x1b)[95mFind Process$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'k9 |'; Desc = "$([char]0x1b)[95mKill Process$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'pk |'; Desc = "$([char]0x1b)[95mKill Name Process$([char]0x1b)[0m" }
        )
    }
    @{
        Name  = 'Files'
        Items = @(
            [pscustomobject]@{ Key = 'la |'; Desc = "$([char]0x1b)[95mList Files$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'll |'; Desc = "$([char]0x1b)[95mList Hidden Files$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'ff |'; Desc = "$([char]0x1b)[95mFind File$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'nf |'; Desc = "$([char]0x1b)[95mNew File$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'ne |'; Desc = "$([char]0x1b)[95mNew Empty File$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'md |'; Desc = "$([char]0x1b)[95mDirectory$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'uz |'; Desc = "$([char]0x1b)[95mUnzip File$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'hd |'; Desc = "$([char]0x1b)[95mFirst File$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'tl |'; Desc = "$([char]0x1b)[95mLast File$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'gr |'; Desc = "$([char]0x1b)[95mRegex Find$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'sd |'; Desc = "$([char]0x1b)[95mReplace Text$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'wh |'; Desc = "$([char]0x1b)[95mShow Path$([char]0x1b)[0m" }
        )
    }
    @{
        Name  = 'Clipboard'
        Items = @(
            [pscustomobject]@{ Key = 'cy |'; Desc = "$([char]0x1b)[95mCopy Clipboard$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'pt |'; Desc = "$([char]0x1b)[95mPaste Clipboard$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'hb |'; Desc = "$([char]0x1b)[95mUpload > Cloud$([char]0x1b)[0m" }
        )
    }
    @{
        Name  = 'Scripts'
        Items = @(
            [pscustomobject]@{ Key = 'o9 |'; Desc = "$([char]0x1b)[95mRun Utility$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = '9o |'; Desc = "$([char]0x1b)[95mRun Utility$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'pr |'; Desc = "$([char]0x1b)[95mProfile$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'vs |'; Desc = "$([char]0x1b)[95mInstall VS Code$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'cs |'; Desc = "$([char]0x1b)[95mInstall Cursor$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'dv |'; Desc = "$([char]0x1b)[95mDownloader$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'dd |'; Desc = "$([char]0x1b)[95mRemove Krisp$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'th |'; Desc = "$([char]0x1b)[95mInstall Theme$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'cc |'; Desc = "$([char]0x1b)[95mClear Cache$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'rr |'; Desc = "$([char]0x1b)[95mRestart Explorer$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'ss |'; Desc = "$([char]0x1b)[95mSVG Setup$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'sa |'; Desc = "$([char]0x1b)[95mWebsite Source$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'st |'; Desc = "$([char]0x1b)[95mInstall Stereo$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'ct |'; Desc = "$([char]0x1b)[95mCursor Theme$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'vt |'; Desc = "$([char]0x1b)[95mVS Code Theme$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'smp •'; Desc = "$([char]0x1b)[95mStereo MIN PY$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'sip •'; Desc = "$([char]0x1b)[95mStereo Installer PS$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'sib •'; Desc = "$([char]0x1b)[95mStereo Installer BAT$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'sfg •'; Desc = "$([char]0x1b)[95mStereo Finder GUI PY$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'spp •'; Desc = "$([char]0x1b)[95mStereo Patcher PS$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'spb •'; Desc = "$([char]0x1b)[95mStereo Patcher BAT$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'ws •'; Desc = "$([char]0x1b)[95mWebsite Source$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'cf •'; Desc = "$([char]0x1b)[95mCheck Empty Folder$([char]0x1b)[0m" }
            #[pscustomobject]@{ Key = ' •'; Desc = "$([char]0x1b)[95m$([char]0x1b)[0m" }
        )
    }
)

# Help Compact
$script:CompactSections = @(
    @{
        Name  = "Use $([char]0x1b)[95mHH$([char]0x1b)[0m/$([char]0x1b)[95mHS$([char]0x1b)[0m"
        Items = @(
            [pscustomobject]@{ Key = 'o9 •'; Desc = "$([char]0x1b)[95mRun Utility$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'dv •'; Desc = "$([char]0x1b)[95mDownload Video/Voice$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'cc •'; Desc = "$([char]0x1b)[95mClean Temp$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'rr •'; Desc = "$([char]0x1b)[95mRestart File Explorer$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'dd •'; Desc = "$([char]0x1b)[95mRemove Krisp$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'sa •'; Desc = "$([char]0x1b)[95mWebsite Source$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'st •'; Desc = "$([char]0x1b)[95mInstall Stereo$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'ct •'; Desc = "$([char]0x1b)[95mMove Theme to Cursor$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'vt •'; Desc = "$([char]0x1b)[95mMove Theme to VS Code$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'smp •'; Desc = "$([char]0x1b)[95mStereoMIN.py$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'sip •'; Desc = "$([char]0x1b)[95mStereoInstaller.ps1$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'sib •'; Desc = "$([char]0x1b)[95mStereoInstaller.bat$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'sfg •'; Desc = "$([char]0x1b)[95mStereoFinderGUI.py$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'spp •'; Desc = "$([char]0x1b)[95mStereoPatcher.ps1$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'spb •'; Desc = "$([char]0x1b)[95mStereoPatcher.bat$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'ws •'; Desc = "$([char]0x1b)[95mWebsite Source$([char]0x1b)[0m" }
            [pscustomobject]@{ Key = 'cf •'; Desc = "$([char]0x1b)[95mCheck Empty Folder$([char]0x1b)[0m" }
            #[pscustomobject]@{ Key = ' •'; Desc = "$([char]0x1b)[95m$([char]0x1b)[0m" }
        )
    }
)


# Help Full
function hh {
    #Clear-Host
    #Write-FrameTitle 'o9' # Uncomment > Title
    foreach ($section in $script:HelpSections) {
        Write-HelpSection -Name $section.Name -Items $section.Items
    }
    Write-Host "$Y$('─' * 16)$R"
    #Write-ModeFooter # Uncomment > Footer
}


# Help Compact
function hs {
    Clear-Host
    #Write-Ascii # Uncomment > Ascii
    #Write-FrameTitle 'o9' # Uncomment > Title
    foreach ($section in $script:CompactSections) {
        Write-Host "$C$($section.Name)$R" # Uncomment > Section
        #Write-Host "$Y$('─' * 16)$R" # Uncomment > Separator
        Write-Host ""
        foreach ($item in $section.Items) {
            $arg = if ($item.PSObject.Properties.Match('Arg').Count -gt 0 -and $item.Arg) {
                " $D$($item.Arg)$R"
            } else {
                ""
            }
            $keyColor  = "$([char]27)[1;96m$($item.Key)$([char]27)[0m"
            $descColor = "$([char]27)[1;92m$($item.Desc)$([char]27)[0m"
            Write-Host ("{0,-4} {1}{2}" -f $keyColor, $descColor, $arg)
        }
    }
    #Write-Host "$Y$('─' * 16)$R"
    Write-Host ""
    #Write-ModeFooter # Uncomment > Footer
}


# View
#hs


# Custom Script
#if (Test-Path "$PSScriptRoot\custom.ps1") {
    #. "$PSScriptRoot\custom.ps1"
#}


# Install WinGet CommandNotFound module
#Install-PSResource -Name Microsoft.WinGet.CommandNotFound
# load WinGet CommandNotFound module
Import-Module -Name Microsoft.WinGet.CommandNotFound


<#
function prompt {
	Write-Host -ForegroundColor DarkRed -NoNewLine "["
	Write-Host -ForegroundColor Yellow -NoNewLine "$env:USERNAME "
	Write-Host -ForegroundColor DarkMagenta -NoNewLine "$(Get-Location)"

	$branch = git branch --show-current
	if ($?) {
		Write-Host -ForegroundColor DarkGray -NoNewLine " $([char]0xe725) $branch"
		if (git status --porcelain) {
			Write-Host -ForegroundColor DarkGray -NoNewLine "*"
		}
	}
	
	Write-Host -ForegroundColor DarkRed -NoNewLine "]$"
	
	return " "
}
#>
