<#
.SYNOPSIS
    Renamer files, folder and content
.DESCRIPTION
    Renamer Features:
      1. Folder rename
      2. Files rename
      3. Files content rename
      4. Clone repo and rename
		  5. Local repo rename
.NOTES
    Author         : o9 @o9ll
    GitHub         : https://github.com/o9ll/renamer
.NOTES
    Requires: PowerShell 5.1+
#>

param(
	[string]$RepoUrl,
	[string]$TargetPath,
	[string]$LocalPath,
	[string]$LatestReleaseUrl,
	[switch]$SkipReleaseDownload
)

if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') {
    Write-Host "Renamer is unable to run on your system, powershell execution is restricted by security policies" -ForegroundColor Red
    return
}

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "Renamer needs to be run as Administrator. Attempting to relaunch."
    $argList = @()

    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        $argList += if ($_.Value -is [switch] -and $_.Value) {
            "-$($_.Key)"
        } elseif ($_.Value -is [array]) {
            "-$($_.Key) $($_.Value -join ',')"
        } elseif ($_.Value) {
            "-$($_.Key) '$($_.Value)'"
        }
    }

    $script = "& { & `'$($PSCommandPath)`' $($argList -join ' ') }"

    $powershellCmd = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
    $processCmd = if (Get-Command wt.exe -ErrorAction SilentlyContinue) { "wt.exe" } else { "$powershellCmd" }

    if ($processCmd -eq "wt.exe") {
        Start-Process $processCmd -ArgumentList "$powershellCmd -ExecutionPolicy Bypass -NoProfile -Command `"$script`"" -Verb RunAs
    } else {
        Start-Process $processCmd -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command `"$script`"" -Verb RunAs
    }

    break
}
Clear-Host

$RenamerLogDateStamp = Get-Date -Format "dd-MM-yyyy"

# Set the path to where the script is running
$RenamerRootPath = $PSScriptRoot

$RenamerLogPath = Join-Path $RenamerRootPath "logs"
if (-not (Test-Path $RenamerLogPath)) {
    New-Item -Path $RenamerLogPath -ItemType Directory -Force | Out-Null
}
$RenamerHistoryPath = Join-Path $RenamerRootPath "history"
Start-Transcript -Path (Join-Path $RenamerLogPath "renamer_$(Get-Random -Minimum 0 -Maximum 1000)_$RenamerLogDateStamp.log") -Append -NoClobber | Out-Null

# Set PowerShell window title
$Host.UI.RawUI.WindowTitle = "o9 Renamer"
Clear-Host

$script:RenamerReplacementPairs = @()

$script:RenamerLogAction = {
	param([string]$Message, [ConsoleColor]$Color = [ConsoleColor]::White)
	Write-Host $Message -ForegroundColor $Color
}

function Show-RenamerBanner
{
	$asciiArt = @"
⠀⠀⠀⠀⣀⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⠀
⠀⠀⠀⣿⡏⡏⡏⡏⡏⡏⡏⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷
⠀⠀⠀⣿⢸⡇⡇⡇⡇⢸⡇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟
⠀⠀⠀⠉⠙⣿⣿⣿⣿⣿⣿⣿⣿⡿⢿⡿⠿⢿⣿⡿⠿⠿⠿⠿⠿⠛⠛⠛⠃
⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⠲⡸⣄⠀⠀⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⣸⣿⣿⣿⣿⣿⠀⡿⠛⠿⠿⠻⠶⠿⠿⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⢸⣿⣿⣿⣿⣿⣿⣿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠻⡯⣭⣭⣭⣭⣥⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠛⠛⠓⠛⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
"@
	Write-Host $asciiArt
}

function New-RenamerLogo
{
	param(
		[ValidateSet('logo')]
		[string]$Type = 'logo',
		[double]$Size = 25,
		[switch]$Render,
		[System.Windows.Media.Brush]$Fill
	)

	$logoViewbox = New-Object Windows.Controls.Viewbox
	$logoViewbox.Width = $Size
	$logoViewbox.Height = $Size

	$canvas = New-Object Windows.Controls.Canvas
	$canvas.Width = 125
	$canvas.Height = 125

	$scaleTransform = New-Object Windows.Media.ScaleTransform(($Size / 100), ($Size / 100))
	$canvas.LayoutTransform = $scaleTransform

	$logoPathData = @"
M118.5 44.7a69 69 0 0 1-11 35.4L83 119.8H69.8l26-40.2a18 18 0 0 1-11.1 3.8 27 27 0 0 1-19.5-8l.1 3c0 25.2-11.9 43.3-30.3 43.3-19 0-30.5-18.1-30.5-43.2 0-25.3 11.6-43.2 30.5-43.2q12.3.2 20 9.2c.2-23 13-40.2 32-40.2 19.9 0 31.5 17.5 31.5 40.4M54 78.5c0-18.4-6.1-31.8-19-31.8S15.8 60.1 15.8 78.5c0 18.6 6.2 31.8 19.2 31.8S54 97 54 78.5m53.6-33.8c0-15.6-7.2-29-20.5-29-13.1 0-20.8 13.4-20.8 29.4 0 15.8 7.3 28.6 20.5 28.6 13 0 20.8-13.8 20.8-29
"@
	$logoPath = New-Object Windows.Shapes.Path
	$logoPath.Data = [Windows.Media.Geometry]::Parse($logoPathData)
	$logoPath.Fill = if ($Fill) { $Fill } else { [System.Windows.Media.Brushes]::White }
	[void]$canvas.Children.Add($logoPath)

	$logoViewbox.Child = $canvas
	$logoViewbox.Tag = $logoPath

	if ($Render)
	{
		$canvas.Measure([Windows.Size]::new($canvas.Width, $canvas.Height))
		$canvas.Arrange([Windows.Rect]::new(0, 0, $canvas.Width, $canvas.Height))
		$canvas.UpdateLayout()

		$renderTargetBitmap = New-Object Windows.Media.Imaging.RenderTargetBitmap($canvas.Width, $canvas.Height, 96, 96, [Windows.Media.PixelFormats]::Pbgra32)
		$renderTargetBitmap.Render($canvas)

		$bitmapFrame = [Windows.Media.Imaging.BitmapFrame]::Create($renderTargetBitmap)
		$bitmapEncoder = [Windows.Media.Imaging.PngBitmapEncoder]::new()
		$bitmapEncoder.Frames.Add($bitmapFrame)

		$imageStream = New-Object System.IO.MemoryStream
		$bitmapEncoder.Save($imageStream)
		$imageStream.Position = 0

		$bitmapImage = [Windows.Media.Imaging.BitmapImage]::new()
		$bitmapImage.BeginInit()
		$bitmapImage.StreamSource = $imageStream
		$bitmapImage.CacheOption = [Windows.Media.Imaging.BitmapCacheOption]::OnLoad
		$bitmapImage.EndInit()
		return $bitmapImage
	}

	return $logoViewbox
}

Show-RenamerBanner

$global:RenamerStatusTracker = @{
	Cloning = 'Not Started'
	ReplaceContents = 'Not Started'
	RenameFiles = 'Not Started'
	RenameDirectories = 'Not Started'
	DownloadLatestRelease = 'Not Started'
	FailedOperations = @()
	SuccessfulOperations = @()
}

function Write-RenamerLog
{
	param([string]$Message, [ConsoleColor]$Color = [ConsoleColor]::White)
	& $script:RenamerLogAction $Message $Color
}

function Apply-Replacements
{
	param([string]$Text)
	foreach ($pair in $script:RenamerReplacementPairs)
	{
		if ($pair[0]) { $Text = $Text.Replace($pair[0], $pair[1]) }
	}
	$Text
}

