import * as vscode from 'vscode';

export function activate(context: vscode.ExtensionContext) {
  context.subscriptions.push(RiveViewerEditorProvider.register(context));
}

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
    webview.options = {enableScripts: true};
    const selectedAsset = webview.asWebviewUri(document.uri);
    const riveScript = webview.asWebviewUri(
      vscode.Uri.joinPath(this._context.extensionUri, 'assets', 'rive.min.js')
    );

    const styleSheet = webview.asWebviewUri(
      vscode.Uri.joinPath(
        this._context.extensionUri,
        'assets',
        'viewer',
        'style.css'
      )
    );

    const riveViewer = webview.asWebviewUri(
      vscode.Uri.joinPath(
        this._context.extensionUri,
        'dist',
        'viewer',
        'rive.js'
      )
    );
    webview.html = /* html */ `
<link rel="stylesheet" href="${styleSheet}">
<div id="viewer">
	<canvas id="canvas" width="400" height="300"></canvas>
  <div id="contents">
		<h2 id="currentArtboard"></h2>
    <div id="artboards">
		  <label>Artboards</label>
		</div>
    
		<div id=animations class="section">
			<h3>Animations</h3>
			<div id="animationsDetails"></div>
		</div>
		
		<div id=stateMachines class="section">
			<h3>State Machines</h3>
    	<div id="stateMachinesDetails"></div>
		</div>
  </div>
</div>
<script src="${riveScript}"></script>
<script src="${riveViewer}" file="${selectedAsset}"></script>
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
