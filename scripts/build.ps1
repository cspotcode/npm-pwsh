param(
    <# install pester on CI #>
    [switch] $installPester,
    <# compile TS and bundle via webpack #>
    [switch] $compile,
    [switch] $package,
    [switch] $test,
    [switch] $testWindows,
    [switch] $testLinux,
    [switch] $getPwshVersions,
    <# `npm version` and prepare CHANGELOG for new version #>
    [switch] $prePublish,
    [string] $npmVersionFlag,
    # <# npm publish all tags #>
    [switch] $publish,
    <# update CHANGELOG for next version #>
    [switch] $postPublish,
    [string[]] $parseVersion,
    [switch] $dryrun
)
$BoundParamNames = $PSBoundParameters.Keys

$ErrorActionPreference = 'Stop'

if($test -or $testWindows) {
    $winPwsh = get-command pwsh.cmd -ea continue
    if(-not $winPwsh) { $winPwsh = get-command pwsh.exe }
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

    if($installPester) {
        install-module -scope currentuser -force pester
    }

    if($compile) {
        echo out dist | % { (test-path $_) -and (rm -recurse $_) } | out-null
        run { tsc -p . }
        run { webpack }
        cp ./out/__root.js ./dist/
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

    if($package) {
        forEachPwshVersion @('latest') {
            run { npm pack }
        }
    }

    if($test -or $testWindows) {
        write-host 'Testing in Windows'
        & $winPwsh -noprofile -file ./test/test.ps1
        if($LASTEXITCODE -ne 0) {throw "Non-zero exit code: $LASTEXITCODE"}
    }
    if($test -or $testLinux) {
        write-host 'Testing in Linux'
        bash -c "bash -l -c 'pwsh -noprofile -file ./test/test.ps1'"
        if($LASTEXITCODE -ne 0) {throw "Non-zero exit code: $LASTEXITCODE"}
    }

    if($prePublish) {
        if(-not ($BoundParamNames -contains 'npmVersionFlag')) { throw "must pass -npmVersionFlag" }
        write-host 'bumping npm version'
        run { npm version --no-git-tag-version --allow-same-version $npmVersionFlag }
        $npmVersion = (readfile package.json | convertfrom-json).version
        run { git add package.json }
        write-host 'preparing changelog...'
        writefile CHANGELOG.md ((readfile CHANGELOG.md) -replace 'vNEXT',"v$npmVersion")
        write-host 'Update and `git add` changelog.  Make sure package.json version is accurate.  Then run publish.'
    }

    if($publish) {

        $pwshVersions = & {
            'latest'
            'prerelease'
            ( getPwshVersions ).version
        }
        $pwshVersions
        $npmBaseVersion = ( readfile package.json | convertfrom-json ).version
        write-host "Creating version commit and tag for $npmBaseVersion"
        if(-not $dryrun) {
            run { git add package.json }
            run { git commit -m "v$npmBaseVersion" --allow-empty }
            run { git tag "v$npmBaseVersion" }
        }
        write-host "npmBaseVersion: $npmBaseVersion"
        forEachPwshVersion $pwshVersions {
            write-host ''
            Write-host 'PUBLISHING:'
            write-host "npm version: $npmVersion"
            write-host "npm dist-tag: $distTag"
            write-host "pwsh version: $pwshVersion"
            write-host "buildTags.json: $(readfile ./dist/buildTags.json)"
            if(-not $dryrun) {
                run { npm version --no-git-tag-version $npmVersion --allow-same-version }
                run { npm publish --tag $buildTags.distTag }
            }
            write-host '-----'
        }
        run { npm version --no-git-tag-version $npmBaseVersion --allow-same-version }
    }

    if($postPublish) {
        write-host 'adding vNEXT to changelog, committing to git'
        writefile CHANGELOG.md "# vNEXT`n`n* `n`n$(readfile CHANGELOG.md)"
        run { git add CHANGELOG.md }
        run { git commit -m "Bump changelog for next version" }

        run { git push }
        run { git push --tags }

    }

    if($parseVersion) {
        $ghHashes = $parseVersion
        $versions = $ghHashes |
        ? { $_ } |
        % { $m = $false } {
            $m = -not $m
            if($m) {
                $name = $_.trim()
            } else {
                $name -match 'PowerShell-(?<version>.*)-(?<platform>.*?)-(?<arch>.*?)(?<extension>\..*)'
                [pscustomobject]@{
                    # name = $name;
                    # version = $Matches.version;
                    platform = $Matches.platform;
                    arch = $Matches.arch;
                    extension = $Matches.extension;
                    sha256 = $_.trim();
                    url = "https://github.com/PowerShell/PowerShell/releases/download/v$( $Matches.version )/$name";
                    bin = 'pwsh'
                }
            }
        } |
        ? {
            $_.platform -match 'win|osx|linux' -and $_.extension -match '\.tar\.gz|\.zip' -and $_.arch -match 'x86|x64'
        } |
        % {
            $_.arch = @{ x64 = 'x64'; x86 = 'ia32'; }.($_.arch);
            $_.platform = @{ osx = 'darwin'; win = 'win32'; linux = 'linux' }.($_.platform);
            if($_.platform -eq 'win32') { $_.bin += '.exe' }
            $_
        }

        $versions
    }

}

function getPwshVersions {
    $versions = run { ts-node --transpile-only -e @'
        console.log(JSON.stringify(require('./src/versions').versions));
'@
    } | convertfrom-json
    $versions
}

function readfile($path) {
    ,(get-content -raw -encoding utf8 -path $path)
}
function writefile {
    param(
        $path,
        [Parameter(valuefrompipeline)] $content
    )
    [IO.File]::WriteAllText(($path | resolve-path), $content)
}

function run($block) {
    & $block
    if($LASTEXITCODE -ne 0) { throw "Non-zero exit code: $LASTEXITCODE" }
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
