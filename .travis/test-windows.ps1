$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

# Use wget because powershell on Travis can't make an https connection to github (?!@)
bash -c "wget -qO pwsh.zip https://github.com/PowerShell/PowerShell/releases/download/v6.2.0-preview.1/PowerShell-6.2.0-preview.1-win-x64.zip"
# Invoke-WebRequest https://github.com/PowerShell/PowerShell/releases/download/v6.2.0-preview.1/PowerShell-6.2.0-preview.1-win-x64.zip -OutFile pwsh.zip
Microsoft.PowerShell.Archive\Expand-Archive -Path pwsh.zip -DestinationPath pwsh -Force

# Install pnpm; needed for some test cases
npm install -g pnpm

# Create npm prefix symlink
new-item -type Directory -Path $PSScriptRoot/../test/real/prefix-windows
new-item -type SymbolicLink -Path $PSScriptRoot/../test/prefix-link-windows -Target $PSScriptRoot/../test/real/prefix-windows

$env:Path = "$(Get-Location)/pwsh;" + $env:Path

[System.Environment]::GetEnvironmentVariables()
write-host 'BINARY PATHS:'
get-command node
get-command npm
get-command pnpm
get-command pwsh

# Run tests
pwsh -executionpolicy remotesigned -noprofile ./scripts/build.ps1 -installPester -compile -package -testWindows -winPwsh "$(Get-location)/pwsh/pwsh"
exit $LASTEXITCODE
