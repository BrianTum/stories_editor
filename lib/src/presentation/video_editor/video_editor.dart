import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../domain/providers/notifiers/control_provider.dart';
import '../../domain/providers/notifiers/draggable_widget_notifier.dart';
import '../widgets/animated_onTap_button.dart';
import 'crop_page.dart';
import 'export_service.dart';

class VideoEditor extends StatefulWidget {
  const VideoEditor(
      {super.key, required this.itemProvider, required this.controlNotifier});

  final ControlNotifier controlNotifier;
  final DraggableWidgetNotifier itemProvider;

  @override
  State<VideoEditor> createState() => _VideoEditorState();
}

class _VideoEditorState extends State<VideoEditor> {
  final _exportingProgress = ValueNotifier<double>(0.0);
  final _isExporting = ValueNotifier<bool>(false);
  final double height = 60;

  late final VideoEditorController _controller;

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controlNotifier.videoEditController;
  }

  @override
  void dispose() async {
    _exportingProgress.dispose();
    _isExporting.dispose();
    _isDisposed = true;
    _controller.dispose();
    ExportService.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
        ),
      );

  void _exportVideo() async {
    _exportingProgress.value = 0;
    _isExporting.value = true;

    final config = VideoFFmpegVideoEditorConfig(_controller);
    final configCover = CoverFFmpegVideoEditorConfig(_controller);

    String coverPath = "";

    final executeCover = await configCover.getExecuteConfig();
    if (executeCover == null) {
      _showErrorSnackBar("Error on cover exportation initialization.");
      return;
    }

    await ExportService.runFFmpegCommand(
      executeCover,
      onError: (e, s) {
        if (!_isDisposed) {
          _showErrorSnackBar("Error on cover exportation :(");
        }
      },
      onCompleted: (cover) {
        if (_isDisposed) return;

        debugPrint("cover is ${cover.path}");
        coverPath = cover.path;
        widget.controlNotifier.mediaPath == cover.path;
      },
    );

    await ExportService.runFFmpegCommand(
      await config.getExecuteConfig(),
      onProgress: (stats) {
        if (!_isDisposed) {
          _exportingProgress.value = config.getFFmpegProgress(stats.getTime());
        }
      },
      onError: (e, s) {
        if (!_isDisposed) {
          _showErrorSnackBar("Error on export video :(");
        }
      },
      onCompleted: (file) async {
        debugPrint("file is ${file.path}");

        if (_isDisposed) return;

        _isExporting.value = false;

        Navigator.pop(context, [file.path, coverPath, _controller]);
      },
    );
  }

  // void _exportCover() async {
  //   final configCover = CoverFFmpegVideoEditorConfig(_controller);
  //   final executeCover = await configCover.getExecuteConfig();
  //   if (executeCover == null) {
  //     _showErrorSnackBar("Error on cover exportation initialization.");
  //     return;
  //   }

  //   await ExportService.runFFmpegCommand(
  //     executeCover,
  //     onError: (e, s) => _showErrorSnackBar("Error on cover exportation :("),
  //     onCompleted: (cover) {
  //       if (!mounted) return;

  //       // widget.controlNotifier.mediaPath == cover.path;
  //       // showDialog(
  //       //   context: context,
  //       //   builder: (_) => CoverResultPopup(cover: cover),
  //       // );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _controller.initialized
            ? SafeArea(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                Expanded(
                                    flex: 1,
                                    child: Container(
                                      color: Colors.white54,
                                      child: const Center(
                                          child: Text(
                                        "VIDEO EDITOR",
                                        style: TextStyle(fontSize: 36),
                                      )),
                                    )),
                                Expanded(flex: 1, child: _topNavBar()),
                              ],
                            )),
                        Expanded(
                          flex: 7,
                          child: DefaultTabController(
                            length: 2,
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: TabBarView(
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        children: [
                                          Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              CropGridViewer.preview(
                                                  controller: _controller),
                                              AnimatedBuilder(
                                                animation: _controller.video,
                                                builder: (_, __) =>
                                                    AnimatedOpacity(
                                                  opacity: _controller.isPlaying
                                                      ? 0
                                                      : 1,
                                                  duration:
                                                      kThemeAnimationDuration,
                                                  child: GestureDetector(
                                                    onTap:
                                                        _controller.video.play,
                                                    child: Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: Colors.white,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.play_arrow,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          CoverViewer(controller: _controller)
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        color: Colors.white70,
                                        height: 200,
                                        margin: const EdgeInsets.only(top: 10),
                                        child: Column(
                                          children: [
                                            const TabBar(
                                              tabs: [
                                                Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Padding(
                                                          padding:
                                                              EdgeInsets.all(5),
                                                          child: Icon(Icons
                                                              .content_cut)),
                                                      Text('Trim')
                                                    ]),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Padding(
                                                        padding:
                                                            EdgeInsets.all(5),
                                                        child: Icon(
                                                            Icons.video_label)),
                                                    Text('Cover')
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Expanded(
                                              child: TabBarView(
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                children: [
                                                  Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: _trimSlider(),
                                                  ),
                                                  _coverSelection(),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Center(
                                  child: ValueListenableBuilder(
                                    valueListenable: _isExporting,
                                    builder: (_, bool export, Widget? child) =>
                                        AnimatedSize(
                                      duration: kThemeAnimationDuration,
                                      child: export ? child : null,
                                    ),
                                    child: AlertDialog(
                                      backgroundColor: Colors.white60,
                                      title: ValueListenableBuilder(
                                        valueListenable: _exportingProgress,
                                        builder: (_, double value, __) =>
                                            CircularPercentIndicator(
                                          radius: 45.0,
                                          lineWidth: 4.0,
                                          percent: value,
                                          center:
                                              Text("${(value * 100).ceil()}%"),
                                          progressColor: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _topNavBar() {
    return SafeArea(
      child: Container(
        color: Colors.white60,
        height: height,
        child: Row(
          children: [
            Expanded(
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.exit_to_app),
                tooltip: 'Leave editor',
              ),
            ),
            const VerticalDivider(endIndent: 22, indent: 22),
            Expanded(
              child: IconButton(
                onPressed: () =>
                    _controller.rotate90Degrees(RotateDirection.left),
                icon: const Icon(Icons.rotate_left),
                tooltip: 'Rotate unclockwise',
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () =>
                    _controller.rotate90Degrees(RotateDirection.right),
                icon: const Icon(Icons.rotate_right),
                tooltip: 'Rotate clockwise',
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => CropPage(controller: _controller),
                  ),
                ),
                icon: const Icon(Icons.crop),
                tooltip: 'Open crop screen',
              ),
            ),
            const VerticalDivider(endIndent: 22, indent: 22),
            Expanded(
              child: AnimatedOnTapButton(
                onTap: () {
                  _exportVideo();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(90),
                    elevation: 1,
                    shadowColor: Colors.white60,
                    child: Container(
                      height: 35,
                      width: 60,
                      decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black, width: 2)),
                      child: Transform.scale(
                        scale: 0.8,
                        child: const Center(
                            child: Text(
                          "Done",
                          style: TextStyle(color: Colors.black, fontSize: 20),
                        )),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatter(Duration duration) => [
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        duration.inSeconds.remainder(60).toString().padLeft(2, '0')
      ].join(":");

  List<Widget> _trimSlider() {
    return [
      AnimatedBuilder(
        animation: Listenable.merge([
          _controller,
          _controller.video,
        ]),
        builder: (_, __) {
          final int duration = _controller.videoDuration.inSeconds;
          final double pos = _controller.trimPosition * duration;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: height / 4),
            child: Row(children: [
              Text(formatter(Duration(seconds: pos.toInt()))),
              const Expanded(child: SizedBox()),
              AnimatedOpacity(
                opacity: _controller.isTrimming ? 1 : 0,
                duration: kThemeAnimationDuration,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(formatter(_controller.startTrim)),
                  const SizedBox(width: 10),
                  Text(formatter(_controller.endTrim)),
                ]),
              ),
            ]),
          );
        },
      ),
      Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.symmetric(vertical: height / 4),
        child: TrimSlider(
          controller: _controller,
          height: height,
          horizontalMargin: height / 4,
          child: TrimTimeline(
            controller: _controller,
            padding: const EdgeInsets.only(top: 10),
          ),
        ),
      )
    ];
  }

  Widget _coverSelection() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(15),
          child: CoverSelection(
            controller: _controller,
            size: height + 10,
            quantity: 8,
            selectedCoverBuilder: (cover, size) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  cover,
                  Icon(
                    Icons.check_circle,
                    color: const CoverSelectionStyle().selectedBorderColor,
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
