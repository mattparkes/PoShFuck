Function Invoke-TheFuck {
<#
	.SYNOPSIS
	Powershell Implementation of 'thefuck' https://github.com/nvbn/thefuck
	.DESCRIPTION
	Uses Get-History and edits your last command to fix common mistakes.
	.EXAMPLE
	Fuck
#>
[CmdletBinding()] param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
	[switch]$Force
)

	## GATHER THE LAST ERROR NOW BEFORE WE GENERATE MORE - IF WE DO, -EA IGNORE THE COMMAND OR REMOVE THEM ($global:error.Remove($global:error[0]))
	$preverror = $global:Error[0]
	
	## GATHER THE LAST COMMAND, BUT NOT IF IT IS ITSELF
	$cmditeration = 1
	do {
	
		try {
			$lastcommand = (Get-History -Count $cmditeration -ea SilentlyContinue)[0]
		} catch {
			throw "Cannot fuck without a previous command"
		}
		
		$splitcmd = $lastcommand.CommandLine.Split(' ')[0]
		Write-Verbose "
			Testing executed command: $lastcommand
			Testing resolved command: $($(get-alias $splitcmd -ea ignore).ResolvedCommand.Name)"
		$cmditeration++
		
		$aliasres = (get-alias $splitcmd -ea ignore).ResolvedCommand.Name
		
	} until (
		( ($lastcommand.CommandLine -notmatch "Invoke-TheFuck") -and ($aliasres -notmatch "Invoke-TheFuck") -and ($lastcommand.CommandLine -notmatch "fuck!") ) -or ($lastcommand.id -eq 1)
	)
	
	## THE LOOP STOPS AT THE FIRST COMMAND TO PREVENT AN INFINITE LOOP  - IF THAT -EQ FUCK THEN BREAK
	if ( ($lastcommand.CommandLine -match "Invoke-TheFuck") -or ($aliasres -match "Invoke-TheFuck") -or ($lastcommand.CommandLine -match "fuck!") ) { throw "No valid commands found" }
	
	Write-Verbose "Fucking command: $lastcommand"
	
	## GET THE STATIC DICTIONARY
	$dictloc = ( Join-Path (Split-Path (Get-Module -ListAvailable PoShFuck).Path) StaticDict.xml )
	if ( Test-Path $dictloc ) {
		Write-Verbose "Loading static dictionary"
		$staticdict = Import-Clixml $dictloc
	} else {
		$staticdict = @{}
	}
	
	$newcommand = FuckFix -lastcommand $lastcommand.CommandLine -splitcmd $splitcmd -preverror $preverror -staticdict $staticdict
	
	## CHOOSE WHETHER TO EXECUTE THE FIXED COMMAND
	
	if ( !$Force ) {
		$title = "Did you mean?"
		$message = " $newcommand"
		$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes",'Execute'
		$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No",'Exit'
		$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
		$answer = $host.ui.PromptForChoice($title, $message, $options, 0)
	}
	
	## EXECUTE IF CHOSEN AT PROMPT
	
	if ( ($answer -eq 0) -or $Force ) {
	
		## DONT WRITE THE EXEC NAME UNLESS IT WAS WRONG
		if ( $splitcmd -ne $newcommand.Split(' ')[0] ) {
			$staticdict.Set_Item($splitcmd,$newcommand.Split(' ')[0])
			$staticdict | Export-Clixml $dictloc
		}

		Invoke-Expression "$newcommand"
	}
	
}

Function Get-FuckingHelp {
<#
	.SYNOPSIS
	Googles your last error message.
	.DESCRIPTION
	Googles your last error message.
	.EXAMPLE
	Get-FuckingHelp
#>
	try {
		$preverr = ($global:Error[0].ToString() -split [regex]::Escape([environment]::newline))
		Start-Process "http://www.google.com/search?q=PowerShell $preverr"
	} catch {
		throw "WTF are you doing? Cannot Get-FuckingHelp without a previous error."
	}
}

function fuck! {
[CmdletBinding()] param()
	Invoke-TheFuck -Force
}

function Get-Fucked {
[CmdletBinding()] param()
	Import-Clixml ( Join-Path (Split-Path (Get-Module -ListAvailable PoShFuck).Path) StaticDict.xml )
}

##############################################
##			PRIVATE FUNCTIONS				##
##############################################

