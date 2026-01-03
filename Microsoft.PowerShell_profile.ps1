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
[datetime]$lastExec = $null
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
Set-Alias -Name up -Value Update-Profile

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
Set-Alias -Name uo -Value Update-PowerShell

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

# Utility Functions
function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

# Editor Configuration
if ($EDITOR_Override){
    $EDITOR = $EDITOR_Override
} else {
    $EDITOR = if (Test-CommandExists nvim) { 'nvim' }
    elseif (Test-CommandExists pvim) { 'pvim' }
    elseif (Test-CommandExists vim) { 'vim' }
    elseif (Test-CommandExists vi) { 'vi' }
    elseif (Test-CommandExists code) { 'code' }
    elseif (Test-CommandExists codium) { 'codium' }
    elseif (Test-CommandExists notepad++) { 'notepad++' }
    elseif (Test-CommandExists sublime_text) { 'sublime_text' }
    else { 'notepad' }
    Set-Alias -Name vim -Value $EDITOR
}

# Quick Access to Editing the Profile
function Edit-Profile {
    vim $PROFILE.CurrentUserAllHosts
}
Set-Alias -Name ep -Value Edit-Profile

function Invoke-Profile {
    if ($PSVersionTable.PSEdition -eq "Desktop") {
        Write-Host "Note: Some Oh My Posh/PSReadLine errors are expected in PowerShell 5. The profile still works fine." -ForegroundColor Yellow
    }
    & $PROFILE
}

function cr($file) { "" | Out-File $file -Encoding ASCII }
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

