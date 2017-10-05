import * as fs from 'fs';
import * as crypto from 'crypto';
import * as getStream from 'get-stream';
import * as request from 'request';

/** return the sha256 of a file as a hex-formatted string */
export async function sha256OfFile(path: string): Promise<string> {
    const input = fs.createReadStream(path);
    const cipher = crypto.createHash('sha256');
    return await getStream(input.pipe(cipher), {encoding: 'hex'});
}

/** download a URL and save it to a file */
export async function downloadUrlToFile(url: string, path: string): Promise<void> {
    const fileStream = fs.createWriteStream(path);
    await new Promise((res, rej) => {
        request(url).pipe(fileStream).on('close', () => {
            res();
        });
    });
}

export function readFileWithDefault(path: string, defaultContent: string): string {
    try {
        return fs.readFileSync(path, 'utf8');
    } catch(e) {
        if(!fs.existsSync(path)) return defaultContent;
        throw e;
    }
}
export function readJsonFileWithDefault(path: string, defaultContent: any): any {
    try {
        return JSON.parse(fs.readFileSync(path, 'utf8'));
    } catch(e) {
        if(!fs.existsSync(path)) return defaultContent;
        throw e;
    }
}
export function writeJsonFile(path: string, value: any, indent: boolean | string = true) {
    if(indent === true) indent = '    ';
    fs.writeFileSync(path, JSON.stringify(value, null, indent as string));
}

interface PatchJsonFileOpts { defaultValue: any; indent: string | boolean; }
/**
 * Read JSON from a file, process it with a callback, then write the result back to the file
 * @param callback Returns new value to be stringified.  If it returns undefined, original value is used, which is useful if you modified the original in-place.
 */
export function patchJsonFile(path: string, opts: PatchJsonFileOpts, callback: (v: any) => any);
export function patchJsonFile(path: string, callback: (v: any) => any);
export function patchJsonFile(path: string, _a: any, _b?: any) {
    let [opts = {}, callback] = [_a, _b];
    if(!callback) [opts, callback] = [{}, _a];
    const {defaultValue = null, indent = false} = opts;
    const value = readJsonFileWithDefault(path, defaultValue);
    let newValue = callback(value);
    if(newValue === undefined) newValue = value;
    writeJsonFile(path, newValue, indent);
}
