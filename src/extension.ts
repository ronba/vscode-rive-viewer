import {dirname, isAbsolute, relative} from 'path';
import * as vscode from 'vscode';

export function activate(context: vscode.ExtensionContext) {
  context.subscriptions.push(RiveViewerEditorProvider.register(context));
}

const externalDirectoriesSetting = 'riveviewer.externalDirectories';

export function deactivate() {}

export class RiveViewerEditorProvider
  implements vscode.CustomEditorProvider<RiveDocument>
{
  constructor(private _context: vscode.ExtensionContext) {}

  private readonly _onDidChangeCustomDocument = new vscode.EventEmitter<
    vscode.CustomDocumentEditEvent<RiveDocument>
  >();
  public readonly onDidChangeCustomDocument =
    this._onDidChangeCustomDocument.event;
  saveCustomDocument(
    _document: RiveDocument,
    _cancellation: vscode.CancellationToken
  ): Thenable<void> {
    throw new Error('Method not implemented.');
  }
  saveCustomDocumentAs(
    _document: RiveDocument,
    _destination: vscode.Uri,
    _cancellation: vscode.CancellationToken
  ): Thenable<void> {
    throw new Error('Method not implemented.');
  }
  revertCustomDocument(
    _document: RiveDocument,
    _cancellation: vscode.CancellationToken
  ): Thenable<void> {
    throw new Error('Method not implemented.');
  }
  backupCustomDocument(
    _document: RiveDocument,
    _context: vscode.CustomDocumentBackupContext,
    _cancellation: vscode.CancellationToken
  ): Thenable<vscode.CustomDocumentBackup> {
    throw new Error('Method not implemented.');
  }
  openCustomDocument(
    uri: vscode.Uri,
    _openContext: vscode.CustomDocumentOpenContext,
    _token: vscode.CancellationToken
  ): RiveDocument | Thenable<RiveDocument> {
    return new RiveDocument(uri);
  }
  resolveCustomEditor(
    document: RiveDocument,
    webviewPanel: vscode.WebviewPanel,
    _token: vscode.CancellationToken
  ): void | Thenable<void> {
    const webview = webviewPanel.webview;

    const selectedAsset = document.uri.with({scheme: 'vscode-resource'});
    const userAdditionalDirectories = vscode.workspace
      .getConfiguration()
      .get(externalDirectoriesSetting) as string[];

    const userRoots = userAdditionalDirectories.map(directory =>
      vscode.Uri.file(directory)
    );

    const roots = [vscode.Uri.file(this._context.extensionPath)].concat(
      userRoots
    );
    const workspaceRoots = vscode.workspace.workspaceFolders;
    if (workspaceRoots && workspaceRoots.length > 0) {
      for (const root of workspaceRoots) {
        roots.push(root.uri);
      }
    }

    // Configure supported roots, add additional user directories.
    webview.options = {
      enableScripts: true,
      localResourceRoots: roots,
    };

    validateResource(webview.options.localResourceRoots!, document.uri);

    const flutterMain = webview.asWebviewUri(
      vscode.Uri.joinPath(
        this._context.extensionUri,
        'viewer',
        'build',
        'web',
        'main.dart.js'
      )
    );

    const root = webview.asWebviewUri(
      vscode.Uri.joinPath(this._context.extensionUri, 'viewer', 'build', 'web')
    );

    const manifest = webview.asWebviewUri(
      vscode.Uri.joinPath(
        this._context.extensionUri,
        'viewer',
        'build',
        'web',
        'manifest.json'
      )
    );

    const nonce = getNonce();

    const contentSecurityPolicy = [
      "default-src *  data: blob: filesystem: about: ws: wss: 'unsafe-inline' 'unsafe-eval'; ",
      "script-src 'nonce-${nonce}",
      "connect-src * data: blob: 'unsafe-inline'; ",
      "img-src * data: blob: 'unsafe-inline'; ",
      'frame-src * data: blob: ; ',
      "style-src * data: blob: 'unsafe-inline';",
      "font-src * data: blob: 'unsafe-inline';",
    ].join(' ');

    webview.html = `
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Security-Policy" content="${contentSecurityPolicy}">

  <base href="${root}">

  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="A new Flutter project.">

  <!-- iOS meta tags & icons -->
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="viewer">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">

  <title>viewer</title>
  <link rel="manifest" href="${manifest}">
</head>
<body>
  <div id="selectedAsset" file="${selectedAsset}"></div>
  <!-- This script installs service_worker.js to provide PWA functionality to
       application. For more information, see:
       https://developers.google.com/web/fundamentals/primers/service-workers -->
  <script nonce="${nonce}">
    var serviceWorkerVersion = null;
    var scriptLoaded = false;
    function loadMainDartJs() {
      if (scriptLoaded) {
        return;
      }
      scriptLoaded = true;
      var scriptTag = document.createElement('script');
      scriptTag.src = '${flutterMain}';
      scriptTag.type = 'application/javascript';
      document.body.append(scriptTag);
    }

    loadMainDartJs();
    
  </script>
</body>
</html>

    `;
  }

  private static readonly viewType = 'riveViewer.rivView';
  public static register(context: vscode.ExtensionContext): vscode.Disposable {
    return vscode.window.registerCustomEditorProvider(
      this.viewType,
      new RiveViewerEditorProvider(context),
      {
        supportsMultipleEditorsPerDocument: false,
      }
    );
  }
}

export class RiveDocument
  extends vscode.Disposable
  implements vscode.CustomDocument
{
  public get uri() {
    return this._uri;
  }
  private _uri: vscode.Uri;

  constructor(uri: vscode.Uri) {
    super(() => {});
    this._uri = uri;
  }
}

function getNonce() {
  let text = '';
  const possible =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  for (let i = 0; i < 32; i++) {
    text += possible.charAt(Math.floor(Math.random() * possible.length));
  }
  return text;
}
function validateResource(
  localResourceRoots: readonly vscode.Uri[],
  documentUri: vscode.Uri
) {
  console.log('Validating whether ' + documentUri.path + ' is allowed.');
  for (const root of localResourceRoots) {
    const relativePath = relative(root.path, documentUri.path);
    console.log(
      'Resolved relative path from ' + root.path + ': ' + relativePath
    );

    if (!relativePath.startsWith('..') && !isAbsolute(relativePath)) {
      return true;
    }
  }

  const parentDir = dirname(documentUri.fsPath);
  vscode.window.showErrorMessage(
    `To view "${documentUri.fsPath}" from the current workspace add "${parentDir}" (or a parent of that directory) to "${externalDirectoriesSetting}".`
  );
}
