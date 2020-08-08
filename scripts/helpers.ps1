function run($block) {
    $OldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $block
    $ErrorActionPreference = $OldErrorActionPreference
    if($LASTEXITCODE -ne 0) { throw "Non-zero exit code: $LASTEXITCODE" }
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