# Get public IP address using Cloudflare (privacy-respecting, no logs for this endpoint)
function ip { (Invoke-WebRequest http://ifconfig.me/ip).Content }

# Open o9 full-release
function o9 {
    Invoke-Expression (Invoke-RestMethod https://o9ll.com/o9)
}

# Open o9 pre-release
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
function vs {
	irm https://raw.githubusercontent.com/o9-9/vscode-setup/main/setup.ps1 | iex
}

# Install cursor setup
function cs {
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

function ti {
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

function un ($file) {
    Write-Output("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}
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
function se($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

function di {
    get-volume
}

function ch($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function sh($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function ev($name, $value) {
    set-item -force -path "env:$name" -value $value;
}

function kp($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function lp($name) {
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
function oc { param($dir) mkdir $dir -Force; Set-Location $dir }

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

function gm {
    git add .
    git commit -m "$args"
}
function lg {
    git add .
    git commit -m "$args"
    git push
}

# Quick Access to System Information
function sy { Get-ComputerInfo }

# Networking Utilities
function dn {
    Clear-DnsClientCache
    Write-Host "DNS has been flushed"
}

# Clipboard Utilities
function cp { Set-Clipboard $args[0] }

function ps { Get-Clipboard }

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
        # $themeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/atomic.omp.json"
        $themeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json"
        try {
            Invoke-RestMethod -Uri $themeUrl -OutFile $localThemePath
            Write-Host "Downloaded missing Oh My Posh theme to $localThemePath"
        } catch {
            Write-Warning "Failed to download theme file. Falling back to remote theme. Error: $_"
        }
    }
    if (Test-Path $localThemePath) {
        oh-my-posh init pwsh --config $localThemePath | Invoke-Expression
    } else {
        # Fallback to remote theme if local file doesn't exist
        # oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/atomic.omp.json | Invoke-Expression
        oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json | Invoke-Expression
    }
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
} else {
    Write-Host "zoxide command not found. Attempting to install via winget..."
    try {
        winget install -e --id ajeetdsouza.zoxide
        Write-Host "zoxide installed successfully. Initializing..."
        Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
    } catch {
        Write-Error "Failed to install zoxide. Error: $_"
    }
}

# Help Function
function hh {
    $border = "$($PSStyle.Foreground.DarkGray) $($PSStyle.Reset)"
    $sectionHeader = { param($emoji, $title) "$($PSStyle.Foreground.Magenta)$emoji  $title$($PSStyle.Reset)" }
    $cmd = { param($cmd, $alias, $desc, $sym)
        "$($PSStyle.Foreground.Cyan)$cmd$($PSStyle.Reset) $(if($alias){"$($PSStyle.Foreground.Green)[$alias]$($PSStyle.Reset) "}else{''})$sym  $desc"
    }

    $helpText = @"
$border
$($sectionHeader.Invoke("⚡", "o9 Profile Help"    ))
$border
$($sectionHeader.Invoke("🚀", "Navigation"         ))
$($cmd.Invoke("dc","","Go to Documents",       "📄"))
$($cmd.Invoke("dt","","Go to Desktop",         "🖥️"))
$($cmd.Invoke("do","","Go to Downloads",       "⬇️"))
$($cmd.Invoke("lc","","Go to Local",           "📁"))
$($cmd.Invoke("ro","","Go to Roaming",         "📁"))
$($cmd.Invoke("oc","","Change Directory",      "📂"))
$border
$($sectionHeader.Invoke("🛠️", "System / Utility"   ))
$($cmd.Invoke("o9","","Run o9",                "⚡"))
$($cmd.Invoke("o99","","Run o99",              "⚡"))
$($cmd.Invoke("vs","","VSCode Setup",          "⚡"))
$($cmd.Invoke("cs","","Cursor Setup",          "⚡"))
$($cmd.Invoke("pr","","Profile Setup",         "⚡"))
$($cmd.Invoke("cc","","Clear Cache",           "🧹"))
$($cmd.Invoke("rr","","Restarts Explorer",     "🔧"))
$($cmd.Invoke("sy","","System Info",           "🖥️"))
$($cmd.Invoke("dn","","Clear DNS Cache",       "🌐"))
$($cmd.Invoke("kp","","Kill Process Name",     "💀"))
$($cmd.Invoke("lp","","List Process Name",     "🔎"))
$($cmd.Invoke("k9","","Kill Process",          "🪓"))
$border
$($sectionHeader.Invoke("📄", "Files & Directories"))
$($cmd.Invoke("la","","List All Files",        "📁"))
$($cmd.Invoke("ll","","List Hidden Files",     "👻"))
$($cmd.Invoke("fl","","Show First Lines",      "🔝"))
$($cmd.Invoke("lf","","Show Last Lines",       "🔚"))
$($cmd.Invoke("cr","","Create Empty File",     "🆕"))
$($cmd.Invoke("nn","","Create New File",       "✏️"))
$($cmd.Invoke("ff","","Find Files",            "🔍"))
$($cmd.Invoke("un","","Extract Zip File",      "🗜️"))
$($cmd.Invoke("hb","","Upload URL",            "🌐"))
$($cmd.Invoke("di","","Disk Free Space",       "ℹ️"))
$($cmd.Invoke("sh","","Show Command Path",     "🛤️"))
$($cmd.Invoke("ev","","Set Environmente",      "🌱"))
$($cmd.Invoke("ch","","Replace in File",       "✂️"))
$border
$($sectionHeader.Invoke("🔎", "Search & Data"      ))
$($cmd.Invoke("se","","Search Regex",          "🧬"))
$($cmd.Invoke("ip","","Show Public IP",        "🌎"))
$($cmd.Invoke("ti","","Show time",             "⏰"))
$border
$($sectionHeader.Invoke("🔗", "Clipboard"          ))
$($cmd.Invoke("cp","","Copy File",             "📋"))
$($cmd.Invoke("ps","","Paste File",            "📋"))
$border
$($sectionHeader.Invoke("🌱", "Git Shortcuts"      ))
$($cmd.Invoke("gs","","git status",            "🟢"))
$($cmd.Invoke("ga","","git add .",             "➕"))
$($cmd.Invoke("gc","","git commit -m",         "💬"))
$($cmd.Invoke("gp","","git push",              "🚀"))
$($cmd.Invoke("g","","GitHub Folder",          "🌐"))
$($cmd.Invoke("gm","","Add & Commit",          "📝"))
$($cmd.Invoke("lg","","Add-Commit-Push",       "🚀"))
$border
$($sectionHeader.Invoke("👤", "Profile Management" ))
$($cmd.Invoke("up","","Update Profile",        "🔄"))
$($cmd.Invoke("uo","","Update PowerShell",     "🔄"))
$($cmd.Invoke("ep","","Edit Profile",          "📝"))
$border
$($sectionHeader.Invoke("⚡", "Examples"           ))
$($PSStyle.Foreground.Green)$($PSStyle.Reset)hh$($PSStyle.Foreground.DarkGray)   Display Help Menu.$($PSStyle.Reset)
$($PSStyle.Foreground.Green)$($PSStyle.Reset)dc$($PSStyle.Foreground.DarkGray)   Go to Documents.$($PSStyle.Reset)
$($PSStyle.Foreground.Green)$($PSStyle.Reset)o9$($PSStyle.Foreground.DarkGray)   Run o9.$($PSStyle.Reset)
$($PSStyle.Foreground.Green)$($PSStyle.Reset)oc$($PSStyle.Foreground.DarkGray)   Change Directory.$($PSStyle.Reset)
$($PSStyle.Foreground.Green)$($PSStyle.Reset)gs$($PSStyle.Foreground.DarkGray)   Show Git Status.$($PSStyle.Reset)
$($PSStyle.Foreground.Green)$($PSStyle.Reset)gm$($PSStyle.Foreground.DarkGray)   Git Commit.$($PSStyle.Reset)
$($PSStyle.Foreground.Green)$($PSStyle.Reset)lg$($PSStyle.Foreground.DarkGray)   Git Add, Commit, Push.$($PSStyle.Reset)
$($PSStyle.Foreground.Green)$($PSStyle.Reset)cp$($PSStyle.Foreground.DarkGray)   Copy File.$($PSStyle.Reset)

Use '$($PSStyle.Foreground.Magenta)hh$($PSStyle.Reset)' to Display Help.
$border
"@
    Write-Host $helpText
}

if (Test-Path "$PSScriptRoot\o9Custom.ps1") {
    Invoke-Expression -Command "& `"$PSScriptRoot\o9Custom.ps1`""
}

Write-Host "$($PSStyle.Foreground.DarkMagenta)Use 'hh' to display help$($PSStyle.Reset)"
