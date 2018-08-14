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
        $npmPrefix = "$( get-location )$( if($IsPosix) { '/npm-prefix' } else { '\npm-prefix' } )"
        $npmGlobalInstallPath = "$npmPrefix$( if($IsPosix) { '/bin' } else { '' } )"
        $npmLocalInstallPath = "$PSScriptRoot$( $dirSep )node_modules$( $dirSep ).bin"
        $env:PATH = (& {
            # Local bin
            $npmLocalInstallPath
            # Global bin in npm prefix
            $npmGlobalInstallPath
            # Path to node
            Split-Path -Parent ( Get-Command node ).Source
            # Path to sh
            if($IsPosix) { split-path -parent ( get-command sh ).source }
        }) -join $pathSep
        if(test-path ./node_modules) {
            remove-item -recurse ./node_modules -force
        }
        if(test-path ./npm-prefix) {
            remove-item -recurse ./npm-prefix -force
        }
        new-item -type directory ./npm-prefix
        set-content ./.npmrc -encoding utf8 "prefix = $npmPrefix"

        function run($block) {
            & $block
            if($lastexitcode -ne 0) { throw "Non-zero exit code: $LASTEXITCODE" }
        }
        Function npm {
            & $npm --userconfig "$PSScriptRoot/.npmrc" @args
        }
    }
    AfterEach {
        $env:PATH = $oldPath
        Set-Location $oldLocation
    }

    it 'npm prefix set correctly for testing' {
        run { npm config get prefix } | should -be $npmPrefix
    }

    describe 'before installation' {
        it 'pwsh is not in path' {
            { get-command pwsh } | should -throw
        }
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
            if($pwshVersion -ne 'latest') {
                pwsh --version | should -be "PowerShell v$pwshVersion"
            }
        }
        aftereach {
            run { npm uninstall --global $tgz }
        }
    }
    describe 'after uninstallation' {
        it 'pwsh is not in path' {
            { get-command pwsh } | should -throw
        }
    }
}
