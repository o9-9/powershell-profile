<#
# This runs after Microsoft.PowerShell_profile.ps1
# Write-Host "loading custom.ps1"

Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
        [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
        $Local:word = $wordToComplete.Replace('"', '""')
        $Local:ast = $commandAst.ToString().Replace('"', '""')
        winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

#Visual Studio DevShell Integration
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path -Path $vswhere)) {
    Write-Warning "vswhere not found at '$vswhere'. Visual Studio DevShell not loaded."
} else {
    Set-Alias vswhere -value $vswhere
    $vs = & $vswhere -prerelease -latest -products * -requires Microsoft.Component.MSBuild -format json | ConvertFrom-Json | Select-Object -First 1
    if (-not $vs) {
        Write-Warning "No Visual Studio instance found. Visual Studio DevShell not loaded."
    } else {
        $devShellDll = Join-Path $vs.installationPath 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll'
        if (-not (Test-Path -Path $devShellDll)) {
            Write-Warning "DevShell DLL not found at '$devShellDll'. Visual Studio DevShell not loaded."
        } else {
            Import-Module $devShellDll | Out-Null
            Enter-VsDevShell -VsInstanceId $vs.instanceId -SkipAutomaticLocation | Out-Null
            Import-Module $devShellDll
            Enter-VsDevShell -VsInstanceId $vs.instanceId -SkipAutomaticLocation -DevCmdArguments """-arch=x64 -host_arch=x64 -no_logo"""
        }
    }
}

if (Get-Module -ListAvailable -Name PSKubectlCompletion) {
    Import-Module -Name PSKubectlCompletion
} else {
    Write-Warning "PSKubectlCompletion module not found. Run setup.ps1 to install it."
}

function ex() {
    explorer.exe .
}

function env {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string] $Pattern,
        [switch] $Regex,
        [switch] $Raw
    )

    $items = Get-ChildItem Env: | Sort-Object Name
    if ($Pattern) {
        if ($Regex) {
            $items = $items | Where-Object { $_.Name -match $Pattern -or $_.Value -match $Pattern }
        } else {
            $items = $items | Where-Object { $_.Name -like "*$Pattern*" -or $_.Value -like "*$Pattern*" }
        }
    }

    if ($Raw) { return $items }

    $items | Format-Table -AutoSize Name, Value
}

function cleanupmodules {
    $modulePaths = @(
        "$env:USERPROFILE\Documents\PowerShell\Modules",
        "$env:USERPROFILE\Documents\WindowsPowerShell\Modules",
        "$env:ProgramFiles\PowerShell\Modules",
        "$env:ProgramFiles\WindowsPowerShell\Modules"
    ) | Where-Object { Test-Path $_ }

    foreach ($path in $modulePaths) {
        Write-Host "`nScanning: $path" -ForegroundColor Cyan

        # Get all module folders
        $modules = Get-ChildItem -Path $path -Directory -ErrorAction SilentlyContinue
        foreach ($module in $modules) {
            # Get all version subfolders (valid semantic versions only)
            $versions = Get-ChildItem -Path $module.FullName -Directory |
                Where-Object { $_.Name -match '^\d+(\.\d+){0,3}$' } |
                Sort-Object { [version]$_.Name } -Descending

            if ($versions.Count -gt 1) {
                $latest = $versions[0]
                $oldVersions = $versions | Select-Object -Skip 1

                Write-Host "Module '$($module.Name)' has $($versions.Count) versions. Keeping: $($latest.Name)" -ForegroundColor Yellow

                foreach ($old in $oldVersions) {
                    try {
                        Remove-Item -Path $old.FullName -Recurse -Force -ErrorAction Stop
                        Write-Host "Deleted: $($old.FullName)" -ForegroundColor Green
                    }
                    catch {
                        Write-Warning "Failed to delete $($old.FullName): $_"
                    }
                }
            }
        }
    }
}

$MyModulePath = "C:\Users\ZITZJ\Source\repos\PowerShellTools\Modules"
$sep = [System.IO.Path]::PathSeparator

if (Test-Path -LiteralPath $MyModulePath) {
    $existingPaths = $env:PSModulePath -split [regex]::Escape($sep)
    if ($existingPaths -notcontains $MyModulePath) {
        $env:PSModulePath = $env:PSModulePath + "$sep$MyModulePath"
    }
    Import-Module ema-tools
}

$TpfToolsExe = 'C:\Tools\IGEM2\TpfTools\TpfTools.exe'
if (Test-Path -LiteralPath $TpfToolsExe) {
    New-Alias -Name 'TpfTools' -Value $TpfToolsExe -Scope Global -Force
}


function fluxrefresh {
    flux reconcile source git cluster -n flux-system
}

# https://github.com/ajeetdsouza/zoxide
# zoxide for my german keyboard layout
$env:_ZO_FZF_OPTS = "--height=~100% --layout=reverse --border"
Set-Alias -Name x -Value z -PassThru | Out-Null
Set-Alias -Name xx -Value zi -PassThru | Out-Null

mise activate pwsh | Out-String | Invoke-Expression
#>