function Update-RenamerStatus
{
	param([string]$Operation, [string]$Status, [string]$Details = '')
	$global:RenamerStatusTracker[$Operation] = $Status
	if ($Status -eq 'Success') { $global:RenamerStatusTracker.SuccessfulOperations += $Operation }
	elseif ($Status -in 'Failed', 'Partial Success') { $global:RenamerStatusTracker.FailedOperations += "$Operation - $Details" }
	if ($Operation -eq 'Cloning') { return }
	Write-RenamerLog "`n=== ${Operation}: $Status ===" ([ConsoleColor]::Yellow)
	if ($Details) { Write-RenamerLog $Details ([ConsoleColor]::Cyan) }
}

function Show-RenamerSummary
{
	Write-RenamerLog "`n=== OPERATION SUMMARY ===" ([ConsoleColor]::Green)
	foreach ($operationName in @('ReplaceContents', 'RenameFiles', 'RenameDirectories', 'DownloadLatestRelease'))
	{
		$color = switch ($global:RenamerStatusTracker[$operationName])
		{
			'Success' { [ConsoleColor]::Green }
			{ $_ -in 'Skipped', 'Not Started' } { [ConsoleColor]::Yellow }
			default { [ConsoleColor]::Red }
		}
		Write-RenamerLog "${operationName}: $($global:RenamerStatusTracker[$operationName])" $color
	}
	if ($global:RenamerStatusTracker.FailedOperations.Count -gt 0)
	{
		Write-RenamerLog "`nFailed Operations:" ([ConsoleColor]::Red)
		foreach ($failedOperation in $global:RenamerStatusTracker.FailedOperations) { Write-RenamerLog " - $failedOperation" ([ConsoleColor]::Red) }
	}
	Write-RenamerLog "`nCurrent Date and Time (UTC): $((Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss'))" ([ConsoleColor]::White)
	Write-RenamerLog "Current User: $env:USERNAME" ([ConsoleColor]::White)
}

function Test-IsBinaryFile
{
	param([string]$FilePath)
	try
	{
		$bytes = [System.IO.File]::ReadAllBytes($FilePath)
		for ($i = 0; $i -lt [Math]::Min($bytes.Length, 1024); $i++)
		{
			if ($bytes[$i] -eq 0) { return $true }
		}
		return $false
	}
	catch { return $true }
}

function Clone-Repository
{
	param([string]$RepoUrl, [string]$TargetPath)
	try
	{
		if (Test-Path $TargetPath)
		{
			Remove-Item -Path $TargetPath -Force -Recurse -ErrorAction Stop
		}
		$parentDir = Split-Path -Parent $TargetPath
		if ($parentDir -and -not (Test-Path $parentDir))
		{
			New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
		}
		git clone $RepoUrl $TargetPath
		if ($LASTEXITCODE -ne 0) { throw "Git clone failed with exit code $LASTEXITCODE" }
		Update-RenamerStatus -Operation 'Cloning' -Status 'Success' -Details "Repository cloned to $TargetPath"
		return $true
	}
	catch
	{
		Update-RenamerStatus -Operation 'Cloning' -Status 'Failed' -Details "Error: $($_.Exception.Message)`nSolution: Make sure git is installed, you have internet access, and the repository URL is correct."
		return $false
	}
}

function Replace-FileContents
{
	param([string]$TargetPath)
	try
	{
		Write-RenamerLog 'Starting content replacement in all files...' ([ConsoleColor]::Yellow)
		$files = @(Get-ChildItem -Path $TargetPath -File -Recurse -Force -ErrorAction SilentlyContinue)
		$processedFiles = 0
		$failedFiles = @()
		foreach ($file in $files)
		{
			$processedFiles++
			if ($files.Count -gt 0)
			{
				Write-Progress -Activity 'Replacing content in files' -Status "Processing file $processedFiles of $($files.Count)" -PercentComplete (($processedFiles / $files.Count) * 100)
			}
			if (Test-IsBinaryFile -FilePath $file.FullName) { continue }
			try
			{
				$content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
				$updated = Apply-Replacements $content
				if ($updated -ne $content)
				{
					Set-Content -Path $file.FullName -Value $updated -Force -ErrorAction Stop
				}
			}
			catch
			{
				$failedFiles += "$($file.FullName): $($_.Exception.Message)"
				Write-RenamerLog "Failed to process file: $($file.FullName)" ([ConsoleColor]::Red)
			}
		}
		Write-Progress -Activity 'Replacing content in files' -Completed
		if ($failedFiles.Count -eq 0)
		{
			Update-RenamerStatus -Operation 'ReplaceContents' -Status 'Success' -Details "Content replaced in $processedFiles files"
			return $true
		}
		Update-RenamerStatus -Operation 'ReplaceContents' -Status 'Partial Success' -Details "Failed to process $($failedFiles.Count) files.`n$($failedFiles -join ', ')"
		return $false
	}
	catch
	{
		Update-RenamerStatus -Operation 'ReplaceContents' -Status 'Failed' -Details "Error: $($_.Exception.Message)`nSolution: Check file permissions and make sure files are not locked."
		return $false
	}
}

function Get-FoldersByDepth
{
	param([string]$RootPath)
	Get-ChildItem -Path $RootPath -Directory -Recurse -Force -ErrorAction SilentlyContinue | Select-Object FullName, @{
		Name = 'Depth'; Expression = { ($_.FullName -split '\\').Count }
	} | Sort-Object -Property Depth -Descending
}

function Rename-Directories
{
	param([string]$TargetPath)
	try
	{
		$folders = @(Get-FoldersByDepth -RootPath $TargetPath)
		$processedFolders = 0
		$failedFolders = @()
		Write-RenamerLog 'Starting directory renaming (deepest first)...' ([ConsoleColor]::Yellow)
		foreach ($folder in $folders)
		{
			$processedFolders++
			if ($folders.Count -gt 0)
			{
				Write-Progress -Activity 'Renaming directories' -Status "Processing folder $processedFolders of $($folders.Count)" -PercentComplete (($processedFolders / $folders.Count) * 100)
			}
			$folderName = Split-Path -Leaf $folder.FullName
			$newFolderName = Apply-Replacements $folderName
			if ($newFolderName -eq $folderName) { continue }
			$newFolderPath = Join-Path (Split-Path -Parent $folder.FullName) $newFolderName
			try
			{
				if (Test-Path $newFolderPath) { throw "Target folder already exists: $newFolderPath" }
				Rename-Item -Path $folder.FullName -NewName $newFolderName -ErrorAction Stop
			}
			catch
			{
				$failedFolders += "$($folder.FullName): $($_.Exception.Message)"
				Write-RenamerLog "Failed to rename folder: $($folder.FullName)" ([ConsoleColor]::Red)
			}
		}
		Write-Progress -Activity 'Renaming directories' -Completed
		if ($failedFolders.Count -eq 0)
		{
			Update-RenamerStatus -Operation 'RenameDirectories' -Status 'Success' -Details "Successfully renamed directories"
			return $true
		}
		Update-RenamerStatus -Operation 'RenameDirectories' -Status 'Partial Success' -Details "Failed to rename $($failedFolders.Count) directories.`n$($failedFolders -join ', ')"
		return $false
	}
	catch
	{
		Update-RenamerStatus -Operation 'RenameDirectories' -Status 'Failed' -Details "Error: $($_.Exception.Message)`nSolution: Check folder permissions and make sure folders are not in use."
		return $false
	}
}

