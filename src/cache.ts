import * as Path from 'path';
import * as os from 'os';
import { readJsonFileWithDefault, writeJsonFile, isGlobalInstall, getNpmGlobalNodeModules } from './util';

export interface CacheManifest {
    [name: string]: CacheManifestEntry;
}

export interface CacheManifestEntry {
    relativePathToBin: string;
}

/**
 * @param machine Reserved for future use, in case behavior differs based on OS or other environment attributes.
 * @returns absolute path to a global shared cache directory into which we can download and extract powershell versions.
 */
export function getCacheInstallDirectory(machine: Pick<NodeJS.Process, 'platform'> = process): string {
    if(isGlobalInstall) {
        return Path.join(getNpmGlobalNodeModules(), '@cspotcode/pwsh-cache');
        // TODO should cache in NPM_PREFIX for --global installations
    } else {
        return Path.join(os.homedir(), '.npm-pwsh');
    }
}

export function getCacheManifestPath() {
    return Path.join(getCacheInstallDirectory(), 'cache-manifest.json');
}

export function readCacheManifest() {
    const manifest: CacheManifest = readJsonFileWithDefault(getCacheManifestPath(), {});
    return manifest;
}

export function writeCacheManifest(manifest: CacheManifest) {
    writeJsonFile(getCacheManifestPath(), manifest, true);
}
