module.exports = {
  entry: "./app/assets/javascripts/app.js",
  output: {
    path: __dirname + "/app/assets/javascripts/",
    filename: "bundle.js"
  },
  module: {
    loaders: [
      {test: /\.js$/, exclude: /node_modules/, loader: "babel-loader"}
    ]
  }
};
