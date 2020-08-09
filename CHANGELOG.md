# vNEXT

* 

# v0.3.0

* Move tests from Pester to mocha
* Move from TravisCI to Github Actions
* Tweak publishing workflow
* Improve version parsing script to pull and parse all releases from Github's API.
* Add many more pwsh versions
* Add arm and arm64 pwsh packages

# v0.2.0

* Add Powershell 6.2.0-preview.1
* Rename to `pwsh` (git repo `npm-pwsh`)
* Fix compatibility with pnpm [#14](https://github.com/cspotcode/npm-pwsh/issues/14)

# v0.1.1

* Avoid repeated, unnecessary package extractions on Windows.  [#11](https://github.com/cspotcode/npm-pwsh/issues/11)
* Fix support for symlinked npm prefix.  This affects users of nvs; possibly others.  [#9](https://github.com/cspotcode/npm-pwsh/issues/9)

# v0.1.0

* Add PowerShell Core v6.1.0.
* Remove "beta" header from README.
* Mark v6.0.0-rc2 as prerelease.
* Fix nvm compatibility when running WSL tests.

# v0.0.8

* Adds support for prerelease versions of pwsh, installable via `npm i pwsh@prerelease`.
* Adds pwsh v6.1.0-rc.1.

# v0.0.7

* Adds automated tests.
* Fix issue where npm would refuse to remove the installed symlinks / cmd shims when you `npm uninstall pwsh`
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
