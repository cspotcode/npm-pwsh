write-host 'test.ps1: Start'
$ErrorActionPreference = 'Stop'

# For some reason with -noprofile I have to Get-command to trigger loading
# of microsoft.powershell.utility and microsoft.powershell.management
# Import-Module was not working either; it was trying to load a PowerShell
# *Desktop* module, not *Core*.
# If we don't do this, pester fails to load
Get-Command Get-ChildItem > $null
Get-Command Add-Member > $null
import-module pester

write-host 'test.ps1: invoking pester'
invoke-pester -verbose -enableexit
write-host 'test.ps1: done'
