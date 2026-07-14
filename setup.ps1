$Script = Join-Path $env:TEMP setup.ps1

if (-not (Test-Path $Script)) {
    Invoke-WebRequest https://github.com/o9-9/powershell-profile/raw/main/setup.ps1 -OutFile $Script
}

if (-not (Get-Command wt.exe -ErrorAction SilentlyContinue)) {
    winget source reset --force *> $null
    winget source update *> $null
    winget install --id Microsoft.WindowsTerminal --exact --source winget --accept-package-agreements --accept-source-agreements --silent
}

if (-not $Env:WT_SESSION) {
    Start-Process wt.exe "pwsh -NoProfile -ExecutionPolicy Bypass -File `"$Script`""
    return
}

if (-not (Get-Command pwsh.exe -ErrorAction SilentlyContinue)) {
    winget source reset --force *> $null
    winget source update *> $null
    winget install --id Microsoft.PowerShell --exact --source winget --accept-package-agreements --accept-source-agreements --silent
    if (-not (Get-Command pwsh.exe -ErrorAction SilentlyContinue)) {
        Write-Host "Install PowerShell 7 manually" -ForegroundColor Red
        return
    }
}

if ($PSVersionTable.PSVersion.Major -ne 7) {
    Start-Process (Get-Command pwsh.exe).Source -Verb RunAs -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-File","`"$Script`""
    return
}

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Run Script as Administrator" -ForegroundColor Red
    return
}

if (-not (Test-Connection 8.8.8.8 -Count 1 -TimeoutSeconds 1 -Quiet)) {
    Write-Host "Activate internet connection" -ForegroundColor Red
    return
}

if (Test-Path $Profile) {
    Move-Item $Profile "$Profile.bak" -Force
} else {
    New-Item -ItemType File -Path $Profile -Force | Out-Null
}

Write-Host "Profile..." -ForegroundColor Cyan
Invoke-WebRequest https://github.com/o9-9/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $Profile
Write-Host "✔ Profile" -ForegroundColor Green

Write-Host "Theme..." -ForegroundColor Cyan
$ThemeDir = "$env:USERPROFILE\.config\ohmyposh"
$ThemeFile = Join-Path $ThemeDir mocha.omp.yaml
if (-not (Test-Path $ThemeFile)) {
    New-Item -ItemType Directory -Path $ThemeDir -Force | Out-Null
    Invoke-WebRequest https://github.com/o9-9/powershell-profile/raw/main/ohmyposh/mocha.omp.yaml -OutFile $ThemeFile
}
Write-Host "✔ Theme" -ForegroundColor Green

Write-Host "Fonts..." -ForegroundColor Cyan
$Zip = Join-Path $env:TEMP fonts.zip
$Dir = Join-Path $env:TEMP fonts
Invoke-WebRequest https://raw.githubusercontent.com/o9-9/powershell-profile/main/stuff/fonts.zip -OutFile $Zip
Expand-Archive $Zip $Dir -Force
Get-ChildItem $Dir -Filter *.ttf | ForEach-Object {
    (New-Object -ComObject Shell.Application).Namespace(0x14).CopyHere($_.FullName)
    Write-Host "✔ Font $($_.Name)" -ForegroundColor Green
}
Remove-Item $Zip,$Dir -Recurse -Force

Write-Host "Dependencies..." -ForegroundColor Cyan
Install-PackageProvider NuGet -Force -ErrorAction SilentlyContinue | Out-Null
Install-Module Terminal-Icons -Force
Write-Host "✔ Dependencies" -ForegroundColor Green

Write-Host "Oh My Posh..." -ForegroundColor Cyan
winget install --id JanDeDobbeleer.OhMyPosh --exact --source winget --accept-package-agreements --accept-source-agreements --silent
Write-Host "✔ Oh My Posh" -ForegroundColor Green

Write-Host "Zoxide..." -ForegroundColor Cyan
winget install --id ajeetdsouza.zoxide --exact --source winget --accept-package-agreements --accept-source-agreements --silent
Write-Host "✔ Zoxide" -ForegroundColor Green

Write-Host "✔ Complete" -ForegroundColor Green
