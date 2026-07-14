if (-Not ($Env:WT_SESSION)) {
    Write-Host "Use Windows Terminal to Install" -ForegroundColor Red
    return
}

if ($PSVersionTable.PSVersion.Major -ne 7) {
    Write-Host "Use PowerShell 7 to Install" -ForegroundColor Red
    return
}

if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Run Script as Administrator" -ForegroundColor Red
    return
}

if (-Not (Test-Connection 8.8.8.8 -Count 1 -TimeoutSeconds 1 -Quiet)) { 
    Write-Host "Activate internet connection" -ForegroundColor Red
    return
}

if (Test-Path $Profile) {
    Move-Item -Path $Profile -Destination ($Profile + ".bak")
} else {
    New-Item -Path $Profile -Force | Out-Null
}

Write-Host "Profile..." -ForegroundColor Cyan
Invoke-WebRequest -Uri https://github.com/o9-9/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $Profile
Write-Host "✔ Profile" -ForegroundColor Green

Write-Host "Theme..." -ForegroundColor Cyan
$themeDir = "$env:USERPROFILE\.config\ohmyposh"
$themeFile = Join-Path $themeDir "mocha.omp.yaml"
if (-not (Test-Path $themeFile)) {
    New-Item -ItemType Directory -Path $themeDir -Force | Out-Null
    Invoke-WebRequest -Uri "https://github.com/o9-9/powershell-profile/raw/main/ohmyposh/mocha.omp.yaml" -OutFile $themeFile
}
Write-Host "✔ Theme" -ForegroundColor Green

Write-Host "Fonts..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/o9-9/powershell-profile/main/stuff/fonts.zip" -OutFile "$env:TEMP\fonts.zip"
Expand-Archive -Path fonts.zip
Get-ChildItem fonts -Filter *.ttf | ForEach-Object {
    ((New-Object -ComObject Shell.Application).Namespace(0x14)).CopyHere($_.FullName)
    Write-Host -ForegroundColor Green "✔ Font $(Split-Path $_ -Leaf)"
}
Remove-Item -Path fonts.zip
Remove-Item -Path fonts -Recurse

Write-Host "Dependencies..." -ForegroundColor Cyan
Install-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue | Out-Null
Install-Module -Name Terminal-Icons -Force
Write-Host "✔ Dependencies" -ForegroundColor Green

Write-Host "Oh My Posh..." -ForegroundColor Cyan
winget install JanDeDobbeleer.OhMyPosh --source winget --silent
Write-Host "✔ Oh My Posh" -ForegroundColor Green

Write-Host "Zoxide..." -ForegroundColor Cyan
winget install ajeetdsouza.zoxide --source winget --silent
Write-Host "✔ Zoxide" -ForegroundColor Green

Write-Host "✔ Complete" -ForegroundColor Green