function Rename-Files
{
	param([string]$TargetPath)
	try
	{
		$files = @(Get-ChildItem -Path $TargetPath -File -Recurse -Force -ErrorAction SilentlyContinue)
		$processedFiles = 0
		$failedFiles = @()
		Write-RenamerLog 'Starting file renaming...' ([ConsoleColor]::Yellow)
		foreach ($file in $files)
		{
			$processedFiles++
			if ($files.Count -gt 0)
			{
				Write-Progress -Activity 'Renaming files' -Status "Processing file $processedFiles of $($files.Count)" -PercentComplete (($processedFiles / $files.Count) * 100)
			}
			$newFileName = Apply-Replacements $file.Name
			if ($newFileName -eq $file.Name) { continue }
			$newFilePath = Join-Path $file.DirectoryName $newFileName
			try
			{
				if (Test-Path $newFilePath) { throw "Target file already exists: $newFilePath" }
				Rename-Item -Path $file.FullName -NewName $newFileName -ErrorAction Stop
			}
			catch
			{
				$failedFiles += "$($file.FullName): $($_.Exception.Message)"
				Write-RenamerLog "Failed to rename file: $($file.FullName)" ([ConsoleColor]::Red)
			}
		}
		Write-Progress -Activity 'Renaming files' -Completed
		if ($failedFiles.Count -eq 0)
		{
			Update-RenamerStatus -Operation 'RenameFiles' -Status 'Success' -Details 'Successfully renamed files'
			return $true
		}
		Update-RenamerStatus -Operation 'RenameFiles' -Status 'Partial Success' -Details "Failed to rename $($failedFiles.Count) files.`n$($failedFiles -join ', ')"
		return $false
	}
	catch
	{
		Update-RenamerStatus -Operation 'RenameFiles' -Status 'Failed' -Details "Error: $($_.Exception.Message)`nSolution: Check file permissions and make sure files are not locked."
		return $false
	}
}

function Get-LatestReleaseFile
{
	param([string]$ReleaseUrl, [string]$TargetPath)
	try
	{
		if (-not $ReleaseUrl)
		{
			Update-RenamerStatus -Operation 'DownloadLatestRelease' -Status 'Skipped' -Details 'No release URL provided'
			return $true
		}
		Write-RenamerLog "Downloading latest release from $ReleaseUrl..." ([ConsoleColor]::Yellow)
		if (-not (Test-Path $TargetPath)) { throw "Target path does not exist: $TargetPath" }
		$originalFileName = Split-Path -Leaf $ReleaseUrl
		$newFileName = Apply-Replacements $originalFileName
		$tempFilePath = Join-Path $env:TEMP $originalFileName
		$finalFilePath = Join-Path $TargetPath $newFileName
		Invoke-WebRequest -Uri $ReleaseUrl -OutFile $tempFilePath -UseBasicParsing
		if (-not (Test-Path $tempFilePath)) { throw "Failed to download file: $ReleaseUrl" }
		if (Test-IsBinaryFile $tempFilePath)
		{
			Move-Item -Path $tempFilePath -Destination $finalFilePath -Force
		}
		else
		{
			$content = Apply-Replacements (Get-Content -Path $tempFilePath -Raw)
			Set-Content -Path $finalFilePath -Value $content -Force
			Remove-Item -Path $tempFilePath -Force
		}
		Write-RenamerLog "Latest release saved as: $finalFilePath" ([ConsoleColor]::Green)
		Update-RenamerStatus -Operation 'DownloadLatestRelease' -Status 'Success' -Details "Release file saved to $finalFilePath"
		return $true
	}
	catch
	{
		Update-RenamerStatus -Operation 'DownloadLatestRelease' -Status 'Failed' -Details "Error: $($_.Exception.Message)`nSolution: Check internet connectivity and if the release URL is valid."
		return $false
	}
}

function Invoke-Renamer
{
	param(
		[string]$RepoUrl,
		[string]$TargetPath,
		[string]$LocalPath,
		[string]$LatestReleaseUrl,
		[array]$ReplacementPairs = @(),
		[switch]$SkipReleaseDownload
	)

	$script:RenamerReplacementPairs = @($ReplacementPairs | Where-Object { $_ -and $_[0] })

	$global:RenamerStatusTracker = @{
		Cloning = 'Not Started'
		ReplaceContents = 'Not Started'
		RenameFiles = 'Not Started'
		RenameDirectories = 'Not Started'
		DownloadLatestRelease = 'Not Started'
		FailedOperations = @()
		SuccessfulOperations = @()
	}

	$workingPath = $null
	if ($LocalPath)
	{
		$workingPath = [System.IO.Path]::GetFullPath($LocalPath)
		if (-not (Test-Path -LiteralPath $workingPath -PathType Container))
		{
			Update-RenamerStatus -Operation 'Cloning' -Status 'Failed' -Details "Local path does not exist: $workingPath"
			Show-RenamerSummary
			return
		}
		Update-RenamerStatus -Operation 'Cloning' -Status 'Skipped' -Details "Using local folder: $workingPath"
	}
	else
	{
		if (-not $RepoUrl)
		{
			Update-RenamerStatus -Operation 'Cloning' -Status 'Failed' -Details 'Repository URL is required.'
			Show-RenamerSummary
			return
		}
		if (-not $TargetPath)
		{
			Update-RenamerStatus -Operation 'Cloning' -Status 'Failed' -Details 'Target path is required.'
			Show-RenamerSummary
			return
		}
		$workingPath = [System.IO.Path]::GetFullPath($TargetPath)
		if (-not (Clone-Repository -RepoUrl $RepoUrl -TargetPath $workingPath))
		{
			Show-RenamerSummary
			return
		}
	}

	Replace-FileContents -TargetPath $workingPath | Out-Null
	Rename-Files -TargetPath $workingPath | Out-Null
	Rename-Directories -TargetPath $workingPath | Out-Null
	if (-not $SkipReleaseDownload)
	{
		Get-LatestReleaseFile -ReleaseUrl $LatestReleaseUrl -TargetPath $workingPath | Out-Null
	}
	else
	{
		Update-RenamerStatus -Operation 'DownloadLatestRelease' -Status 'Skipped' -Details 'Release download skipped'
	}
	Show-RenamerSummary
}

function Show-FolderDialog
{
	param([string]$Description = 'Select a folder', [string]$InitialPath = '')
	Add-Type -AssemblyName System.Windows.Forms
	$dialog = New-Object System.Windows.Forms.FolderBrowserDialog
	$dialog.Description = $Description
	if ($InitialPath -and (Test-Path $InitialPath)) { $dialog.SelectedPath = $InitialPath }
	if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return $dialog.SelectedPath }
	return $null
}

function Get-RenamerHistoryPath
{
	if (-not (Test-Path $RenamerHistoryPath)) {
		New-Item -Path $RenamerHistoryPath -ItemType Directory -Force | Out-Null
	}
	$RenamerHistoryPath
}

function Get-LatestRenamerHistorySession
{
	Get-ChildItem -Path (Get-RenamerHistoryPath) -Directory -ErrorAction SilentlyContinue |
		Where-Object { Test-Path (Join-Path $_.FullName 'session.json') } |
		Sort-Object LastWriteTime -Descending |
		Select-Object -First 1
}

