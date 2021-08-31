# Rive viewer for vscode

<a href="https://marketplace.visualstudio.com/items?itemName=ronba.vscode-rive-viewer">
    <img alt="VS Code Marketplace Downloads" src="https://img.shields.io/visual-studio-marketplace/v/ronba.vscode-rive-viewer"></a>

View [.riv](https://rive.app/) animations directly in vscode.

## Installation

- In vscode extensions look for `vscode-rive-viewer`.
- [vscode market place](https://marketplace.visualstudio.com/items?itemName=ronba.vscode-rive-viewer).
- In vscode, press (cmd+p/ctrl+p) and paste `ext install ronba.vscode-rive-viewer`

![screenshot](https://raw.githubusercontent.com/ronba/vscode-rive-viewer/main/screenshot.png)
This extension uses the rive [javascript runtime](https://github.com/rive-app/rive-wasm) to provides a webview of a riv animation file.

## Features

- Switch between artboards.
- Trigger animations.
- Trigger state machines.

## Requirements

N/A.

## Extension Settings

- `riveviewer.externalDirectories` - directories from which vscode is allowed to display .riv files.
  By default only riv files in the current workspace and from the extension directory can be displayed.

## Known Issues

Please report issues [here](https://github.com/ronba/vscode-rive-viewer).

## Release Notes

### 0.2.0

Add support for `riveviewer.externalDirectories`.

### 0.1.0

Update README with a screenshot.

### 0.0.1

Initial release.
