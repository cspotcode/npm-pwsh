# pwsh

Install PowerShell Core via npm, allowing you to use it in npm scripts and node projects.

`npm i -g pwsh` may be the easiest way to get started with PowerShell Core on any platform.

## Why?

I prefer PowerShell to bash for quickly writing npm scripts. (opinion)  However, I can't expect collaborators to have it installed.*  Adding `"pwsh"` as a `"devDependency"` solves that problem without any extra effort.

We support both global and local npm installations, and we use a shared cache to avoid downloading duplicate copies of the full `pwsh` distribution.  This means you can install us as a *local* dev dependency in dozens of projects, and the installation process will quickly create a symlink to the cache.

*\* Even on Windows, the aging "Windows PowerShell" is preinstalled but we want to use `pwsh` / PowerShell Core, the cross-platform, more up-to-date edition of PowerShell.*

## Usage

If you just want to use `pwsh` for your npm scripts, add us as a devDependency:

```
npm install --save-dev pwsh
```

If you want `pwsh` to be globally available as an interactive shell:

```
npm install --global pwsh
```

All installations are shared, so you can depend on "pwsh" in many projects without downloading multiple copies of `pwsh`.  See the FAQ for details.

## Example

```json
// Example package.json
{
    "devDependencies": {
        // Use the latest pwsh to install pwsh 6.0.4
        "pwsh": "pwsh6.0.4"
    },
    "scripts": {
        "test": "pwsh -NoProfile ./scripts/test.ps1"
    }
}
```

## FAQ

### Where is PowerShell installed?

`--global` installations go into your npm prefix:

* Linux and Mac: "\<npm prefix\>/lib/node_modules/@cspotcode/pwsh-cache"
* Windows: "\<npm prefix\>/node_modules/@cspotcode/pwsh-cache"

Local installations are cached in "$HOME/.npm-pwsh".  We use your $HOME directory because Linux and Mac, by default, require root for global installations, so the npm
prefix isn't writable.

Installation is merely extracting the .zip or .tar.gz download from [PowerShell Core's Github releases](https://github.com/PowerShell/PowerShell/releases).  No scripts are run; your system is not modified.

```bash
# To view globally installed versions on Linux and Mac
cd "$(npm get prefix)/lib/node_modules/@cspotcode/pwsh-cache"
ls # shows all the versions installed
```

Installations are cached and shared, so if you work on 5 different projects that all depend
on "pwsh", only a single copy of `pwsh` will be downloaded.  Subsequent `npm install`s should be very fast, merely creating a symlink at "./node_modules/.bin/pwsh".

PowerShell Core is about 50MB to download; 127MB extracted.

### How do I install a specific version of pwsh?

By default we install the latest version of PowerShell Core.  To install a specific version -- including prereleases -- check the [dist-tags](https://www.npmjs.com/package/pwsh?activeTab=versions) and install the one you want.

```
npm install pwsh@pwsh6.2.0-preview.1
```

*Remember, npm dist-tags !== npm versions.

### Dependencies

We are not running `sudo apt-get`, `brew install`, etc.  So it's possible PowerShell will complain about unmet dependencies that we're unable to provide.  For context, checkout out [issue #8](https://github.com/cspotcode/npm-pwsh/issues/8).
