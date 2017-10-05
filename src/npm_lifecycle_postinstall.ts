#!/usr/bin/env node

import * as Path from 'path';
import {sync as mkdirpSync} from 'mkdirp';
import * as fs from 'fs';
import {spawnSync} from 'child_process';
import * as assert from 'assert';
import {
  appImageUrl,
  appImageSha256,
  filesInAppImage,
  nameAndVersion
} from "./constants";
import {
  sha256OfFile,
  downloadUrlToFile,
  readJsonFileWithDefault,
  patchJsonFile
} from "./util";

const log = console.log.bind(console);

async function main() {
    // Skip Windows entirely; it already has PowerShell.
    if(process.platform === 'win32') {
        console.log('Windows comes with Powershell preinstalled; no action required.');
        process.exit(0);
    }

    // Find powershell on the PATH; maybe it's already installed.
    /** PATH to the powershell executable that this module places into node_modules/.bin */
    const ownBinPath = Path.normalize(Path.resolve(Path.join(require.resolve('../package.json'), '../../.bin/powershell')));
    let foundPath: string;
    found: {
        for(foundPath of process.env.PATH.split(':').map(v => Path.join(v, 'powershell'))) {
            // Skip the powershell command that this package puts on the path; that's not the one we want
            if(Path.normalize(foundPath) === ownBinPath) continue;
            try {
                // Does it exist?
                const stat = fs.statSync(foundPath);
                // Is it executable?  (TODO properly check if current user has execute permission)
                const executeBits = stat.mode & 0o111;
                if(executeBits) break found;
            } catch(e) {}
        }
        // did not find it
        foundPath = null;
    }
    if(foundPath) {
        log('Found powershell on PATH; no action required.');
        // process.exit(0);
    }

    // TODO add support for Mac
    if(process.platform === 'darwin') {
        log('macos is not yet supported.');
        process.exit(1);
    }

    /**
     * Path to a "fake" globally installed NPM module where we actually store cached PowerShell installations.
     * 
     * The goal is to cache the downloaded PowerShell archive in a shared location without forcing the user to install this module globally.
     */
    const cacheInstallationDirectory = Path.resolve(Path.join(process.env.npm_config_prefix, 'node_modules/@cspotcode/get-powershell--cache'));
    mkdirpSync(cacheInstallationDirectory, {mode: 0o700});

    /** Path to powershell executable (actually a bash script that sets environment variables and then invokes powershell, but that's just an AppImage detail) */
    let symlinkTarget;

    // Check if our expected Powershell version is already downloaded and installed in the cache.
    const cacheManifestPath = Path.join(cacheInstallationDirectory, 'cache-manifest.json');
    const manifest = readJsonFileWithDefault(cacheManifestPath, {});
    if(manifest[nameAndVersion]) {
        symlinkTarget = manifest[nameAndVersion];
        try {
            assert(fs.statSync(symlinkTarget).mode & 0o100);
        } catch(e) {
            symlinkTarget = undefined;
        }
    }

    /** Download the AppImage file to this path on disc */
    const appImageDownloadPath = Path.join(cacheInstallationDirectory, `${ nameAndVersion }.AppImage`);
    /** Extract squashfs-root as a child of this directory */
    const extractionTargetPath = Path.join(cacheInstallationDirectory, `${ nameAndVersion }`);

    // If cached powershell installation not found, we must download and install
    if(!symlinkTarget) {

        // If AppImage already exists and is the same version
        if(fs.existsSync(appImageDownloadPath) && await sha256OfFile(appImageDownloadPath) === appImageSha256) {
            log(`Found AppImage on disk; skipping download. (${ appImageDownloadPath })`);
        } else {
            // Download the AppImage archive
            log(`Downloading Powershell AppImage from ${ appImageUrl } to ${ appImageDownloadPath }...`);
            await downloadUrlToFile(appImageUrl, appImageDownloadPath);
            log('Download finished.');
            assert(await sha256OfFile(appImageDownloadPath) === appImageSha256, 'SHA256 verification failed; download appears corrupt.');
        }

        // Extract the entire AppImage.  Not all systems support FUSE; extracting the AppImage eliminates that requirement.
        log(`Extracting AppImage to ${ extractionTargetPath }...`);
        await extractAppImage();
        log(`Extracted to ${ extractionTargetPath }`);

        // Create an alternative entry-point that bypasses the `.wrapper` script
        log(`Creating entry-point that bypasses AppImage's .wrapper script.`);
        const entryPointPath = Path.join(extractionTargetPath, 'squashfs-root/AppRun');
        const alternativeEntryPointPath = Path.join(extractionTargetPath, 'squashfs-root/AppRun-skip-wrapper');
        fs.writeFileSync(
            alternativeEntryPointPath,
            fs.readFileSync(entryPointPath, 'utf8').replace('.wrapper', '')
        );
        fs.chmodSync(alternativeEntryPointPath, 0o700);

        symlinkTarget = alternativeEntryPointPath;

        // Store the desired symlink target into our cache manifest
        patchJsonFile(cacheManifestPath, {
            indent: true, defaultValue: {}
        }, (json) => {
            json[nameAndVersion] = symlinkTarget;
        });
    }

    log(`Symlinking from node_modules/.bin/powershell to ${ symlinkTarget }...`);
    mkdirpSync(Path.dirname(ownBinPath), {mode: 0o700});
    fs.symlinkSync(symlinkTarget, ownBinPath);

    log(`Done!`);

    return;

    async function extractAppImage() {
        mkdirpSync(extractionTargetPath, {mode: 0o700});
        // Set the execute bit
        fs.chmodSync(appImageDownloadPath, fs.statSync(appImageDownloadPath).mode | 0o100);

        /*
         * Unfortunately, at the time of writing, the PowerShell AppImage is using an older version of AppImage and can't fully extract itself.
         * However, the only thing it fails to extract is a directory, so we can do that ourselves.
         * 
         * We must manually extract each file, one at a time, and when we detect the specific failure noted above, we create the directory manually.
         */
        const filesToExtract = filesInAppImage;
        filesToExtract.forEach((fileToExtract, i) => {
            log(`Extracting ${ fileToExtract } (${ Math.round(i / filesToExtract.length * 100) }%)...`);
            const spawnResult = spawnSync(appImageDownloadPath, ['--appimage-extract', fileToExtract], {
                cwd: extractionTargetPath,
                encoding: 'utf8'
            });
            const {stdout, stderr} = spawnResult;
            if(spawnResult.status) {
                throw new Error('AppImage failed to extract:\n' + stderr);
            }
            // catch the expected inode_type 8 failures
            const expected = 'TODO: Implement inode.base.inode_type 8';
            if(spawnResult.stderr.indexOf(expected) > -1) {
                const dir = Path.join(extractionTargetPath, 'squashfs-root', fileToExtract);
                log(`Manually creating directory: ${ dir }`);
                mkdirpSync(dir, {mode: 0o700});
            }
        });
    }
}

main().catch(err => {
    console.error(err);
    process.exit(1);
});


// First download and extract the appimage tool
// https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
// Use it to list all files in the powershell appimage
//  * invoke with -l <path to powershell appimage>
//  * discard lines beginning with WARNING:
// manually extract powershell appimage files one at a time
//  * while looping, if the file thrown an error about inode 8, instead mkdir -p and manually set 700 permissions

