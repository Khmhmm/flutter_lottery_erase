import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:flutter_drawing_board/paint_extension.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'lottery erase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'lottery erase'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});
  final String title;
  bool erased = false;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final DrawingController _drawingController = DrawingController();
  Widget? board;

  Future<void> checkIfErased(PointerDownEvent _) async {
    ByteData? imgbts = await _drawingController.getImageData();
    final buf = imgbts!.buffer.asInt8List();

    int zeroBts = buf.where((bt) => bt == 0).length;
    if (zeroBts / buf.length >= 0.7) {
      setState(() => widget.erased = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: (widget.erased)? Center(child: Text("Erased", style: TextStyle(fontSize: 36))) : buildBoard(context),
    );
  }

  Widget buildBoard(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;

    return FutureBuilder<ui.Image>(
      future: getUiImage('assets/yumiko_017.png', (w * 0.66).round(), (h * 0.33).round()),
      builder: (BuildContext context, AsyncSnapshot<ui.Image> snapshot) {
        if (snapshot.hasData) {
          if (board == null) {
            board = SizedBox(width: w*0.66, height: h*0.36, child:
            DrawingBoard(
              controller: _drawingController,
              background: Container(width: w * 0.66, height: h * 0.36, color: Colors.transparent),
              panAxis: PanAxis.aligned,
              boardScaleEnabled: false,
              boardPanEnabled: false,
              onPointerDown: checkIfErased,
            )
            );
            _drawingController.setPaintContent(
              ImgPainter(snapshot.data)
            );
            _drawingController.startDraw(Offset(0, 0));
            _drawingController.endDraw();
          }
          _drawingController.setPaintContent(Eraser(color: Theme.of(context).colorScheme.background));
          _drawingController.setStyle(strokeWidth: 36);

          return Center(child: board!);
        } else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(),
              Image.asset('assets/yumiko_017.png', width: w * 0.66, height: h * 0.36),
              Spacer(),
            ],
          );
        }
      },
    );
  }
}


class ImgPainter extends PaintContent {
  ImgPainter(this.img);

  ImgPainter.data({
    required this.startPoint,
    // required this.img,
    required Paint paint,
  }) : super.paint(paint);

  factory ImgPainter.fromJson(Map<String, dynamic> data) {
    return ImgPainter.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      // img: ui.Image(),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  Offset startPoint = Offset.zero;
  ui.Image? img;

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  void drawing(Offset nowPoint) {
    // A = Offset(startPoint.dx + (nowPoint.dx - startPoint.dx) / 2, startPoint.dy);
    // B = Offset(startPoint.dx, nowPoint.dy);
    // C = nowPoint;
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    canvas.drawImage(this.img!, startPoint, paint);
  }

  @override
  ImgPainter copy() => ImgPainter(this.img);

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'startPoint': startPoint.toJson(),
    };
  }

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint.toJson(),
    };
  }
}


// https://stackoverflow.com/questions/59923245/flutter-convert-and-resize-asset-image-to-dart-ui-image
Future<ui.Image> getUiImage(String imageAssetPath, int width, int height) async {
  final ByteData assetImageByteData = await rootBundle.load(imageAssetPath);
  final codec = await ui.instantiateImageCodec(
    assetImageByteData.buffer.asUint8List(),
    targetHeight: height,
    targetWidth: width,
  );

  final image = (await codec.getNextFrame()).image;
  return image;
}
