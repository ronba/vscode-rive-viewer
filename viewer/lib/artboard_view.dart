import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rive/rive.dart';

final Map<int, TextStyle> indentToTextStyleMap = {
  0: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
  1: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
  2: TextStyle(fontWeight: FontWeight.w300, fontSize: 14, color: Colors.white),
  3: TextStyle(fontWeight: FontWeight.w300, fontSize: 14, color: Colors.white),
};

class ArtboardView extends StatefulWidget {
  final Artboard artboard;

  const ArtboardView({
    Key? key,
    required this.artboard,
  }) : super(key: key);

  @override
  State<ArtboardView> createState() => _ArtboardViewState();
}

class IndentedItem extends StatelessWidget {
  final int indent;
  final Widget child;
  const IndentedItem({Key? key, required this.indent, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: indentToTextStyleMap[indent] ?? TextStyle(),
      child: Container(
        margin: EdgeInsets.only(
          left: (20 * indent).toDouble(),
          top: (10 * 1 / (indent == 0 ? 0.5 : indent)).toDouble(),
          bottom: (5 * 1 / (indent == 0 ? 0.5 : indent)).toDouble(),
        ),
        child: child,
      ),
    );
  }
}

class _ArtboardViewState extends State<ArtboardView> {
  Map<String, RiveAnimationController> _animationControllers = {};
  Map<StateMachine, StateMachineController> _stateMachineControllers = {};
  BoxFit _fit = BoxFit.contain;
  @override
  Widget build(BuildContext context) {
    final artboard = widget.artboard;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 20),
        Expanded(
          child: ListView(
            children: [
              IndentedItem(
                  indent: 0,
                  child: SelectableText(
                    artboard.name,
                  )),
              if (artboard.stateMachines.length > 0)
                Column(
                    children: artboard.stateMachines.map((stateMachine) {
                  final controller = _stateMachineControllers[stateMachine]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IndentedItem(
                          indent: 1, child: SelectableText("State Machines")),
                      IndentedItem(
                        indent: 2,
                        child: SelectableText(stateMachine.name),
                      ),
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

                          return IndentedItem(
                            indent: 3,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(flex: 8, child: Text(input.name)),
                                Expanded(flex: 2, child: controllerWidget),
                                Spacer()
                              ],
                            ),
                          );
                        },
                      )
                    ],
                  );
                }).toList()),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IndentedItem(
                    indent: 1,
                    child: Text('Animations'),
                  ),
                  SizedBox(height: 10),
                  ...artboard.animations.map((animation) {
                    final controller = _animationControllers[animation.name];
                    var isActive = controller?.isActive ?? false;

                    return Container(
                      color: isActive ? Colors.black.withOpacity(0.5) : null,
                      child: IndentedItem(
                        indent: 2,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                                flex: 8, child: SelectableText(animation.name)),
                            Expanded(
                              flex: 2,
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
                      ),
                    );
                  }).toList()
                ],
              )
            ],
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Stack(
            children: [
              Center(
                child: Rive(
                  artboard: artboard,
                  fit: _fit,
                ),
              ),
              Wrap(
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
      ],
    );
  }

  @override
  void dispose() {
    for (final animationController in _animationControllers.values) {
      animationController.dispose();
    }

    for (final stateMachineController in _stateMachineControllers.values) {
      stateMachineController.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _changeArtboard(widget.artboard);
    });
  }

  void _changeArtboard(Artboard artboard) {
    for (var i = 0; i < artboard.animations.length; i++) {
      final animation = artboard.animations[i];
      final animationController =
          OneShotAnimation(animation.name, autoplay: i == 0, onStart: () {
        if (mounted) {
          setState(() {});
        }
      }, onStop: () {
        if (mounted) {
          setState(() {});
        }
      });
      artboard.addController(animationController);
      _animationControllers[animation.name] = animationController;
    }

    for (final stateMachine in artboard.stateMachines) {
      final controller = StateMachineController(stateMachine);
      _stateMachineControllers[stateMachine] = controller;
      artboard.addController(controller);
    }
  }
}
