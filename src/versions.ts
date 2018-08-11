import { Version } from './version-utils';
import * as assert from 'assert';

// When a new version of powershell comes out, add the various downloads to this list.
export const versions: Array<Version> = [{
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
        arch: 'ia32',
        extension: '.zip',
        platform: 'win32',
        url: 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.4/PowerShell-6.0.4-win-x86.zip',
        sha256: '787FBECBA57CD385428DBF4F4A0B7E16F92EECEE3E6ADAE65D1AB04CA8CF41DD',
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
    version: '6.0.3',
    versionOutput: 'PowerShell v6.0.3',
    builds: [
        [
            {
                "platform":  "linux",
                "arch":  "x64",
                "extension":  ".tar.gz",
                "sha256":  "A43D3056688FABC442BFBE0FD7A096F7E28036759EFF9D6EBE8CB9155C9D9AAB",
                "url":  "https://github.com/PowerShell/PowerShell/releases/download/v6.0.3/powershell-6.0.3-linux-x64.tar.gz",
                bin: 'pwsh'
            },
            {
                "platform":  "darwin",
                "arch":  "x64",
                "extension":  ".tar.gz",
                "sha256":  "9161416723031CA9C5422A707376660EF2F5D6D64D3B8A94B107EB1AABF3D2F0",
                "url":  "https://github.com/PowerShell/PowerShell/releases/download/v6.0.3/powershell-6.0.3-osx-x64.tar.gz",
                bin: 'pwsh'
            },
            {
                "platform":  "win32",
                "arch":  "x64",
                "extension":  ".zip",
                "sha256":  "DFFBB84E3E474E00100F6E51F36F7CC1146C70E68CAB72F94AA91AB35CB24AC7",
                "url":  "https://github.com/PowerShell/PowerShell/releases/download/v6.0.3/PowerShell-6.0.3-win-x64.zip",
                bin: 'pwsh.exe'
            },
            {
                "platform":  "win32",
                "arch":  "ia32",
                "extension":  ".zip",
                "sha256":  "51A3FB4AF86C72E300B3C9AAD93BE1665CE67E1077CF109B72CC57F4F8AC539C",
                "url":  "https://github.com/PowerShell/PowerShell/releases/download/v6.0.3/PowerShell-6.0.3-win-x86.zip",
                bin: 'pwsh.exe'
            }
        ]
    ]
}, {
    version: '6.0.2',
    versionOutput: 'PowerShell v6.0.2',
    builds: [
        {
            "platform":  "linux",
            "arch":  "x64",
            "extension":  ".tar.gz",
            "sha256":  "092F628A7F1672C8FB46EC0D7EC90590B8CD372188DE3243E2E18660C9EC6F29",
            "url":  "https://github.com/PowerShell/PowerShell/releases/download/v6.0.2/powershell-6.0.2-linux-x64.tar.gz",
            bin: 'pwsh'
        },
        {
            "platform":  "darwin",
            "arch":  "x64",
            "extension":  ".tar.gz",
            "sha256":  "F2311BDA90CA02251D9AD930BE2167B6B906B3EA6B62EF323CA79FA4B5AA3B31",
            "url":  "https://github.com/PowerShell/PowerShell/releases/download/v6.0.2/powershell-6.0.2-osx-x64.tar.gz",
            bin: 'pwsh'
        },
        {
            "platform":  "win32",
            "arch":  "x64",
            "extension":  ".zip",
            "sha256":  "8CB153E540ED9D9A7FE00CB3D1FE94A0ED089B574FD02E816AB2BB066F4C4F89",
            "url":  "https://github.com/PowerShell/PowerShell/releases/download/v6.0.2/PowerShell-6.0.2-win-x64.zip",
            bin: 'pwsh.exe'
        },
        {
            "platform":  "win32",
            "arch":  "ia32",
            "extension":  ".zip",
            "sha256":  "87048B0A2DBD56AA8FE1F92DDB7D7BBF8E904F8D54EE2A62443C7B31AE9E55F8",
            "url":  "https://github.com/PowerShell/PowerShell/releases/download/v6.0.2/PowerShell-6.0.2-win-x86.zip",
            bin: 'pwsh.exe'
        }
    ]
}, {
    version: '6.0.0-rc.2',
    versionOutput: 'PowerShell v6.0.0-rc.2',
    builds: [{
        arch: 'x64',
        platform: 'linux',
        extension: '.tar.gz',
        url: 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-rc.2/powershell-6.0.0-rc.2-linux-x64.tar.gz',
        sha256: 'D5E9389A1FBB275AC2EDD98A28A3D57AC174EE36B211BD34442653E830AE53BE',
        bin: 'pwsh'
    }, {
        arch: 'x64',
        platform: 'darwin',
        extension: '.tar.gz',
        url: 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-rc.2/powershell-6.0.0-rc.2-osx-x64.tar.gz',
        sha256: '1615D48FD665FBFD758F86A31CC078513736245F529A654B02353838EF06D505',
        bin: 'pwsh'
    }, {
        arch: 'arm',
        platform: 'linux',
        extension: '.tar.gz',
        url: 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-rc.2/powershell-6.0.0-rc.2-linux-arm32.tar.gz',
        sha256: '4A5D1012FF1FEF82B29A6BDBC14B40B5481D94D63CA71F889F0BDF1E18066BED',
        bin: 'pwsh'
    }, {
        arch: 'x64',
        platform: 'win32',
        extension: '.zip',
        url: 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-rc.2/PowerShell-6.0.0-rc.2-win-x64.zip',
        sha256: 'D225B274923E554E14E4B64EA63E470F44ACF11B050C8C12AFDFD7E54677C443',
        bin: 'pwsh.exe'
    }, {
        arch: 'ia32',
        platform: 'win32',
        extension: '.zip',
        url: 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-rc.2/PowerShell-6.0.0-rc.2-win-x86.zip',
        sha256: 'D47FB1B7067FC720B9D44B17563FE2232CDC52F90F97B0E84DB1EB90A866AF19',
        bin: 'pwsh.exe'
    }]
}];

export const latestVersion = versions.filter(v => v.version === latestVersionString)[0]!;

assert(latestVersion);
