#!/usr/bin/env bash
set -euxo pipefail

# osx, linux, or windows
os=$1

# Install pnpm
npm install -g pnpm

# Grab PowerShell
mkdir pwsh
pushd pwsh
if [ $os = osx ] ; then
    wget -qO- https://github.com/PowerShell/PowerShell/releases/download/v6.2.0-preview.1/powershell-6.2.0-preview.1-osx-x64.tar.gz -o - | tar -xvz
elif [ $os = linux ] ; then
    wget -qO- https://github.com/PowerShell/PowerShell/releases/download/v6.2.0-preview.1/powershell-6.2.0-preview.1-linux-x64.tar.gz -o - | tar -xvz
fi
popd
# Put ~/bin on path; symlink pwsh into ~/bin
export PATH=$HOME/bin:$PATH
mkdir -p $HOME/bin
ln -s $PWD/pwsh/pwsh ~/bin/pwsh

# Create npm prefix symlink
mkdir -p ./test/real/prefix-posix
ln -s "$PWD/test/real/prefix-posix" "$PWD/test/prefix-link-posix"

# Diagnostic logging
export
echo 'BINARY PATHS:'
which node
which npm
which pnpm
which pwsh

pwsh -noprofile ./scripts/build.ps1 -installPester -compile -package -testPosix
