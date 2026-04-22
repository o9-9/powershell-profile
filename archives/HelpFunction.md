# Help Function

```powershell
if (Test-Path "$PSScriptRoot\custom.ps1") {
    # Invoke-Expression -Command "& `"$PSScriptRoot\custom.ps1`""
    # . (Join-Path -Path $PSScriptRoot -ChildPath 'custom.ps1')
    . "$PSScriptRoot\custom.ps1"
}
```

---

```powershell
# Full help
function hh {
    $helpText = @"
$($PSStyle.Foreground.Cyan)o9 Full Help$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)═══════════════════════$($PSStyle.Reset)
$($PSStyle.Foreground.Green)c$($PSStyle.Reset)   Open Cursor           <file>
$($PSStyle.Foreground.Green)e$($PSStyle.Reset)   Open editor           <file>
$($PSStyle.Foreground.Green)ed$($PSStyle.Reset)  Edit profile
$($PSStyle.Foreground.Green)u1$($PSStyle.Reset)  Update profile
$($PSStyle.Foreground.Green)u2$($PSStyle.Reset)  Update PowerShell

$($PSStyle.Foreground.Cyan)Git$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)═══════════════════════$($PSStyle.Reset)
$($PSStyle.Foreground.Green)cl$($PSStyle.Reset)  Clone repo            <repo>
$($PSStyle.Foreground.Green)gg$($PSStyle.Reset)  Clone repo            <repo>
$($PSStyle.Foreground.Green)gd$($PSStyle.Reset)  Add changes
$($PSStyle.Foreground.Green)gc$($PSStyle.Reset)  Add commit            <message>
$($PSStyle.Foreground.Green)gp$($PSStyle.Reset)  Push changes
$($PSStyle.Foreground.Green)gu$($PSStyle.Reset)  Pull changes
$($PSStyle.Foreground.Green)gs$($PSStyle.Reset)  Show status
$($PSStyle.Foreground.Green)gm$($PSStyle.Reset)  Add + commit          <message>
$($PSStyle.Foreground.Green)ga$($PSStyle.Reset)  Add + commit + push   <message>

$($PSStyle.Foreground.Cyan)Navigation$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)═══════════════════════$($PSStyle.Reset)
$($PSStyle.Foreground.Green)g$($PSStyle.Reset)   GitHub C
$($PSStyle.Foreground.Green)g1$($PSStyle.Reset)  Github D
$($PSStyle.Foreground.Green)of$($PSStyle.Reset)  o9 local
$($PSStyle.Foreground.Green)tm$($PSStyle.Reset)  User Temp
$($PSStyle.Foreground.Green)dc$($PSStyle.Reset)  Documents
$($PSStyle.Foreground.Green)dt$($PSStyle.Reset)  Desktop
$($PSStyle.Foreground.Green)dw$($PSStyle.Reset)  Downloads
$($PSStyle.Foreground.Green)lo$($PSStyle.Reset)  Local
$($PSStyle.Foreground.Green)ro$($PSStyle.Reset)  Roaming
$($PSStyle.Foreground.Green)pf$($PSStyle.Reset)  Program Files

$($PSStyle.Foreground.Cyan)System$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)═══════════════════════$($PSStyle.Reset)
$($PSStyle.Foreground.Green)df$($PSStyle.Reset)  Show disk volumes
$($PSStyle.Foreground.Green)ex$($PSStyle.Reset)  Environment variable  <name> <value>
$($PSStyle.Foreground.Green)sy$($PSStyle.Reset)  Show system info
$($PSStyle.Foreground.Green)ut$($PSStyle.Reset)  Show uptime
$($PSStyle.Foreground.Green)pi$($PSStyle.Reset)  Get public IP
$($PSStyle.Foreground.Green)fd$($PSStyle.Reset)  Flush DNS cache
$($PSStyle.Foreground.Green)k9$($PSStyle.Reset)  Kill process          <name>
$($PSStyle.Foreground.Green)pg$($PSStyle.Reset)  Find process by name  <name>
$($PSStyle.Foreground.Green)pk$($PSStyle.Reset)  Kill process by name  <name>

