$dst = (Join-Path $env:PSModulePath.Split(';')[0] PoShFuck);
$pfk = "$env:temp\poshfuck.zip"

md $dst -ea silentlycontinue

Invoke-WebRequest 'https://github.com/mattparkes/PoShFuck/archive/master.zip' -OutFile $pfk

$shell = New-Object -ComObject Shell.Application; $shell.Namespace($dst).copyhere(($shell.NameSpace($pfk)).items(),20)

Move-Item "$dst\PoShFuck-master\*" "$dst" -Force
Remove-Item "$dst\PoShFuck-master" -Recurse -Force
Remove-Item $pfk -Force

if ( !(Select-String -Path $profile -Pattern "Import-Module PoShFuck")) {
	Write-Output "Import-Module PoShFuck" | Out-File $profile -Append -encoding utf8
}