module.exports = {
  entry: './app/assets/javascripts/app.js',
  output: {
    path: __dirname + '/app/assets/javascripts/',
    filename: 'bundle.js'
  },
  module: {
    loaders: [
      // runs all javascript through babel for ES6 support
      {test: /\.js$/, exclude: /node_modules/, loader: 'babel-loader'},

      // exposes $ and jQuery on the window object for compatability with jQuery plugins
      {test: /jquery/, loader: 'expose?$!expose?jQuery'}
    ]
  }
};