$($PSStyle.Foreground.Cyan)Files$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)═══════════════════════$($PSStyle.Reset)
$($PSStyle.Foreground.Green)la$($PSStyle.Reset)  List files
$($PSStyle.Foreground.Green)ll$($PSStyle.Reset)  List hidden files
$($PSStyle.Foreground.Green)ff$($PSStyle.Reset)  Find files by name    <name>
$($PSStyle.Foreground.Green)nf$($PSStyle.Reset)  Create file + name    <name>
$($PSStyle.Foreground.Green)ne$($PSStyle.Reset)  Creates empty file    <file>
$($PSStyle.Foreground.Green)md$($PSStyle.Reset)  cd to directory       <dir>
$($PSStyle.Foreground.Green)uz$($PSStyle.Reset)  Unzip file            <file>
$($PSStyle.Foreground.Green)hd$($PSStyle.Reset)  Show first n lines    <path> [n]
$($PSStyle.Foreground.Green)tl$($PSStyle.Reset)  Show last n lines     <path> [n]
$($PSStyle.Foreground.Green)gr$($PSStyle.Reset)  Search text by regex  <regex> [dir]
$($PSStyle.Foreground.Green)sd$($PSStyle.Reset)  Replace text in file  <file> <find> <replace>
$($PSStyle.Foreground.Green)wh$($PSStyle.Reset)  Show command path     <name>

$($PSStyle.Foreground.Cyan)Clipboard$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)═══════════════════════$($PSStyle.Reset)
$($PSStyle.Foreground.Green)cy$($PSStyle.Reset)  Copy text             <text>
$($PSStyle.Foreground.Green)pt$($PSStyle.Reset)  Paste from clipboard
$($PSStyle.Foreground.Green)hb$($PSStyle.Reset)  Upload to hastebin    <file>

$($PSStyle.Foreground.Cyan)Scripts$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)═══════════════════════$($PSStyle.Reset)
$($PSStyle.Foreground.Green)o9$($PSStyle.Reset)  Run latest o9
$($PSStyle.Foreground.Green)9o$($PSStyle.Reset)  Run latest o99
$($PSStyle.Foreground.Green)pr$($PSStyle.Reset)  Run profile setup
$($PSStyle.Foreground.Green)vs$($PSStyle.Reset)  Run vs code setup
$($PSStyle.Foreground.Green)cs$($PSStyle.Reset)  Run cursor setup
$($PSStyle.Foreground.Green)dv$($PSStyle.Reset)  Download video
$($PSStyle.Foreground.Green)de$($PSStyle.Reset)  Remove discord krisp and spell check
$($PSStyle.Foreground.Green)th$($PSStyle.Reset)  install o9 theme
$($PSStyle.Foreground.Green)cc$($PSStyle.Reset)  Clear cache
$($PSStyle.Foreground.Green)rr$($PSStyle.Reset)  Restart explorer
$($PSStyle.Foreground.Green)ss$($PSStyle.Reset)  Setup SVG

$($PSStyle.Foreground.Yellow)═══════════════════════$($PSStyle.Reset)
Use '$($PSStyle.Foreground.Magenta)hh$($PSStyle.Reset)' for full help • '$($PSStyle.Foreground.Magenta)hs$($PSStyle.Reset)' for compact help
"@
    Write-Host $helpText
}

# Compact help
function hs {
    $compact = @"
$($PSStyle.Foreground.Cyan)o9 Compact Help$($PSStyle.Reset) (• 'hh' Full Help)
$($PSStyle.Foreground.Yellow)Profile: $($PSStyle.Reset) c e ed u1 u2
$($PSStyle.Foreground.Yellow)Git:$($PSStyle.Reset) cl gl gd gc gp gu gs gm ga
$($PSStyle.Foreground.Yellow)Nav:$($PSStyle.Reset) g g1 dc dt dw of lo ro tm pf
$($PSStyle.Foreground.Yellow)System:$($PSStyle.Reset) df ex sy ut pi fd k9 pg pk
$($PSStyle.Foreground.Yellow)Files:$($PSStyle.Reset) la ll ff nf ne md uz hd tl gr sd wh
$($PSStyle.Foreground.Yellow)Clip:$($PSStyle.Reset) cy pt hb
$($PSStyle.Foreground.Yellow)Scripts:$($PSStyle.Reset) o9 9o pr vs cs dv de th cc rr sv
"@
    Write-Host $compact
}

