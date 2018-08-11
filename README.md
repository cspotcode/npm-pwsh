# get-powershell (beta)

*Note: currently missing Mac support because I don't have a Mac to test on.*

Installs powershell into an internal cache and exposes it to your npm scripts.

Alternatively, install it globally for a super-simple powershell installation.

## Why?

PowerShell's great; way better than bash for quickly writing npm scripts. (opinion)  However, I can't expect collaborators to have it installed already on their Mac or Linux boxes.  Adding `"get-powershell"` as a `"devDependency"` solves that problem without any extra effort.

## Usage

If you just want to use PowerShell for your npm scripts, add us as a devDependency:

```
npm install --save-dev get-powershell
```

If you want powershell to be globally available in general:

```
npm install --global get-powershell
```

## Example

```json
// Example package.json
{
    "devDependencies": {
        "get-powershell": "0.0.3" // ... or the latest version
    },
    "scripts": {
        "test": "powershell -File ./scripts/test.ps1"
    }
}
```

## FAQ

### Where is powershell being installed?

```
# On Linux, the shared, extracted powershell installations are stored here:
cd "$(npm get prefix)/lib/node_modules/@cspotcode/get-powershell--cache"
ls # shows all the versions installed
```

### How do I install a specific version of PowerShell?

By default `get-powershell` installs the latest version of PowerShell
