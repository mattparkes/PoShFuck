Function Invoke-TheFuck {
<#
	.SYNOPSIS
	Powershell Implementation of 'thefuck' https://github.com/nvbn/thefuck
	.DESCRIPTION
	Uses Get-History and edits your last command to fix common mistakes.
	.EXAMPLE
	Fuck
#>

[CmdletBinding()]
param
(
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
	[switch]$Force
)

	## GATHER THE LAST ERROR NOW BEFORE WE GENERATE MORE - IF WE DO, REMOVE THEM, LIKE $aliasres
	$preverror = $global:Error[0]
	
	## GATHER THE LAST COMMAND, BUT NOT IF IT IS ITSELF
	$cmditeration = 1
	do {
		$lastcommand = (Get-History -Count $cmditeration)[0]
		$splitcmd = $lastcommand.CommandLine.Split(' ')[0]
		Write-Verbose "
			Testing executed command: $lastcommand
			Testing resolved command: $($(get-alias $splitcmd -ea SilentlyContinue).ResolvedCommand.Name)"
		$cmditeration++
		
		if ( ($aliasres = (get-alias $splitcmd -ea ignore).ResolvedCommand.Name) -eq $null ) { $global:error.Remove($global:error[0]) }
	} until (
		( ($lastcommand.CommandLine -notmatch "Invoke-TheFuck") -and ($aliasres -notmatch "Invoke-TheFuck") ) -or ($lastcommand -eq $null)
	)
	
	## TODO: TEST THIS
	if ($lastcommand -eq $null) { throw "Cannot fuck without a previous command" }
	
	Write-Verbose "Fucking command: $lastcommand"
	
	$newcommand = FuckFix -lastcommand $lastcommand.CommandLine -splitcmd $splitcmd -preverror $preverror
	
	if ($Force) { Invoke-Expression "$newcommand"; }
	else
	{
		$title = "Did you mean?"
		$message = " $newcommand"
		$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes",'Execute'
		$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No",'Exit'
		$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
		$answer = $host.ui.PromptForChoice($title, $message, $options, 0)
	
		if ($answer -eq 0) { Invoke-Expression "$newcommand"; }
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
	#ToDo: Add Null checks, etc...doesnt execute the search in chrome
	
    Start-Process ("http://www.google.com/?q=PowerShell " + ($global:Error[0].ToString() -split [regex]::Escape([environment]::newline))  )
}

##############################################
##			PRIVATE FUNCTIONS				##
##############################################

Function FuckFix {

[CmdletBinding()]
param
(
	[string]$lastcommand,
	[string]$splitcmd,
	[string]$preverror
)

	#Bunch of stand-alone IF blocks (not a switch) so it can hit multiple conditions and be corrected multiple times
	
    #cleanup the command
	#if ($lastcommand -match "foo")
    #{ 
    #    $newcommand = $lastcommand -replace "foo", "bar"
    #}
	
	if ( $preverror -match 'is not recognized as the name of a cmdlet, function' ) {
		$icf = IsCommandFucked -Command $splitcmd
			if ( $icf -ne $false ) { 
				$newcommand = $lastcommand -replace $splitcmd, $icf
			}
	}

    return $newcommand

}

function IsCommandFucked {
## FIND WHETHER THE EXECUTABLE IS FUCKED

[CmdletBinding()]
param
(
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

[CmdletBinding()]
param
(
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
			$cmdmatch = @($cmd)
			Write-Verbose "New top score - $topcmd - $cmd"
		} else {
			#DEBUG Write-Verbose "Discarding - $cmd"
		}
	}
	
	## NOW WE HAVE CANDIDATES, IF ONE IS THE SAME LENGTH, CHOOSE IT
	
	foreach ( $cmd in $cmdmatch ) {
		if ( $cmd.Length -eq $Command.Length ) {
			$result = $cmd
			Write-Verbose "Result set by length - $cmd"
		}
	}
	
	## OTHERWISE, JUST RETURN THE FIRST??
	
	if ( $result ) {
		return $result
	} else {
		Write-Verbose "Returning the first match array element"
		return $cmdmatch[0]
	}
	
	return $result
}

function CommandAnagramExtApp {
##	TEST EXTERNAL EXECUTABLES

[CmdletBinding()]
param
(
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

[CmdletBinding()]
param
(
	[string]$Command
)

	$rawlist = Get-Command -CommandType Cmdlet | Select-Object Name
	
	if ( $rawlist.Name -contains $Command ) { Write-Verbose "Command is correct"; return $Command }
	
	foreach ( $cmd in $rawlist ) {
		$verblist += @( $cmd.Name.Split('-')[0]	)
		$nounlist += @( $cmd.Name.Split('-')[1]	)
	}
	$verblist = $verblist | select -uniq
	$nounlist = $nounlist | select -uniq

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

function fuck! { Invoke-TheFuck -Force }

Export-ModuleMember *-*
Export-ModuleMember fuck!

Set-Alias -Scope global -Name "Fuck" -Value "Invoke-TheFuck"
Set-Alias -Scope global -Name "WTF" -Value "Get-FuckingHelp"