./scripts/build.ps1 is our catch-all build and publish script.

Tests are run via Pester.  See ./test/main.test.ps1

To compile and test:

```powershell
./scripts/build.ps1 -compile -package -test
```

This will run tests on Windows and Linux (via WSL).  You'll need a copy of `pwsh` installed in both Windows and Linux.  You should be able to do this via `npm install --global get-powershell`

Also make sure npm and node are installed in WSL and are on your PATH.  If they're added via bashrc, you'll need to setup a `pwsh` $PROFILE to set the right PATH due to the way we invoke Linux `pwsh` to run the tests.  We read your `pwsh` $PROFILE, not your bash profile.
