# PoShFuck
PowerShell implementation of "The Fuck" (https://github.com/nvbn/thefuck)

#Installation

For PoShFuck to run, your execution policy must be lowered. So run this in an admin elevated PowerShell to install:

	Set-ExecutionPolicy remoteSigned
	iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/mattparkes/PoShFuck/master/Install-TheFucker.ps1'))

Then restart PowerShell.