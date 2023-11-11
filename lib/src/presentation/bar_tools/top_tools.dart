import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/control_provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/draggable_widget_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/painting_notifier.dart';
import 'package:stories_editor/src/presentation/utils/constants/app_enums.dart';
// import 'package:stories_editor/src/domain/sevices/save_as_image.dart';
import 'package:stories_editor/src/presentation/utils/modal_sheets.dart';
import 'package:stories_editor/src/presentation/widgets/animated_onTap_button.dart';
import 'package:stories_editor/src/presentation/widgets/tool_button.dart';
import '../../domain/models/video_dimensions_list.dart';
import '../../domain/providers/notifiers/gradient_notifier.dart';
import '../../domain/providers/notifiers/scroll_notifier.dart';
import '../../domain/sevices/save_as_image.dart';
import '../../domain/sevices/save_as_video.dart';
import '../image_editor/crop.dart';

class TopTools extends StatefulWidget {
  final GlobalKey contentKey;
  final BuildContext context;
  const TopTools({Key? key, required this.contentKey, required this.context})
      : super(key: key);

  @override
  _TopToolsState createState() => _TopToolsState();
}

class _TopToolsState extends State<TopTools> {
  @override
  Widget build(BuildContext context) {
    return Consumer6<ControlNotifier, DraggableWidgetNotifier, ScrollNotifier,
        PaintingNotifier, GradientNotifier, DraggableWidgetNotifier>(
      builder: (_, controlNotifier, itemProvider, scrollProvider,
          paintingNotifier, colorProvider, itemNotifier, __) {
        return SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 20.w),
            decoration: const BoxDecoration(color: Colors.transparent),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// close button
                ToolButton(
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                    backGroundColor: Colors.black12,
                    onTap: () async {
                      var res = await exitDialog(
                          context: widget.context,
                          contentKey: widget.contentKey);
                      if (res) {
                        Navigator.pop(context);
                      }
                    }),
                _selectColor(
                    controlProvider: controlNotifier,
                    colorProvider: colorProvider,
                    onTap: () {
                      if (controlNotifier.mediaPath != "") {
                        controlNotifier.isVideoTheme =
                            !controlNotifier.isVideoTheme;
                      } else {
                        if (controlNotifier.gradientIndex >=
                            controlNotifier.gradientColors!.length - 1) {
                          setState(() {
                            controlNotifier.gradientIndex = 0;
                          });
                        } else {
                          setState(() {
                            controlNotifier.gradientIndex += 1;
                            if (controlNotifier.mediaPath.isNotEmpty) {
                              controlNotifier.isVideoTheme = false;
                            }
                          });
                        }
                      }
                    }),
                ToolButton(
                    child: const ImageIcon(
                      AssetImage('assets/icons/download.png',
                          package: 'stories_editor'),
                      color: Colors.white,
                      size: 20,
                    ),
                    backGroundColor: Colors.black12,
                    onTap: () async {
                      if (itemNotifier.draggableWidget.first.type ==
                          ItemType.video) {
                        saveVideo(controlNotifier, itemNotifier, colorProvider,
                            widget.contentKey, context);
                      } else {
                        if (paintingNotifier.lines.isNotEmpty ||
                            itemNotifier.draggableWidget.isNotEmpty) {
                          String response = await takePicture(
                            contentKey: widget.contentKey,
                            // saveToGallery: true,
                          );

                          showDialog(
                            context: context,
                            builder: (_) =>
                                Center(child: Image.file(File(response))),
                          );
                        }
                      }
                    }),
                ToolButton(
                    child: const ImageIcon(
                      AssetImage('assets/icons/crop.png',
                          package: 'stories_editor'),
                      color: Colors.white,
                      size: 20,
                    ),
                    backGroundColor: Colors.black12,
                    onTap: () async {
                      if (itemProvider.draggableWidget.isNotEmpty &&
                          itemProvider.draggableWidget.first.type ==
                              ItemType.image) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResizableWidget(
                              child: Center(
                                child: Container(
                                  color: Colors.transparent,
                                ),
                              ),
                              imagePath: controlNotifier.mediaPath,
                              imageWidth:
                                  itemProvider.draggableWidget.first.mediaWidth,
                              imageHeight: itemProvider
                                  .draggableWidget.first.mediaHeight,
                              cn: controlNotifier,
                            ),
                          ),
                        );
                      } else if (itemProvider.draggableWidget.isNotEmpty &&
                          itemProvider.draggableWidget.first.type ==
                              ItemType.video) {
                        debugPrint(
                            "video file size  = ${(File(controlNotifier.videoPath).lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB");

                        Map<int, int> inputMap = {
                          itemProvider.draggableWidget.first.videoController!
                                  .value.size.width
                                  .toInt():
                              itemProvider.draggableWidget.first
                                  .videoController!.value.size.height
                                  .toInt()
                        }; // Replace this with your desired map {x: y}

                        Map<int, int>? selectedPair =
                            selectSuitableKeyValuePair(
                                inputMap, deviceDimensionsList);
                        debugPrint("Selected Pair: $selectedPair");
                        return;
                      } else {
                        return;
                      }
                    }),
                // Padding(
                //   padding: const EdgeInsets.all(8.0),
                //   child: Container(
                //     height: 35,
                //     width: 50,
                //     decoration: BoxDecoration(
                //         color: Colors.transparent,
                //         shape: BoxShape.circle,
                //         border: Border.all(color: Colors.white, width: 2)),
                //     child: TextButton(
                //       onPressed: () {},
                //       child: const Text("done"),
                //     ),
                //   ),
                // ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AnimatedOnTapButton(
                    onTap: () async {
                      Map mediaData = {};
                      if (itemProvider.draggableWidget.isNotEmpty &&
                          itemProvider.draggableWidget.first.type ==
                              ItemType.image) {
                        String response =
                            await takePicture(contentKey: widget.contentKey);
                        mediaData = {
                          'type': "photo",
                          'url': response,
                          'caption': controlNotifier.textCaption
                        };
                      } else if (itemProvider.draggableWidget.isNotEmpty &&
                          itemProvider.draggableWidget.first.type ==
                              ItemType.video) {
                        mediaData = await saveVideo(
                            controlNotifier,
                            itemNotifier,
                            colorProvider,
                            widget.contentKey,
                            context);
                      } else {
                        mediaData = {'type': "nothing", 'url': "url"};
                      }
                      Navigator.pop(context, mediaData);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(90),
                        elevation: 1,
                        shadowColor: Colors.black.withOpacity(0.5),
                        child: Container(
                          height: 35,
                          width: 60,
                          decoration: BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: Colors.white, width: 2)),
                          child: Transform.scale(
                            scale: 0.8,
                            child: const Center(
                                child: Text(
                              "Done",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            )),
                          ),
                        ),
                      ),
                    ),
                  ),
                )

                // ToolButton(
                //     child: const Text("Done"),
                //     backGroundColor: Colors.black12,
                //     onTap: () {
                //       // controlNotifier.isPainting = true;
                //       //createLinePainting(context: context);
                //     }),
                // ToolButton(
                //   child: ImageIcon(
                //     const AssetImage('assets/icons/photo_filter.png',
                //         package: 'stories_editor'),
                //     color: controlNotifier.isPhotoFilter ? Colors.black : Colors.white,
                //     size: 20,
                //   ),
                //   backGroundColor:  controlNotifier.isPhotoFilter ? Colors.white70 : Colors.black12,
                //   onTap: () => controlNotifier.isPhotoFilter =
                //   !controlNotifier.isPhotoFilter,
                // ),
                // ToolButton(
                //   child: const ImageIcon(
                //     AssetImage('assets/icons/text.png',
                //         package: 'stories_editor'),
                //     color: Colors.white,
                //     size: 20,
                //   ),
                //   backGroundColor: Colors.black12,
                //   onTap: () => controlNotifier.isTextEditing =
                //       !controlNotifier.isTextEditing,
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<int, int>? selectSuitableKeyValuePair(
      Map<int, int> inputMap, List<Map<int, int>> keyValuePairs) {
    // Sorting the list based on keys in ascending order
    keyValuePairs.sort((a, b) => a.keys.first.compareTo(b.keys.first));

    int x = inputMap.keys.first;
    int y = inputMap.values.first;

    Map<int, int>? result;

    if (x > y) {
      // Filter the pairs where the key is closest to x
      int minDiffKey = double.maxFinite.toInt();
      for (var pair in keyValuePairs) {
        int diffKey = (pair.keys.first - x).abs();
        if (diffKey < minDiffKey) {
          minDiffKey = diffKey;
          result = pair;
        }
      }
    } else if (y > x) {
      // Filter the pairs where the value is closest to y
      int minDiffValue = double.maxFinite.toInt();
      for (var pair in keyValuePairs) {
        int diffValue = (pair.values.first - y).abs();
        if (diffValue < minDiffValue) {
          minDiffValue = diffValue;
          result = pair;
        }
      }
    } else {
      // Filter the pairs with keys closest to x
      int minDiffKey = double.maxFinite.toInt();
      for (var pair in keyValuePairs) {
        int diffKey = (pair.keys.first - x).abs();
        if (diffKey < minDiffKey) {
          minDiffKey = diffKey;
          result = pair;
        }
      }
    }

    return result;
  }

  /// gradient color selector
  Widget _selectColor(
      {onTap,
      ControlNotifier? controlProvider,
      GradientNotifier? colorProvider}) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, right: 5, top: 8),
      child: AnimatedOnTapButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: controlProvider!.mediaPath.isEmpty
                      ? controlProvider
                          .gradientColors![controlProvider.gradientIndex]
                      : controlProvider.isVideoTheme == false
                          ? controlProvider
                              .gradientColors![controlProvider.gradientIndex]
                          : [
                              colorProvider!.color1,
                              colorProvider.color2,
                              colorProvider.color3,
                              colorProvider.color4,
                              colorProvider.color5,
                              colorProvider.color6
                            ]),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
