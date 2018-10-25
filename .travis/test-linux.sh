#!/usr/bin/env bash
set -euxo pipefail
npm install -g pnpm
mkdir pwsh
pushd pwsh
wget -qO- https://github.com/PowerShell/PowerShell/releases/download/v6.2.0-preview.1/powershell-6.2.0-preview.1-linux-x64.tar.gz -o - | tar -xvz
popd
mkdir local-bin
ln -s ./pwsh/pwsh ./local-bin/pwsh 
export PATH="$PWD/local-bin:$PATH"
pwsh -noprofile ./scripts/build.ps1 -compile -package -testLinux
