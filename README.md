# get-powershell (beta)

Installs powershell into an internal cache and exposes it to your npm scripts.

Alternatively, install it globally for a super-simple powershell installation.

## Why?

I prefer PowerShell to bash for quickly writing npm scripts. (opinion)  However, I can't expect collaborators to have it installed.*  Adding `"get-powershell"` as a `"devDependency"` solves that problem without any extra effort.

*\* Even on Windows, "Windows PowerShell" is preinstalled but we want to use `pwsh` / PowerShell Core, the cross-platform, more up-to-date edition of PowerShell.*

## Usage

If you just want to use `pwsh` for your npm scripts, add us as a devDependency:

```
npm install --save-dev get-powershell
```

If you want `pwsh` to be globally available as an interactive shell:

```
npm install --global get-powershell
```

All installations are shared, so you can depend on "get-powershell" in many projects without downloading multiple copies of `pwsh`.  See the FAQ for details.

## Example

```json
// Example package.json
{
    "devDependencies": {
        // Use the latest get-powershell to install pwsh 6.0.4
        "get-powershell": "pwsh6.0.4"
    },
    "scripts": {
        "test": "pwsh -NoProfile ./scripts/test.ps1"
    }
}
```

## FAQ

### Where is powershell installed?

`--global` installations go into your npm prefix:

* Linux and Mac: "\<npm prefix\>/lib/node_modules/@cspotcode/get-powershell-cache"
* Windows: "\<npm prefix\>/node_modules/@cspotcode/get-powershell-cache"

Local installations go into "$HOME/.npm-get-powershell".  We use your $HOME directory because Linux and Mac, by default, require root for global installations, so the npm
prefix isn't writable.

Installation is merely extracting the .zip or .tar.gz download from [PowerShell Core's Github releases](https://github.com/PowerShell/PowerShell/releases).  No scripts are run; your system is not modified.

```bash
# To view globally installed versions on Linux and Mac
cd "$(npm get prefix)/lib/node_modules/@cspotcode/get-powershell-cache"
ls # shows all the versions installed
```

Installations are cached and shared, so if you work on 5 different projects that all depend
on "get-powershell", only a single copy of `pwsh` will be downloaded.  Subsequent `npm install`s should be very fast, merely creating a symlink at "./node_modules/.bin/pwsh".

PowerShell Core is about 50MB to download; 127MB extracted.

### How do I install a specific version of pwsh?

By default we install the latest version of PowerShell Core.  To install a specific version, check the [dist-tags](https://www.npmjs.com/package/get-powershell?activeTab=versions) and install the one you want.

```
npm install get-powershell@pwsh6.0.4
```

*Remember, npm dist-tags !== npm versions.