function Save-RenamerSession
{
	param(
		[string]$WorkingPath,
		[string]$RepoUrl,
		[string]$TargetPath,
		[bool]$IsLocalMode,
		[string]$LatestReleaseUrl,
		[bool]$SkipReleaseDownload,
		[array]$ReplacementPairs
	)
	if (-not $WorkingPath -or -not (Test-Path -LiteralPath $WorkingPath -PathType Container)) { return $null }

	$sessionDir = Join-Path (Get-RenamerHistoryPath) (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')
	$renamerContentsDir = Join-Path $sessionDir 'renamer_contents'
	New-Item -Path $renamerContentsDir -ItemType Directory -Force | Out-Null
	& robocopy $WorkingPath $renamerContentsDir /E /COPY:DAT /NFL /NDL /NJH /NJS /nc /ns /np 2>$null | Out-Null
	if ($LASTEXITCODE -gt 7) { Remove-Item -Path $sessionDir -Recurse -Force -ErrorAction SilentlyContinue; return $null }

	@{
		LastModified = (Get-Date).ToString('dd-MM-yyyy HH:mm')
		RenamerWorkDir = $sessionDir
		RenamerContentsDir = $renamerContentsDir
		RepoUrl = $RepoUrl
		TargetPath = $TargetPath
		IsLocalMode = $IsLocalMode
		LatestReleaseUrl = $LatestReleaseUrl
		SkipReleaseDownload = $SkipReleaseDownload
		ReplacementPairs = @($ReplacementPairs)
	} | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $sessionDir 'session.json') -Encoding UTF8

	$sessionDir
}

function Get-RenamerRunspaceScript
{
	(
		@(
			'Apply-Replacements', 'Write-RenamerLog', 'Update-RenamerStatus', 'Show-RenamerSummary', 'Test-IsBinaryFile',
			'Get-FoldersByDepth', 'Clone-Repository', 'Replace-FileContents', 'Rename-Files',
			'Rename-Directories', 'Get-LatestReleaseFile', 'Invoke-Renamer'
		) | ForEach-Object {
			$cmd = Get-Command $_ -CommandType Function
			"function $($cmd.Name) {`n$($cmd.ScriptBlock.ToString())`n}"
		}
	) -join "`n"
}

