import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

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
        body: RiveViewer(
          riveAsset: asset ?? 'https://cdn.rive.app/animations/skills_v7.riv',
        ),
      ),
    ),
  );
}

class RiveViewer extends StatefulWidget {
  final String riveAsset;
  const RiveViewer({Key? key, required this.riveAsset}) : super(key: key);

  @override
  _RiveViewerState createState() => _RiveViewerState();
}

class _RiveViewerState extends State<RiveViewer> {
  RiveFile? _riveFile;
  Artboard? _artboard;
  Map<String, RiveAnimationController> _animationControllers = {};
  Map<StateMachine, StateMachineController> _stateMachineControllers = {};
  BoxFit _fit = BoxFit.contain;

  @override
  Widget build(BuildContext context) {
    if (_riveFile == null) {
      return Container();
    }
    final riveFile = this._riveFile!;
    final artboard = this._artboard!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Stack(
            children: [
              Center(
                child: Rive(
                  artboard: _artboard ?? riveFile.mainArtboard,
                  fit: _fit,
                ),
              ),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                childAspectRatio: 4,
                children: [
                  ...BoxFit.values.map((fit) {
                    final fitName = fit.toString().splitMapJoin(
                        RegExp('(BoxFit\.)([a-z]+)'),
                        onMatch: (m) => "${m[2]!} ",
                        onNonMatch: (m) => m.toLowerCase());

                    return TextButton(
                      child: Text(fitName),
                      style: ButtonStyle(
                          shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero)),
                          backgroundColor: MaterialStateProperty.all(
                              Colors.black.withOpacity(0.8))),
                      onPressed: () {
                        setState(() {
                          _fit = fit;
                        });
                      },
                    );
                  }).toList()
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: ListView(
            children: [
              GridView.count(
                shrinkWrap: true,
                childAspectRatio: 3,
                crossAxisCount: 4,
                children: [
                  ...riveFile.artboards.map((artboard) {
                    return TextButton(
                      child: Text(
                          "${artboard.name}${artboard == _artboard! ? ' (current)' : ''}"),
                      onPressed: () {
                        setState(() {
                          if (artboard.name != _artboard) {
                            _changeArtboard(artboard);
                          }
                        });
                      },
                    );
                  }).toList()
                ],
              ),
              if (artboard.stateMachines.length > 0)
                Text(
                  'State Machines',
                  style: Theme.of(context).textTheme.headline5,
                ),
              Container(
                padding: EdgeInsets.only(left: 10),
                child: Column(
                    children: artboard.stateMachines.map((stateMachine) {
                  final controller = _stateMachineControllers[stateMachine]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      SelectableText(stateMachine.name,
                          style: Theme.of(context).textTheme.headline6),
                      SizedBox(height: 20),
                      ...controller.inputs.map(
                        (input) {
                          final Widget controllerWidget;
                          switch (input.type) {
                            case SMIType.number:
                              final textController = TextEditingController();

                              textController.addListener(() {
                                (input as SMINumber).value = double.tryParse(
                                        textController.value.text) ??
                                    0;
                              });
                              controllerWidget = TextField(
                                controller: textController,
                                keyboardType: TextInputType.number,
                              );

                              break;
                            case SMIType.boolean:
                              controllerWidget = TextButton(
                                child: Text('fire'),
                                onPressed: () {
                                  (input as SMIBool).value = !input.value;
                                },
                              );
                              break;
                            case SMIType.trigger:
                              controllerWidget = TextButton(
                                child: Text('fire'),
                                onPressed: () {
                                  (input as SMITrigger).fire();
                                },
                              );
                              break;
                          }

                          return Container(
                            padding: EdgeInsets.only(left: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(child: Text(input.name)),
                                Expanded(child: controllerWidget),
                                Spacer()
                              ],
                            ),
                          );
                        },
                      )
                    ],
                  );
                }).toList()),
              ),
              Column(
                children: [
                  Divider(),
                  SizedBox(height: 30),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Animations',
                      style: Theme.of(context).textTheme.headline5,
                    ),
                  ),
                  SizedBox(height: 10),
                  ...artboard.animations.map((animation) {
                    final controller = _animationControllers[animation.name];
                    final isActive = controller?.isActive ?? false;

                    return Container(
                      color: isActive ? Colors.black.withOpacity(0.5) : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(child: SelectableText(animation.name)),
                          Expanded(
                            child: TextButton(
                              child: Text(isActive ? 'stop' : 'play'),
                              onPressed: () {
                                setState(() {
                                  controller?.isActive = !controller.isActive;
                                });
                              },
                            ),
                          ),
                          Spacer(),
                        ],
                      ),
                    );
                  }).toList()
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    RiveFile.network(widget.riveAsset).then((riveFile) {
      setState(() {
        _riveFile = riveFile;
        _changeArtboard(riveFile.mainArtboard);
      });
    });
  }

  void _changeArtboard(Artboard artboard) {
    for (var i = 0; i < artboard.animations.length; i++) {
      final animation = artboard.animations[i];
      final animationController =
          OneShotAnimation(animation.name, autoplay: i == 0);
      artboard.addController(animationController);
      _animationControllers[animation.name] = animationController;
      animationController.isActiveChanged.addListener(() {
        // Trigger a setState to update the current playing animation list.
        setState(() {});
      });
    }

    for (final stateMachine in artboard.stateMachines) {
      final controller = StateMachineController(stateMachine);
      _stateMachineControllers[stateMachine] = controller;
      artboard.addController(controller);
    }

    _artboard = artboard;
  }
}
