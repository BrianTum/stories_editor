import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:stories_editor/src/presentation/utils/color_detection.dart';
import 'package:video_player/video_player.dart';

import '../../domain/providers/notifiers/draggable_widget_notifier.dart';

class FileVideoBG extends StatefulWidget {
  final File? filePath;
  final String? videoPath;
  final void Function(Color color1, Color color2) generatedGradient;

  const FileVideoBG({
    Key? key,
    required this.filePath,
    required this.generatedGradient,
    required this.videoPath,
  }) : super(key: key);

  @override
  _FileVideoBGState createState() => _FileVideoBGState();
}

class _FileVideoBGState extends State<FileVideoBG> {
  final GlobalKey imageKey = GlobalKey();
  final GlobalKey paintKey = GlobalKey();
  GlobalKey? currentKey;

  final StreamController<Color> stateController = StreamController<Color>();
  Color color1 = const Color(0xFFFFFFFF);
  Color color2 = const Color(0xFFFFFFFF);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    var _tempItemProvider =
        Provider.of<DraggableWidgetNotifier>(context, listen: false);
    currentKey = paintKey;

    if (kDebugMode) {
      print("video path 2 == ${widget.videoPath}");
    }

    _tempItemProvider.draggableWidget.first.videoController =
        VideoPlayerController.file(File(widget.videoPath!));

    _tempItemProvider.draggableWidget.first.videoController!
        .initialize()
        .then((_) {
      setState(() {});

      _timer =
          Timer.periodic(const Duration(milliseconds: 500), (callback) async {
        if (kDebugMode) {
          print(imageKey.currentState!.context.size!.height);
        }
        if (imageKey.currentState!.context.size!.height == 0.0) {
          return;
        }

        var cd1 = await ColorDetection(
          currentKey: currentKey,
          paintKey: paintKey,
          stateController: stateController,
        ).searchPixel(
            Offset(imageKey.currentState!.context.size!.width / 2, 480));

        var cd12 = await ColorDetection(
          currentKey: currentKey,
          paintKey: paintKey,
          stateController: stateController,
        ).searchPixel(
            Offset(imageKey.currentState!.context.size!.width / 2.03, 530));

        setState(() {
          color1 = cd1;
          color2 = cd12;
        });

        widget.generatedGradient(color1, color2);
        callback.cancel();
      });
    }).then((value) {
      _tempItemProvider.draggableWidget.first.videoController!.play();
      _tempItemProvider.draggableWidget.first.videoController!.addListener(() {
        if (_tempItemProvider
                .draggableWidget.first.videoController!.value.position >=
            _tempItemProvider
                .draggableWidget.first.videoController!.value.duration) {
          Future.delayed(const Duration(seconds: 1), () {
            _tempItemProvider.draggableWidget.first.videoController!.play();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    disposeVideoController();
    super.dispose();
  }

  void disposeVideoController() async {
    var _tempItemProvider =
        Provider.of<DraggableWidgetNotifier>(context, listen: false);
    stateController.close();
    _tempItemProvider.draggableWidget.first.videoController!.pause();
    await _tempItemProvider.draggableWidget.first.videoController!.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final screenUtil = ScreenUtil();

    return Consumer<DraggableWidgetNotifier>(
      builder: (context, itemProvider, child) {
        return SizedBox(
          height: screenUtil.screenHeight,
          width: screenUtil.screenWidth,
          child: RepaintBoundary(
            key: paintKey,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  final videoController =
                      itemProvider.draggableWidget.first.videoController!;
                  if (videoController.value.isPlaying) {
                    videoController.pause();
                  } else {
                    videoController.play();
                  }
                },
                child: AspectRatio(
                  aspectRatio: itemProvider
                      .draggableWidget.first.videoController!.value.aspectRatio,
                  child: VideoPlayer(
                    itemProvider.draggableWidget.first.videoController!,
                    key: imageKey,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
