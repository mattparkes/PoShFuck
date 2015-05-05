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
#param
#(
#    [Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True, HelpMessage='')] [switch]$Yes
#)

    $lastcommand = Get-History -Count 1
    $lasterror = $Error[0]

    $newcommand = Fuck-Fix($lastcommand.CommandLine, $lasterror)

    $Force = $False    #REMOVE THIS WHEN FORCE IS FIXED
    if ($Force) { Invoke-Expression "$newcommand"; }
    else
    {
        $title = "Fuck!"
        $message = "Did you mean: $xxxx?"
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes",'Execute'
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No",'Exit'
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        $answer = $host.ui.PromptForChoice($title, $message, $options, 0)

        if ($answer -eq 0) { Invoke-Expression "$newcommand"; }
    }
    

}
Set-Alias Fuck Invoke-TheFuck
#Set-Alias Fuck! Invoke-TheFuck -Yes


Function Fuck-Fix ($cmd, $error)
{
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