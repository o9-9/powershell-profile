# $debug = $true
$debug = $false

# Define the path to the file that stores the last execution time
$timeFilePath = [Environment]::GetFolderPath("o9 Documents") + "\PowerShell\LastExecutionTime.txt"

# Define the update interval in days, set to -1 to always check
$updateInterval = 7

if ($debug) {
    Write-Host "Debug On" -ForegroundColor Cyan
}

# opt-out of telemetry before doing anything, only if PowerShell is run as admin
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
    [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}

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
            Write-Host "✔ Profile Updated > Restart Terminal" -ForegroundColor Magenta
        } else {
            Write-Host "Profile Up Date." -ForegroundColor Green
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
            Write-Host "✔ PowerShell Updated > Restart Terminal" -ForegroundColor Magenta
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
function fi($name) {
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

# Open setup
function setup {
	irm https://raw.githubusercontent.com/o9-9/vscode-setup/main/setup.ps1 | iex
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

function reload-profile {
    & $profile
}

function unzip ($file) {
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
        Write-Output $url
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

function rep($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function path($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function exp($name, $value) {
    set-item -force -path "env:$name" -value $value;
}

function okill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function ogrep($name) {
    Get-Process $name
}

function head {
  param($Path, $n = 10)
  Get-Content $Path -Head $n
}

function tail {
  param($Path, $n = 10, [switch]$f = $false)
  Get-Content $Path -Tail $n -Wait:$f
}

# Quick File Creation
function nf { param($name) New-Item -ItemType "file" -Path . -Name $name }

# Directory Management
function o9cd { param($dir) mkdir $dir -Force; Set-Location $dir }

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
function docs {
    $docs = if(([Environment]::GetFolderPath("o9 Documents"))) {([Environment]::GetFolderPath("o9 Documents"))} else {$HOME + "\Documents"}
    Set-Location -Path $docs
}
# Go to Desktop
function dtop {
    $dtop = if ([Environment]::GetFolderPath("Desktop")) {[Environment]::GetFolderPath("Desktop")} else {$HOME + "\Documents"}
    Set-Location -Path $dtop
}
# Go to Downloads folder
function dow {
    $dow = if(([Environment]::GetFolderPath("Downloads"))) {([Environment]::GetFolderPath("Downloads"))} else {$HOME + "\Downloads"}
    Set-Location -Path $dow
}

# Go to Local AppData folder
function loc {
    $loc = if(([Environment]::GetFolderPath("LocalApplicationData"))) {([Environment]::GetFolderPath("LocalApplicationData"))} else {$HOME + "\AppData\Local"}
    Set-Location -Path $loc
}

# Go to Roaming AppData folder
function roa {
    $roa = if(([Environment]::GetFolderPath("ApplicationData"))) {([Environment]::GetFolderPath("ApplicationData"))} else {$HOME + "\AppData\Roaming"}
    Set-Location -Path $roa
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

function gcom {
    git add .
    git commit -m "$args"
}
function lazyg {
    git add .
    git commit -m "$args"
    git push
}

# Quick Access to System Information
function sysinfo { Get-ComputerInfo }

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


# Get theme from profile.ps1 or use a default theme
function Get-Theme {
    if (Test-Path -Path $PROFILE.CurrentUserAllHosts -PathType leaf) {
        $existingTheme = Select-String -Raw -Path $PROFILE.CurrentUserAllHosts -Pattern "oh-my-posh init pwsh --config"
        if ($null -ne $existingTheme) {
            Invoke-Expression $existingTheme
            return
        }
        oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json | Invoke-Expression
    } else {
        oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json | Invoke-Expression
    }
}

## Final Line to set prompt
Get-Theme
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

Set-Alias -Name z -Value __zoxide_z -Option AllScope -Scope Global -Force
Set-Alias -Name zi -Value __zoxide_zi -Option AllScope -Scope Global -Force

# Help Function
function sh {
    $helpText = @"
$($PSStyle.Foreground.Cyan)o9$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)

$($PSStyle.Foreground.Cyan)o9$($PSStyle.Reset) - Run o9.

$($PSStyle.Foreground.Cyan)setup$($PSStyle.Reset) - Run setup.

$($PSStyle.Foreground.Cyan)docs$($PSStyle.Reset) - Go to Documents.

$($PSStyle.Foreground.Cyan)dtop$($PSStyle.Reset) - Go to Desktop.

$($PSStyle.Foreground.Cyan)dow$($PSStyle.Reset) - Go to Downloads.

$($PSStyle.Foreground.Cyan)loc$($PSStyle.Reset) - Go to Local.

$($PSStyle.Foreground.Cyan)roa$($PSStyle.Reset) - Go to Roaming.

$($PSStyle.Foreground.Cyan)Update-Profile$($PSStyle.Reset) - Check Updates Profile.

$($PSStyle.Foreground.Cyan)Update-PowerShell$($PSStyle.Reset) - Check Updates PowerShell.

$($PSStyle.Foreground.Cyan)ep$($PSStyle.Reset) - Open Powershell Profile.

$($PSStyle.Foreground.Cyan)Edit-Profile$($PSStyle.Reset) - Edit Powershell Profile.

$($PSStyle.Foreground.Cyan)reload-profile$($PSStyle.Reset) - Reloads Powershell Profile.

$($PSStyle.Foreground.Cyan)cr$($PSStyle.Reset)  - Creates File.

$($PSStyle.Foreground.Cyan)fi$($PSStyle.Reset) - Find File.

$($PSStyle.Foreground.Cyan)ip$($PSStyle.Reset) - Public IP.

$($PSStyle.Foreground.Cyan)time$($PSStyle.Reset) - Show time.

$($PSStyle.Foreground.Cyan)unzip$($PSStyle.Reset)  - Extract Zip File.

$($PSStyle.Foreground.Cyan)hb$($PSStyle.Reset)  - Upload File URL.

$($PSStyle.Foreground.Cyan)grep$($PSStyle.Reset) - Searche Regex.

$($PSStyle.Foreground.Cyan)df$($PSStyle.Reset) - Show Info.

$($PSStyle.Foreground.Cyan)rep$($PSStyle.Reset)  - Replaces Text File.

$($PSStyle.Foreground.Cyan)path$($PSStyle.Reset) - Shows Path.

$($PSStyle.Foreground.Cyan)exp$($PSStyle.Reset) - Sets Environment.

$($PSStyle.Foreground.Cyan)okill$($PSStyle.Reset) - Kills Processes.

$($PSStyle.Foreground.Cyan)ogrep$($PSStyle.Reset) - Lists Processes.

$($PSStyle.Foreground.Cyan)head$($PSStyle.Reset) - Show First Files.

$($PSStyle.Foreground.Cyan)tail$($PSStyle.Reset) - Show last Files.

$($PSStyle.Foreground.Cyan)nf$($PSStyle.Reset) - Create File > Name.

$($PSStyle.Foreground.Cyan)o9cd$($PSStyle.Reset) - Change Directory.

$($PSStyle.Foreground.Cyan)k9$($PSStyle.Reset) - Kill Process.

$($PSStyle.Foreground.Cyan)la$($PSStyle.Reset) - Show Files.

$($PSStyle.Foreground.Cyan)ll$($PSStyle.Reset) - Show Hidden Files.

$($PSStyle.Foreground.Cyan)gs$($PSStyle.Reset) - 'git status.

$($PSStyle.Foreground.Cyan)ga$($PSStyle.Reset) - 'git add.

$($PSStyle.Foreground.Cyan)gc$($PSStyle.Reset) - 'git commit.

$($PSStyle.Foreground.Cyan)gp$($PSStyle.Reset) - 'git push'.

$($PSStyle.Foreground.Cyan)g$($PSStyle.Reset) - GO to GitHub.

$($PSStyle.Foreground.Cyan)gcom$($PSStyle.Reset) - Add > Change > Commit.

$($PSStyle.Foreground.Cyan)lazyg$($PSStyle.Reset) - Add > Change > Commit > Pushe.

$($PSStyle.Foreground.Cyan)sysinfo$($PSStyle.Reset) - System Info.

$($PSStyle.Foreground.Cyan)dns$($PSStyle.Reset) - DNS Cache.

$($PSStyle.Foreground.Cyan)cp$($PSStyle.Reset) - Copy.

$($PSStyle.Foreground.Cyan)ps$($PSStyle.Reset) - Paste.

Use '$($PSStyle.Foreground.Magenta)sh$($PSStyle.Reset)' Help.
"@
    Write-Host $helpText
}

Write-Host "$($PSStyle.Foreground.Yellow)'sh'$($PSStyle.Reset)"
