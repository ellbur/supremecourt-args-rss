module.exports = {
  mode: 'production',
  entry: './src/Index.bs',
  output: {
    path: __dirname,
    filename: 'index.js'
  },
  externals: {
    '@google-cloud/functions-framework': 'commonjs2 @google-cloud/functions-framework',
  },
}