Function FuckFix {
[CmdletBinding()] param(
	[string]$lastcommand,
	[string]$splitcmd,
	[string]$preverror,
	[hashtable]$staticdict
)
	$newcommand = $lastcommand
	
	#Bunch of stand-alone IF blocks (not a switch) so it can hit multiple conditions and be corrected multiple times
	
	## CHECK THE STATIC DICTIONARY - IF IT HITS RETURN IMMEDIATELY
	$prevmatch = $staticdict.Get_Item($splitcmd)
	if ( $prevmatch ) {
		Write-Verbose "Returning dictionary result"
		return $lastcommand -replace $splitcmd, $prevmatch
	}
	
	if ( $preverror -match 'is not recognized as the name of a cmdlet, function' ) {
		$icf = IsCommandFucked -Command $splitcmd
			if ( $icf -ne $false ) { 
				$newcommand = $newcommand -replace $splitcmd, $icf
			}
	}
	
	# Checking if the issue is with the parameter name
	if ( (Get-Command $splitcmd -ea Ignore).CommandType -eq 'Application' ) {
			$ipf  = IsExtParameterFucked -lastcommand $lastcommand -splitcmd $splitcmd
			if ( $ipf -ne $false ) {
				$newcommand = $ipf
			}
	} else {
		if ( $preverror -match 'A parameter cannot be found that matches parameter name' ) {
			$fuckedParameter = ([regex]"'[^']*'").Matches($preverror)[0].Value
			$fuckedParameter = $fuckedParameter.Replace("'","")
			$CorrectedCommand = $newcommand.Split(' ')[0]
			$ipf  = IsParameterFucked -Command $CorrectedCommand -Parameter $fuckedParameter
			if ( $ipf -ne $false ) { 
				$newcommand = $newcommand -replace $fuckedParameter, $ipf
			}
		}
	}
	
	if($prevmatch)
	{
		return $newcommand
	}
	
	## TODO SEPARATE COMMAND AND ARGUMENT FIXES
	#Fix PING -a (-a param must be BEFORE the Host/IP or it is ignored, so move it before the Host/IP if it's not)
	if ($newcommand -Match "^(ping)( .*)( -a)(.*)") {
		$newcommand = $Matches[1].ToString() + $Matches[3].ToString() + $Matches[4].ToString() + $Matches[2].ToString()
	}
	
	if ($newcommand -Match "^(ifconfig | grep addr)") {
		$newcommand = 'ipconfig | find "Address"'
	}
	
	## TODO RETURN AN ARRAY FOR THE USER ITERATE OVER
	return $newcommand
	
}

function IsCommandFucked {
## FIND WHETHER THE EXECUTABLE IS FUCKED

[CmdletBinding()] param(
	[string]$Command
)

	if ($Command -match "-") {
		Write-Verbose "Testing '$Command' as a Powershell Cmdlet"
		$result = CommandAnagramCmdlet -Command $Command
	} else {
		Write-Verbose "Testing '$Command' as a binary executable"
		$result = CommandAnagramExtApp -Command $Command
	}
	
	if ($result -eq $Command) {
		return $false
	} else {
		return [string]$result
	}
}

function GetFuckingCandidates {
[CmdletBinding()] param(
	[string]$Command,
	[array]$Candidates
)
	## ONLY INCLUDE CANDIDATES OF A SIMILAR SIZE
	
	$Candidates = $Candidates | Where-Object { ($_.Length -eq $Command.Length) -or ($_.Length -eq $Command.Length-1) -or ($_.Length -eq $Command.Length+1) }
	
	## FOR EACH CANDIDATE IN THE LIST
		## FOR EACH CHARACTER IN THE EXECUTED COMMAND
			## IF THE CHARACTER EXISTS, ADD A POINT TO THE CANDIDATE SCORE
	
	foreach ( $cmd in $Candidates ) {
		$cmdscore = 0
		for ( $cmditeration = 0 ; $cmditeration -lt $command.Length ; $cmditeration++ ) {
			if ( $cmd | Where-Object { $_ -match $command[$cmditeration] } ) {
				$cmdscore++
			}
		}
		
		## IF THIS CANDIDATE HAS EQUAL SCORE TO THE PREVIOUS HIGH SCORE, ADD THIS COMMAND TO THE MATCH ARRAY
		## IF THIS CANDIDATE HAS A HIGHER SCORE THAN THE PREVIOUS HIGH SCORE, OVERWRITE THE MATCH ARRAY
		
		if ( $cmdscore -eq $topcmd ) {
			$cmdmatch += @( $cmd )
			Write-Verbose "Adding - $cmd"
		} elseif ( $cmdscore -gt $topcmd ) {
			$topcmd = $cmdscore
			$cmdmatch = @( $cmd )
			Write-Verbose "New top score - $topcmd - $cmd"
		} else {
			#Write-Verbose "Discarding - $cmd"
		}
	}
	
	### NOW WE HAVE CANDIDATES
	## IF THERE IS ONLY ONE, TAKE IT!
	
	if ($cmdmatch.count -eq 1) {
		Write-Verbose "Choosing last remaining candidate"
		return $cmdmatch[0]
	}
	
	## TRY CHOOSING ONE WITH SIMILARITIES
		## CHOOSE A CANDIDATE WITH THE SAME FIRST CHAR
			## IF THAT CANDIDATE HAS THE SAME LAST TWO CHARS ADD IT TO TOPMATCH
			## ELSE PUT IT AT THE TOP OF THE ARRAY - THE FIRST CHAR IS MORE OFTEN CORRECT
		## ELSE CHOOSE A CANDIDATE WITH THE SAME LAST TWO CHARS
	
	foreach ( $cmd in $cmdmatch ) {
		if ( $Command[0] -eq $cmd[0] ) {
			if ( ($Command[-1] -eq $cmd[-1]) -and ( $Command[-2] -eq $cmd[-2] ) ) {
				Write-Verbose "First and last char match - $cmd"
				$topmatch += @( $cmd )
			} else {
				Write-Verbose "First char match - $cmd"
				$lettermatch = ,$cmd + $lettermatch
			}			
		} elseif ( ($Command[-1] -eq $cmd[-1]) -and ( $Command[-2] -eq $cmd[-2] ) ) {
			Write-Verbose "Last 2 chars match - $cmd"
			$lettermatch += @( $cmd )
		}
	}

	## IF THE LOOP RETURNED ANY MATCHES RESET THE ARRAY WITH TOPMATCH AT FIRST
	
	if ( ( $lettermatch -ne $null ) -or ( $topmatch -ne $null ) ) { $cmdmatch = $topmatch + $lettermatch }

	## IF THERE IS ONLY ONE, TAKE IT!
	
	if ($cmdmatch.count -eq 1) {
		Write-Verbose "Choosing last remaining candidate"
		return $cmdmatch[0]
	}
	
	## TRY CHOOSING ONE THE SAME LENGTH
	
	foreach ( $cmd in $cmdmatch ) {
		if ( $cmd.Length -eq $Command.Length ) {
			Write-Verbose "Length match - $cmd"
			$lengthrmatch += @( $cmd )
		}
	}
	
	if ( $lengthrmatch -ne $null ) { $cmdmatch = $lengthrmatch }

	## THEN, JUST RETURN THE FIRST?? --TODO RETURN THE WHOLE ARRAY
	
	Write-Verbose "Returning the first match array element"
	return $cmdmatch[0]
}

