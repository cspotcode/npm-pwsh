if(require('fs').existsSync(require('path').join(__dirname, 'dist'))) {
    require('./dist/npm_lifecycle_postinstall.js');
}
