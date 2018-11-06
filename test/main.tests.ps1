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

function logBinaryLocations() {
    write-host 'PATH:'
    write-host $env:PATH
    write-host 'BINARY PATHS:'
    write-host (which node)
    write-host (which npm)
    write-host (which pnpm)
    write-host (which pwsh)
}

$npm = (Get-Command npm).Source
$pnpm = (Get-Command pnpm).Source

if($IsWindows) {
    try {
        $winPwsh = (get-command pwsh.cmd).path
    } catch {
        $winPwsh = (get-command pwsh.exe).path
    }
}

$npmPrefixRealpath = "$PSScriptRoot$( if($IsPosix) { '/real/prefix-posix' } else { '\real\prefix-windows' } )"
$npmPrefixSymlink = "$PSScriptRoot$( if($IsPosix) { '/prefix-link-posix' } else { '\prefix-link-windows' } )"
$npmGlobalInstallPath = "$npmPrefixSymlink$( if($IsPosix) { '/bin' } else { '' } )"
$npmLocalInstallPath = "$PSScriptRoot$( $dirSep )node_modules$( $dirSep ).bin"

<### HELPER FUNCTIONS ###>
function run($block, [switch]$show) {
    if($show) {
        & $block 2>&1 | write-host
    } else {
        & $block
    }
    if($lastexitcode -ne 0) { throw "Non-zero exit code: $LASTEXITCODE" }
}
Function npm {
    & $npm --userconfig "$PSScriptRoot/.npmrc" @args
}
Function pnpm {
    & $pnpm --userconfig "$PSScriptRoot/.npmrc" @args
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
    if((get-item $from).target -eq $to) {
        write-host "Symlink already exists: $from --> $to"
        return
    }
    write-host "Symlinking $from --> $to"
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

Describe 'pwsh' {
    $oldLocation = Get-Location
    Set-Location $PSScriptRoot
    BeforeEach {
        <### SETUP ENVIRONMENT ###>

        # Add node_modules/.bin to PATH; remove any paths containing pwsh
        $oldPath = $env:PATH
        $env:PATH = (& {
            # Local bin
            $npmLocalInstallPath
            # Global bin in npm prefix
            $npmGlobalInstallPath
            # Path to node & npm, pnpm, which, sh, etc
            Split-Path -Parent $npm
            Split-Path -Parent $pnpm
            Split-Path -Parent (which which)
            # Path to sh
            if($IsPosix) {
                Split-Path -Parent ( Get-Command sh ).Source
            }
        }) -join $pathSep

        <### CLEAN ###>
        if(test-path ./node_modules) {
            remove-item -recurse ./node_modules -force
        }
        if(test-path $npmPrefixRealpath) {
            remove-item -recurse $npmPrefixRealpath -force
        }
        new-item -type directory $npmPrefixRealpath
        symlink $npmPrefixSymlink $npmPrefixRealpath

        # Set npm prefix
        set-content ./.npmrc -encoding utf8 "prefix = $($npmPrefix -replace '\\','\\')"

        $preexistingPwsh = get-command pwsh -EA SilentlyContinue
        if($preexistingPwsh) { $preExistingPwsh = $preexistingPwsh.Source }

    }
    AfterEach {
        $env:PATH = $oldPath
    }

    $tests = {

        it 'npm prefix symlink exists' {
            (Get-Item $npmPrefixSymlink).attributes -eq 'symboliclink'
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
                run { pnpm install $tgz }
            }
            it 'pwsh is in path and is correct version' {
                (get-command pwsh).source | should -belike "$npmLocalInstallPath*"
                
                if($pwshVersion -ne 'latest') {
                    pwsh --version | should -be "PowerShell v$pwshVersion"
                }
            }
            aftereach {
                # run { pnpm uninstall $tgz }
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
