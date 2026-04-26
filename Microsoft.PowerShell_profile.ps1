<#
.SYNOPSIS
    PowerShell Profile Refactor
    Version 1.00
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
    if ([datetime]::TryParseExact($lastExecRaw, 'yyyy-MM-dd', $null, [System.Globalization.DateTimeStyles]::None, [ref]$parsed)) {
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
    $currentTime = Get-Date -Format 'yyyy-MM-dd'
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
    $currentTime = Get-Date -Format 'yyyy-MM-dd'
    $currentTime | Out-File -FilePath $timeFilePath
} elseif ($debug) {
    Write-Warning "Skipping o9 PowerShell update in debug mode"
}

# Cleanup cache
function Clear-Cache {
    if (Get-Command -Name "Clear-Cache_Override" -ErrorAction SilentlyContinue) {
        Clear-Cache_Override
    } else {
        # Add clear cache logic here
        Write-Host "Clearing cache..." -ForegroundColor Cyan
        # Clear Windows Prefetch
        Write-Host ""
        Write-Host "Clearing Windows Prefetch..." -ForegroundColor Cyan
        Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue
        # Clear Windows Temp
        Write-Host ""
        Write-Host "Clearing Windows Temp..." -ForegroundColor Cyan
        Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        # Clear User Temp
        Write-Host ""
        Write-Host "Clearing User Temp..." -ForegroundColor Cyan
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        # Clear Internet Explorer Cache
        Write-Host ""
        Write-Host "Clearing Internet Explorer Cache..." -ForegroundColor Cyan
        Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host ""
        Write-Host "Cache clearing completed." -ForegroundColor Green
        # Run Disk Cleanup on Drive C
        Write-Host ""
        Write-Host "Running Disk Cleanup on Drive C..." -ForegroundColor Cyan
        cleanmgr.exe /d C: /VERYLOWDISK
        Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
        Write-Host ""
        Write-Host "Cleanup completed." -ForegroundColor Green
        # Remove icon cache
        Write-Host ""
        Write-Host "Remove icon cache..." -ForegroundColor Cyan
        Stop-Process -Name explorer -Force
        Remove-Item -Path "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*" -Force -ErrorAction SilentlyContinue
        Start-Process explorer.exe
        Write-Host ""
        Write-Host "Remove icon completed." -ForegroundColor Green
    }
}
Set-Alias -Name cc -Value Clear-Cache

# Function to restart Windows Explorer
function Restarts-Explorer {
        # Stop Windows Explorer
        Stop-Process -Name explorer -Force
        # Restart Windows Explorer
        Start-Process explorer.exe
}
Set-Alias -Name rr -Value Restarts-Explorer

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
function Open-InCursor { param($file) cursor $file }
Set-Alias -Name c -Value Open-InCursor -Force

# Edit profile.ps1
function ed {
    cursor $PROFILE.CurrentUserAllHosts
}

