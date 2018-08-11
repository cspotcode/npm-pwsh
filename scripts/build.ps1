param(
    <# compile TS and bundle via webpack #>
    [switch] $compile,
    [switch] $getPwshVersions,
    <# `npm version` and prepare CHANGELOG for new version #>
    # [switch] $prePublish,
    # <# npm publish all tags #>
    [switch] $publish,
    <# update CHANGELOG for next version #>
    # [switch] $postPublish
    # <# powershell version that this package should install, or 'latest' to install the latest version #>
    # [string] $pwshVersion = 'latest'
    [string[]] $parseVersion
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

    if($publish) {
        $pwshVersions = & {
            'latest'
            ( getPwshVersions ).version
        }
        $pwshVersions
        $npmBaseVersion = (get-content package.json | convertfrom-json).version
        write-host 'npmBaseVersion: ' + $npmBaseVersion
        foreach($pwshVersion in $pwshVersions) {
            $distTag = if($pwshVersion -eq 'latest') { 'latest' } else { "pwsh$pwshVersion" }
            $npmVersion = if($pwshVersion -eq 'latest') { $npmBaseVersion } else { "$npmBaseVersion-pwsh$pwshVersion" }
            $buildTags = @{
                distTag = $distTag;
                pwshVersion = $pwshVersion;
            }
            $buildTags | convertto-json -depth 100 | out-file -encoding utf8 ./dist/buildTags.json
            Write-host 'Publishing:'
            write-host 'npm version: ' + $npmVersion
            write-host 'npm dist-tag: ' + $distTag
            write-host 'pwsh version: ' + $pwshVersion
            write-host 'buildTags.json: ' + get-content ./dist/buildTags.json
            run { npm version --no-git-tag-version $npmVersion --allow-same-version }
            # run { npm publish --dist-tag $buildTags.distTag }
            write-host '-----'
        }
        run { npm version --no-git-tag-version $npmBaseVersion --allow-same-version }


        exit
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