function CommandAnagramExtApp {
##	TEST EXTERNAL EXECUTABLES

[CmdletBinding()] param(
	[string]$Command
)
	$topcmd = 0
	
	## GATHER A LIST OF CANDIDATE COMMANDS AND PLACE THOSE OF A SIMILAR SIZE TO THE EXECUTED COMMAND INTO AN ARRAY
	
	$rawlist = Get-Command -CommandType Application | Select-Object Name
	
	foreach ( $cmd in $rawlist ) {
		$cmdlist += @( $cmd.Name.Split('.')[0] )
	}
	
	if ( $cmdlist -contains $Command ) { Write-Verbose "Command is correct"; return $Command }
	
	return GetFuckingCandidates -Command $Command -Candidates $cmdlist
}

function CommandAnagramCmdlet {
##	TEST POWERSHELL CMDLETS

[CmdletBinding()] param(
	[string]$Command
)

	$rawlist = Get-Command -CommandType 'Cmdlet,Function' | Select-Object Name
	
	if ( $rawlist.Name -contains $Command ) { Write-Verbose "Command is correct"; return $Command }
	
	foreach ( $cmd in $rawlist ) {
		$verblist += @( $cmd.Name.Split('-')[0]	)
		$nounlist += @( $cmd.Name.Split('-')[1]	)
	}
	$verblist = $verblist | select -unique
	$nounlist = $nounlist | select -unique

	if ( $verblist -contains $Command.Split('-')[0] ) {
		Write-Verbose "Cmdlet verb is correct"
		$usenoun = GetFuckingCandidates -Command $Command.Split('-')[1] -Candidates $nounlist
		return "$($Command.Split('-')[0])-$usenoun"
	} else {
		Write-Verbose "Cmdlet verb not found"
		$useverb = GetFuckingCandidates -Command $Command.Split('-')[0] -Candidates $verblist
		return "$useverb-$($Command.Split('-')[1])"
	}
}

function IsParameterFucked {	
[CmdletBinding()] param(
		[string]$Command,
		[string]$Parameter
	)
	
	$Parameters = (GET-Command $Command).parameters.Keys
	$result = GetFuckingCandidates -Command $Command -Candidates $Parameters
	if ($result -eq $Parameter) {
		return $false
	} else {
		return [string]$result
	}
}

Function Fixgit {
[CmdletBinding()] param(
	[string]$lastcommand
)
	Write-Verbose "Git command to fix: $lastcommand"
	Invoke-Expression "$lastcommand 2>&1" -ErrorVariable gitres | Out-Null
	$origcmd = ([string]$gitres[0]).split('')[1].Replace("'",'')
	$correctedcmd = ([string]($gitres[1])).split('')[7]
	
	return $lastcommand -replace $origcmd,$correctedcmd
}

Function IsExtParameterFucked {
[CmdletBinding()] param(
	[string]$lastcommand,
	[string]$splitcmd
)

	switch ($splitcmd) {
	'git'		{ return Fixgit -lastcommand $lastcommand }
	}
	
	return $false
}

Export-ModuleMember *-*
Export-ModuleMember fuck!

Set-Alias -Scope global -Name "Fuck" -Value "Invoke-TheFuck"
Set-Alias -Scope global -Name "WTF" -Value "Get-FuckingHelp"