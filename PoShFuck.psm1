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

	## GATHER THE LAST COMMAND, BUT NOT IF IT IS ITSELF
	$cmditeration = 1
	do {
		$lastcommand = (Get-History -Count $cmditeration)[0]
		$aliascmd = $lastcommand.CommandLine.Split(' ')[0]
		Write-Verbose "
			Testing executed command: $lastcommand
			Testing resolved command: $($(get-alias $aliascmd -ea SilentlyContinue).ResolvedCommand.Name)"
		$cmditeration++
	} until (
		(($lastcommand.CommandLine -notmatch "Invoke-TheFuck") -and (((get-alias $aliascmd -ea SilentlyContinue).ResolvedCommand.Name) -notmatch "Invoke-TheFuck")) -or
		($lastcommand -eq $null)
	)
## TODO: TEST THIS
	if ($lastcommand -eq $null) { throw "Cannot fuck without a previous command" }
	
	Write-Verbose "Fucking command: $lastcommand"
	
	$lasterror = $Error[0]
	
	$newcommand = FuckFix($lastcommand.CommandLine, $lasterror)
	
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

Function FuckFix ($cmd, $error) {

	#Bunch of stand-alone IF blocks (not a switch) so it can hit multiple conditions and be corrected multiple times
	
    #cleanup the command
	if ($cmd -match "foo")
    { 
        $cmd = $cmd -replace "foo", "bar"
    }
	
	#cleanup the command based on any errors
#	if ($error -match "baz")
#    { 
#        $cmd = $cmd -replace "baz", "qux"
#    }

    return $cmd

}

export-modulemember *-*

Set-Alias -Scope global -Name "Fuck" -Value "Invoke-TheFuck"
Set-Alias -Scope global -Name "Fuck!" -Value "Invoke-TheFuck -Force"