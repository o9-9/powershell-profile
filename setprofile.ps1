$profilePath = Split-Path -Path $PROFILE
Copy-Item .\Microsoft.PowerShell_profile.ps1 $profilePath
Copy-Item .\custom.ps1 $profilePath
Copy-Item .\cobalt2.omp.json $profilePath
if (-not (Test-Path -Path (Join-Path $profilePath 'profile.ps1'))) {
    Copy-Item .\profile.ps1 $profilePath
}