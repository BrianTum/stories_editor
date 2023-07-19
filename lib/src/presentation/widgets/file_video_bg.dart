import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/control_provider.dart';
import 'package:video_player/video_player.dart';

import '../../domain/providers/notifiers/draggable_widget_notifier.dart';

class FileVideoBG extends StatefulWidget {
  final String? filePath;
  final String? videoPath;
  final GlobalKey contentKey;

  final void Function(Color color1, Color color2, Color color3, Color color4,
      Color color5, Color color6) generatedGradient;

  const FileVideoBG({
    Key? key,
    required this.filePath,
    required this.generatedGradient,
    required this.videoPath,
    required this.contentKey,
  }) : super(key: key);

  @override
  _FileVideoBGState createState() => _FileVideoBGState();
}

class _FileVideoBGState extends State<FileVideoBG> {
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

  late VideoPlayerController videoController;

  bool loading = true;

  late ControlNotifier controlNotifier;

  @override
  void initState() {
    super.initState();

    controlNotifier = Provider.of<ControlNotifier>(context, listen: false);

    final itempItemProvider =
        Provider.of<DraggableWidgetNotifier>(context, listen: false);

    videoController = itempItemProvider.draggableWidget.first.videoController!;

    videoController.play();

    loadGradients();

    Timer.periodic(const Duration(milliseconds: 500), (callback) async {
      if (imageKey.currentState!.context.size!.height == 0.0) {
      } else {
        itempItemProvider.draggableWidget.first.itemKey = imageKey;
        itempItemProvider.draggableWidget.first.mediaHeight =
            imageKey.currentState!.context.size!.height;
        itempItemProvider.draggableWidget.first.mediaWidth =
            imageKey.currentState!.context.size!.width;
        callback.cancel();
      }
    });

    videoController.play();
    videoController.addListener(() {
      if (videoController.value.position >= videoController.value.duration) {
        Future.delayed(const Duration(seconds: 1), () {
          videoController.play();
        });
      }
    });
  }

  loadGradients() async {
    final colors = await sampleColorsAlongCenter(controlNotifier.mediaPath);

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
    videoController.pause();
    videoController.dispose();
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
    final screenUtil = ScreenUtil();

    return SizedBox(
      height: videoController.value.isInitialized
          ? videoController.value.size.height
          : screenUtil.screenHeight,
      width: videoController.value.isInitialized
          ? videoController.value.size.width
          : screenUtil.screenWidth,
      child: RepaintBoundary(
        key: paintKey,
        child: Center(
          child: GestureDetector(
            onTap: () {
              if (videoController.value.isPlaying) {
                videoController.pause();
              } else {
                videoController.play();
              }
            },
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: videoController.value.aspectRatio,
                  child: VideoPlayer(
                    videoController,
                    key: imageKey,
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
      ),
    );
  }
}