# Multi-column layout with colored aliases and descriptions
$cyan = $PSStyle.Foreground.Cyan
$magenta = $PSStyle.Foreground.Magenta
$r = $PSStyle.Reset
$w = [Math]::Floor($Host.UI.RawUI.WindowSize.Width / 3) - 2

$cmds = @(
    [pscustomobject]@{ Key = 'o9'; Name = 'Run o9 Utility'    }
    [pscustomobject]@{ Key = 'dv'; Name = 'Video Downloader'  }
    [pscustomobject]@{ Key = 'de'; Name = 'Remove Krisp'      }
    [pscustomobject]@{ Key = 'cc'; Name = 'Clear Temp'        }
    [pscustomobject]@{ Key = 'rr'; Name = 'Restart Explorer'  }
    [pscustomobject]@{ Key = 'vs'; Name = 'Install VS Code'   }
    [pscustomobject]@{ Key = 'cs'; Name = 'Install Cursor'    }
    [pscustomobject]@{ Key = 'th'; Name = 'Install o9 Theme'  }
    [pscustomobject]@{ Key = 'ss'; Name = 'Install SVG'       }
)

$cmds | Format-Table -AutoSize

Write-Host "`n${magenta}Help: ${cyan}hh${magenta} • ${cyan}hs$r`n"
for ($i = 0; $i -lt $cmds.Count; $i += 3) {
    $col1 = if ($cmds[$i]) {
        $parts = $cmds[$i].TrimStart() -split ' ', 2
        "$cyan$($parts[0])$magenta $($parts[1])$r".PadRight($w + 2)
    } else { " " * $w }

    $col2 = if ($cmds[$i+1]) {
        $parts = $cmds[$i+1].TrimStart() -split ' ', 2
        "$cyan$($parts[0])$magenta $($parts[1])$r".PadRight($w + 2)
    } else { " " * $w }

    $col3 = if ($cmds[$i+2]) {
        $parts = $cmds[$i+2].TrimStart() -split ' ', 2
        "$cyan$($parts[0])$magenta $($parts[1])$r"
    } else { "" }

    Write-Host "$col1 $col2 $col3"
}
```

---

```powershell
# Help Function
function hh {
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
$($cmd.Invoke("ed","","Edit Profile",          "⚙️"))
$($cmd.Invoke("u1","","Update Profile",        "🔄"))
$($cmd.Invoke("u2","","Update PowerShell",     "🔄"))
$border
$($sectionHeader.Invoke("🌱", "Git Shortcuts"      ))
$($cmd.Invoke("cl","","git clone",             "⬇️"))
$($cmd.Invoke("gg","","git clone",             "⬇️"))
$($cmd.Invoke("gs","","git status",            "🟢"))
$($cmd.Invoke("gd","","git add .",             "➕"))
$($cmd.Invoke("gc","","git commit -m",         "💬"))
$($cmd.Invoke("gp","","git push",              "🚀"))
$($cmd.Invoke("gu","","git pull",              "⬇️"))
$($cmd.Invoke("gm","","Add & Commit",          "📝"))
$($cmd.Invoke("ga","","Add-Commit-Push",       "🚀"))
$border
$($sectionHeader.Invoke("🚀", "Shortcuts"          ))
$($cmd.Invoke("cy","","Copy File",             "📋"))
$($cmd.Invoke("pt","","Paste File",            "📋"))
$($cmd.Invoke("df","","Disk Free Space",       "ℹ️"))
$($cmd.Invoke("g","","GitHub folder",          "📁"))
$($cmd.Invoke("g1","","GitHub folder in D",    "📁"))
$($cmd.Invoke("dc","","Documents folder",      "📁"))
$($cmd.Invoke("dt","","Desktop folder",        "📁"))
$($cmd.Invoke("dw","","Downloads folder",      "📁"))
$($cmd.Invoke("of","","o9 folder",             "📁"))
$($cmd.Invoke("lo","","Local folder",          "📁"))
$($cmd.Invoke("ro","","Roaming folder",        "📁"))
$($cmd.Invoke("tm","","Temp folder",           "📁"))
$($cmd.Invoke("pf","","Program Files folder",  "📁"))
$($cmd.Invoke("ex","","Set Environmente",      "🌱"))
$($cmd.Invoke("ff","","Find Files",            "🔍"))
$($cmd.Invoke("fd","","Clear DNS Cache",       "🌐"))
$($cmd.Invoke("pi","","Show Public IP",        "🌎"))
$($cmd.Invoke("pg","","Search Regex",          "🧬"))
$($cmd.Invoke("hb","","Upload URL",            "🌐"))
$($cmd.Invoke("hd","","Show First Lines",      "🔝"))
$($cmd.Invoke("k9","","Kill Process",          "🪓"))
$($cmd.Invoke("la","","List All Files",        "📁"))
$($cmd.Invoke("ll","","List Hidden Files",     "👻"))
$($cmd.Invoke("md","","Change Directory",      "📂"))
$($cmd.Invoke("nf","","Create Empty File",     "🆕"))
$($cmd.Invoke("pk","","Kill Process Name",     "💀"))
$($cmd.Invoke("pg","","List Process Name",     "🔎"))
$($cmd.Invoke("sd","","Replace in File",       "✂️"))
$($cmd.Invoke("sy","","System Info",           "🖥️"))
$($cmd.Invoke("tl","","Show Last Lines",       "🔚"))
$($cmd.Invoke("ne","","Create New File",       "✏️"))
$($cmd.Invoke("uz","","Extract Zip File",      "🗜️"))
$($cmd.Invoke("ut","","Show time",             "⏰"))
$($cmd.Invoke("wh","","Show Command Path",     "🛤️"))
$border
$($cmd.Invoke("o9","","Run o9",                 "⚡"))
$($cmd.Invoke("9o","","Run o99",                "⚡"))
$($cmd.Invoke("pr","","Profile Setup",          "⚡"))
$($cmd.Invoke("vs","","VSCode Setup",           "⚡"))
$($cmd.Invoke("cs","","Cursor Setup",           "⚡"))
$($cmd.Invoke("dv","","Download Video",        "💾"))
$($cmd.Invoke("cc","","Clear Cache",           "🧹"))
$($cmd.Invoke("rr","","Restarts Explorer",     "🔧"))
$border

Use '$($PSStyle.Foreground.Magenta)hh$($PSStyle.Reset)' to display this help message.
$border
"@
    Write-Host $helpText
}

