#Require -PSEdition Core

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$IsPosix = $IsMacOS -or $IsLinux

$pathSep = if($IsPosix) { ':' } else { ';' }
$dirSep = if($IsPosix) { '/' } else { '\' }
$tgz = get-item $PSScriptRoot/../pwsh-*.tgz
# $fromTgz = get-item $PSScriptRoot/../pwsh-*.tgz
# $tgz = "./this-is-the-tgz.tgz"
# remove-item $tgz -ea continue
# move-item $fromTgz $tgz
$npmVersion = (get-content $PSScriptRoot/../package.json | convertfrom-json).version
$pwshVersion = (get-content $PSScriptRoot/../dist/buildTags.json | convertfrom-json).pwshVersion

$npm = (Get-Command npm).Source
$pnpm = (Get-Command pnpm).Source

$winPwsh = get-command pwsh.cmd -ea continue
if(-not $winPwsh) { $winPwsh = get-command pwsh.exe }

Describe 'get-powershell' {
    BeforeEach {
        <### HELPER FUNCTIONS ###>
        function run($block) {
            & $block
            if($lastexitcode -ne 0) { throw "Non-zero exit code: $LASTEXITCODE" }
        }
        Function npm {
            & $npm --userconfig "$PSScriptRoot/.npmrc" @args | write-host
        }
        Function pnpm {
            & $pnpm --userconfig "$PSScriptRoot/.npmrc" @args | write-host
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
            if($IsPosix) {
                new-item -type symboliclink -path $from -Target $to -EA Stop
            }
            else {
                start-process -verb runas -wait $winPwsh -argumentlist @(
                    '-noprofile', '-c', {
                        param($from, $to)
                        echo new-item -type symboliclink -path $npmSymlinkPrefix -Target $npmRealpathPrefix -EA Stop
                    }, $from, $to
                )
            }
        }

        <### SETUP ENVIRONMENT ###>

        $oldLocation = Get-Location
        Set-Location $PSScriptRoot
        # Add node_modules/.bin to PATH; remove any paths containing pwsh.exe
        $oldPath = $env:PATH
        $npmRealpathPrefix = "$( get-location )$( if($IsPosix) { '/real/npm-prefix' } else { '\real\npm-prefix' } )"
        $npmSymlinkPrefix = "$( get-location )$( if($IsPosix) { '/link-to-npm-prefix-linux' } else { '\link-to-npm-prefix-windows' } )"
        $npmGlobalInstallPath = "$npmSymlinkPrefix$( if($IsPosix) { '/bin' } else { '' } )"
        $npmLocalInstallPath = "$PSScriptRoot$( $dirSep )node_modules$( $dirSep ).bin"
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
        if(test-path ./real/npm-prefix) {
            remove-item -recurse ./real/npm-prefix -force
        }
        new-item -type directory $npmRealpathPrefix
        symlink $npmSymlinkPrefix $npmRealpathPrefix
        set-content ./.npmrc -encoding utf8 "prefix = $($npmPrefix -replace '\\','\\')"

        $preexistingPwsh = get-command pwsh -EA SilentlyContinue
        if($preexistingPwsh) { $preExistingPwsh = $preexistingPwsh.Source }

    }
    AfterEach {
        Set-Location $oldLocation
        if($IsPosix) { Remove-Item -Path $npmSymlinkPrefix }
        else { Remove-Item -Path $npmSymlinkPrefix }
        $env:PATH = $oldPath
    }

    it 'Symlink exists (it requires admin privileges to create on windows and isnt done automatically)' {
        write-host ">>$npmSymlinkPrefix"
        Get-Item $npmSymlinkPrefix
    }

    $tests = {
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
                write-host 'deleting node_modules'
                retry 4 1 { remove-item -r node_modules }
                write-host 'deleted node_modules'
            }
        }
        describe 'local installation via pnpm' {
            beforeeach {
                run { pnpm install $tgz }
            }
            it 'pwsh is in path and is correct version' {
                (get-command pwsh).source | should -belike "$npmLocalInstallPath*"

                if($pwshVersion -ne 'latest') {
                    pwsh --version | should -be "PowerShell v$pwshVersion"
                }
            }
            aftereach {
                run { pnpm uninstall $tgz }
                write-host 'deleting node_modules'
                retry 4 1 { remove-item -r node_modules }
                write-host 'deleted node_modules'
            }
        }
        describe 'global installation' {
            beforeeach {
                run { npm install --global $tgz }
            }
            it 'pwsh is in path and is correct version' {
                (get-command pwsh).source | should -belike "$npmGlobalInstallPath*"
                (get-command pwsh).source | should -not -Be $preExistingPwsh
                if($pwshVersion -ne 'latest') {
                    pwsh --version | should -be "PowerShell v$pwshVersion"
                }
            }
            aftereach {
                run { npm uninstall --global $tgz }
            }
        }
    }

    describe 'npm prefix is symlink' {
        $npmPrefix = $npmSymlinkPrefix
        . $tests
    }
    describe 'npm prefix is realpath' {
        $npmPrefix = $npmRealpathPrefix
        . $tests
    }
}