function Show-RenamerWindow
{
	Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

	[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Renamer"
        Width="1400" Height="1150" MinWidth="1100" MinHeight="850"
        WindowStartupLocation="CenterScreen" UseLayoutRounding="True"
        ResizeMode="CanResize" WindowStyle="None"
        Background="Transparent" AllowsTransparency="True">
    <WindowChrome.WindowChrome>
        <WindowChrome CaptionHeight="0" CornerRadius="10" ResizeBorderThickness="8"
                      GlassFrameThickness="0"/>
    </WindowChrome.WindowChrome>
    <Window.Resources>
        <Style x:Key="ScrollThumbs" TargetType="{x:Type Thumb}">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type Thumb}">
                        <Grid>
                            <Rectangle Fill="Transparent"/>
                            <Border x:Name="ThumbBorder" CornerRadius="5"
                                    Background="{TemplateBinding Background}"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="Tag" Value="Horizontal">
                                <Setter TargetName="ThumbBorder" Property="Height" Value="7"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="{x:Type ScrollBar}">
            <Setter Property="Stylus.IsFlicksEnabled" Value="False"/>
            <Setter Property="Foreground" Value="{DynamicResource ScrollBarBackgroundColor}"/>
            <Setter Property="Background" Value="{DynamicResource MainBackgroundColor}"/>
            <Setter Property="Width" Value="6"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type ScrollBar}">
                        <Grid x:Name="GridRoot" Width="7" Background="{TemplateBinding Background}">
                            <Track x:Name="PART_Track" IsDirectionReversed="True" Focusable="False">
                                <Track.Thumb>
                                    <Thumb x:Name="Thumb" Background="{TemplateBinding Foreground}"
                                           Style="{DynamicResource ScrollThumbs}"/>
                                </Track.Thumb>
                                <Track.IncreaseRepeatButton>
                                    <RepeatButton Command="ScrollBar.PageDownCommand" Opacity="0" Focusable="False"/>
                                </Track.IncreaseRepeatButton>
                                <Track.DecreaseRepeatButton>
                                    <RepeatButton Command="ScrollBar.PageUpCommand" Opacity="0" Focusable="False"/>
                                </Track.DecreaseRepeatButton>
                            </Track>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger SourceName="Thumb" Property="IsMouseOver" Value="True">
                                <Setter TargetName="Thumb" Property="Background" Value="{DynamicResource ScrollBarHoverColor}"/>
                            </Trigger>
                            <Trigger SourceName="Thumb" Property="IsDragging" Value="True">
                                <Setter TargetName="Thumb" Property="Background" Value="{DynamicResource ScrollBarDraggingColor}"/>
                            </Trigger>
                            <Trigger Property="Orientation" Value="Horizontal">
                                <Setter TargetName="GridRoot" Property="LayoutTransform">
                                    <Setter.Value><RotateTransform Angle="-90"/></Setter.Value>
                                </Setter>
                                <Setter Property="Width" Value="Auto"/>
                                <Setter Property="Height" Value="8"/>
                                <Setter TargetName="Thumb" Property="Tag" Value="Horizontal"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="TitleBarButtonStyle" TargetType="Button">
            <Setter Property="Width" Value="30"/>
            <Setter Property="Height" Value="30"/>
            <Setter Property="Padding" Value="0"/>
            <Setter Property="Margin" Value="0"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderBrush" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Foreground" Value="{DynamicResource MainForegroundColor}"/>
            <Setter Property="FontFamily" Value="Segoe MDL2 Assets"/>
            <Setter Property="FontSize" Value="10"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="HorizontalAlignment" Value="Center"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}"
                                CornerRadius="4" Padding="0">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource ButtonBackgroundMouseoverColor}"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource ButtonBackgroundSelectedColor}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="RunButtonStyle" TargetType="Button">
            <Setter Property="Width" Value="120"/>
            <Setter Property="Height" Value="30"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="Background" Value="{DynamicResource ToggleButtonOnColor}"/>
            <Setter Property="BorderBrush" Value="{DynamicResource ToggleButtonOnColor}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="4" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource RunButtonHoverColor}"/>
                                <Setter TargetName="Bd" Property="BorderBrush" Value="{DynamicResource RunButtonHoverColor}"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource RunButtonPressedColor}"/>
                                <Setter TargetName="Bd" Property="BorderBrush" Value="{DynamicResource RunButtonPressedColor}"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Bd" Property="Opacity" Value="0.5"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Height" Value="28"/>
            <Setter Property="Padding" Value="8,0"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="HorizontalAlignment" Value="Stretch"/>
            <Setter Property="Background" Value="{DynamicResource ComboBoxBackgroundColor}"/>
            <Setter Property="Foreground" Value="{DynamicResource MainForegroundColor}"/>
            <Setter Property="BorderBrush" Value="{DynamicResource BorderColor}"/>
            <Setter Property="CaretBrush" Value="{DynamicResource MainForegroundColor}"/>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Height" Value="28"/>
            <Setter Property="Padding" Value="12,0"/>
            <Setter Property="Background" Value="{DynamicResource ButtonBackgroundColor}"/>
            <Setter Property="Foreground" Value="{DynamicResource ButtonForegroundColor}"/>
            <Setter Property="BorderBrush" Value="{DynamicResource BorderColor}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="4" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource ButtonBackgroundMouseoverColor}"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource ButtonBackgroundSelectedColor}"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Bd" Property="Opacity" Value="0.5"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="RadioButton">
            <Setter Property="Foreground" Value="{DynamicResource MainForegroundColor}"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{DynamicResource MainForegroundColor}"/>
        </Style>
        <Style x:Key="SectionCardStyle" TargetType="Border">
            <Setter Property="Background" Value="{DynamicResource SectionBackgroundColor}"/>
            <Setter Property="BorderBrush" Value="{DynamicResource BorderColor}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="5"/>
            <Setter Property="Padding" Value="14"/>
            <Setter Property="Margin" Value="0,0,0,16"/>
            <Setter Property="Effect">
                <Setter.Value>
                    <DropShadowEffect Color="#000000" Opacity="0.18" BlurRadius="10" ShadowDepth="2" Direction="270"/>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="SectionHeaderStyle" TargetType="TextBlock">
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Foreground" Value="{DynamicResource LabelboxForegroundColor}"/>
            <Setter Property="Margin" Value="0,0,0,12"/>
        </Style>
        <Style x:Key="FieldLabelStyle" TargetType="TextBlock">
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Foreground" Value="{DynamicResource MainForegroundColor}"/>
            <Setter Property="Opacity" Value="0.85"/>
            <Setter Property="Margin" Value="0,0,0,4"/>
        </Style>
    </Window.Resources>
    <Border CornerRadius="10" BorderThickness="1" ClipToBounds="True"
            Background="{DynamicResource MainBackgroundColor}"
            BorderBrush="{DynamicResource BorderColor}">
        <Grid ClipToBounds="True">
            <Grid.RowDefinitions>
                <RowDefinition Height="44"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <Border Grid.Row="0" x:Name="TitleBar"
                    Background="{DynamicResource MainBackgroundColor}"
                    CornerRadius="10,10,0,0" Padding="12,8,10,4">
                <Grid>
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center" HorizontalAlignment="Left">
                        <StackPanel x:Name="NavLogoPanel" Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,8,0"/>
                        <TextBlock Text="Renamer" VerticalAlignment="Center"
                                   FontSize="14" FontWeight="Bold" Foreground="{DynamicResource MainForegroundColor}"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                        <Button x:Name="ThemeButton" Style="{StaticResource TitleBarButtonStyle}"
                                FontSize="11" ToolTip="Toggle theme" Content="&#xE793;"/>
                        <Button x:Name="SettingsButton" Style="{StaticResource TitleBarButtonStyle}"
                                FontSize="11" ToolTip="Settings" Content="&#xE713;"/>
                        <Popup x:Name="SettingsPopup" IsOpen="False" StaysOpen="False"
                               PlacementTarget="{Binding ElementName=SettingsButton}" Placement="Bottom"
                               VerticalOffset="4">
                            <Border Background="{DynamicResource MainBackgroundColor}"
                                    BorderBrush="{DynamicResource BorderColor}" BorderThickness="1">
                                <StackPanel MinWidth="160">
                                    <MenuItem x:Name="ResetMenuItem" Header="Reset"
                                              Foreground="{DynamicResource MainForegroundColor}"
                                              Background="{DynamicResource MainBackgroundColor}"/>
                                    <MenuItem x:Name="AboutMenuItem" Header="About"
                                              Foreground="{DynamicResource MainForegroundColor}"
                                              Background="{DynamicResource MainBackgroundColor}"/>
                                    <MenuItem x:Name="GitHubMenuItem" Header="GitHub"
                                              Foreground="{DynamicResource MainForegroundColor}"
                                              Background="{DynamicResource MainBackgroundColor}"/>
                                </StackPanel>
                            </Border>
                        </Popup>
                        <Button x:Name="CloseButton" Style="{StaticResource TitleBarButtonStyle}"
                                Margin="4,0,0,0" FontSize="10" Content="&#xE8BB;"/>
                    </StackPanel>
                </Grid>
            </Border>

            <ScrollViewer x:Name="MainScroll" Grid.Row="1" Margin="12,0,12,8"
                          VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                <StackPanel Margin="4,0,4,4">

                    <Border x:Name="RepositorySection" Style="{StaticResource SectionCardStyle}">
                        <StackPanel>
                            <TextBlock Text="Repository" Style="{StaticResource SectionHeaderStyle}"/>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,14">
                                <RadioButton x:Name="CloneRepositoryRadio" Content="Clone repository" IsChecked="True" Margin="0,0,24,0"/>
                                <RadioButton x:Name="LocalFolderRadio" Content="Use local folder"/>
                            </StackPanel>
                            <StackPanel x:Name="RepoPanel" Margin="0,0,0,14">
                                <TextBlock Text="Repository URL" Style="{StaticResource FieldLabelStyle}"/>
                                <TextBox x:Name="RepoUrlBox"/>
                            </StackPanel>
                            <StackPanel Margin="0,0,0,14">
                                <TextBlock x:Name="TargetLabel" Text="Target path" Style="{StaticResource FieldLabelStyle}"/>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="Auto"/>
                                    </Grid.ColumnDefinitions>
                                    <TextBox x:Name="TargetPathBox" Grid.Column="0"/>
                                    <Button x:Name="BrowseButton" Grid.Column="1" Content="Browse" Margin="8,0,0,0" Width="88"/>
                                </Grid>
                            </StackPanel>
                            <StackPanel Margin="0,0,0,14">
                                <TextBlock Text="Latest release URL (optional)" Style="{StaticResource FieldLabelStyle}"/>
                                <TextBox x:Name="LatestReleaseUrlBox"/>
                            </StackPanel>
                            <CheckBox x:Name="SkipReleaseDownloadBox" Content="Skip release download"/>
                        </StackPanel>
                    </Border>

                    <Border x:Name="ReplacementSection" Style="{StaticResource SectionCardStyle}">
                        <StackPanel>
                            <TextBlock Text="Find &amp; Replace" Style="{StaticResource SectionHeaderStyle}"/>
                            <Grid Margin="0,0,0,8">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="32"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <TextBlock Text="Find" FontWeight="SemiBold" Foreground="{DynamicResource MainForegroundColor}"/>
                                <TextBlock Grid.Column="2" Text="Replace" FontWeight="SemiBold" Foreground="{DynamicResource MainForegroundColor}"/>
                            </Grid>
                            <Border BorderBrush="{DynamicResource BorderColor}" BorderThickness="1"
                                    CornerRadius="4" Padding="8" Margin="0,0,0,8"
                                    Background="{DynamicResource ComboBoxBackgroundColor}">
                                <StackPanel x:Name="PairsPanel"/>
                            </Border>
                            <Button x:Name="AddReplacementPairButton" Content="+ Add pair" Width="110" HorizontalAlignment="Left"/>
                        </StackPanel>
                    </Border>

                    <Border x:Name="OutputSection" Style="{StaticResource SectionCardStyle}" Margin="0">
                        <Grid MinHeight="220">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <TextBlock Grid.Row="0" Text="Status Log"
                                       FontSize="14" FontWeight="Bold"
                                       Foreground="{DynamicResource MainForegroundColor}"
                                       Margin="0,0,0,4"/>
                            <Border Grid.Row="1" MinHeight="200"
                                    Background="{DynamicResource ComboBoxBackgroundColor}"
                                    BorderBrush="{DynamicResource BorderColor}" BorderThickness="1">
                                <Grid>
                                    <TextBlock x:Name="StatusLogPlaceholder"
                                               Text="Ready."
                                               TextWrapping="Wrap" TextAlignment="Center"
                                               HorizontalAlignment="Center" VerticalAlignment="Center"
                                               Foreground="{DynamicResource MainForegroundColor}"
                                               Opacity="0.65" Margin="12"/>
                                    <ScrollViewer x:Name="StatusLogScroll" Visibility="Collapsed"
                                                  VerticalScrollBarVisibility="Auto"
                                                  HorizontalScrollBarVisibility="Disabled"
                                                  VerticalAlignment="Stretch" Padding="6">
                                        <TextBlock x:Name="StatusLog" TextWrapping="Wrap"
                                                   HorizontalAlignment="Stretch" VerticalAlignment="Top"
                                                   TextAlignment="Left"
                                                   Foreground="{DynamicResource MainForegroundColor}"/>
                                    </ScrollViewer>
                                </Grid>
                            </Border>
                        </Grid>
                    </Border>

                </StackPanel>
            </ScrollViewer>

            <Border Grid.Row="2" BorderBrush="{DynamicResource BorderColor}" BorderThickness="0,1,0,0"
                    Background="{DynamicResource MainBackgroundColor}" Padding="12,10"
                    CornerRadius="0,0,10,10">
                <Button x:Name="RunButton" Style="{StaticResource RunButtonStyle}" Content="Run"
                        HorizontalAlignment="Right"/>
            </Border>
        </Grid>
    </Border>