# Help Function
function hh {
    $helpText = @"
$($PSStyle.Foreground.Cyan)PowerShell Profile Help$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)c$($PSStyle.Reset)  - Opens file in cursor editor.
$($PSStyle.Foreground.Green)e$($PSStyle.Reset)  - Opens file in editor.
$($PSStyle.Foreground.Green)ed$($PSStyle.Reset) - Opens current user profile for editing using configured editor.
$($PSStyle.Foreground.Green)u1$($PSStyle.Reset) - Checks for profile updates from remote repository and updates if necessary.
$($PSStyle.Foreground.Green)u2$($PSStyle.Reset) - Checks for latest PowerShell release and updates if new version is available.

$($PSStyle.Foreground.Cyan)Git Shortcuts$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)cl$($PSStyle.Reset) <repo> - git clone
$($PSStyle.Foreground.Green)gg$($PSStyle.Reset) <repo> - git clone
$($PSStyle.Foreground.Green)gd$($PSStyle.Reset) - git add .
$($PSStyle.Foreground.Green)gc$($PSStyle.Reset) <message> - git commit -m
$($PSStyle.Foreground.Green)gp$($PSStyle.Reset) - git push
$($PSStyle.Foreground.Green)gu$($PSStyle.Reset) - git pull
$($PSStyle.Foreground.Green)gs$($PSStyle.Reset) - git status
$($PSStyle.Foreground.Green)gm$($PSStyle.Reset) <message> - Adds all changes and commits
$($PSStyle.Foreground.Green)ga$($PSStyle.Reset) <message> - Adds all changes + commits + pushes

$($PSStyle.Foreground.Cyan)Shortcuts$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)g$($PSStyle.Reset)  - GitHub C
$($PSStyle.Foreground.Green)g1$($PSStyle.Reset) - Github D
$($PSStyle.Foreground.Green)of$($PSStyle.Reset) - o9 local
$($PSStyle.Foreground.Green)tm$($PSStyle.Reset) - User Temp
$($PSStyle.Foreground.Green)dc$($PSStyle.Reset) - Documents
$($PSStyle.Foreground.Green)dt$($PSStyle.Reset) - Desktop
$($PSStyle.Foreground.Green)dw$($PSStyle.Reset) - Downloads
$($PSStyle.Foreground.Green)lo$($PSStyle.Reset) - Local
$($PSStyle.Foreground.Green)ro$($PSStyle.Reset) - Roaming
$($PSStyle.Foreground.Green)pf$($PSStyle.Reset) - Program Files

