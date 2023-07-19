import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';

import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../domain/providers/notifiers/control_provider.dart';

class FileImageBG extends StatefulWidget {
  final File? filePath;
  final GlobalKey contentKey;
  final void Function(Color color1, Color color2, Color color3, Color color4,
      Color color5, Color color6) generatedGradient;
  const FileImageBG(
      {Key? key,
      required this.filePath,
      required this.generatedGradient,
      required this.contentKey})
      : super(key: key);
  @override
  _FileImageBGState createState() => _FileImageBGState();
}

class _FileImageBGState extends State<FileImageBG> {
  GlobalKey imageKey = GlobalKey();
  GlobalKey paintKey = GlobalKey();
  GlobalKey? currentKey;

  final StreamController<Color> stateController = StreamController<Color>();

  Color color1 = const Color(0xFFFFFFFF);
  Color color2 = const Color(0xFFFFFFFF);
  Color color3 = const Color(0xFFFFFFFF);
  Color color4 = const Color(0xFFFFFFFF);
  Color color5 = const Color(0xFFFFFFFF);
  Color color6 = const Color(0xFFFFFFFF);

  bool loading = true;

  double topClipPercentage = 0.0;
  double leftClipPercentage = 0.0;
  double rightClipPercentage = 0.0;
  double bottomClipPercentage = 0.0;

  bool update = false;

  Key mainListKey = const Key('MainList');

  @override
  void initState() {
    super.initState();

    loadGradients();
  }

  loadGradients() async {
    final colors = await sampleColorsAlongCenter(widget.filePath!.path);

    setState(() {
      loading = false;
      color1 = Color(int.parse(colors[0].substring(1), radix: 16));
      color2 = Color(int.parse(colors[1].substring(1), radix: 16));
      color3 = Color(int.parse(colors[2].substring(1), radix: 16));
      color4 = Color(int.parse(colors[3].substring(1), radix: 16));
      color5 = Color(int.parse(colors[4].substring(1), radix: 16));
      color6 = Color(int.parse(colors[5].substring(1), radix: 16));
    });

    widget.generatedGradient(color1, color2, color3, color4, color5, color6);
  }

  List<Offset> getVerticalOffsets(List<Offset> widgetOffsets) {
    // calculate widget height
    double height = widgetOffsets[1].dy - widgetOffsets[0].dy;

    // Calculate the center vertical position
    double centerX = (widgetOffsets[2].dx + widgetOffsets[1].dx) / 2;

    // Calculate the Y coordinate at each percentage
    List<double> percentages = [0.02, 0.22, 0.42, 0.62, 0.82, 0.98];

    List<Offset> verticalOffsets = [];

    for (double percentage in percentages) {
      double y = (height * percentage) + widgetOffsets[0].dy + 51.0;
      verticalOffsets.add(Offset(centerX, y));
    }

    return verticalOffsets;
  }

  List<Offset> getCorners() {
    RenderBox parentBox =
        widget.contentKey.currentContext!.findRenderObject() as RenderBox;
    RenderBox childBox =
        imageKey.currentContext!.findRenderObject() as RenderBox;

    Offset childOffset =
        childBox.localToGlobal(Offset.zero, ancestor: parentBox);

    var centerX = childOffset.dx;
    var centerY = childOffset.dy;

    double lengths = childBox.size.width; // Length of the rectangle
    double widths = childBox.size.height; // Width of the rectangle

    List<Offset> rotatedCorners =
        generateCornerOffsets(Offset(centerX, centerY), lengths, widths);

    return rotatedCorners;
  }

  List<Offset> generateCornerOffsets(
      Offset topLeftOffset, double length, double width) {
    final double top = topLeftOffset.dy;
    final double left = topLeftOffset.dx;
    final double right = left + length;
    final double bottom = top + width;

    final List<Offset> cornerOffsets = [
      Offset(left, top), // Top-left corner
      Offset(left, bottom), // Bottom-left corner
      Offset(right, bottom), // Bottom-right corner
      Offset(right, top), // Top-right corner
    ];

    return cornerOffsets;
  }