</Window>
'@

	$reader = New-Object System.Xml.XmlNodeReader $xaml
	$window = [Windows.Markup.XamlReader]::Load($reader)

	$renamerThemes = @{
		Dark = @{
			MainBackgroundColor = '#232629'; MainForegroundColor = '#ECEFF4'; BorderColor = '#434C5E'
			SectionBackgroundColor = '#2E3440'; LabelboxForegroundColor = '#5BDCFF'
			ComboBoxBackgroundColor = '#1E2124'
			ButtonBackgroundColor = '#3B4252'; ButtonForegroundColor = '#ECEFF4'
			ButtonBackgroundMouseoverColor = '#4C566A'; ButtonBackgroundSelectedColor = '#5E81AC'
			ScrollBarBackgroundColor = '#2E3135'; ScrollBarHoverColor = '#3B4252'; ScrollBarDraggingColor = '#5E81AC'
			ToggleButtonOnColor = '#4C7FD4'; RunButtonHoverColor = '#3D6FB8'; RunButtonPressedColor = '#2F5F9E'
		}
		Light = @{
			MainBackgroundColor = '#F7F7F7'; MainForegroundColor = '#232629'; BorderColor = '#232629'
			SectionBackgroundColor = '#FFFFFF'; LabelboxForegroundColor = '#232629'
			ComboBoxBackgroundColor = '#F7F7F7'
			ButtonBackgroundColor = '#F5F5F5'; ButtonForegroundColor = '#232629'
			ButtonBackgroundMouseoverColor = '#C2C2C2'; ButtonBackgroundSelectedColor = '#F0F0F0'
			ScrollBarBackgroundColor = '#4A4D52'; ScrollBarHoverColor = '#5A5D62'; ScrollBarDraggingColor = '#6A6D72'
			ToggleButtonOnColor = '#5E81AC'; RunButtonHoverColor = '#4C6F96'; RunButtonPressedColor = '#3D5F86'
		}
	}

	function Set-RenamerTheme
	{
		param([bool]$Dark)
		$activeThemePalette = if ($Dark) { $renamerThemes.Dark } else { $renamerThemes.Light }
		foreach ($key in $activeThemePalette.Keys)
		{
			$window.Resources[$key] = [System.Windows.Media.SolidColorBrush]::new(
				[System.Windows.Media.ColorConverter]::ConvertFromString($activeThemePalette[$key]))
		}
		if ($themeButton) { $themeButton.Content = if ($Dark) { [char]0xE793 } else { [char]0xE708 } }
		if ($renamerLogoPath) { $renamerLogoPath.Fill = $window.Resources['MainForegroundColor'] }
	}

	$titleBar = $window.FindName('TitleBar')
	$navLogoPanel = $window.FindName('NavLogoPanel')
	$themeButton = $window.FindName('ThemeButton')
	$settingsButton = $window.FindName('SettingsButton')
	$settingsPopup = $window.FindName('SettingsPopup')
	$resetMenuItem = $window.FindName('ResetMenuItem')
	$aboutMenuItem = $window.FindName('AboutMenuItem')
	$githubMenuItem = $window.FindName('GitHubMenuItem')
	$closeButton = $window.FindName('CloseButton')
	$mainScroll = $window.FindName('MainScroll')
	$outputSection = $window.FindName('OutputSection')
	$cloneRepositoryRadio = $window.FindName('CloneRepositoryRadio')
	$localFolderRadio = $window.FindName('LocalFolderRadio')
	$repoPanel = $window.FindName('RepoPanel')
	$targetLabel = $window.FindName('TargetLabel')
	$repoUrlBox = $window.FindName('RepoUrlBox')
	$targetPathBox = $window.FindName('TargetPathBox')
	$latestReleaseUrlBox = $window.FindName('LatestReleaseUrlBox')
	$skipReleaseDownloadBox = $window.FindName('SkipReleaseDownloadBox')
	$browseButton = $window.FindName('BrowseButton')
	$replacementPairsPanel = $window.FindName('PairsPanel')
	$addReplacementPairButton = $window.FindName('AddReplacementPairButton')
	$statusLog = $window.FindName('StatusLog')
	$statusLogScroll = $window.FindName('StatusLogScroll')
	$statusLogPlaceholder = $window.FindName('StatusLogPlaceholder')
	$runButton = $window.FindName('RunButton')
	$repositorySection = $window.FindName('RepositorySection')
	$replacementSection = $window.FindName('ReplacementSection')
	$renamerSync = @{
		RenamerWorkDir = $null
		RenamerContentsDir = $null
		RenamerModifying = $false
		RepositorySection = $repositorySection
		ReplacementSection = $replacementSection
		OutputSection = $outputSection
	}

	$renamerStatusLogState = @{ HasContent = $false }

	$renamerReplacementPairRows = [System.Collections.Generic.List[object]]::new()
	$renamerThemeState = @{ IsDark = $true }
	$renamerLogoPath = $null

	Set-RenamerTheme -Dark $renamerThemeState.IsDark
	$logoViewbox = New-RenamerLogo -Type logo -Size 25 -Fill $window.Resources['MainForegroundColor']
	$renamerLogoPath = $logoViewbox.Tag
	[void]$navLogoPanel.Children.Add($logoViewbox)

	function Add-RenamerStatusLogLines
	{
		param([string[]]$Lines)
		$pendingLines = @($Lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
		if ($pendingLines.Count -eq 0) { return }
		if ($statusLogPlaceholder.Visibility -eq 'Visible') {
			$statusLogPlaceholder.Visibility = 'Collapsed'
			$statusLogScroll.Visibility = 'Visible'
		}
		$renamerStatusLogState.HasContent = $true
		$block = $pendingLines -join "`n"
		if ([string]::IsNullOrEmpty($statusLog.Text)) { $statusLog.Text = $block }
		else { $statusLog.Text += "`n$block" }
		$statusLogScroll.ScrollToVerticalOffset($statusLogScroll.ExtentHeight)
	}

	function Clear-RenamerStatusLog
	{
		$renamerStatusLogState.HasContent = $false
		$statusLog.Text = ''
		$statusLogScroll.Visibility = 'Collapsed'
		$statusLogScroll.ScrollToVerticalOffset(0)
		$statusLogPlaceholder.Visibility = 'Visible'
	}

	function Write-RenamerStatusLog
	{
		param([string]$Message)
		$ts = (Get-Date).ToString('HH:mm:ss')
		$lines = @($Message -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { "[$ts] $_" })
		if ($lines.Count -eq 0) { return }
		$batch = $lines
		$statusLog.Dispatcher.BeginInvoke([action]{ Add-RenamerStatusLogLines $batch }) | Out-Null
	}

	function Set-RenamerOutputInView
	{
		$outputSection.BringIntoView()
		$mainScroll.ScrollToEnd()
	}

	function Add-RenamerReplacementPairRow
	{
		$rowGrid = New-Object System.Windows.Controls.Grid
		$rowGrid.Margin = [System.Windows.Thickness]::new(0, 0, 0, 4)
		$rowGrid.HorizontalAlignment = 'Stretch'
		foreach ($columnWidth in '1 Star', 'Auto', '1 Star')
		{
			$col = New-Object System.Windows.Controls.ColumnDefinition
			if ($columnWidth -like '*Star*') { $col.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star) }
			else { $col.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Auto) }
			[void]$rowGrid.ColumnDefinitions.Add($col)
		}
		$findTextBox = New-Object System.Windows.Controls.TextBox
		$findTextBox.Height = 28; $findTextBox.HorizontalAlignment = 'Stretch'
		$findTextBox.Padding = [System.Windows.Thickness]::new(8, 0, 8, 0)
		$findTextBox.VerticalContentAlignment = 'Center'
		[Windows.Controls.Grid]::SetColumn($findTextBox, 0)
		$arrow = New-Object System.Windows.Controls.TextBlock
		$arrow.Text = [char]0x2192; $arrow.VerticalAlignment = 'Center'; $arrow.HorizontalAlignment = 'Center'
		$arrow.Margin = [System.Windows.Thickness]::new(8, 0, 8, 0)
		$arrow.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, 'MainForegroundColor')
		[Windows.Controls.Grid]::SetColumn($arrow, 1)
		$replaceTextBox = New-Object System.Windows.Controls.TextBox
		$replaceTextBox.Height = 28; $replaceTextBox.HorizontalAlignment = 'Stretch'
		$replaceTextBox.Padding = [System.Windows.Thickness]::new(8, 0, 8, 0)
		$replaceTextBox.VerticalContentAlignment = 'Center'
		[Windows.Controls.Grid]::SetColumn($replaceTextBox, 2)
		[void]$rowGrid.Children.Add($findTextBox)
		[void]$rowGrid.Children.Add($arrow)
		[void]$rowGrid.Children.Add($replaceTextBox)
		[void]$replacementPairsPanel.Children.Add($rowGrid)
		[void]$renamerReplacementPairRows.Add([PSCustomObject]@{ RowGrid = $rowGrid; FindTextBox = $findTextBox; ReplaceTextBox = $replaceTextBox })
	}

	function Set-RenamerReplacementPairs
	{
		param([array]$Pairs)
		$pairs = @($Pairs | Where-Object { $_ -and $_[0] })
		while ($renamerReplacementPairRows.Count -lt [Math]::Max(10, $pairs.Count)) { Add-RenamerReplacementPairRow }
		for ($i = 0; $i -lt $renamerReplacementPairRows.Count; $i++)
		{
			if ($i -lt $pairs.Count)
			{
				$renamerReplacementPairRows[$i].FindTextBox.Text = [string]$pairs[$i][0]
				$renamerReplacementPairRows[$i].ReplaceTextBox.Text = [string]$pairs[$i][1]
			}
			else
			{
				$renamerReplacementPairRows[$i].FindTextBox.Text = ''
				$renamerReplacementPairRows[$i].ReplaceTextBox.Text = ''
			}
		}
	}

	function Invoke-RenamerCheckExistingWork
	{
		if ($renamerSync['RenamerContentsDir'] -and (Test-Path $renamerSync['RenamerContentsDir'])) { return }
		if ($renamerSync['RenamerModifying']) { return }

		$sessionDir = Get-LatestRenamerHistorySession
		if (-not $sessionDir) { return }

		$session = Get-Content -Path (Join-Path $sessionDir.FullName 'session.json') -Raw | ConvertFrom-Json
		$renamerContentsDir = if ($session.RenamerContentsDir) { $session.RenamerContentsDir } else { Join-Path $sessionDir.FullName 'renamer_contents' }
		if (-not (Test-Path -LiteralPath $renamerContentsDir -PathType Container)) { return }

		$renamerSync['RenamerWorkDir'] = if ($session.RenamerWorkDir) { $session.RenamerWorkDir } else { $sessionDir.FullName }
		$renamerSync['RenamerContentsDir'] = $renamerContentsDir

		if ($session.IsLocalMode) { $localFolderRadio.IsChecked = $true } else { $cloneRepositoryRadio.IsChecked = $true }
		$repoUrlBox.Text = [string]$session.RepoUrl
		$targetPathBox.Text = $renamerContentsDir
		$latestReleaseUrlBox.Text = [string]$session.LatestReleaseUrl
		$skipReleaseDownloadBox.IsChecked = [bool]$session.SkipReleaseDownload
		Set-RenamerReplacementPairs @($session.ReplacementPairs)

		$renamerSync['RepositorySection'].Visibility = 'Collapsed'
		$renamerSync['ReplacementSection'].Visibility = 'Collapsed'
		$renamerSync['OutputSection'].Visibility = 'Visible'

		$modified = if ($session.LastModified) { $session.LastModified } else { $sessionDir.LastWriteTime.ToString('dd-MM-yyyy HH:mm') }
		Write-RenamerStatusLog "Existing working directory found: $($renamerSync['RenamerWorkDir'])"
		Write-RenamerStatusLog "Last modified: $modified"
		Write-RenamerStatusLog "Click 'Reset' if you want to start over."

		[void][System.Windows.MessageBox]::Show(
			"A previous Renamer working directory was found:`n`n$($renamerSync['RenamerWorkDir'])`n`n(Last modified: $modified)`n`nThe previous state has been restored so you can continue from where you left off.`n`nClick 'Reset' if you want to start over.",
			'Renamer', 'OK', 'Information')
		Set-RenamerOutputInView
	}

	function Reset-RenamerSession
	{
		if ($renamerSync['RenamerWorkDir'] -and (Test-Path $renamerSync['RenamerWorkDir'])) {
			$confirm = [System.Windows.MessageBox]::Show(
				"This will clear the restored session and reset the interface.`n`nContinue?",
				'Reset', 'YesNo', 'Warning')
			if ($confirm -ne 'Yes') { return }
		}

		$renamerSync['RenamerWorkDir'] = $null
		$renamerSync['RenamerContentsDir'] = $null
		$renamerSync['RepositorySection'].Visibility = 'Visible'
		$renamerSync['ReplacementSection'].Visibility = 'Visible'
		$cloneRepositoryRadio.IsChecked = $true
		$repoUrlBox.Text = ''
		$targetPathBox.Text = ''
		$latestReleaseUrlBox.Text = ''
		$skipReleaseDownloadBox.IsChecked = $false
		Set-RenamerReplacementPairs @()
		Clear-RenamerStatusLog
	}

	1..10 | ForEach-Object { Add-RenamerReplacementPairRow }

	$syncRepositoryModePanel = {
		if ($localFolderRadio.IsChecked)
		{
			$repoPanel.Visibility = 'Collapsed'
			$targetLabel.Text = 'Local folder path'
		}
		else
		{
			$repoPanel.Visibility = 'Visible'
			$targetLabel.Text = 'Target path'
		}
	}
	$cloneRepositoryRadio.Add_Checked($syncRepositoryModePanel)
	$localFolderRadio.Add_Checked($syncRepositoryModePanel)
	& $syncRepositoryModePanel

	$titleBar.Add_MouseLeftButtonDown({ if ($_.ChangedButton -eq 'Left') { $window.DragMove() } })
	$themeButton.Add_Click({
		$renamerThemeState.IsDark = -not $renamerThemeState.IsDark
		Set-RenamerTheme -Dark $renamerThemeState.IsDark
	})
	$settingsButton.Add_Click({ $settingsPopup.IsOpen = -not $settingsPopup.IsOpen })
	$resetMenuItem.Add_Click({
		$settingsPopup.IsOpen = $false
		Reset-RenamerSession
	})
	$aboutMenuItem.Add_Click({
		$settingsPopup.IsOpen = $false
		[void][System.Windows.MessageBox]::Show(
			"Renamer`n`nAuthor: o9`nGitHub: https://github.com/o9ll/renamer",
			'About', 'OK', 'Information')
	})
	$githubMenuItem.Add_Click({
		$settingsPopup.IsOpen = $false
		Start-Process 'https://github.com/o9ll/renamer'
	})
	$closeButton.Add_Click({ $window.Close() })
	$addReplacementPairButton.Add_Click({ Add-RenamerReplacementPairRow })

	$browseButton.Add_Click({
		$selectedFolderPath = Show-FolderDialog -Description 'Select folder' -InitialPath $targetPathBox.Text
		if ($selectedFolderPath) { $targetPathBox.Text = $selectedFolderPath }
	})

	$runButton.Add_Click({
		if (-not $runButton.IsEnabled) { return }
		$runButton.IsEnabled = $false
		$renamerSync['RenamerModifying'] = $true
		Clear-RenamerStatusLog
		Set-RenamerOutputInView

		$renamerReplacementPairs = @($renamerReplacementPairRows | ForEach-Object {
			$findText = $_.FindTextBox.Text.Trim()
			if ($findText) { , @($findText, $_.ReplaceTextBox.Text) }
		} | Where-Object { $_ })

		if ($renamerReplacementPairs.Count -eq 0)
		{
			Write-RenamerStatusLog 'No Find & Replace pairs configured.'
			$renamerSync['RenamerModifying'] = $false
			$runButton.IsEnabled = $true
			return
		}

		Write-RenamerStatusLog 'Replacement mappings:'
		foreach ($replacementPair in $renamerReplacementPairs) { Write-RenamerStatusLog "  $($replacementPair[0]) -> $($replacementPair[1])" }
		Write-RenamerStatusLog 'Starting operations...'

		$latestReleaseUrlText = $latestReleaseUrlBox.Text.Trim()
		$renamerInvokeParams = if ($localFolderRadio.IsChecked) {
			@{
				LocalPath = $targetPathBox.Text.Trim()
				LatestReleaseUrl = $latestReleaseUrlText
				ReplacementPairs = @($renamerReplacementPairs | ForEach-Object { ,@([string]$_[0], [string]$_[1]) })
				SkipReleaseDownload = [bool]$skipReleaseDownloadBox.IsChecked
			}
		} else {
			@{
				RepoUrl = $repoUrlBox.Text.Trim()
				TargetPath = $targetPathBox.Text.Trim()
				LatestReleaseUrl = $latestReleaseUrlText
				ReplacementPairs = @($renamerReplacementPairs | ForEach-Object { ,@([string]$_[0], [string]$_[1]) })
				SkipReleaseDownload = [bool]$skipReleaseDownloadBox.IsChecked
			}
		}

		$runspace = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
		$runspace.ApartmentState = 'STA'
		$runspace.ThreadOptions = 'ReuseThread'
		$runspace.Open()
		$renamerPowerShell = [Management.Automation.PowerShell]::Create()
		$renamerPowerShell.Runspace = $runspace
		[void]$renamerPowerShell.AddScript((Get-RenamerRunspaceScript))
		[void]$renamerPowerShell.AddScript({
			param($StatusLogControl, $StatusLogScroll, $StatusLogPlaceholder, $StatusLogState, $UiWindow, $InvokeParams)
			$ProgressPreference = 'SilentlyContinue'
			$script:RenamerLogAction = {
				param([string]$Message, [ConsoleColor]$Color)
				$ts = (Get-Date).ToString('HH:mm:ss')
				$lines = @($Message -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { "[$ts] $_" })
				if ($lines.Count -eq 0) { return }
				$batch = $lines
				$UiWindow.Dispatcher.BeginInvoke([action]{
					try {
						if ($StatusLogPlaceholder.Visibility -eq 'Visible') {
							$StatusLogPlaceholder.Visibility = 'Collapsed'
							$StatusLogScroll.Visibility = 'Visible'
						}
						$StatusLogState.HasContent = $true
						$block = $batch -join "`n"
						if ([string]::IsNullOrEmpty($StatusLogControl.Text)) { $StatusLogControl.Text = $block }
						else { $StatusLogControl.Text += "`n$block" }
						$StatusLogScroll.ScrollToVerticalOffset($StatusLogScroll.ExtentHeight)
					} catch {}
				}) | Out-Null
			}
			try { Invoke-Renamer @InvokeParams }
			catch {
				& $script:RenamerLogAction "Error: $($_.Exception.Message)" ([ConsoleColor]::Red)
				throw
			}
		}).AddArgument($statusLog).AddArgument($statusLogScroll).AddArgument($statusLogPlaceholder).AddArgument($renamerStatusLogState).AddArgument($window).AddArgument($renamerInvokeParams)

		$asyncInvokeHandle = $renamerPowerShell.BeginInvoke()
		$timer = New-Object System.Windows.Threading.DispatcherTimer
		$timer.Interval = [TimeSpan]::FromMilliseconds(200)
		$timer.Add_Tick({
			if (-not $asyncInvokeHandle.IsCompleted) { return }
			$timer.Stop()
			$runSucceeded = $true
			try {
				[void]$renamerPowerShell.EndInvoke($asyncInvokeHandle)
				foreach ($runspaceError in $renamerPowerShell.Streams.Error) {
					Write-RenamerStatusLog "Error: $($runspaceError.Exception.Message)"
					$runSucceeded = $false
				}
			}
			catch {
				$runSucceeded = $false
				Write-RenamerStatusLog "Error: $($_.Exception.Message)"
			}
			if ($runSucceeded)
			{
				$workingPath = if ($renamerInvokeParams.LocalPath) { $renamerInvokeParams.LocalPath } else { $renamerInvokeParams.TargetPath }
				$savedSessionDir = Save-RenamerSession -WorkingPath $workingPath `
					-RepoUrl ([string]$renamerInvokeParams.RepoUrl) `
					-TargetPath ([string]$renamerInvokeParams.TargetPath) `
					-IsLocalMode $renamerInvokeParams.ContainsKey('LocalPath') `
					-LatestReleaseUrl ([string]$renamerInvokeParams.LatestReleaseUrl) `
					-SkipReleaseDownload ([bool]$renamerInvokeParams.SkipReleaseDownload) `
					-ReplacementPairs $renamerInvokeParams.ReplacementPairs
				if ($savedSessionDir)
				{
					$renamerSync['RenamerWorkDir'] = $savedSessionDir
					$renamerSync['RenamerContentsDir'] = Join-Path $savedSessionDir 'renamer_contents'
					Write-RenamerStatusLog "Session saved to: $savedSessionDir"
				}
			}
			$renamerSync['RenamerModifying'] = $false
			$renamerPowerShell.Dispose()
			$runspace.Close()
			$runButton.IsEnabled = $true
			Set-RenamerOutputInView
		})
		$timer.Start()
	})

	Invoke-RenamerCheckExistingWork

	if (-not [System.Windows.Application]::Current) { $null = New-Object System.Windows.Application }
	[System.Windows.Application]::Current.DispatcherUnhandledException += {
		param($sender, $e)
		try { Write-RenamerStatusLog "UI error: $($e.Exception.Message)" } catch {}
		$e.Handled = $true
	}

	[void]$window.ShowDialog()
}

# --- Entry point ---

$isRenamerHeadlessRun = $PSBoundParameters.ContainsKey('RepoUrl') -or $PSBoundParameters.ContainsKey('LocalPath')

if (-not $isRenamerHeadlessRun)
{
	Show-RenamerWindow
	return
}

Write-RenamerLog '=== Renamer ===' ([ConsoleColor]::Cyan)
if ($LocalPath) { Write-RenamerLog "Local Path: $LocalPath" ([ConsoleColor]::White) }
else
{
	Write-RenamerLog "Repository URL: $RepoUrl" ([ConsoleColor]::White)
	Write-RenamerLog "Target Path: $TargetPath" ([ConsoleColor]::White)
}

Invoke-Renamer -RepoUrl $RepoUrl -TargetPath $TargetPath -LocalPath $LocalPath `
	-LatestReleaseUrl $LatestReleaseUrl -SkipReleaseDownload:$SkipReleaseDownload

Stop-Transcript
