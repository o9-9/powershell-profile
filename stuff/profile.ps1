<#

# This runs before Microsoft.PowerShell_profile.ps1
# Write-Host "loading profile.ps1"

$EDITOR_Override = 'code'
$debug_Override = $false
$repo_root_Override = "https://raw.githubusercontent.com/jogotcha"
# $timeFilePath_Override
# $updateInterval_Override

function Set-EnvVar {
    $global:GitStatus = Get-GitStatus
    if ($global:GitStatus) {
        $env:POSH_GIT_STRING = $global:GitStatus.RepoName + $(Write-GitStatus -Status $global:GitStatus)
    }
    else {
        $env:POSH_GIT_STRING = $PWD
    }
}

function Get-Theme_Override {
    oh-my-posh init pwsh | Invoke-Expression
    #oh-my-posh init pwsh --config "$env:USERPROFILE\source\repos\powershell-profile\.mytheme.omp.json" | Invoke-Expression
    #New-Alias -Name 'Set-PoshContext' -Value 'Set-EnvVar' -Scope Global -Force
}

#>