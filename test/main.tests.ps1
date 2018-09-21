#Require -PSEdition Core

$ErrorActionPreference = 'Stop'

$IsPosix = $IsMac -or $IsLinux

$pathSep = if($IsPosix) { ':' } else { ';' }
$dirSep = if($IsPosix) { '/' } else { '\' }
$tgz = get-item $PSScriptRoot/../get-powershell-*.tgz
$npmVersion = (get-content $PSScriptRoot/../package.json | convertfrom-json).version
$pwshVersion = (get-content $PSScriptRoot/../dist/buildTags.json | convertfrom-json).pwshVersion

$npm = (Get-Command npm).Source

Describe 'get-powershell' {
    BeforeEach {
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
        if($IsPosix) { new-item -type symboliclink -path $npmSymlinkPrefix -Target $npmRealpathPrefix -EA Stop }
        set-content ./.npmrc -encoding utf8 "prefix = $($npmPrefix -replace '\\','\\')"

        $preexistingPwsh = get-command pwsh -EA SilentlyContinue
        if($preexistingPwsh) { $preExistingPwsh = $preexistingPwsh.Source }

        function run($block) {
            & $block
            if($lastexitcode -ne 0) { throw "Non-zero exit code: $LASTEXITCODE" }
        }
        Function npm {
            & $npm --userconfig "$PSScriptRoot/.npmrc" @args
        }
    }
    AfterEach {
        Set-Location $oldLocation
        if($IsPosix) { Remove-Item -Path $npmSymlinkPrefix }
        $env:PATH = $oldPath
    }

    it 'Symlink exists (it requires admin privileges to create on windows and isnt done automatically)' {
        Get-Item $npmSymlinkPrefix
    }

    $tests = {
        it 'npm prefix set correctly for testing' {
            run { npm config get prefix } | should -be $npmPrefix
        }

        describe 'local installation' {
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
