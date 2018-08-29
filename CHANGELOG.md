# vNEXT

* Mark v6.0.0-rc2 as prerelease.

# v0.0.8

* Adds support for prerelease versions of pwsh, installable via `npm i get-powershell@prerelease`.
* Adds pwsh v6.1.0-rc.1.

# v0.0.7

* Adds automated tests.
* Fix issue where npm would refuse to remove the installed symlinks / cmd shims when you `npm uninstall get-powershell`
* Fix problem `npm install`ing a fresh git clone (only affects contributors, not consumers)
* Switch to cross-spawn; fixes bug globally installing on Windows.

# v0.0.6

* Fix broken 6.0.3 metadata.
* Fix bug in --global installations; was not getting npm prefix correctly.

# v0.0.5

* Publishes tagged packages that install a specific version of PowerShell Core rather than the latest version.
* Bundles via webpack to eliminate all npm dependencies and install faster.
* `--global` installs cache in npm prefix; local installations still cache in $HOME

# v0.0.4

* I did not keep a changelog for this version and prior.
