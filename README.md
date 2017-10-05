# get-powershell (beta)

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
