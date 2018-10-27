$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'
write-host 'test-windows.ps1:'
# invoke-webrequest https://github.com/PowerShell/PowerShell/releases/download/v6.2.0-preview.1/PowerShell-6.2.0-preview.1-win-x64.zip -outfile pwsh.zip
# new-item -type directory pwsh
# expand-archive -path pwsh.zip -outputpath pwsh
npm install -g get-powershell@0.1.1-pwsh6.1.0
mv C:\ProgramData\nvs\node\10.12.0\x64\node_modules\@cspotcode\get-powershell-cache\powershell-6.1.0-win32-x64 ./pwsh
rm -r C:\ProgramData\nvs\node\10.12.0\x64\node_modules\@cspotcode\get-powershell-cache
npm uninstall -g get-powershell
$env:Path = "$(Get-Location)/pwsh;" + $env:Path
write-output '$env:Path ='
write-output ($env:Path -split ';')
npm install -g pnpm
pwsh -executionpolicy remotesigned -noprofile ./scripts/build.ps1 -installPester -compile -package -testWindows
exit $LASTEXITCODE
