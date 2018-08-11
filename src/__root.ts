// expose root directory of module installation at runtime
// Because using __dirname in webpack gets tricky
import * as Path from 'path';

export const __root = Path.resolve(__dirname, '..');
