#!/usr/bin/env pwsh
param(
    <# compile TS and bundle via webpack #>
    [switch] $compile,
    [switch] $packageForTests,
    [switch] $test,
    [switch] $testWindows,
    [switch] $testWsl,
    [switch] $testPosix,
    [switch] $getPwshVersions,
    <# `npm version` and prepare CHANGELOG for new version #>
    [switch] $prepareVersion,
    [string] $npmVersionFlag,
    [switch] $version,
    # <# create all packages to be published to npm #>
    [switch] $packageForPublishing,
    # <# npm publish all tags #>
    [switch] $publishPackages,
    <# update CHANGELOG for next version #>
    [switch] $postPublish,
    [switch] $dryrun,
    [string]$winPwsh
)
$BoundParamNames = $PSBoundParameters.Keys

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. "$PSScriptRoot/helpers.ps1"

if(($test -or $testWindows) -and (-not $winPwsh)) {
    $winPwshCmd = get-command pwsh.cmd -ea SilentlyContinue
    if(-not $winPwshCmd) { $winPwshCmd = get-command pwsh.exe }
    $winPwsh = $winPwshCmd.source
}

function validate {
    # if($pwshVersion -cne 'latest') {
    #     if(-not ($versions -contains $pwshVersion)) {
    #         throw "invalid powershell version $pwshVersion, valid values are:`n$( $versions -join "`n" )"
    #     }
    # }
}
function main {

    validate

    if($getPwshVersions) {
        ( getPwshVersions ).version
    }

    if($compile) {
        write-host '----cleaning----'
        Write-Output out dist | % { (test-path $_) -and (Remove-Item -recurse $_) } | out-null
        write-host '----tsc----'
        run { tsc -p . }
        write-host '----webpack----'
        try {
            run { webpack }
        } catch {
            write-output $_
        }
        write-host '----copying----'
        Copy-Item ./out/__root.js ./dist/
        write-host '----done compiling----'
    }

    function forEachPwshVersion($pwshVersions, $action) {
        $npmBaseVersion = ( readfile package.json | convertfrom-json ).version
        foreach($pwshVersion in $pwshVersions) {
            $distTag = if(@('latest', 'prerelease') -contains $pwshVersion) { $pwshVersion } else { "pwsh$pwshVersion" }
            $npmVersion = if($pwshVersion -eq 'latest') {
                $npmBaseVersion
            } elseif ($pwshVersion -eq 'prerelease') {
                "$npmBaseVersion-prerelease"
            } else {
                "$npmBaseVersion-pwsh$pwshVersion"
            }
            $buildTags = @{
                distTag = $distTag;
                pwshVersion = $pwshVersion;
            }
            $buildTags | convertto-json -depth 100 | out-file -encoding utf8 ./dist/buildTags.json
            & $action
        }
    }

    if($packageForTests) {
        forEachPwshVersion @('latest') {
            run { npm pack }
        }
    }

    if($test -or $testWindows) {
        write-host 'Testing in Windows'
        write-host ('pwsh path: ' + $winPwsh)
        & ./node_modules/.bin/mocha.cmd
        if($LASTEXITCODE -ne 0) {throw "Non-zero exit code: $LASTEXITCODE"}
    }
    if($test -or $testWsl) {
        write-host 'Testing in WSL (should be invoked from Windows)'
        # bash -l is required to set nvm PATHS
        bash -c "bash -l -c './node_modules/.bin/mocha'"
        if($LASTEXITCODE -ne 0) {throw "Non-zero exit code: $LASTEXITCODE"}
    }
    if($testPosix) {
        write-host 'Testing in Posix (should be invoked from within Linux, Mac, or WSL)'
        ./node_modules/.bin/mocha
        if($LASTEXITCODE -ne 0) {throw "Non-zero exit code: $LASTEXITCODE"}
    }

    if($prepareVersion) {
        if(-not ($BoundParamNames -contains 'npmVersionFlag')) { throw "must pass -npmVersionFlag" }
        write-host 'bumping npm version'
        run { npm version --no-git-tag-version --allow-same-version $npmVersionFlag }
        $npmVersion = (readfile package.json | convertfrom-json).version
        run { git add package.json }
        write-host 'preparing changelog...'
        writefile CHANGELOG.md ((readfile CHANGELOG.md) -replace 'vNEXT',"v$npmVersion")
        write-host 'Update and `git add` changelog.  Make sure package.json version is accurate.  Then run -version, -packageForPublish, -publishPackages, and finally -postPublish.'
    }

    if($version) {
        $npmBaseVersion = ( readfile package.json | convertfrom-json ).version
        write-host "Creating version commit and tag for $npmBaseVersion"
        if(-not $dryrun) {
            run { git add package.json }
            run { git commit -m "v$npmBaseVersion" --allow-empty }
            run { git tag "v$npmBaseVersion" }
        }
    }

    if($packageForPublishing) {
        $pwshVersions = & {
            'latest'
            'prerelease'
            ( getPwshVersions ).version
        }
        $pwshVersions
        $npmBaseVersion = ( readfile package.json | convertfrom-json ).version
        write-host "npmBaseVersion: $npmBaseVersion"
        if(test-path packages) { remove-item -Recurse packages }
        new-item -type directory packages
        forEachPwshVersion $pwshVersions {
            write-host ''
            Write-host 'PACKAGING:'
            write-host "npm version: $npmVersion"
            write-host "npm dist-tag: $distTag"
            write-host "pwsh version: $pwshVersion"
            write-host "buildTags.json: $(readfile ./dist/buildTags.json)"
            if(-not $dryrun) {
                run { npm version --no-git-tag-version $npmVersion --allow-same-version }
                run { npm pack }
                move-item *.tgz packages/package-$distTag.tgz
            }
            write-host '-----'
        }
        run { npm version --no-git-tag-version $npmBaseVersion --allow-same-version }
    }

    if($publishPackages) {
        get-childitem packages | % {
            $name = $_.name
            $distTag = (select-string -inputobject $name -pattern 'package-(.*).tgz').matches.groups[1].value
            run { npm publish --tag $distTag ./packages/$name }
        }
    }

    if($postPublish) {
        write-host 'adding vNEXT to changelog, committing to git'
        writefile CHANGELOG.md "# vNEXT`n`n* `n`n$(readfile CHANGELOG.md)"
        run { git add CHANGELOG.md }
        run { git commit -m "Bump changelog for next version" }

        run { git push }
        run { git push --tags }

    }
}

function getPwshVersions {
    $versions = run { ts-node --transpile-only -e @'
        console.log(JSON.stringify(require('./src/versions').versions));
'@
    } | convertfrom-json
    $versions
}

$oldPwd = $pwd
Set-Location "$PSScriptRoot/.."
$oldPath = $env:PATH
$env:PATH = "$pwd/node_modules/.bin$( [IO.Path]::PathSeparator )$env:PATH"
try {
    main
} finally {
    Set-location $oldPwd
    $env:PATH = $oldPath
}
