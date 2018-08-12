import * as Path from 'path';
import * as webpack from 'webpack';

const config: webpack.Configuration = {
    context: __dirname,
    entry: './out/npm_lifecycle_postinstall',
    output: {
        path: __dirname + '/dist',
        filename: 'npm_lifecycle_postinstall.js'
    },
    target: 'node',
    mode: 'production',
    optimization: {
        minimize: false
    },
    devtool: 'source-map',

    externals: [
        function(context, request, callback) {
            const localExternals = [
                './out/buildTags.json',
                './out/__root'
            ];
            for(const localExternal of localExternals) {
                if(request[0] === '.' && Path.resolve(context, request) === Path.resolve(__dirname, localExternal)) {
                    return callback(null, 'commonjs ' + request);
                }
            }
            callback(null, undefined);
        },
        {tar: 'commonjs tar'}
    ],

    module: {
        rules: [{
            test: /\.js$/,
            use: ['source-map-loader']
        }]
    },
};

export = config;
