#!/usr/bin/env bash
set -euxo pipefail
npm install -g pnpm
mkdir pwsh
pushd pwsh
wget -qO- https://github.com/PowerShell/PowerShell/releases/download/v6.2.0-preview.1/powershell-6.2.0-preview.1-osx-x64.tar.gz -o - | tar -xvz
popd
mkdir bin
ln -s ./pwsh/pwsh ./bin/pwsh 
export PATH="$PWD/bin:$PATH"
pwsh -noprofile ./scripts/build.ps1 -compile -package -testLinux
