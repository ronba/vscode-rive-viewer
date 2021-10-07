import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive/rive.dart';
import 'package:viewer/artboard_view.dart';

void main() {
  final asset =
      document.querySelector('#selectedAsset')?.attributes['file'].toString();

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      // Using a builder is required.
      // Using the home property will create a navigator which will fail inside
      // a vscode extension webview when it tries to change the page history.
      builder: (context, child) => Scaffold(
        body: RivePageViewer(assetPath: asset!),
      ),
    ),
  );
}

class RivePageViewer extends StatefulWidget {
  final String assetPath;
  const RivePageViewer({Key? key, required this.assetPath}) : super(key: key);

  @override
  State<RivePageViewer> createState() => _RivePageViewerState();
}

class _RivePageViewerState extends State<RivePageViewer> {
  RiveFile? _riveFile;
  Widget? selectedArtboard;

  @override
  Widget build(BuildContext context) {
    if (_riveFile == null) return Container();

    final riveFile = _riveFile!;
    final height = MediaQuery.of(context).size.height / 2;
    if (riveFile.artboards.length == 1) {
      return ArtboardView(artboard: riveFile.mainArtboard);
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: selectedArtboard == null
          ? ListView.builder(
              itemCount: riveFile.artboards.length,
              itemBuilder: (context, index) {
                final artboard = riveFile.artboards[index];
                final view = ArtboardView(artboard: artboard);
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white12),
                      ),
                      height: height,
                      width: MediaQuery.of(context).size.width,
                      child: view,
                    ),
                    Positioned(
                      right: 30,
                      bottom: 10,
                      child: TextButton(
                        child: const Text('FULLSCREEN'),
                        onPressed: () {
                          setState(() {
                            selectedArtboard = view;
                          });
                        },
                      ),
                    )
                  ],
                );
              },
            )
          : Stack(
              children: [
                selectedArtboard!,
                Positioned(
                  right: 30,
                  bottom: 10,
                  child: TextButton(
                    child: const Text('EXIT FULLSCREEN'),
                    onPressed: () {
                      setState(() {
                        selectedArtboard = null;
                      });
                    },
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void initState() {
    RiveFile.network(widget.assetPath).then((riveFile) {
      setState(() {
        _riveFile = riveFile;
      });
    });

    super.initState();
  }
}
