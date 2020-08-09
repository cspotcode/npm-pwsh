$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

. "$PSScriptRoot\..\scripts\helpers.ps1"

$PowershellUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.0.3/PowerShell-7.0.3-win-x64.zip"

Invoke-WebRequest "$PowershellUrl" -OutFile pwsh.zip
Microsoft.PowerShell.Archive\Expand-Archive -Path pwsh.zip -DestinationPath pwsh -Force

# Install pnpm; needed for some test cases
run { npm install -g pnpm }

# Install npm dependencies locally
run { npm install }

# Create npm prefix symlink
new-item -type Directory -Path $PSScriptRoot/../test/real/prefix-windows
new-item -type SymbolicLink -Path $PSScriptRoot/../test/prefix-link-windows -Target $PSScriptRoot/../test/real/prefix-windows

$env:Path = "$(Get-Location)/pwsh;" + $env:Path

[System.Environment]::GetEnvironmentVariables()
write-host 'BINARY PATHS:'
(get-command node).Path
(get-command npm).Path
(get-command pnpm).Path
(get-command pwsh).Path

# Run tests
pwsh -executionpolicy remotesigned -noprofile .\scripts\build.ps1 -compile -packageForTests -testWindows -winPwsh "$(Get-Location)\pwsh\pwsh.exe"
exit $LASTEXITCODE
