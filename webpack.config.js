//@ts-check

"use strict";

const path = require("path");

/**@type {import('webpack').Configuration}*/
const extension = {
  target: "node", // vscode extensions run in a Node.js-context 📖 -> https://webpack.js.org/configuration/node/
  mode: "none", // this leaves the source code as close as possible to the original (when packaging we set this to 'production')

  entry: "./src/extension.ts", // the entry point of this extension, 📖 -> https://webpack.js.org/configuration/entry-context/
  output: {
    // the bundle is stored in the 'dist' folder (check package.json), 📖 -> https://webpack.js.org/configuration/output/
    path: path.resolve(__dirname, "dist"),
    filename: "extension.js",
    libraryTarget: "commonjs2",
  },
  devtool: "nosources-source-map",
  externals: {
    vscode: "commonjs vscode", // the vscode-module is created on-the-fly and must be excluded. Add other modules that cannot be webpack'ed, 📖 -> https://webpack.js.org/configuration/externals/
    // modules added here also need to be added in the .vsceignore file
  },
  resolve: {
    extensions: [".ts", ".js"],
  },
  module: {
    rules: [
      {
        test: /\.ts$/,
        exclude: [
          path.resolve(__dirname, "node_modules/"),
          path.resolve(__dirname, "src", "viewer"),
        ],
        use: [
          {
            loader: "ts-loader",
          },
        ],
      },
    ],
  },
};

/**@type {import('webpack').Configuration}*/
const frontend = {
  entry: "./src/viewer/rive.ts",
  target: "web",
  mode: "none",
  output: {
    path: path.resolve(__dirname, "dist", "viewer"),
    filename: "rive.js",
  },
  resolve: {
    extensions: [".ts", ".js"],
  },
  module: {
    rules: [
      {
        test: /\.ts$/,
        exclude: /node_modules/,
        use: [
          {
            loader: "ts-loader",
            options: {
              configFile: path.resolve(__dirname, "src/viewer/tsconfig.json"),
            },
          },
        ],
      },
    ],
  },
};

module.exports = [extension, frontend];
