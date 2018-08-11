import * as Path from 'path';
import {sync as mkdirpSync} from 'mkdirp';
import * as fs from 'fs';
import * as assert from 'assert';
import {
  sha256OfFile,
  downloadUrlToFile,
  readJsonFileWithDefault,
  patchJsonFile,
  getNpmBinDirectory,
  getNpmBinShimPath,
  TODO,
  pathsEquivalent,
  createSymlinkTo,
  extractArchive,
  buildTags
} from "./util";
import * as which from 'which';
import { getBestBuild, getFilenameForBuild, getDirnameForBuild } from './version-utils';
import { getCacheInstallDirectory, readCacheManifest, getCacheManifestPath } from './cache';

const log = console.log.bind(console);

const isGlobalInstall = !!process.env.npm_config_global;

async function main() {
    // Find powershell on the PATH; maybe it's already installed.
    /** PATH to the powershell stub that this module installs via npm's "bin" capabilities */
    const ownBinPath = getNpmBinShimPath('pwsh');
    let foundPath: string | null;
    // Type assertion required until https://github.com/DefinitelyTyped/DefinitelyTyped/pull/22437 is merged
    for(foundPath of which.sync('pwsh', {nothrow: true, all: true}) || []) {
        // Skip the powershell command that this package puts on the path; that's not the one we want
        if(pathsEquivalent(foundPath, ownBinPath)) continue; // TODO if foundPath is a *symlink* to ownBinPath
        // TODO verify that it's the desired version of pwsh
        // TODO this is being totally ignored right now!!
    }
    // did not find it
    foundPath = null;
    if(foundPath) {
        log('Found pwsh on PATH; no action required.');
        createSymlinkTo(ownBinPath, foundPath, log);
        process.exit(0);
    }

    /**
     * Path to a shared directory where we store cached PowerShell installations.
     * 
     * The goal is to cache the downloaded PowerShell archive in a shared location without forcing the user to install this module globally
     * or re-downloading powershell for every `npm install` of this package.
     */
    const cacheInstallationDirectory = getCacheInstallDirectory();

    mkdirpSync(cacheInstallationDirectory, {mode: 0o700});

    /** Path to powershell executable */
    let symlinkTarget: string;

    const {version, build} = getBestBuild(buildTags.pwshVersion);
    const cacheDirnameForBuild = getDirnameForBuild({version, build});

    // Check if our expected Powershell version is already downloaded and installed in the cache.
    const manifest = readCacheManifest();
    if(manifest[cacheDirnameForBuild]) {
        symlinkTarget = Path.resolve(cacheInstallationDirectory, cacheDirnameForBuild, manifest[cacheDirnameForBuild].relativePathToBin);
        try {
            // Assert that path both exists and is executable
            assert(fs.statSync(symlinkTarget).mode & 0o100);
        } catch(e) {
            symlinkTarget = undefined;
        }
    }

    /** Download the .tar.gz / .zip file to this path on disc */
    const archiveDownloadPath = Path.join(cacheInstallationDirectory, getFilenameForBuild({version, build}));
    /** Extract .tar.gz / .zip into this directory */
    const extractionTargetPath = Path.join(cacheInstallationDirectory, cacheDirnameForBuild);

    // If cached powershell installation not found, we must download and install
    if(!symlinkTarget) {

        // If downloaded archive already exists and is the same version
        if(fs.existsSync(archiveDownloadPath) && await sha256OfFile(archiveDownloadPath) === build.sha256) {
            log(`Found archive on disk; skipping download. (${ archiveDownloadPath })`);
        } else {
            // Download the archive
            log(`Downloading Powershell archive from ${ build.url } to ${ archiveDownloadPath }...`);
            await downloadUrlToFile(build.url, archiveDownloadPath);
            log('Download finished.');
            const sha256 = await sha256OfFile(archiveDownloadPath);
            assert(await sha256 === build.sha256, `SHA256 verification failed; download appears corrupt.  Expected ${ build.sha256 }, got ${ sha256 }`);
        }

        // Extract the archive.
        log(`Extracting archive to ${ extractionTargetPath }...`);
        mkdirpSync(extractionTargetPath);
        await extractArchive(build.extension, archiveDownloadPath, extractionTargetPath);
        log(`Extracted to ${ extractionTargetPath }`);

        symlinkTarget = Path.resolve(extractionTargetPath, build.bin);

        // Store the desired symlink target into our cache manifest
        patchJsonFile(getCacheManifestPath(), {
            indent: true, defaultValue: {}
        }, (json) => {
            json[cacheDirnameForBuild] = {relativePathToBin: build.bin};
        });
    }

    // Replace our stub with a symlink to the real powershell installation
    await createSymlinkTo(ownBinPath, symlinkTarget, log);

    log(`Done!`);
}

main().catch(err => {
    console.error(err);
    process.exit(1);
});
