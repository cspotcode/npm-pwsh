#!/usr/bin/env ts-node-script

/*
 * This script queries Github's API for all PowerShell releases and parses them into the data structure which resides in
 * versions.ts
 */

import {sync as execSync} from 'execa';
import {Octokit} from '@octokit/core';
import { restEndpointMethods } from "@octokit/plugin-rest-endpoint-methods";
import { paginateRest } from "@octokit/plugin-paginate-rest";
import {groupBy} from 'lodash';
import {Version, Build, Extension, Arch} from '../src/version-utils';
import { inspect } from 'util';
import { outdent } from 'outdent';
import { compare as compareSemver } from 'semver';

const MyOctokit = Octokit.plugin(restEndpointMethods, paginateRest);

async function main() {
    const gitCreds = execSync('git', ['credential', 'fill'], {
        input: 'url=https://github.com',
        stdio: 'pipe'
    }).stdout;

    // Use `git credential fill` to grab a suitable access token.
    // If your local git client isn't setup this way, modify this script to hardcode an access token before running it.
    const gitAccessToken = gitCreds.split('\n').map(v => v.split('=')).find(v => v.length > 1 && v[0] === 'password')[1];

    const githubClient = new MyOctokit({
        auth: gitAccessToken
    });

    const {data: releases} = await githubClient.repos.listReleases({
        owner: 'PowerShell',
        repo: 'PowerShell',
        per_page: 100
    });

    type File = typeof allFiles[number];
    const allFiles = Array.from(parseAllFiles());

    function* parseAllFiles() {
        for(const release of releases) {
            // Skip alphas because I don't think anyone will want to install them, and older ones do not include SHAs and have inconsistent formatting.
            if(release.name.includes('alpha')) continue;
            // Skip ancient v0.6.0 releases
            if(release.name.startsWith('v0')) continue;
            // Skip old 6.0.0 beta because they released different versions for windows 10, 8, and 7, and we don't want to deal with that
            if(release.name.startsWith('v6.0.0-beta')) continue;
            const match = release.body.match(/(?:### )?SHA256 Hashes of (?:the )?[Rr]elease [Aa]rtifacts:?\r?\n(?:\r?\n> .*?\r?\n)?([\s\S]+)/);
            if(!match) {
                console.dir(release.body);
                throw new Error(`Failed to parse ${ release.name }`);
            }
            const a = match[1];
            // const match3 = a.match(/^\r\n>.*\r\n/);
            // console.dir(match3);
            // if(match3) a = a.slice(match3[0].length);
            for(const file of a.trim().split(/\n(?=- )/)) {
                const match = file.match(/- (.*)\r\n +- (.*)\r?/);
                if(!match) {
                    throw new Error(`Failed to parse ${file}`);
                }
                const [, filename, sha256] = match;
                // Ignore irrelevant file extensions.
                if(filename.match(/\.(deb|rpm|AppImage|pkg|msi|msix|wixpdb)$/)) continue;
                // further parse the filename
                const match2 = filename.match(/[Pp]ower[Ss]hell-(.*?)-(win.*|osx|linux-alpine|linux-musl|linux)-(.*?)(\..*)/);
                if(!match2) {
                    console.error('Skipping1:', filename);
                    continue;
                }
                const [, version, platform, arch, extension] = match2;
                const url = `https://github.com/PowerShell/PowerShell/releases/download/v${ version }/${ filename }`;
                if(!['.tar.gz', '.zip'].includes(extension) || !['win', 'osx', 'linux'].includes(platform) || ['x64-fxdependent', 'fxdependent', 'fxdependentWinDesktop'].includes(arch)) {
                    console.error('Skipping2:', version, platform, arch, extension);
                    continue;
                }
                const bin = platform.startsWith('win') ? 'pwsh.exe' : 'pwsh';
                yield {
                    version,
                    platform,
                    arch,
                    extension,
                    sha256,
                    url,
                    bin
                };
            }
        }
    }

    const grouped = groupBy(allFiles, 'version') as Record<string, File[]>;
    // if has preview or rc in the name, then is a prerelease
    const versions: Version[] = Object.entries(grouped).map(([version, files]) => {
        return {
            version,
            versionOutput: `PowerShell ${version}`,
            isPrerelease: version.includes('rc') || version.includes('preview'),
            builds: files.map((file): Build => {
                let arch = file.arch;
                if(arch === 'arm32') arch = 'arm';
                if(arch === 'x86') arch = 'ia32';
                let platform = file.platform;
                if(platform=== 'osx') platform = 'darwin';
                if(platform=== 'win') platform = 'win32';
                return {
                    platform: platform as NodeJS.Platform,
                    arch: arch as Arch,
                    extension: file.extension as Extension,
                    sha256: file.sha256,
                    url: file.url,
                    bin: file.bin,
                };
            })
        };
    });

    function sortVersionsDescending(a: Version, b: Version) {
        const fix = (s: string) => s.replace(/^lts-/, '');
        return compareSemver(fix(b.version), fix(a.version));
    }
    versions.sort(sortVersionsDescending);

    // console.log(JSON.stringify(versions, null, 2));
    console.log(outdent `
        // Auto-generated by ./scripts/parse-versions.ts
        import { Version } from './version-utils';

        // When a new version of powershell comes out, add the various downloads to this list.
        export const versions: ReadonlyArray<Readonly<Version>> = ${
            inspect(versions, {maxArrayLength: null, depth: null}).replace(/\n +/g, ($0) => `${$0}${$0.slice(1)}`)
        }
    `);
    // console.log(Object.keys(grouped));
}

main();
