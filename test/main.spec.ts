import {join, relative, resolve, basename, dirname} from 'path';
import {readdirSync, lstatSync, existsSync, statSync, realpathSync, symlinkSync, mkdirSync as mkdir, writeFileSync, readFileSync} from 'fs';
import {sync as which} from 'which';
import {sync as rimraf} from 'rimraf';
import {sync as execaSync} from 'execa';
import { promisify } from 'util';
import * as pathKey from 'path-key';
import * as assert from 'assert';
import outdent from 'outdent';

const IsWindows = process.platform === 'win32';
const IsPosix = !IsWindows;

const pathSep = IsPosix ? ':' : ';';
const dirSep = IsPosix ? '/' : '\\';
const tgzPath = resolve(readdirSync(join(__dirname, '..')).find(v => basename(v).match(/pwsh-.*\.tgz/))!);
// # $fromTgz = get-item $__dirname/../pwsh-*.tgz
// # $tgz = "./this-is-the-tgz.tgz"
// # remove-item $tgz -ea continue
// # move-item $fromTgz $tgz
const npmVersion = require('../package.json').version;
const pwshVersion = require('../dist/buildTags.json').pwshVersion;

function logBinaryLocations() {
    console.log('PATH:');
    console.log(process.env[pathKey()]);
    console.log('BINARY PATHS:');
    console.log(which('node'));
    console.log(which('npm'));
    console.log(which('pnpm'));
    console.log(which('pwsh'));
}

function Try<T, U>(tryCb: () => T, catchCb: (error: any) => U): T | U {
    try {
        return tryCb();
    } catch(e) {
        return catchCb(e);
    }
}
const npmBinary = which('npm');
const pnpmBinary = Try(
    () => which('pnpm'),
    (e) => { throw new Error('pnpm not found; you must have it installed to run tests.  npm install -g pnpm'); }
);

let winPwsh: string;
if(IsWindows) {
    try {
        winPwsh = which('pwsh.cmd');
    } catch {
        winPwsh = which('pwsh.exe');
    }
}

const npmPrefixRealpath = `${__dirname}${ IsPosix ? '/real/prefix-posix' : '\\real\\prefix-windows' }`;
const npmPrefixSymlink = `${__dirname}${ IsPosix ? '/prefix-link-posix' : '\\prefix-link-windows' }`;
const npmGlobalInstallPath = `${npmPrefixSymlink}${ IsPosix ? '/bin' : '' }`;
const npmLocalInstallPath = `${__dirname}${ dirSep }node_modules${ dirSep }.bin`;

// <### HELPER FUNCTIONS ###>
const delay = promisify(setTimeout);
function assertSuccessExitCode<T extends {exitCode: number}>(execaReturn: T): T {
    assert.equal(execaReturn.exitCode, 0);
    return execaReturn;
}
function logFence(message: string) {
    console.log('------------------------');
    console.log(' ' + message);
    console.log('------------------------');
}
function exec(args: string | string[], env?: Record<string, string>) {
    if(typeof args === 'string') args = args.split(' ');
    logFence('STARTING: ' + args.join(' '));
    const ret = execaSync(args[0], args.slice(1), {
        stdio: 'inherit',
        env: env ? {...process.env, ...env} : undefined
    });
    logFence('FINISHED: ' + args.join(' '));
    return assertSuccessExitCode(ret);
}
function execCapture(args: string | string[], env?: Record<string, string>) {
    if(typeof args === 'string') args = args.split(' ');
    logFence('STARTING: ' + args.join(' '));
    const ret = execaSync(args[0], args.slice(1), {
        stdio: 'pipe',
        input: '',
        env: env ? {...process.env, ...env} : undefined
    });
    logFence('FINISHED: ' + args.join(' '));
    return assertSuccessExitCode(ret);
}
const npmArgs = [npmBinary, '--userconfig', `${__dirname}${dirSep}.npmrc`];
const npmEnvVars = {
    NPM_CONFIG_PREFIX: undefined
}
const pnpmArgs = [pnpmBinary];
const pnpmEnvVars = {
    NPM_CONFIG_PREFIX: undefined,
    NPM_CONFIG_USERCONFIG: `${__dirname}${dirSep}.npmrc`
};
async function retry(times: number, delayMs: number, block: () => void) {
    while(times) {
        try {
            block();
            break;
        } catch(e) {
            times--;
            if(times <= 0) {
                throw e;
            }
        }
        await delay(delayMs);
    }
}
// # Create a symlink.
function symlink(from: string, to: string) {
    const toAbs = resolve(dirname(from), to);
    if(existsSync(from) && lstatSync(from).isSymbolicLink && realpathSync(from) === toAbs) {
        console.log(`Symlink already exists: ${from} -> ${to}`);
        return
    }
    console.log(`Symlinking ${ from } --> ${ to }`);
    symlinkSync(to, from);
}

