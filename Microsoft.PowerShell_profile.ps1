### PowerShell Profile Refactor
### Version 1.04 - Refactored

$debug = $false

#################################################################################################################################
############                                                                                                         ############
############                                          !!!   WARNING:   !!!                                           ############
############                                                                                                         ############
############                DO NOT MODIFY THIS FILE. THIS FILE IS HASHED AND UPDATED AUTOMATICALLY.                  ############
############                    ANY CHANGES MADE TO THIS FILE WILL BE OVERWRITTEN BY COMMITS TO                      ############
############                            https://github.com/o9-9/powershell-profile.git.                              ############
############                                                                                                         ############
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#
############                                                                                                         ############
############                      TO ADD YOUR OWN CODE OR IF YOU WANT TO OVERRIDE ANY OF THESE VARIABLES             ############
############                      OR FUNCTIONS. USE THE Edit-Profile FUNCTION TO CREATE YOUR OWN profile.ps1 FILE.   ############
############                      TO OVERRIDE IN YOUR NEW profile.ps1 FILE, REWRITE THE VARIABLE                     ############
############                      OR FUNCTION, ADDING "_Override" TO THE NAME.                                       ############
############                                                                                                         ############
############                      THE FOLLOWING VARIABLES RESPECT _Override:                                         ############
############                      $EDITOR_Override                                                                   ############
############                      $debug_Override                                                                    ############
############                      $repo_root_Override  [To point to a fork, for example]                             ############
############                      $timeFilePath_Override                                                             ############
############                      $updateInterval_Override                                                           ############
############                                                                                                         ############
############                      THE FOLLOWING FUNCTIONS RESPECT _Override:                                         ############
############                      Debug-Message_Override                                                             ############
############                      Update-Profile_Override                                                            ############
############                      Update-PowerShell_Override                                                         ############
############                      Clear-Cache_Override                                                               ############
############                      Get-Theme_Override                                                                 ############
############                      o99_Override [To call a fork, for example]                                         ############
############                      Set-PredictionSource                                                               ############
#################################################################################################################################

if ($debug_Override){
    # If variable debug_Override is defined in profile.ps1 file
    # then use it instead
    $debug = $debug_Override
} else {
    $debug = $false
}

# Define the path to the file that stores the last execution time
if ($repo_root_Override){
    # If variable $repo_root_Override is defined in profile.ps1 file
    # then use it instead
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

# Define the path to the file that stores the last execution time
if ($timeFilePath_Override){
    # If variable $timeFilePath_Override is defined in profile.ps1 file
    # then use it instead
    $timeFilePath = $timeFilePath_Override
} else {
    $profileDir = Get-ProfileDir
    $timeFilePath = "$profileDir\LastExecutionTime.txt"
}

# Define the update interval in days, set to -1 to always check
if ($updateInterval_Override){
    # If variable $updateInterval_Override is defined in profile.ps1 file
    # then use it instead
    $updateInterval = $updateInterval_Override
} else {
    $updateInterval = 7
}

function Debug-Message{
    # If function "Debug-Message_Override" is defined in profile.ps1 file
    # then call it instead.
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
        Write-Host "#   and update to the latest profile  #" -ForegroundColor Red
        Write-Host "#               version               #" -ForegroundColor Red
        Write-Host "#######################################" -ForegroundColor Red
    }
}

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
        # If PowerShell Core, use a 1 second timeout
        return Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1
    } else {
        # For PowerShell Desktop, use .NET Ping class with timeout
        $ping = New-Object System.Net.NetworkInformation.Ping
        $result = $ping.Send("github.com", 1000)  # 1 second timeout
        return ($result.Status -eq "Success")
    }
}
$global:canConnectToGitHub = Test-GitHubConnection

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

# Safely read and parse the last execution date once to avoid exceptions when the file is missing or empty
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
    # If function "Update-Profile_Override" is defined in profile.ps1 file
    # then call it instead.
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
Set-Alias -Name upr -Value Update-Profile

# Check if not in debug mode AND (updateInterval is -1 OR file doesn't exist OR time difference is greater than the update interval)
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

