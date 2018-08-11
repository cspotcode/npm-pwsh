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

    plugins: [
        new webpack.BannerPlugin({ banner: "#!/usr/bin/env node", raw: true })
    ],
    
    module: {
        rules: [{
            test: /\.js$/,
            use: [
                'source-map-loader',
                'shebang-loader'
            ]
        }]
    },
};

export = config;
