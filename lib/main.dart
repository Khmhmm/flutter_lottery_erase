import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';

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

  Future<bool> checkErased() async {
    ByteData? imgbts = await _drawingController.getImageData();
    final buf = imgbts!.buffer.asInt8List();
    int zeroBts = buf.where((bt) => bt == 0).length;

    return zeroBts / buf.length >= 0.15;
  }

  Future<void> updateIfErased() async {
    if (await checkErased()) {
      setState(() => widget.erased = true);
    }
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(
      const Duration(seconds: 2),
      () => Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 600));
        return !(await checkErased());
      }).then((_) => updateIfErased().then((_){}))
    ).then((_){});
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

    return FutureBuilder<ImageInfo>(
      future: getUiImage(context, 'assets/termoland9.png', (w * 0.66).round(), (h * 0.36).round()),
      builder: (BuildContext context, AsyncSnapshot<ImageInfo> snapshot) {
        if (snapshot.hasData) {
          if (board == null) {
            board = SizedBox(width: w*0.66, height: h*0.36, child:
            DrawingBoard(
              controller: _drawingController,
              background: Container(width: w * 0.66, height: h * 0.36, color: Colors.transparent),
              panAxis: PanAxis.aligned,
              boardScaleEnabled: false,
              boardPanEnabled: false,
              // onPointerDown: updateIfErased,
              // onPointerUp: updateIfErased,
            )
            );
            _drawingController.setPaintContent(
              ImgPainter(snapshot.data)
            );
            _drawingController.setStyle(blendMode: ui.BlendMode.src, filterQuality: ui.FilterQuality.high, isAntiAlias: true);
            _drawingController.startDraw(Offset(0, 0));
            _drawingController.endDraw();
          }
          _drawingController.setPaintContent(Eraser(color: Theme.of(context).colorScheme.background));
          _drawingController.setStyle(strokeWidth: 48);

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(),
              Center(child: Image.asset('assets/termoland9.png', width: w * 0.66, height: h * 0.36)),
              Spacer(),
              Center(child: board!),
              Spacer(),
            ],
          );
        } else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(),
              Image.asset('assets/termoland9.png', width: w * 0.66, height: h * 0.36),
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
  // ui.Image? img;
  ImageInfo? img;

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
    // final p = Paint();
    // p.filterQuality = FilterQuality.high;
    // p.isAntiAlias = true;
    // canvas.drawImage(this.img!, startPoint, p);
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(
         0, 0,
         this.img!.image.width / 1.333,
         this.img!.image.height / 1.333),
         // this.img!.image.width / this.img!.scale,
         // this.img!.image.height / this.img!.scale),
      image: this.img!.image,
      filterQuality: FilterQuality.high,
   );
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
// https://stackoverflow.com/questions/65439889/flutter-canvas-drawimage-draws-a-pixelated-image

// Future<ui.Image> getUiImage(String imageAssetPath, int width, int height) async {
Future<ImageInfo> getUiImage(BuildContext context, String imageAssetPath, int width, int height) async {
  // final buf = await rootBundle.loadBuffer(imageAssetPath);
  // final codec = await ui.instantiateImageCodecFromBuffer(
  //   // assetImageByteData.buffer.asUint8List(),
  //   buf,
  //   targetHeight: height,
  //   targetWidth: width,
  // );
  //
  // final image = (await codec.getNextFrame()).image;

  // final descriptor = ui.ImageDescriptor.raw(
  //   buf,
  //   width: width,
  //   height: height,
  //   pixelFormat: ui.PixelFormat.rgba8888,
  // );
  // final descriptor = await ui.ImageDescriptor.encoded(buf);
  // final codec = await descriptor.instantiateCodec(targetWidth: width, targetHeight: height);
  // final image = (await codec.getNextFrame()).image;


  AssetImage assetImage = AssetImage(imageAssetPath);
  ImageConfiguration cfg = createLocalImageConfiguration(context);
  // ImageConfiguration cfg = ImageConfiguration(
  //   bundle: rootBundle,
  //   devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
  //   locale: null,
  //   textDirection: null,
  //   // size: MediaQuery.of(context).size,
  //   size: Size(width * 1.0, height * 1.0),
  //   platform: null,
  // );
  ImageStream stream = assetImage.resolve(cfg);
  Completer<ImageInfo> completer = Completer();
  stream.addListener(ImageStreamListener( (imageInfo, _) => completer.complete(imageInfo) ));
  ImageInfo imginf = await completer.future;

  return imginf;
}
