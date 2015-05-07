# PoShFuck
PowerShell implementation of "The Fuck" (https://github.com/nvbn/thefuck)

#Installation

We could point you at a script, but you've probably got a restricted execution policy. So run this instead:

	$dst = (Join-Path $env:PSModulePath.Split(';')[0] PoShFuck); md $dst -ea silentlycontinue; $pfk = "$env:temp\poshfuck.zip"
	Invoke-WebRequest 'https://github.com/mattparkes/PoShFuck/archive/master.zip' -OutFile $pfk
	$shell = New-Object -ComObject Shell.Application; $shell.Namespace($dst).copyhere(($shell.NameSpace($pfk)).items(),20); Remove-Item $pfk -Force
	Move-Item "$dst\PoShFuck-master\*" "$dst" -Force; Remove-Item "$dst\PoShFuck-master" -Recurse -Force

Then restart PowerShell.