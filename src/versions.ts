import { Version } from './version-utils';
import * as assert from 'assert';

export const latestVersionString = '6.0.0-rc.2';

// When a new version of powershell comes out, add the various downloads to this list.
export const versions: ReadonlyArray<Readonly<Version>> = [{
    version: '6.0.4',
    versionOutput: 'PowerShell v6.0.4',
    builds: [{
        arch: 'x64',
        extension: '.zip',
        platform: 'win32',
        url: 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.4/PowerShell-6.0.4-win-x64.zip',
        sha256: '0B04B63D2B63D4631CF5BD6E531F26B60F3CC1B1DB41C8B5360F14776E66F797',
        bin: 'pwsh.exe'
    }, {
        arch: 'x64',
        extension: '.tar.gz',
        platform: 'darwin',
        url: 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.4/powershell-6.0.4-osx-x64.tar.gz',
        sha256: '7CF6E229831A1F167D20646ACA2768D53D5EEA280727459171F03E497D154906',
        bin: 'pwsh'
    }, {
        arch: 'x64',
        extension: '.tar.gz',
        platform: 'linux',
        url: 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.4/powershell-6.0.4-linux-x64.tar.gz',
        sha256: 'BF085C3C8B6288C3FD64F0B0D757DCD54212FA3643DAA48CD77C67BD779EFCE2',
        bin: 'pwsh'
    }]
}, {
    version: '6.0.0-rc.2',
    versionOutput: 'PowerShell v6.0.0-rc.2',
    builds: [{
        arch: 'x64',
        platform: 'linux',
        extension: '.tar.gz',
        url: 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-rc.2/powershell-6.0.0-rc.2-linux-x64.tar.gz',
        sha256: 'D5E9389A1FBB275AC2EDD98A28A3D57AC174EE36B211BD34442653E830AE53BE'
    }, {
        arch: 'x64',
        platform: 'darwin',
        extension: '.tar.gz',
        url: 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-rc.2/powershell-6.0.0-rc.2-osx-x64.tar.gz',
        sha256: '1615D48FD665FBFD758F86A31CC078513736245F529A654B02353838EF06D505'
    }, {
        arch: 'arm',
        platform: 'linux',
        extension: '.tar.gz',
        url: 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-rc.2/powershell-6.0.0-rc.2-linux-arm32.tar.gz',
        sha256: '4A5D1012FF1FEF82B29A6BDBC14B40B5481D94D63CA71F889F0BDF1E18066BED'
    }, {
        arch: 'x64',
        platform: 'win32',
        extension: '.zip',
        url: 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-rc.2/PowerShell-6.0.0-rc.2-win-x64.zip',
        sha256: 'D225B274923E554E14E4B64EA63E470F44ACF11B050C8C12AFDFD7E54677C443'
    }, {
        arch: 'ia32',
        platform: 'win32',
        extension: '.zip',
        url: 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-rc.2/PowerShell-6.0.0-rc.2-win-x86.zip',
        sha256: 'D47FB1B7067FC720B9D44B17563FE2232CDC52F90F97B0E84DB1EB90A866AF19'
    }]
}];

export const latestVersion = versions.filter(v => v.version === latestVersionString)[0]!;

assert(latestVersion);