# Edit Microsoft.PowerShell_profile.ps1
function ce {
    c $PROFILE
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

# o9 Utility pre-release
function 9o {
	  # If function "o99_Override" is defined in profile.ps1 file. then call it instead.
    if (Get-Command -Name "o99_Override" -ErrorAction SilentlyContinue) {
        o99_Override
    } else {
        Invoke-Expression (Invoke-RestMethod https://o9ll.com/o99)
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

# o9 local
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
    $gf = 'C:\Users\o9\Documents\github'
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
function Clone-GitHubRepo {
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
Set-Alias -Name cl -Value Clone-GitHubRepo

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

# If function "Get-Theme_Override" is defined in profile.ps1 file. then call it instead.
if (Get-Command -Name "Get-Theme_Override" -ErrorAction SilentlyContinue) {
    Get-Theme_Override
} else {
    # Oh My Posh initialization with local theme fallback and auto-download
    $localThemePath = Join-Path (Get-ProfileDir) "cobalt2.omp.json"
    if (-not (Test-Path $localThemePath)) {
        # Try to download theme file to detected local path
        $themeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json"
        try {
            Invoke-RestMethod -Uri $themeUrl -OutFile $localThemePath
            Write-Host "✔ Downloaded missing Oh My Posh theme to $localThemePath"
        } catch {
            Write-Warning "Failed to download theme file. Falling back to remote theme. Error: $_"
        }
    }
    if (Test-Path $localThemePath) {
        oh-my-posh init pwsh --config $localThemePath | Invoke-Expression
    } else {
        # Fallback to remote theme if local file doesn't exist
        oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json | Invoke-Expression
    }
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
} else {
    Write-Host "zoxide command not found. Attempting to install via winget..."
    try {
        winget install -e --id ajeetdsouza.zoxide
        Write-Host "✔ zoxide installed successfully. Initializing..."
        Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
    } catch {
        Write-Error "Failed to install zoxide. Error: $_"
    }
}

# YT-DLP for Audio/Video Downloader
# - Example Command: dv -Url "https://www.youtube.com/watch?v=657474"
function Get-YouTubeVideo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Url
    )
    # Check if yt-dlp is available
    if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
        Write-Error "Run: winget install yt-dlp"
        Write-Error "Set: Path Environment Variable"
        return
    }
    # Prompt for URL if not provided
    if ([string]::IsNullOrWhiteSpace($Url)) {
        $Url = Read-Host "Enter URL"
    }
    # Validate URL
    if ([string]::IsNullOrWhiteSpace($Url)) {
        Write-Warning "No URL Provided"
        return
    }
    # Set download path to Desktop
    $DownloadPath = "$env:userprofile\Downloads"
    # Create folder if it doesn't exist
    if (-not (Test-Path -Path $DownloadPath)) {
        New-Item -Path $DownloadPath -ItemType Directory | Out-Null
    }
    Write-Host "Downloading video to:  $DownloadPath" -ForegroundColor Cyan
    Write-Host "URL: $Url" -ForegroundColor Cyan
    # Download video
    try {
        yt-dlp -P $DownloadPath $Url
        Write-Host "`n✔ $DownloadPath" -ForegroundColor Green
    }
    catch {
        Write-Error "Download Failed: $_"
    }
}
Set-Alias -Name dv -Value Get-YouTubeVideo

# Theme Setup
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
        Write-Host "o9 Theme"
        Write-Host ""
        Write-Host "1. Cursor"
        Write-Host "2. VS Code"
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


# Remove Discord Folders (Krisp and SpellCheck)
function Remove-Krisp {
    $builds = @{
        '1' = @{ Name = 'Discord Stable'; Path = "$env:LOCALAPPDATA\Discord" }
        '2' = @{ Name = 'Discord Canary'; Path = "$env:LOCALAPPDATA\DiscordCanary" }
        '3' = @{ Name = 'Discord PTB';    Path = "$env:LOCALAPPDATA\DiscordPTB" }
    }
    while ($true) {
        Write-Host ""
        Write-Host "Delete Krisp and SpellCheck"
      	Write-Host ""
        Write-Host "1. Discord Stable"
        Write-Host "2. Discord Canary"
        Write-Host "3. Discord PTB"
      	Write-Host ""
        Write-Host "4.Exit"
      	Write-Host ""
        $selection = Read-Host "Enter"
        $selection = $selection.Trim()
        if ($selection -eq '4') {
            break
        }
        if (-not $builds.ContainsKey($selection)) {
            Write-Warning "Enter:"
            continue
        }
        $buildInfo = $builds[$selection]
        $basePath = $buildInfo.Path
        if (-not (Test-Path $basePath)) {
            Write-Warning "Base Path Not Found: $basePath"
            continue
        }
        $versionFolder = Get-ChildItem -Path $basePath -Directory |
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
        $targets = @(
            'discord_krisp-1',
            'discord_spellcheck-1'
        )
        foreach ($t in $targets) {
            $fullPath = Join-Path $modulesPath $t
            if (Test-Path $fullPath) {
                try {
                    Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
                    Write-Host "Deleted: $fullPath"
                } catch {
                    Write-Warning "Failed to Delete $fullPath – $($_.Exception.Message)"
                }
            } else {
                Write-Host "Not Present: $fullPath"
            }
        }
        Write-Host "Done $($buildInfo.Name). Menu..."
    }
}
Set-Alias -Name de -Value Remove-Krisp


# SVG
function ss {
    Push-Location "C:\Program Files\SVG"
    & regsvr32 win_svg_thumbs.dll
    Pop-Location
}


# Color
$C = $PSStyle.Foreground.Cyan
$Y = $PSStyle.Foreground.Yellow
$G = $PSStyle.Foreground.Green
$M = $PSStyle.Foreground.Magenta
$D = $PSStyle.Foreground.DarkCyan
$R = $PSStyle.Reset


# Ascii
$Ascii = @'
                ⣀⣤⣶⣶⣶⣶⣦⣤⣀⣀
            ⢀⣴⣿⡿⠛⠉⠙⠛⠛⠛⠛⠻⢿⣿⣷⣄
            ⣼⣿⠋       ⣀⣀⣀⡈⢻⣿⣿⡄
           ⣸⣿⡏   ⣠⣶⣾⣿⣿⣿⠿⠿⠿⢿⣿⣿⣿⣄
           ⣿⣿⠁  ⢰⣿⣿⣯⠁       ⠈⠙⢿⣷⡄
      ⣀⣤⣴⣶⣶⣿⡟   ⢸⣿⣿⣿⣆          ⣿⣷
     ⢰⣿⡟⠋⠉⣹⣿⡇   ⠘⣿⣿⣿⣿⣷⣦⣤⣤⣤⣶⣶⣶⣶⣿⣿
     ⢸⣿⡇  ⣿⣿⡇    ⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿
     ⣸⣿⡇  ⣿⣿⡇     ⠉⠻⠿⣿⣿⣿⣿⡿⠿⠿⠛⢻⣿⡇
     ⣿⣿⠁  ⣿⣿⡇                ⢸⣿⣿⠃
     ⣿⣿   ⣿⣿⡇                ⢸⣿⣿
     ⣿⣿   ⣿⣿⡇                ⢸⣿⣿
     ⢿⣿⡆  ⣿⣿⡇                ⢼⣿⡇
     ⠸⣿⣧⡀ ⣿⣿⡇                ⣿⣿⡇
      ⠛⢿⣿⣿⣿⣿⣇     ⣰⣿⣿⣷⣶⣿⣷⡆  ⣿⣿
           ⣿⣿     ⣿⣿⡇ ⣽⣿⡟⠁  ⢸⣿⡟
           ⣿⣿     ⣿⣿⡇ ⢹⣿⡆   ⣼⣿⡇
           ⢿⣿⣦⣄⣀⣠⣴⣿⣿  ⠈⠻⣿⣿⣿⣿⡿⠇
           ⠈⠛⠻⠿⠿⠿⠿⠋⠁
'@
<#
$Ascii = @'
       ┌────┬───────────┬────┬───────────────┬────┬──────────────┐
       │ c  │ Cursor    │ o9 │ Utility       │ ll │ Hidden       │
       │ vs │ VS Code   │ e  │ Editor        │ dc │ Documents    │
       │ ff │ Find      │ cs │ Cursor        │ ed │ Edit Profile │
       │ dt │ Desktop   │ nf │ File          │ dv │ Downloader   │
       │ u1 │ UProfile  │ dw │ Downloads     │ ne │ Empty        │
       │ de │ krisp     │ u2 │ UPowershell   │ lo │ Local        │
       │ md │ Directory │ th │ Theme         │ cl │ Clone        │
       │ ro │ Roaming   │ uz │ Unzip         │ cc │ Clearup      │
       │ gg │ Clone     │ pf │ Program Files │ hd │ First        │
       │ rr │ Restart   │ gd │ Add           │ df │ Volume       │
       │ tl │ Last      │ gc │ Commit        │ ex │ Environment  │
       │ gr │ Regex     │ gp │ Push          │ sy │ System       │
       │ sd │ Replace   │ gu │ Pull          │ ut │ Time         │
       │ wh │ Path      │ pi │ IP            │ cy │ Copy         │
       │ gm │ Commit    │ fd │ DNS           │ pt │ Paste        │
       │ hb │ Upload    │ ga │ Git All       │ pg │ Find         │
       │ gf │ C GitHub  │ k9 │ Kill          │ ss │ SVG          │
       │ pr │ Profile   │ tm │ Temp          │ la │ List         │
       └────┴───────────┴────┴───────────────┴────┴──────────────┘
'@
#>
<#
$Ascii = @'
┌───────────── Git ────────────┬─────── User/Profile ───────┬─────── Files/Dirs ────────┬─────── System/Utility ────┐
│ 01. cl > Clone               │ 11. ed > EProfile          │ 21. dc > Documents        │ 31. ex > Environment      │
│ 02. gg > Clone               │ 12. ga > AddCommitPush     │ 22. dt > Desktop          │ 32. sy > Systemnfo        │
│ 03. gd > Add                 │ 13. gm > AddCommit         │ 23. dw > Downloads        │ 33. ut > Time             │
│ 04. gc > Commit              │ 14. gs > Status            │ 24. lo > Local            │ 34. pi > IP               │
│ 05. gp > Push                │ 15. u1 > UProfile          │ 25. ro > Roaming          │ 35. fd > DNS              │
│ 06. gu > Pull                │ 16. u2 > UPowerShell       │ 26. pf > ProgramFiles     │ 36. df > Volume           │
│ 07. gf > CGitHub             │ 17. pr > Profile           │ 27. md > Directory        │ 37. wh > Path             │
│ 08. g  > DGithub             │                            │ 28. la > List             │ 38. tm > Temp             │
│ 09. hb > Upload              │                            │ 29. uz > Unzip            │ 39. o9 > Utility          │
│ 10. gs > Status              │                            │ 30. hd > First            │ 40. o99 > Utility         │
│                                                                                                                   │
├───────── Edit/Clip ───────────────── Search/Replace ────────── Copy/Move/Setup ──────────────── Other ────────────┤
│                                                                                                                   │
│ 41. e  > Editor              │ 51. ff > Find              │ 61. cy > Copy              │ 71. th > Theme           │
│ 42. vs > VSCode              │ 52. pg > Find              │ 62. pt > Paste             │ 72. cc > Clearup         │
│ 43. cs > Cursor              │ 53. sd > Replace           │ 63. ll > Hidden            │ 73. rr > Restart         │
│ 44. c  > Cursor              │ 54. gr > Regex             │ 64. ne > Empty             │ 74. ss > SVG Setup       │
│ 45. pt > Paste               │                            │ 65. ff > Find              │ 75. dv > Downloader      │
│ 46. cy > Copy                │                            │                            │ 76. de > krisp           │
│ 47. pk > Kill                │                            │                            │ 77. k9 > Kill            │
│ 48. k9 > Kill                │                            │                            │                          │
└──────────────────────────────┴────────────────────────────┴────────────────────────────┴──────────────────────────┘
'@
#>


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
    #Write-Host "'$Mhh$R' HH '•' '$Mhs$R' HS"
}


# Help Full
$script:HelpSections = @(
    @{
        Name  = 'Profile'
        Items = @(
            [pscustomobject]@{ Key = 'c  >'; Desc = 'Cursor'; Arg = '[N]' }
            [pscustomobject]@{ Key = 'e  >'; Desc = 'Editor'; Arg = '[N]' }
            [pscustomobject]@{ Key = 'ed >'; Desc = 'EProfile' }
            [pscustomobject]@{ Key = 'u1 >'; Desc = 'UProfile' }
            [pscustomobject]@{ Key = 'u2 >'; Desc = 'UPowerShell' }
        )
    }
    @{
        Name  = 'Git'
        Items = @(
            [pscustomobject]@{ Key = 'cl >'; Desc = 'Clone'; Arg = '[N]' }
            [pscustomobject]@{ Key = 'gg >'; Desc = 'Clone'; Arg = '[N]' }
            [pscustomobject]@{ Key = 'gd >'; Desc = 'Add' }
            [pscustomobject]@{ Key = 'gc >'; Desc = 'Commit'; Arg = '[N]' }
            [pscustomobject]@{ Key = 'gp >'; Desc = 'Push' }
            [pscustomobject]@{ Key = 'gu >'; Desc = 'Pull' }
            [pscustomobject]@{ Key = 'gs >'; Desc = 'Status' }
            [pscustomobject]@{ Key = 'gm >'; Desc = 'AddCommit'; Arg = '[N]' }
            [pscustomobject]@{ Key = 'ga >'; Desc = 'AddCommitPush'; Arg = '[N]' }
        )
    }
    @{
        Name  = 'Go to'
        Items = @(
            [pscustomobject]@{ Key = 'gf >'; Desc = 'CGitHub' }
            [pscustomobject]@{ Key = 'g  >'; Desc = 'DGithub' }
            [pscustomobject]@{ Key = 'of >'; Desc = 'o9Local' }
            [pscustomobject]@{ Key = 'tm >'; Desc = 'Temp' }
            [pscustomobject]@{ Key = 'dc >'; Desc = 'Documents' }
            [pscustomobject]@{ Key = 'dt >'; Desc = 'Desktop' }
            [pscustomobject]@{ Key = 'dw >'; Desc = 'Downloads' }
            [pscustomobject]@{ Key = 'lo >'; Desc = 'Local' }
            [pscustomobject]@{ Key = 'ro >'; Desc = 'Roaming' }
            [pscustomobject]@{ Key = 'pf >'; Desc = 'ProgramFiles' }
        )
    }
    @{
        Name  = 'System'
        Items = @(
            [pscustomobject]@{ Key = 'df >'; Desc = 'Volume' }
            [pscustomobject]@{ Key = 'ex >'; Desc = 'Environment'; Arg = '[N]' }
            [pscustomobject]@{ Key = 'sy >'; Desc = 'Systemnfo' }
            [pscustomobject]@{ Key = 'ut >'; Desc = 'Time' }
            [pscustomobject]@{ Key = 'pi >'; Desc = 'IP' }
            [pscustomobject]@{ Key = 'fd >'; Desc = 'DNS' }
            [pscustomobject]@{ Key = 'pg >'; Desc = 'Find'; Arg = '[N]' }
            [pscustomobject]@{ Key = 'k9 >'; Desc = 'Kill'; Arg = '[N]' }
            [pscustomobject]@{ Key = 'pk >'; Desc = 'Kill'; Arg = '[N]' }
        )
    }
    @{
        Name  = 'Files'
        Items = @(
            [pscustomobject]@{ Key = 'la >'; Desc = 'List' }
            [pscustomobject]@{ Key = 'll >'; Desc = 'Hidden' }
            [pscustomobject]@{ Key = 'ff >'; Desc = 'Find'; Arg = '[N]' }
            [pscustomobject]@{ Key = 'nf >'; Desc = 'File'; Arg = '[N]' }
            [pscustomobject]@{ Key = 'ne >'; Desc = 'Empty'; Arg = '[N]' }
            [pscustomobject]@{ Key = 'md >'; Desc = 'Directory'; Arg = '[N]' }
            [pscustomobject]@{ Key = 'uz >'; Desc = 'Unzip'; Arg = '[N]' }
            [pscustomobject]@{ Key = 'hd >'; Desc = 'First'; Arg = '[n]' }
            [pscustomobject]@{ Key = 'tl >'; Desc = 'Last'; Arg = '[n]' }
            [pscustomobject]@{ Key = 'gr >'; Desc = 'Regex'; Arg = '[dir]' }
            [pscustomobject]@{ Key = 'sd >'; Desc = 'Replace'; Arg = '[n]' }
            [pscustomobject]@{ Key = 'wh >'; Desc = 'Path'; Arg = '[n]' }
        )
    }
    @{
        Name  = 'Clipboard'
        Items = @(
            [pscustomobject]@{ Key = 'cy >'; Desc = 'Copy'; Arg = '[n]' }
            [pscustomobject]@{ Key = 'pt >'; Desc = 'Paste' }
            [pscustomobject]@{ Key = 'hb >'; Desc = 'Upload'; Arg = '[n]' }
        )
    }
    @{
        Name  = 'Scripts'
        Items = @(
            [pscustomobject]@{ Key = 'o9 >'; Desc = 'Utility' }
            [pscustomobject]@{ Key = '9o >'; Desc = 'Utility' }
            [pscustomobject]@{ Key = 'pr >'; Desc = 'Profile' }
            [pscustomobject]@{ Key = 'vs >'; Desc = 'VSCode' }
            [pscustomobject]@{ Key = 'cs >'; Desc = 'Cursor' }
            [pscustomobject]@{ Key = 'dv >'; Desc = 'Downloader' }
            [pscustomobject]@{ Key = 'de >'; Desc = 'krisp' }
            [pscustomobject]@{ Key = 'th >'; Desc = 'Theme' }
            [pscustomobject]@{ Key = 'cc >'; Desc = 'Clearup' }
            [pscustomobject]@{ Key = 'rr >'; Desc = 'Restart' }
            [pscustomobject]@{ Key = 'ss >'; Desc = 'SVG Setup' }
        )
    }
)


# Help Compact
$script:CompactSections = @(
    @{
        Name  = 'Fast Commands'
        Items = @(
            [pscustomobject]@{ Key = 'c '; Desc = 'Editor' }
            [pscustomobject]@{ Key = 'o9'; Desc = 'Utility' }
            [pscustomobject]@{ Key = 'dv'; Desc = 'Downloader' }
            [pscustomobject]@{ Key = 'cc'; Desc = 'Cleanup' }
            [pscustomobject]@{ Key = 'rr'; Desc = 'Restart' }
            [pscustomobject]@{ Key = 'de'; Desc = 'Krisp' }
            [pscustomobject]@{ Key = 'gg'; Desc = 'Clone' }
            [pscustomobject]@{ Key = 'ga'; Desc = 'Git' }
        )
    }
)


# Help Full
function hh {
    Clear-Host
    Write-FrameTitle 'o9'
    foreach ($section in $script:HelpSections) {
        Write-HelpSection -Name $section.Name -Items $section.Items
    }
    Write-Host "$Y$('─' * 16)$R"
    #Write-ModeFooter
}


# Help Compact
function hs {
    Clear-Host
    Write-Ascii
    Write-FrameTitle 'o9'
    foreach ($section in $script:CompactSections) {
        Write-Host ""
        Write-Host "$C$($section.Name)$R"
        Write-Host "$Y$('─' * 16)$R"
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
    Write-Host "$Y$('─' * 16)$R"
    #Write-ModeFooter
}


# View
hs


# Custom Script
#if (Test-Path "$PSScriptRoot\custom.ps1") {
    #. "$PSScriptRoot\custom.ps1"
#}