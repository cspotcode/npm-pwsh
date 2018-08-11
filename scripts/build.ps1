param(
    <# compile TS and bundle via webpack #>
    [switch] $compile,
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

$ErrorActionPreference = 'Stop'

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
        echo out dist | % { (test-path $_) -and (rm -recurse $_) } | out-null
        # run { tsc -p . }
        tsc -p .
        run { webpack }
        cp ./out/__root.js ./dist/
    }

    if($prePublish) {
        if($npmVersionFlag -eq $null) { throw "must pass -npmVersionFlag" }
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
            ( getPwshVersions ).version
        }
        $pwshVersions
        $npmBaseVersion = ( readfile package.json | convertfrom-json ).version

        write-host "Creating version commit and tag for $npmBaseVersion"
        if(-not $dryrun) {
            run { git add package.json }
            run { git commit -m "v$npmBaseVersion" }
            run { git tag "v$npmBaseVersion" }
        }

        write-host "npmBaseVersion: $npmBaseVersion"
        foreach($pwshVersion in $pwshVersions) {
            $distTag = if($pwshVersion -eq 'latest') { 'latest' } else { "pwsh$pwshVersion" }
            $npmVersion = if($pwshVersion -eq 'latest') { $npmBaseVersion } else { "$npmBaseVersion-pwsh$pwshVersion" }
            $buildTags = @{
                distTag = $distTag;
                pwshVersion = $pwshVersion;
            }
            $buildTags | convertto-json -depth 100 | out-file -encoding utf8 ./dist/buildTags.json
            Write-host 'Publishing:'
            write-host "npm version: $npmVersion"
            write-host "npm dist-tag: $distTag"
            write-host "pwsh version: $pwshVersion"
            write-host "buildTags.json: $(readfile ./dist/buildTags.json)"
            if(-not $dryrun) {
                run { npm version --no-git-tag-version $npmVersion --allow-same-version }
                run { npm publish --dist-tag $buildTags.distTag }
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
                $name -match 'PowerShell-(?<version>.*?)-(?<platform>.*?)-(?<arch>.*?)(?<extension>\..*)'
                [pscustomobject]@{
                    # name = $name;
                    # version = $Matches.version;
                    platform = $Matches.platform;
                    arch = $Matches.arch;
                    extension = $Matches.extension;
                    sha256 = $_.trim();
                    url = "https://github.com/PowerShell/PowerShell/releases/download/v$( $Matches.version )/$name";
                }
            }
        } |
        ? {
            $_.platform -match 'win|osx|linux' -and $_.extension -match '\.tar\.gz|\.zip' -and $_.arch -match 'x86|x64'
        } |
        % {
            $_.arch = @{ x64 = 'x64'; x86 = 'ia32'; }.($_.arch);
            $_.platform = @{ osx = 'darwin'; win = 'win32'; linux = 'linux' }.($_.platform);
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
