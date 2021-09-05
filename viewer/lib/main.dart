import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:html';

/// MaterialApp cannot be used as it provides a navigator.
void main() {
  final asset =
      document.querySelector('#selectedAsset')?.attributes['file'].toString();
  runApp(
    Theme(
      data: ThemeData(textTheme: TextTheme()),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: RiveViewer(
          riveAsset:
              asset ?? 'https://cdn.rive.app/animations/off_road_car_v7.riv',
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
  String? _artboard = null;
  List<String>? _displayedAnimations = null;
  List<String>? _displayedStateMachines = null;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Center(
            child: RiveAnimation.network(
              widget.riveAsset,
              artboard: _artboard,
              animations: _displayedAnimations ?? [],
              stateMachines: _displayedStateMachines ?? [],
              fit: BoxFit.contain,
              onInit: _riveOnInit,
            ),
          ),
        ),
        Expanded(
            child: Container(
          color: Colors.blue,
          child: RiveAssetController(_artboard),
        )),
      ],
    );
  }

  void _riveOnInit(Artboard artboard) {
    setState(() {
      _artboard = artboard.name;
    });
  }
}

class RiveAssetController extends StatelessWidget {
  RiveAssetController(String? artboard);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