describe('pwsh', () => {
    let oldLocation: string;
    let oldPath: string;
    let preexistingPwsh: string;

    // cd to __dirname for duration of tests
    before(() => {
        oldLocation = process.cwd();
        process.chdir(__dirname);
    });
    after(() => {
        process.chdir(oldLocation);
    });

    beforeEach(() => {
        // <### SETUP ENVIRONMENT ###>

        // # Add node_modules/.bin to PATH; remove any paths containing pwsh
        oldPath = process.env[pathKey()];
        process.env[pathKey()] = [
            // # Local bin
            npmLocalInstallPath,
            // # Global bin in npm prefix
            npmGlobalInstallPath,
            // # Path to node & npm, pnpm, which, sh, etc
            dirname(npmBinary),
            dirname(pnpmBinary),
            // # Path to sh
            IsPosix && dirname(which('sh'))
        ].filter(v => v).join(pathSep);

        // <### CLEAN ###>
        if(existsSync('./node_modules')) {
            rimraf('./node_modules');
        }
        if(existsSync(npmPrefixRealpath)) {
            rimraf(npmPrefixRealpath);
        }

        mkdir(npmPrefixRealpath, {recursive: true});
        symlink(npmPrefixSymlink, npmPrefixRealpath);

        // # Set npm prefix
        writeFileSync('.npmrc', outdent `
            prefix = ${npmPrefix.replace('\\','\\\\')}
            pnpm-prefix = ${npmPrefix.replace('\\','\\\\')}
        `);

        preexistingPwsh = Try(() => which('pwsh'), () => null);
    });

    afterEach(() => {
        process.env[pathKey()] = oldPath;
    });

    let npmPrefix: string;
    describe('npm prefix is symlink', () => {
        npmPrefix = npmPrefixSymlink;
        tests();
    });

    describe('npm prefix is realpath', () => {
        npmPrefix = npmPrefixRealpath
        tests();
    });

    function tests() {
        it('npm prefix symlink exists', async () => {
            assert(lstatSync(npmPrefixSymlink).isSymbolicLink());
        });

        it('npm prefix set correctly for testing', async () => {
            assert.equal(execCapture([...npmArgs, 'config', 'get', 'prefix'], npmEnvVars).stdout, npmPrefix);
        });

        describe('local installation', () => {
            describe('via npm', () => {
                beforeEach(async () => {
                    exec([...npmArgs, 'install', tgzPath], npmEnvVars);
                })
                localInstallationTests();
                afterEach(async () => {
                    exec([...npmArgs, 'uninstall', tgzPath], npmEnvVars);
                    await deleteNodeModules();
                });
            });
            describe('via pnpm', () => {
                beforeEach(async () => {
                    exec([...pnpmArgs, 'install', tgzPath], pnpmEnvVars);
                });
                localInstallationTests();
                afterEach(async () => {
                    const installedDependencyNames = Object.keys(JSON.parse(readFileSync('./package.json', 'utf8')).dependencies);
                    assert.equal(installedDependencyNames.length, 1);
                    exec([...pnpmArgs, 'uninstall', installedDependencyNames[0]], pnpmEnvVars);
                    await deleteNodeModules();
                })
            })
            function localInstallationTests() {
                it('pwsh is in path and is correct version', async () => {
                    assert(which('pwsh').startsWith(npmLocalInstallPath));
                    
                    if(pwshVersion !== 'latest') {
                        assert.equal(execCapture('pwsh --version').stdout, `PowerShell v${ pwshVersion }`);
                    }
                });
            }
            async function deleteNodeModules() {
                console.log('deleting node_modules');
                await retry(4, 1, () => { rimraf('node_modules'); });
                console.log('deleted node_modules');
            }
        });
        describe('global installation', () => {
            beforeEach(async () => {
                exec([...npmArgs, 'install', '--global', tgzPath], npmEnvVars);
            })
            it('pwsh is in path and is correct version', async () => {
                const pwshPath = which('pwsh');
                assert(pwshPath.startsWith(npmGlobalInstallPath));
                assert.notEqual(pwshPath, preexistingPwsh);
                if(pwshVersion !==  'latest') {
                    assert.equal(execCapture('pwsh --version').stdout, `PowerShell v${pwshVersion}`);
                }
            });
            afterEach(async () => {
                exec([...npmArgs, 'uninstall', '--global', tgzPath], npmEnvVars);
            });
        });
    }
});