$($PSStyle.Foreground.Green)df$($PSStyle.Reset) - Displays information about volumes
$($PSStyle.Foreground.Green)ex$($PSStyle.Reset) <name> <value> - Sets an environment variable
$($PSStyle.Foreground.Green)sy$($PSStyle.Reset) - Displays detailed system information
$($PSStyle.Foreground.Green)ut$($PSStyle.Reset) - Displays system uptime
$($PSStyle.Foreground.Green)pi$($PSStyle.Reset) - Retrieves public IP address of machine
$($PSStyle.Foreground.Green)fd$($PSStyle.Reset) - Clears DNS cache
$($PSStyle.Foreground.Green)k9$($PSStyle.Reset) <name> - Kills process by name
$($PSStyle.Foreground.Green)pg$($PSStyle.Reset) <name> - Lists processes by name
$($PSStyle.Foreground.Green)pk$($PSStyle.Reset) <name> - Kills processes by name

$($PSStyle.Foreground.Green)la$($PSStyle.Reset) - Lists all files in current directory with detailed formatting
$($PSStyle.Foreground.Green)ll$($PSStyle.Reset) - Lists all files, including hidden, in current directory with detailed formatting.
$($PSStyle.Foreground.Green)ff$($PSStyle.Reset) <name> - Finds files recursively with specified name
$($PSStyle.Foreground.Green)nf$($PSStyle.Reset) <name> - Creates new file with specified name
$($PSStyle.Foreground.Green)ne$($PSStyle.Reset) <file> - Creates new empty file
$($PSStyle.Foreground.Green)md$($PSStyle.Reset) <dir> - Creates and changes to new directory
$($PSStyle.Foreground.Green)uz$($PSStyle.Reset) <file> - Extracts zip file to current directory
$($PSStyle.Foreground.Green)hd$($PSStyle.Reset) <path> [n] - Displays first n lines of file (default 10)
$($PSStyle.Foreground.Green)tl$($PSStyle.Reset) <path> [n] - Displays last n lines of file (default 10)
$($PSStyle.Foreground.Green)gr$($PSStyle.Reset) <regex> [dir] - Search text by regex
$($PSStyle.Foreground.Green)sd$($PSStyle.Reset) <file> <find> <replace> - Replaces text in file
$($PSStyle.Foreground.Green)wh$($PSStyle.Reset) <name> - Shows path of command

$($PSStyle.Foreground.Green)cy$($PSStyle.Reset) <text> - Copies specified text to clipboard
$($PSStyle.Foreground.Green)pt$($PSStyle.Reset) - Retrieves text from clipboard
$($PSStyle.Foreground.Green)hb$($PSStyle.Reset) <file> - Uploads file content to hastebin

$($PSStyle.Foreground.Green)o9$($PSStyle.Reset) - Runs latest o
$($PSStyle.Foreground.Green)9o$($PSStyle.Reset) - Runs latest o99
$($PSStyle.Foreground.Green)pr$($PSStyle.Reset) - Runs Profile Setup
$($PSStyle.Foreground.Green)vs$($PSStyle.Reset) - Runs VS Code Setup
$($PSStyle.Foreground.Green)cs$($PSStyle.Reset) - Runs Cursor Setup
$($PSStyle.Foreground.Green)dv$($PSStyle.Reset) - Download Video
$($PSStyle.Foreground.Green)cc$($PSStyle.Reset) - Clear Cache
$($PSStyle.Foreground.Green)rr$($PSStyle.Reset) - Restarts Explorer
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)

Use '$($PSStyle.Foreground.Magenta)hh$($PSStyle.Reset)' to display this help message.
"@
    Write-Host $helpText
}
```

---

```powershell
Write-Host "$($PSStyle.Foreground.DarkMagenta)Use 'hh' for full help$($PSStyle.Reset)"
Write-Host "$($PSStyle.Foreground.DarkMagenta)Use 'hs' for compact help$($PSStyle.Reset)"
```