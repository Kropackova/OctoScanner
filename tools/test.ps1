param([string]$LuaPath = "$PSScriptRoot\..\.tooling\lua50\lua50.exe")
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $LuaPath)) {
    throw 'Lua 5.0 interpreter missing. Supply -LuaPath with a Lua 5.0 executable; see README.md.'
}
$testLua = (Resolve-Path -LiteralPath $LuaPath).Path
$testRoot = (Resolve-Path -LiteralPath "$PSScriptRoot\..").Path
Push-Location -LiteralPath $testRoot
try {
    $testVersion = & $testLua -e 'print(_VERSION)'
    if ($LASTEXITCODE -ne 0 -or $testVersion -notmatch '^Lua 5\.0') {
        throw "These checks require Lua 5.0, got: $testVersion"
    }
    $testFiles = @('tests/run.lua', 'tests/reload.lua', 'tests/history.lua', 'tests/feedback.lua', 'tests/scale.lua', 'tests/ui-scale.lua', 'tests/corpus.lua', 'tests/corpus-third.lua', 'tests/corpus-fourth.lua', 'tests/corpus-fifth.lua')
    if (Test-Path -LiteralPath "$testRoot\OctoChatLogger\OctoChatLogger.toc") {
        $testFiles += @('tests/logger.lua', 'tests/logger-night.lua', 'tests/logger-traffic.lua')
    }
    foreach ($testFile in $testFiles) {
        & $testLua $testFile
        if ($LASTEXITCODE -ne 0) { throw "Failed: $testFile" }
    }
    if (Test-Path -LiteralPath "$testRoot\OctoChatLogger\OctoChatLogger.toc") {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$testRoot\tests\overnight-helper.ps1"
        if ($LASTEXITCODE -ne 0) { throw 'Failed: tests/overnight-helper.ps1' }
    }
} finally { Pop-Location }
