# PoShFuck
PowerShell implementation of "The Fuck" (https://github.com/nvbn/thefuck)

When you type a command incorrectly, don't say 'fuck', type it!

#Installation

For PoShFuck to run, your execution policy must be lowered. So run this in an admin elevated PowerShell to install:

	Set-ExecutionPolicy remoteSigned
	iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/mattparkes/PoShFuck/master/Install-TheFucker.ps1'))

#Usage

We've all done this before...

	PS C:\> peng 8.8.8.8 -a
	peng : The term 'peng' is not recognized as the name of a cmdlet, function, script file, or operable program.
	Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
	At line:1 char:1
	+ peng 8.8.8.8 -a
	+ ~~~~
		+ CategoryInfo          : ObjectNotFound: (peng:String) [], CommandNotFoundException
		+ FullyQualifiedErrorId : CommandNotFoundException

PoShFuck can fix it.

	PS C:\> fuck

	Did you mean?
	 PING -a 8.8.8.8
	[Y] Yes  [N] No  [?] Help (default is "Y"): y

	Pinging google-public-dns-a.google.com [8.8.8.8] with 32 bytes of data:
	Reply from 8.8.8.8: bytes=32 time=15ms TTL=56
	Reply from 8.8.8.8: bytes=32 time=14ms TTL=56
	Reply from 8.8.8.8: bytes=32 time=14ms TTL=56
	Reply from 8.8.8.8: bytes=32 time=14ms TTL=56

	Ping statistics for 8.8.8.8:
		Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),
	Approximate round trip times in milli-seconds:
		Minimum = 14ms, Maximum = 15ms, Average = 14ms

#Commands

- fuck (alias to Invoke-TheFuck)

This is the command which mungs your last command and presents you with options to fix it.

- fuck! (alias to Invoke-TheFuck -Force)

This command will execute the recommended option without prompting the user.

- WTF (alias to Get-FuckingHelp)

Googles your last console error.

- Get-Fucked

Prints the list of commands which you have used PoShFuck to correct previously.
