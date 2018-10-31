#Require -PSEdition Core

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$IsPosix = $IsMacOS -or $IsLinux

$pathSep = if($IsPosix) { ':' } else { ';' }
$dirSep = if($IsPosix) { '/' } else { '\' }
$tgz = "../$((get-item $PSScriptRoot/../pwsh-*.tgz).name)"
# $fromTgz = get-item $PSScriptRoot/../pwsh-*.tgz
# $tgz = "./this-is-the-tgz.tgz"
# remove-item $tgz -ea continue
# move-item $fromTgz $tgz
$npmVersion = (get-content $PSScriptRoot/../package.json | convertfrom-json).version
$pwshVersion = (get-content $PSScriptRoot/../dist/buildTags.json | convertfrom-json).pwshVersion

$npm = (Get-Command npm).Source
$pnpm = (Get-Command pnpm).Source

if($IsWindows) {
    $winPwsh = (get-command pwsh.cmd -ea continue).path
    if(-not $winPwsh) { $winPwsh = (get-command pwsh.exe).path }
}

Describe 'get-powershell' {
    $oldLocation = Get-Location
    Set-Location $PSScriptRoot
    $npmPrefixRealpath = "$( get-location )$( if($IsPosix) { '/real/npm-prefix-linux' } else { '\real\npm-prefix-windows' } )"
    $npmPrefixSymlink = "$( get-location )$( if($IsPosix) { '/link-to-npm-prefix-linux' } else { '\link-to-npm-prefix-windows' } )"
    $npmGlobalInstallPath = "$npmPrefixSymlink$( if($IsPosix) { '/bin' } else { '' } )"
    $npmLocalInstallPath = "$PSScriptRoot$( $dirSep )node_modules$( $dirSep ).bin"

    BeforeEach {
        <### HELPER FUNCTIONS ###>
        function run($block) {
            & $block
            if($lastexitcode -ne 0) { throw "Non-zero exit code: $LASTEXITCODE" }
        }
        Function npm([switch]$show) {
            if($show) {
                & $npm --userconfig "$PSScriptRoot/.npmrc" @args 2>&1 | write-host
            } else {
                & $npm --userconfig "$PSScriptRoot/.npmrc" @args
            }
        }
        Function pnpm([switch]$show) {
            if($show) {
                & $pnpm --userconfig "$PSScriptRoot/.npmrc" @args 2>&1 | write-host
            } else {
                & $pnpm --userconfig "$PSScriptRoot/.npmrc"
            }
        }
        Function retry($times, $delay, $block) {
            while($times) {
                try {
                    $block
                    break
                } catch {
                    $times--
                    if($times -le 0) {
                        throw $_
                    }
                    start-sleep $delay
                }
            }
        }
        # Create a symlink.  On Windows this requires popping a UAC prompt (ugh)
        Function symlink($from, $to) {
            write-host $from $to
            write-host (get-item $from)
            write-host (get-item $from).target
            if((get-item $from).target -eq $to) { return }
            if($IsPosix) {
                new-item -type symboliclink -path $from -Target $to -EA Stop
            }
            else {
                start-process -verb runas -wait $winPwsh -argumentlist @(
                    '-noprofile', '-file', "$PSScriptRoot/create-symlink.ps1",
                    $from, $to
                ) -erroraction stop
            }
        }

        <### SETUP ENVIRONMENT ###>

        # Add node_modules/.bin to PATH; remove any paths containing pwsh.exe
        $oldPath = $env:PATH
        $env:PATH = (& {
            # Local bin
            $npmLocalInstallPath
            # Global bin in npm prefix
            $npmGlobalInstallPath
            # Path to node & npm
            Split-Path -Parent ( Get-Command node ).Source
            # Path to sh
            if($IsPosix) {
                Split-Path -Parent ( Get-Command sh ).Source
            }
        }) -join $pathSep
        if(test-path ./node_modules) {
            remove-item -recurse ./node_modules -force
        }
        if(test-path $npmPrefixRealpath) {
            remove-item -recurse $npmPrefixRealpath -force
        }
        new-item -type directory $npmPrefixRealpath
        symlink $npmPrefixSymlink $npmPrefixRealpath
        set-content ./.npmrc -encoding utf8 "prefix = $($npmPrefix -replace '\\','\\')"

        $preexistingPwsh = get-command pwsh -EA SilentlyContinue
        if($preexistingPwsh) { $preExistingPwsh = $preexistingPwsh.Source }

    }
    AfterEach {
        # if($IsPosix) { Remove-Item -Path $npmPrefixSymlink }
        # Never delete the symlink on Windows.  It's too annoying to create in the first place
        # else { Remove-Item -Path $npmPrefixSymlink }
        $env:PATH = $oldPath
    }

    $tests = {

        it 'Symlink exists (it requires admin privileges to create on windows and isnt done automatically)' {
            Get-Item $npmPrefixSymlink
        }

        it 'npm prefix set correctly for testing' {
            run { npm config get prefix } | should -be $npmPrefix
        }


        describe 'local installation via npm' {
            beforeeach {
                run { npm install $tgz }
            }
            it 'pwsh is in path and is correct version' {
                (get-command pwsh).source | should -belike "$npmLocalInstallPath*"

                if($pwshVersion -ne 'latest') {
                    pwsh --version | should -be "PowerShell v$pwshVersion"
                }
            }
            aftereach {
                run { npm uninstall $tgz }
                retry 4 1 { remove-item -r node_modules }
            }
        }
        describe 'local installation via pnpm' {
            beforeeach {
                run { pnpm -show install $tgz }
            }
            it 'pwsh is in path and is correct version' {
                (get-command pwsh).source | should -belike "$npmLocalInstallPath*"

                if($pwshVersion -ne 'latest') {
                    pwsh --version | should -be "PowerShell v$pwshVersion"
                }
            }
            aftereach {
                # run { pnpm -show uninstall $tgz }
                write-host 'deleting node_modules'
                retry 4 1 { remove-item -r node_modules }
                write-host 'deleted node_modules'
            }
        }
        describe 'global installation' {
            beforeeach {
                run { npm -show install --global $tgz }
            }
            it 'pwsh is in path and is correct version' {
                (get-command pwsh).source | should -belike "$npmGlobalInstallPath*"
                (get-command pwsh).source | should -not -Be $preExistingPwsh
                if($pwshVersion -ne 'latest') {
                    pwsh --version | should -be "PowerShell v$pwshVersion"
                }
            }
            aftereach {
                run { npm -show uninstall --global $tgz }
            }
        }
    }

    $npmPrefix = $npmPrefixSymlink
    describe 'npm prefix is symlink' {
        . $tests
    }

    $npmPrefix = $npmPrefixRealpath
    describe 'npm prefix is realpath' {
        . $tests
    }

    Set-Location $oldLocation
}
