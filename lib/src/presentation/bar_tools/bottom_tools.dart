import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gallery_media_picker/gallery_media_picker.dart';
import 'package:provider/provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/control_provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/draggable_widget_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/scroll_notifier.dart';

import '../../domain/providers/notifiers/gradient_notifier.dart';
import '../captioner/caption.dart';
import '../filters/filters.dart';

class BottomTools extends StatefulWidget {
  final GlobalKey contentKey;
  final Function(String imageUri) onDone;
  final Widget? onDoneButtonStyle;

  /// editor background color
  final Color? editorBackgroundColor;
  const BottomTools(
      {Key? key,
      required this.contentKey,
      required this.onDone,
      this.onDoneButtonStyle,
      this.editorBackgroundColor})
      : super(key: key);

  @override
  State<BottomTools> createState() => _BottomToolsState();
}

class _BottomToolsState extends State<BottomTools> {
  int activeButton = 1;

  @override
  Widget build(BuildContext context) {
    return Consumer4<ControlNotifier, ScrollNotifier, DraggableWidgetNotifier,
        GradientNotifier>(
      builder: (_, controlNotifier, scrollNotifier, itemNotifier, colorProvider,
          __) {
        return Container(
          decoration: BoxDecoration(
              color: controlNotifier
                  .gradientColors![controlNotifier.gradientIndex].last
                  .withOpacity(0.2)),
          height: MediaQuery.of(context).size.height * 0.15,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// preview gallery
                Expanded(
                  flex: 1,
                  child: Container(
                    alignment: Alignment.center,
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.15,
                      width: double.infinity,
                      child: _preViewContainer(
                        /// if [model.imagePath] is null/empty return preview image
                        child: controlNotifier.mediaPath.isEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: GestureDetector(
                                  onTap: () {
                                    controlNotifier.isTextEdit = false;

                                    /// scroll to gridView page
                                    if (mounted &&
                                        controlNotifier.mediaPath.isEmpty) {
                                      scrollNotifier.pageController
                                          .animateToPage(1,
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              curve: Curves.ease);
                                    }
                                  },
                                  child: const CoverThumbnail(
                                      thumbnailQuality: 200,
                                      thumbnailFit: BoxFit.cover),
                                ),
                              )

                            /// return clear [imagePath] provider
                            : GestureDetector(
                                onTap: () {
                                  controlNotifier.isTextEdit = false;

                                  /// clear image url variable

                                  activeButton = 1;
                                  controlNotifier.mediaPath = '';

                                  if (controlNotifier.videoPath != '') {
                                    controlNotifier.videoPath = '';

                                    itemNotifier
                                        .draggableWidget.first.videoController!
                                        .dispose();
                                  }

                                  itemNotifier.draggableWidget.removeAt(0);

                                  controlNotifier.clippersList!.clear();
                                  controlNotifier.clippersList!
                                      .addAll([0.0, 0.0, 0.0, 0.0]);

                                  controlNotifier.isVideoTheme = true;
                                },
                                child: Container(
                                  height: 45,
                                  width: 45,
                                  color: Colors.transparent,
                                  child: Transform.scale(
                                    scale: 0.7,
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  flex: 6,
                  child: Container(
                    color: Colors.white12,
                    child: Column(
                      children: [
                        Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        activeButton = 1;
                                      });
                                    },
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty
                                          .resolveWith<Color>(
                                        (Set<WidgetState> states) {
                                          if (activeButton == 1) {
                                            return controlNotifier
                                                .gradientColors![controlNotifier
                                                    .gradientIndex]
                                                .first
                                                .withOpacity(0.9);
                                          } else {
                                            return controlNotifier
                                                .gradientColors![controlNotifier
                                                    .gradientIndex]
                                                .last
                                                .withOpacity(0.5);
                                          }
                                        },
                                      ),
                                    ),
                                    child: const Text('Caption'),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        activeButton = 2;
                                      });
                                    },
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty
                                          .resolveWith<Color>(
                                        (Set<WidgetState> states) {
                                          if (activeButton == 2) {
                                            return controlNotifier
                                                .gradientColors![controlNotifier
                                                    .gradientIndex]
                                                .first
                                                .withOpacity(0.9);
                                          } else {
                                            return controlNotifier
                                                .gradientColors![controlNotifier
                                                    .gradientIndex]
                                                .last
                                                .withOpacity(0.5);
                                          }
                                        },
                                      ),
                                    ),
                                    child: const Text('Filters'),
                                  ),
                                ),
                              ],
                            )),
                        Expanded(
                          flex: 5,
                          child: activeButton == 1
                              ? Captioner(
                                  controlNotifier: controlNotifier,
                                )
                              : const Filters(),
                        ),
                      ],
                    ),
                  ),
                )

                // /// center logo
                // if (controlNotifier.middleBottomWidget != null)
                //   Expanded(
                //     child: Center(
                //       child: Container(
                //           alignment: Alignment.bottomCenter,
                //           child: controlNotifier.middleBottomWidget),
                //     ),
                //   )
                // else
                //   Expanded(
                //     child: Center(
                //       child: Column(
                //         mainAxisSize: MainAxisSize.min,
                //         children: [
                //           Image.asset(
                //             'assets/images/instagram_logo.png',
                //             package: 'stories_editor',
                //             color: Colors.white,
                //             height: 42,
                //           ),
                //           const Text(
                //             'Stories Creator',
                //             style: TextStyle(
                //                 color: Colors.white38,
                //                 letterSpacing: 1.5,
                //                 fontSize: 9.2,
                //                 fontWeight: FontWeight.bold),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),

                // /// save final image to gallery
                // Expanded(
                //   child: Container(
                //     alignment: Alignment.centerRight,
                //     child: Transform.scale(
                //       scale: 0.9,
                //       child: AnimatedOnTapButton(
                //           onTap: () async {
                //             String pngUri;
                //             await takePicture(
                //                     contentKey: contentKey,
                //                     context: context,
                //                     saveToGallery: false)
                //                 .then((bytes) {
                //               if (bytes != null) {
                //                 pngUri = bytes;
                //                 onDone(pngUri);
                //               } else {}
                //             });
                //           },
                //           child: onDoneButtonStyle ??
                //               Container(
                //                 padding: const EdgeInsets.only(
                //                     left: 12, right: 5, top: 4, bottom: 4),
                //                 decoration: BoxDecoration(
                //                     borderRadius: BorderRadius.circular(15),
                //                     border: Border.all(
                //                         color: Colors.white, width: 1.5)),
                //                 child: const Row(
                //                     mainAxisSize: MainAxisSize.min,
                //                     children: [
                //                       Text(
                //                         'Share',
                //                         style: TextStyle(
                //                             color: Colors.white,
                //                             letterSpacing: 1.5,
                //                             fontSize: 16,
                //                             fontWeight: FontWeight.w400),
                //                       ),
                //                       Padding(
                //                         padding: EdgeInsets.only(left: 5),
                //                         child: Icon(
                //                           Icons.arrow_forward_ios,
                //                           color: Colors.white,
                //                           size: 15,
                //                         ),
                //                       ),
                //                     ]),
                //               )),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _preViewContainer({child}) {
    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(width: 1.4, color: Colors.white)),
      child: child,
    );
  }
}
