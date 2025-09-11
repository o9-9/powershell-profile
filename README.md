<div align="center">
	<img width="976" height="192" alt="powershell-profile" src="https://github.com/user-attachments/assets/3e1630d8-20c9-48e1-94e9-70eb2c30f6cf" />
	<br>
	<br>
	<br>
	<br>
	<div>
		<sub>🎨</sub>
		<br>
		<h2>
			<a href="https://github.com/o9-9/powershell-profile">PowerShell Profile</a>
			<br>
			<sup>>A stylish and functional PowerShell profile that looks and feels almost as good as a Linux terminal.</sup>
		</h2>
	</div>
	<br>
	<br>
	<br>
	<br>

## ⚡ One Line Install</h2>

Command in an elevated PowerShell window to install the PowerShell profile:

```
irm "https://github.com/o9-9/powershell-profile/raw/main/setup.ps1" | iex
```

## With `oh-my-posh` (loaded automatically through the PowerShell profile script hosted on this repo):
- Run the command `oh-my-posh font install`
- A list of Nerd Fonts will appear like so:
<pre>
PS> oh-my-posh font install

   Select font

  > 0xProto
    3270
    Agave
    AnonymousPro
    Arimo
    AurulentSansMono
    BigBlueTerminal
    BitstreamVeraSansMono

    •••••••••
    ↑/k up • ↓/j down • q quit • ? more</pre>
- With the up/down arrow keys, select the font you would like to install and press <kbd>ENTER</kbd>
- DONE!

## Customize profile

**Do not make any changes to the `Microsoft.PowerShell_profile.ps1` file**, since it's hashed and automatically overwritten by any commits to this repository.

After the profile is installed and active, run the `Edit-Profile` function to create a separate profile file [`profile.ps1`] for your current user. Add any custom code, and/or override VARIABLES/FUNCTIONS in `Microsoft.PowerShell_profile.ps1` by adding any of the following Variable or Function names:

THE FOLLOWING VARIABLES RESPECT _Override:
<pre>
$EDITOR_Override
$debug_Override
$repo_root_Override  [To point to a fork, for example]
$timeFilePath_Override
$updateInterval_Override
</pre>

THE FOLLOWING FUNCTIONS RESPECT _Override: _(do not call the original function from your override function, or you'll create an infinite loop)_
<pre>
Debug-Message_Override
Update-Profile_Override
Update-PowerShell_Override
Clear-Cache_Override
Get-Theme_Override
o99_Override [To call a fork, for example]
</pre>
