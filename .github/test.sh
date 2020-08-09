#!/usr/bin/env bash
set -euxo pipefail

# osx, linux, or windows
os=$1
if [ $os = osx ] ; then
    powershellUrl=https://github.com/PowerShell/PowerShell/releases/download/v7.0.3/PowerShell-7.0.3-osx-x64.tar.gz
elif [ $os = linux ] ; then
    powershellUrl=https://github.com/PowerShell/PowerShell/releases/download/v7.0.3/powershell-7.0.3-linux-x64.tar.gz
fi

# Install pnpm
sudo npm install -g pnpm

# Grab PowerShell
mkdir pwsh
pushd pwsh
wget --quiet --output-document=- $powershellUrl | tar -xvz
popd
# Put ~/bin on path; symlink pwsh into ~/bin
export PATH=$HOME/bin:$PATH
mkdir -p $HOME/bin
ln -s $PWD/pwsh/pwsh ~/bin/pwsh

# Install npm dependencies locally
npm install

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

pwsh -noprofile ./scripts/build.ps1 -compile -packageForTests -testPosix