function Update-PowerShell {
    # If function "Update-PowerShell_Override" is defined in profile.ps1 file
    # then call it instead.
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
Set-Alias -Name upo -Value Update-PowerShell

# skip in debug mode
# Check if not in debug mode AND (updateInterval is -1 OR file doesn't exist OR time difference is greater than the update interval)
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

function Clear-Cache {
    # If function "Clear-Cache_Override" is defined in profile.ps1 file
    # then call it instead.
    # -----------------------------------------------------------------
    # If you do override this function, you should should probably duplicate
    # the following calls in your override function, just don't call this
    # function from your override function, otherwise you'll be in an infinate loop.
    # Clear Prefetch
    if (Get-Command -Name "Clear-Cache_Override" -ErrorAction SilentlyContinue) {
        Clear-Cache_Override
    } else {
        # add clear cache logic here
        Write-Host "Clearing cache..." -ForegroundColor Cyan

        # Clear Windows Prefetch
        Write-Host "Clearing Windows Prefetch..." -ForegroundColor Cyan
        Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue

        # Clear Windows Temp
        Write-Host "Clearing Windows Temp..." -ForegroundColor Cyan
        Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

        # Clear User Temp
        Write-Host "Clearing User Temp..." -ForegroundColor Cyan
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

        # Clear Internet Explorer Cache
        Write-Host "Clearing Internet Explorer Cache..." -ForegroundColor Cyan
        Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue

        Write-Host "Cache clearing completed." -ForegroundColor Green

        # Run Disk Cleanup on Drive C
        Write-Host "Running Disk Cleanup on Drive C..." -ForegroundColor Cyan
        cleanmgr.exe /d C: /VERYLOWDISK
        Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
        
        Write-Host "Cleanup completed." -ForegroundColor Green
    }
}
Set-Alias -Name cc -Value Clear-Cache

# Function to restart Windows Explorer
function Restarts-Explorer {
    # Restarts Windows Explorer
    # Provides functionality to either restart the Windows Explorer process
    # ---------------------------------------------------------------------
    param (
        [string]$action = "refresh"
    )

    if ($action -eq "refresh") {
        # Add the necessary type for Windows API calls
        if (-not ("Win32.NativeMethods" -as [type])) {
            Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @"
[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
public static extern IntPtr SendMessageTimeout(
    IntPtr hWnd,
    uint Msg,
    IntPtr wParam,
    string lParam,
    uint fuFlags,
    uint uTimeout,
    out IntPtr lpdwResult);
"@
        }

        $HWND_BROADCAST = [IntPtr]0xffff
        $WM_SETTINGCHANGE = 0x1A
        $SMTO_ABORTIFHUNG = 0x2
        $timeout = 100
        $result = [IntPtr]::Zero

        # Send the broadcast message to all windows
        [Win32.NativeMethods]::SendMessageTimeout(
            $HWND_BROADCAST, 
            $WM_SETTINGCHANGE, 
            [IntPtr]::Zero, 
            "ImmersiveColorSet", 
            $SMTO_ABORTIFHUNG, 
            $timeout, 
            [ref]$result
        )
        
        Write-Output "Explorer UI settings have been refreshed"
    } 
    elseif ($action -eq "restart") {
        # Restart the Windows Explorer
        Write-Output "Restarting Explorer..."
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Process "explorer.exe"
        Write-Output "Explorer has been restarted"
    }
    else {
        Write-Error "Invalid action. Use 'refresh' or 'restart'"
    }
}
Set-Alias -Name rr -Value Restarts-Explorer

# Admin Check and Prompt Customization
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
function prompt {
    if ($isAdmin) { "[" + (Get-Location) + "] # " } else { "[" + (Get-Location) + "] $ " }
}
$adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix" -f $PSVersionTable.PSVersion.ToString()

# ====================
# Editor Configuration
# ====================

# Force Cursor as default
$EDITOR_Override = 'cursor'

# Test if command exists
function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

# Set editor with fallback
if ($EDITOR_Override){
    $EDITOR = $EDITOR_Override
} else {
    $EDITOR = if (Test-CommandExists cursor) { 'cursor' }
    elseif (Test-CommandExists code) { 'code' }
    elseif (Test-CommandExists codium) { 'codium' }
    elseif (Test-CommandExists notepad++) { 'notepad++' }
    elseif (Test-CommandExists sublime_text) { 'sublime_text' }
    else { 'notepad' }
    # Editor  aliases
    Set-Alias -Name e -Value $EDITOR -Force
    Set-Alias -Name edit -Value $EDITOR -Force
}
# Cursor-specific shortcuts
function Open-InCursor { param($file) cursor $file }
Set-Alias -Name c -Value Open-InCursor -Force
# Quick Access to Editing the Profile
function Edit-Profile {
    cursor $PROFILE.CurrentUserAllHosts
}
Set-Alias -Name ep -Value Edit-Profile

# Invoke Profile
function Invoke-Profile {
    if ($PSVersionTable.PSEdition -eq "Desktop") {
        Write-Host "Note: Some Oh My Posh/PSReadLine errors are expected in PowerShell 5. The profile still works fine." -ForegroundColor Yellow
    }
    & $PROFILE
}

# Create Empty File with ASCII Encoding
function new($file) { "" | Out-File $file -Encoding ASCII }

# Find File Recursively
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

# Get public IP address using Cloudflare (privacy-respecting, no logs for this endpoint)
function pubip { (Invoke-WebRequest http://ifconfig.me/ip).Content }

# Run o9 Utility release
function o9 {
    Invoke-Expression (Invoke-RestMethod https://o9ll.com/o9)
}

# Run o9 Utility pre-release
function o99 {
	  # If function "o99_Override" is defined in profile.ps1 file
    # then call it instead.
    if (Get-Command -Name "o99_Override" -ErrorAction SilentlyContinue) {
        o99_Override
    } else {
        Invoke-Expression (Invoke-RestMethod https://o9ll.com/o99)
    }
}

# Install VS Code setup
function vsc {
	irm https://raw.githubusercontent.com/o9-9/vscode-setup/main/setup.ps1 | iex
}

# Install cursor setup
function cur {
	irm https://raw.githubusercontent.com/o9-9/cursor-setup/main/setup.ps1 | iex
}

# PowerShell Profile Setup
function pr {
	irm https://raw.githubusercontent.com/o9-9/powershell-profile/main/setup.ps1 | iex
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

# System Uptime
function uptime {
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
            # the Get-ti cmdlet was introduced in PowerShell 6.0
            $lastBoot = (Get-ti -Since).ToString("$dateFormat $timeFormat")			
            $bootTime = [System.DateTime]::ParseExact($lastBoot, "$dateFormat $timeFormat", [System.Globalization.CultureInfo]::InvariantCulture)
        }

        # Format the start time
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

# Extract Archive to Current Directory
function unzip ($file) {
    Write-Output("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}

# Upload File to Hastebin and copy URL to clipboard
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

# Search for Text in Files
function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

# Disk Information
function df {
    get-volume
}

# Change Text in File
function sed($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

# Show Command Definition
function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

# Set Environment Variable
function export($name, $value) {
    set-item -force -path "env:$name" -value $value;
}

# Kill Processes
function pkill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

# List Processes
function pgrep($name) {
    Get-Process $name
}

# Show First Lines of File
function head {
    param($Path, $n = 10)
    Get-Content $Path -Head $n
}

# Show File
function tail {
    param($Path, $n = 10, [switch]$f = $false)
    Get-Content $Path -Tail $n -Wait:$f
}

# Quick File Creation
function nf { param($name) New-Item -ItemType "file" -Path . -Name $name }

# Directory Management
function mkcd { param($dir) mkdir $dir -Force; Set-Location $dir }

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

### Quality of Life Aliases

#Navigation Shortcuts
# Go to Documents folder
function doc {
    $doc = if(([Environment]::GetFolderPath("MyDocuments"))) {([Environment]::GetFolderPath("MyDocuments"))} else {$HOME + "\Documents"}
    Set-Location -Path $doc
}
# Go to Desktop folder
function dto {
    $dto = if ([Environment]::GetFolderPath("Desktop")) {[Environment]::GetFolderPath("Desktop")} else {$HOME + "\Desktop"}
    Set-Location -Path $dto
}
# Go to Downloads folder
function dow {
    $dow = if(([Environment]::GetFolderPath("Downloads"))) {([Environment]::GetFolderPath("Downloads"))} else {$HOME + "\Downloads"}
    Set-Location -Path $dow
}
# Go to o9 folder
function o9f {
    $o9f = if(([Environment]::GetFolderPath("LocalApplicationData"))) {([Environment]::GetFolderPath("LocalApplicationData"))} else {$HOME + "\AppData\Local\o9"}
    Set-Location -Path $o9f
}
# Go to Local folder
function lo {
    $lo = if(([Environment]::GetFolderPath("LocalApplicationData"))) {([Environment]::GetFolderPath("LocalApplicationData"))} else {$HOME + "\AppData\Local"}
    Set-Location -Path $lo
}
# Go to Roaming folder
function ro {
    $ro = if(([Environment]::GetFolderPath("ApplicationData"))) {([Environment]::GetFolderPath("ApplicationData"))} else {$HOME + "\AppData\Roaming"}
    Set-Location -Path $ro
}
# Go to Temp folder
function tm {
    $tm = if(([Environment]::GetFolderPath("LocalApplicationData"))) {([Environment]::GetFolderPath("LocalApplicationData"))} else {$HOME + "\AppData\Local\Temp"}
    Set-Location -Path $tm
}
# Go to Program Files folder
function pf {
    $pf = 'C:\Program Files'
    Set-Location $pf
}
# Go to Github folder in D
function gh {
    $gh = 'D:\10_Github'
    Set-Location -Path $gh
}
# Go to Githyb Folder in C
function g { __zoxide_z github }

# Simplified Process Management
function k9 { Stop-Process -Name $args[0] }

# Enhanced Listing
# List files in table format
function la { Get-ChildItem | Format-Table -AutoSize }
# List all files including hidden in table format
function ll { Get-ChildItem -Force | Format-Table -AutoSize }

# Git Shortcuts
# Git status
function gs { git status }
# Git add
function ga { git add . }
# Git commit
function gc { param($m) git commit -m "$m" }
# Git push
function gp { git push }
# Git pull
function gpu { git pull }
# Git clone
function gcl { git clone "$args" }
# Git add and commit with message
function gcom {
    git add .
    git commit -m "$args"
}
# Git add, commit with message, and push
function gall {
    git add .
    git commit -m "$args"
    git push
}

# Quick Access to System Information
function info { Get-ComputerInfo }

# Networking Utilities
function flushdns {
    Clear-DnsClientCache
    Write-Host "DNS has been flushed"
}

# Clipboard Utilities
# Copy to clipboard
function cpy { Set-Clipboard $args[0] }

# Paste from clipboard
function pst { Get-Clipboard }

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
    # If "Set-PredictionSource_Override" is defined in profile.ps1 file
    # then call it instead.
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

# If function "Get-Theme_Override" is defined in profile.ps1 file
# then call it instead. 
if (Get-Command -Name "Get-Theme_Override" -ErrorAction SilentlyContinue) {
    Get-Theme_Override
} else {
    # Oh My Posh initialization with local theme fallback and auto-download
    $localThemePath = Join-Path (Get-ProfileDir) "cobalt2.omp.json"
    if (-not (Test-Path $localThemePath)) {
        # Try to download the theme file to the detected local path
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

# Clone GitHub Repo
function Clone-GitHubRepo {
    <#
    .SYNOPSIS
        Clones GitHub repo.

    .DESCRIPTION
        Prompts for GitHub repo URL and clones it using git clone.
        Validates the URL format and checks if git is available.

    .PARAMETER Url
        The GitHub repo URL to clone.  If not provided, will prompt interactively.

    . PARAMETER Destination
        Optional destination path where the repo will be cloned. 
        If not specified, clones to the current directory.

    .EXAMPLE
        Clone-GitHubRepo
        Prompts for URL and clones to current directory.

    . EXAMPLE
        Clone-GitHubRepo -Url "https://github.com/o9-9/o9.git"
        Clones the specified repo to current directory.

    . EXAMPLE
        Clone-GitHubRepo -Url "https://github.com/o9-9/o9.git" -Destination "D:\10_Github"
        Clones the specified repo to D:\10_Github.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidatePattern('^https?://github\.com/[\w\-]+/[\w\-\. ]+(? : \.git)?$')]
        [string]$Url,
        
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateScript({
            if (Test-Path $_ -PathType Container) { $true }
            else { throw "The path '$_' does not exist or is not a directory." }
        })]
        [string]$Destination
    )

    begin {
        # Check if git is installed
        try {
            $gitVersion = git --version 2>$null
            if (-not $gitVersion) {
                throw "Git is not installed or not in PATH."
            }
            Write-Verbose "Git found:  $gitVersion"
        }
        catch {
            Write-Error "Git is not available. Please install Git first."
            return
        }
    }

    process {
        # Prompt for URL if not provided
        if (-not $Url) {
            Write-Host "`nGitHub Repo Clone" -ForegroundColor Cyan
            Write-Host "═" * 50 -ForegroundColor Cyan
            $Url = Read-Host "Enter Repo URL"

            # Validate the URL format
            if ($Url -notmatch '^https?://github\.com/[\w\-]+/[\w\-\.]+(?:\.git)?$') {
                Write-Error "Invalid GitHub URL format. Expected format: https://github.com/o9-9/o9.git"
                return
            }
        }

        # Ensure URL ends with .git
        if ($Url -notmatch '\.git$') {
            $Url = "$Url.git"
        }

        Write-Host "`nCloning repo from: $Url" -ForegroundColor Green

        try {
            # Clone Repo
            if ($Destination) {
                Push-Location $Destination
                git clone $Url
                Pop-Location
                Write-Host "`n✔ Repo cloned successfully to: $Destination" -ForegroundColor Green
            }
            else {
                git clone $Url
                Write-Host "`n✔ Repo cloned successfully!" -ForegroundColor Green
            }
        }
        catch {
            Write-Error "Failed to clone repo:  $_"
            return
        }
    }
}
# Create Clone-GitHubRepo alias
Set-Alias -Name cl -Value Clone-GitHubRepo

# Downloads YouTube video
function Get-YouTubeVideo {
    <#
    .SYNOPSIS
        Downloads YouTube video to D:\07_Videos using yt-dlp. 

    .DESCRIPTION
        Prompts for YouTube URL and downloads the video to D:\07_Videos.
        Requires yt-dlp to be installed and available in PATH.

    .PARAMETER Url
        The YouTube video URL.  If not provided, will prompt for input.

    .EXAMPLE
        Get-YouTubeVideo
        Prompts for URL and downloads video

    .EXAMPLE
        Get-YouTubeVideo -Url "https://www.youtube.com/watch?v=o9"
        Downloads video directly from provided URL
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Url
    )

    # Check if yt-dlp is available
    if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
        Write-Error "yt-dlp is not installed or not in PATH. Install it first:  winget install yt-dlp"
        return
    }

    # Prompt for URL if not provided
    if ([string]::IsNullOrWhiteSpace($Url)) {
        $Url = Read-Host "Enter Video URL"
    }

    # Validate URL
    if ([string]::IsNullOrWhiteSpace($Url)) {
        Write-Warning "No URL provided. Operation cancelled."
        return
    }

    # Set download path to Desktop
    $DownloadPath = "D:\07_Videos"

    # Create the folder if it doesn't exist
    if (-not (Test-Path -Path $DownloadPath)) {
        New-Item -Path $DownloadPath -ItemType Directory | Out-Null
    }

    Write-Host "Downloading video to:  $DownloadPath" -ForegroundColor Cyan
    Write-Host "URL: $Url" -ForegroundColor Cyan

    # Download video
    try {
        yt-dlp -P $DownloadPath $Url
        Write-Host "`n✔ Video downloaded successfully to: $DownloadPath" -ForegroundColor Green
    }
    catch {
        Write-Error "Download failed: $_"
    }
}
# Create Get-YouTubeVideo alias
Set-Alias -Name dv -Value Get-YouTubeVideo

<# Help Function
function h {
    $border = "$($PSStyle.Foreground.DarkGray) $($PSStyle.Reset)"
    $sectionHeader = { param($emoji, $title) "$($PSStyle.Foreground.Magenta)$emoji  $title$($PSStyle.Reset)" }
    $cmd = { param($cmd, $alias, $desc, $sym)
        "$($PSStyle.Foreground.Cyan)$cmd$($PSStyle.Reset) $(if($alias){"$($PSStyle.Foreground.Green)[$alias]$($PSStyle.Reset) "}else{''})$sym  $desc"
    }

    $helpText = @"
$border
$($sectionHeader.Invoke("⚡", "o9 Profile Help"     ))
$($cmd.Invoke("c","","Edit in Cursor",         "⚙️"))
$($cmd.Invoke("e","","Edit file",              "⚙️"))
$($cmd.Invoke("edit","","Edit file",           "⚙️"))
$($cmd.Invoke("ep","","Edit Profile",          "⚙️"))
$($cmd.Invoke("upr","","Update Profile",       "🔄"))
$($cmd.Invoke("upo","","Update PowerShell",    "🔄"))
$border
$($sectionHeader.Invoke("🌱", "Git Shortcuts"      ))
$($cmd.Invoke("cl","","git clone",             "⬇️"))
$($cmd.Invoke("gcl","","git clone",            "⬇️"))
$($cmd.Invoke("gs","","git status",            "🟢"))
$($cmd.Invoke("ga","","git add .",             "➕"))
$($cmd.Invoke("gc","","git commit -m",         "💬"))
$($cmd.Invoke("gp","","git push",              "🚀"))
$($cmd.Invoke("gpu","","git pull",             "⬇️"))
$($cmd.Invoke("gcom","","Add & Commit",        "📝"))
$($cmd.Invoke("gall","","Add-Commit-Push",     "🚀"))
$border
$($sectionHeader.Invoke("🚀", "Shortcuts"          ))
$($cmd.Invoke("cpy","","Copy File",            "📋"))
$($cmd.Invoke("pst","","Paste File",           "📋"))
$($cmd.Invoke("df","","Disk Free Space",       "ℹ️"))
$($cmd.Invoke("g","","GitHub folder",          "📁"))
$($cmd.Invoke("gh","","GitHub folder in D",    "📁"))
$($cmd.Invoke("doc","","Documents folder",     "📁"))
$($cmd.Invoke("dto","","Desktop folder",       "📁"))
$($cmd.Invoke("dow","","Downloads folder",     "📁"))
$($cmd.Invoke("o9f","","o9 folder",            "📁"))
$($cmd.Invoke("lo","","Local folder",          "📁"))
$($cmd.Invoke("ro","","Roaming folder",        "📁"))
$($cmd.Invoke("tm","","Temp folder",           "📁"))
$($cmd.Invoke("pf","","Program Files folder",  "📁"))
$($cmd.Invoke("export","","Set Environmente",  "🌱"))
$($cmd.Invoke("ff","","Find Files",            "🔍"))
$($cmd.Invoke("flushdns","","Clear DNS Cache", "🌐"))
$($cmd.Invoke("pubip","","Show Public IP",     "🌎"))
$($cmd.Invoke("grep","","Search Regex",        "🧬"))
$($cmd.Invoke("hb","","Upload URL",            "🌐"))
$($cmd.Invoke("head","","Show First Lines",    "🔝"))
$($cmd.Invoke("k9","","Kill Process",          "🪓"))
$($cmd.Invoke("la","","List All Files",        "📁"))
$($cmd.Invoke("ll","","List Hidden Files",     "👻"))
$($cmd.Invoke("mkcd","","Change Directory",    "📂"))
$($cmd.Invoke("nf","","Create Empty File",     "🆕"))
$($cmd.Invoke("pkill","","Kill Process Name",  "💀"))
$($cmd.Invoke("pgrep","","List Process Name",  "🔎"))
$($cmd.Invoke("sed","","Replace in File",      "✂️"))
$($cmd.Invoke("info","","System Info",         "🖥️"))
$($cmd.Invoke("tail","","Show Last Lines",     "🔚"))
$($cmd.Invoke("new","","Create New File",      "✏️"))
$($cmd.Invoke("unzip","","Extract Zip File",   "🗜️"))
$($cmd.Invoke("uptime","","Show time",         "⏰"))
$($cmd.Invoke("which","","Show Command Path",  "🛤️"))
$border
$($cmd.Invoke("o9","","Run o9",                 "⚡"))
$($cmd.Invoke("o99","","Run o99",               "⚡"))
$($cmd.Invoke("pr","","Profile Setup",          "⚡"))
$($cmd.Invoke("vsc","","VSCode Setup",          "⚡"))
$($cmd.Invoke("cur","","Cursor Setup",          "⚡"))
$($cmd.Invoke("dv","","Download Video",        "💾"))
$($cmd.Invoke("cc","","Clear Cache",           "🧹"))
$($cmd.Invoke("rr","","Restarts Explorer",     "🔧"))
$border

Use '$($PSStyle.Foreground.Magenta)H$($PSStyle.Reset)' to display this help message.
$border
"@
    Write-Host $helpText
}
#>

# Help Function
function h {
    $helpText = @"
$($PSStyle.Foreground.Cyan)PowerShell Profile Help$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)c$($PSStyle.Reset) - Opens file in cursor editor.
$($PSStyle.Foreground.Green)e$($PSStyle.Reset) - Opens file in editor.
$($PSStyle.Foreground.Green)edit$($PSStyle.Reset) - Opens file in editor.
$($PSStyle.Foreground.Green)ep$($PSStyle.Reset) - Opens the current user's profile for editing using the configured editor.
$($PSStyle.Foreground.Green)upr$($PSStyle.Reset) - Checks for profile updates from a remote repository and updates if necessary.
$($PSStyle.Foreground.Green)upo$($PSStyle.Reset) - Checks for the latest PowerShell release and updates if a new version is available.

$($PSStyle.Foreground.Cyan)Git Shortcuts$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)cl$($PSStyle.Reset) <repo> - Shortcut for 'git clone'.
$($PSStyle.Foreground.Green)gcl$($PSStyle.Reset) <repo> - Shortcut for 'git clone'.
$($PSStyle.Foreground.Green)ga$($PSStyle.Reset) - Shortcut for 'git add .'.
$($PSStyle.Foreground.Green)gc$($PSStyle.Reset) <message> - Shortcut for 'git commit -m'.
$($PSStyle.Foreground.Green)gcom$($PSStyle.Reset) <message> - Adds all changes and commits with the specified message.
$($PSStyle.Foreground.Green)gp$($PSStyle.Reset) - Shortcut for 'git push'.
$($PSStyle.Foreground.Green)gpu$($PSStyle.Reset) - Shortcut for 'git pull'.
$($PSStyle.Foreground.Green)gs$($PSStyle.Reset) - Shortcut for 'git status'.
$($PSStyle.Foreground.Green)gall$($PSStyle.Reset) <message> - Adds all changes, commits with the specified message, and pushes to the remote repository.

$($PSStyle.Foreground.Cyan)Shortcuts$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)cpy$($PSStyle.Reset) <text> - Copies the specified text to the clipboard.
$($PSStyle.Foreground.Green)df$($PSStyle.Reset) - Displays information about volumes.
$($PSStyle.Foreground.Green)g$($PSStyle.Reset) - Changes to the C:GitHub directory.
$($PSStyle.Foreground.Green)gh$($PSStyle.Reset) - Changes to the D:GitHub directory.
$($PSStyle.Foreground.Green)doc$($PSStyle.Reset) - Changes the current directory to Documents folder.
$($PSStyle.Foreground.Green)dto$($PSStyle.Reset) - Changes the current directory to Desktop folder.
$($PSStyle.Foreground.Green)dow$($PSStyle.Reset) - Changes the current directory to Downloads folder.
$($PSStyle.Foreground.Green)o9f$($PSStyle.Reset) - Changes the current directory to o9 folder.
$($PSStyle.Foreground.Green)lo$($PSStyle.Reset) - Changes the current directory to Local folder.
$($PSStyle.Foreground.Green)ro$($PSStyle.Reset) - Changes the current directory to Roaming folder.
$($PSStyle.Foreground.Green)tm$($PSStyle.Reset) - Changes the current directory to the user's Temp folder.  
$($PSStyle.Foreground.Green)pf$($PSStyle.Reset) - Changes the current directory to Program Files folder.
$($PSStyle.Foreground.Green)export$($PSStyle.Reset) <name> <value> - Sets an environment variable.
$($PSStyle.Foreground.Green)ff$($PSStyle.Reset) <name> - Finds files recursively with the specified name.
$($PSStyle.Foreground.Green)flushdns$($PSStyle.Reset) - Clears the DNS cache.
$($PSStyle.Foreground.Green)pubip$($PSStyle.Reset) - Retrieves the public IP address of the machine.
$($PSStyle.Foreground.Green)grep$($PSStyle.Reset) <regex> [dir] - Searches for a regex pattern in files within the specified directory or from the pipeline input.
$($PSStyle.Foreground.Green)hb$($PSStyle.Reset) <file> - Uploads the specified file's content to a hastebin-like service and returns the URL.
$($PSStyle.Foreground.Green)head$($PSStyle.Reset) <path> [n] - Displays the first n lines of a file (default 10).
$($PSStyle.Foreground.Green)k9$($PSStyle.Reset) <name> - Kills a process by name.
$($PSStyle.Foreground.Green)la$($PSStyle.Reset) - Lists all files in the current directory with detailed formatting.
$($PSStyle.Foreground.Green)ll$($PSStyle.Reset) - Lists all files, including hidden, in the current directory with detailed formatting.
$($PSStyle.Foreground.Green)mkcd$($PSStyle.Reset) <dir> - Creates and changes to a new directory.
$($PSStyle.Foreground.Green)nf$($PSStyle.Reset) <name> - Creates a new file with the specified name.
$($PSStyle.Foreground.Green)pgrep$($PSStyle.Reset) <name> - Lists processes by name.
$($PSStyle.Foreground.Green)pkill$($PSStyle.Reset) <name> - Kills processes by name.
$($PSStyle.Foreground.Green)pst$($PSStyle.Reset) - Retrieves text from the clipboard.
$($PSStyle.Foreground.Green)sed$($PSStyle.Reset) <file> <find> <replace> - Replaces text in a file.
$($PSStyle.Foreground.Green)info$($PSStyle.Reset) - Displays detailed system information.
$($PSStyle.Foreground.Green)tail$($PSStyle.Reset) <path> [n] - Displays the last n lines of a file (default 10).
$($PSStyle.Foreground.Green)new$($PSStyle.Reset) <file> - Creates a new empty file.
$($PSStyle.Foreground.Green)unzip$($PSStyle.Reset) <file> - Extracts a zip file to the current directory.
$($PSStyle.Foreground.Green)uptime$($PSStyle.Reset) - Displays the system uptime.
$($PSStyle.Foreground.Green)which$($PSStyle.Reset) <name> - Shows the path of the command.
$($PSStyle.Foreground.Green)o9$($PSStyle.Reset) - Runs the latest o9 full-release script from o9.
$($PSStyle.Foreground.Green)o99$($PSStyle.Reset) - Runs the latest o99 pre-release script from o9.
$($PSStyle.Foreground.Green)pr$($PSStyle.Reset) - Runs PowerShell Profile Setup script from o9.
$($PSStyle.Foreground.Green)vsc$($PSStyle.Reset) - Runs VS Code Setup script from o9.
$($PSStyle.Foreground.Green)cur$($PSStyle.Reset) - Runs Cursor Setup script from o9.
$($PSStyle.Foreground.Green)dv$($PSStyle.Reset) - Download Video from YouTube.
$($PSStyle.Foreground.Green)cc$($PSStyle.Reset) - Clear Cache.
$($PSStyle.Foreground.Green)rr$($PSStyle.Reset) - Restarts Explorer.
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)

Use '$($PSStyle.Foreground.Magenta)h$($PSStyle.Reset)' to display this help message.
"@
    Write-Host $helpText
}

if (Test-Path "$PSScriptRoot\o9custom.ps1") {
    Invoke-Expression -Command "& `"$PSScriptRoot\o9custom.ps1`""
}

Write-Host "$($PSStyle.Foreground.DarkMagenta)Use 'h' to display help$($PSStyle.Reset)"