  @override
  void dispose() {
    stateController.close();
    super.dispose();
  }

  Future<List<String>> sampleColorsAlongCenter(String imagePath) async {
    final image = await loadImage(imagePath);
    final colors = await sampleColors(image);
    return colors;
  }

  Future<ui.Image> loadImage(String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  Future<List<String>> sampleColors(ui.Image image) async {
    final points = [
      0.02,
      0.10,
      0.35,
      0.65,
      0.90,
      0.98
    ]; // Points along the center vertical line

    final colors = <String>[];
    final byteData = await image.toByteData();
    final buffer = byteData!.buffer;
    final pixels = buffer.asUint8List();

    final centerWidth = image.width ~/ 2; // Calculate center width

    for (var i = 0; i < points.length; i++) {
      final y = (image.height * points[i]).toInt();
      final pixelOffset = ((y * image.width) + centerWidth) *
          4; // Calculate pixel offset from center width and height
      final r = pixels[pixelOffset];
      final g = pixels[pixelOffset + 1];
      final b = pixels[pixelOffset + 2];
      final a = pixels[pixelOffset + 3];

      final color =
          '#${_componentToHex(a)}${_componentToHex(r)}${_componentToHex(g)}${_componentToHex(b)}';
      colors.add(color);
    }

    return colors;
  }

  String _componentToHex(int component) {
    final hex = component.toRadixString(16).padLeft(2, '0');
    return hex.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ScreenUtil screenUtil = ScreenUtil();
    return Consumer<ControlNotifier>(builder: (context, controlNotifier, _) {
      List<double> clippers = controlNotifier.clippersList!;
      return SizedBox(
        height: screenUtil.screenHeight,
        width: screenUtil.screenWidth,
        child: RepaintBoundary(
          key: paintKey,
          child: Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () async {
                    controlNotifier.isTextEdit = false;

                    // final colors =
                    //     await sampleColorsAlongCenter(widget.filePath!.path);
                    // print("colors are $colors");
                  },
                  child: Center(
                    child: ClipPath(
                      clipper: MyCustomClipper(
                        topClipPercentage: clippers[0],
                        leftClipPercentage: clippers[1],
                        rightClipPercentage: clippers[2],
                        bottomClipPercentage: clippers[3],
                      ),
                      child: VisibilityDetector(
                        key: mainListKey,
                        onVisibilityChanged: (visibilityInfo) {
                          // Additional visibility changes can be detected here

                          if (visibilityInfo.visibleFraction == 0.0) {
                            update = false;
                          } else {
                            if (update == false) {
                              setState(() {
                                update = true;
                              });
                            }
                          }
                        },
                        child: Image.file(
                          File(widget.filePath!.path),
                          key: imageKey,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    left: 0,
                    child: loading == true
                        ? const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 5,
                            ),
                          )
                        : const Center())
              ],
            ),
          ),
        ),
      );
    });
  }
}

class MyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(size.width * 0.1, size.height * 0.2);
    path.lineTo(size.width * 0.1, size.height * 0.6);
    path.lineTo(size.width * 0.8, size.height * 0.6);
    path.lineTo(size.width * 0.8, size.height * 0.2);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

class MyCustomClipper extends CustomClipper<Path> {
  final double topClipPercentage;
  final double leftClipPercentage;
  final double rightClipPercentage;
  final double bottomClipPercentage;

  MyCustomClipper({
    required this.topClipPercentage,
    required this.leftClipPercentage,
    required this.rightClipPercentage,
    required this.bottomClipPercentage,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    // Define the shape of the clipped area
    path.moveTo(
        size.width * leftClipPercentage, size.height * topClipPercentage);
    path.lineTo(size.width * leftClipPercentage,
        size.height * (1 - bottomClipPercentage));
    path.lineTo(size.width * (1 - rightClipPercentage),
        size.height * (1 - bottomClipPercentage));
    path.lineTo(size.width * (1 - rightClipPercentage),
        size.height * topClipPercentage);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}
