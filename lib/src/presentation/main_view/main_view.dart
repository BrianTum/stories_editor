// ignore_for_file: must_be_immutable

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gallery_media_picker/gallery_media_picker.dart';
import 'package:mime/mime.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:stories_editor/src/domain/models/editable_items.dart';
import 'package:stories_editor/src/domain/models/painting_model.dart';
import 'package:stories_editor/src/domain/providers/notifiers/control_provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/draggable_widget_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/gradient_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/painting_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/scroll_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/text_editing_notifier.dart';
import 'package:stories_editor/src/presentation/bar_tools/bottom_tools.dart';
import 'package:stories_editor/src/presentation/bar_tools/top_tools.dart';
import 'package:stories_editor/src/presentation/draggable_items/delete_item.dart';
import 'package:stories_editor/src/presentation/draggable_items/draggable_widget.dart';
import 'package:stories_editor/src/presentation/painting_view/painting.dart';
import 'package:stories_editor/src/presentation/painting_view/widgets/sketcher.dart';
import 'package:stories_editor/src/presentation/text_editor_view/text_editor.dart';
import 'package:stories_editor/src/presentation/utils/constants/app_enums.dart';
import 'package:stories_editor/src/presentation/utils/modal_sheets.dart';
import 'package:stories_editor/src/presentation/widgets/animated_onTap_button.dart';
import 'package:stories_editor/src/presentation/widgets/scrollable_pageView.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';

import '../filters/model.dart';
import '../video_editor/video_editor.dart';

class MainView extends StatefulWidget {
  /// editor custom font families
  final List<String>? fontFamilyList;

  /// editor custom font families package
  final bool? isCustomFontList;

  /// editor custom color gradients
  final List<List<Color>>? gradientColors;

  /// editor custom logo
  final Widget? middleBottomWidget;

  /// on done
  final Function(String)? onDone;

  /// on done button Text
  final Widget? onDoneButtonStyle;

  /// on back pressed
  final Future<bool>? onBackPress;

  /// editor background color
  Color? editorBackgroundColor;

  /// gallery thumbnail quality
  final int? galleryThumbnailQuality;

  /// editor custom color palette list
  List<Color>? colorList;

  // share image file path
  final String? mediaPath;
  MainView({
    Key? key,
    required this.onDone,
    this.middleBottomWidget,
    this.colorList,
    this.isCustomFontList,
    this.fontFamilyList,
    this.gradientColors,
    this.onBackPress,
    this.onDoneButtonStyle,
    this.editorBackgroundColor,
    this.galleryThumbnailQuality,
    this.mediaPath,
  }) : super(key: key);

  @override
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  /// content container key
  final GlobalKey contentKey = GlobalKey();

  ///Editable item
  EditableItem? _activeItem;

  /// Gesture Detector listen changes
  Offset _initPos = const Offset(0, 0);
  Offset _currentPos = const Offset(0, 0);
  double _currentScale = 1;
  double _currentRotation = 0;

  /// delete position
  bool _isDeletePosition = false;
  bool _inAction = false;

  bool _processing = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      var _control = Provider.of<ControlNotifier>(context, listen: false);
      var _tempItemProvider =
          Provider.of<DraggableWidgetNotifier>(context, listen: false);

      /// initialize control variable provider
      // _control.giphyKey = widget.giphyKey;
      // _control.middleBottomWidget = widget.middleBottomWidget;
      // _control.isCustomFontList = widget.isCustomFontList ?? false;
      if (widget.mediaPath != null) {
        _processing = true;
        String mimeStr = lookupMimeType(widget.mediaPath!)!;
        var fileType = mimeStr.split('/');
        if (fileType[0] == "image") {
          _control.mediaPath = widget.mediaPath!;

          if (mounted && _control.mediaPath.isNotEmpty) {
            _tempItemProvider.draggableWidget.insert(
                0,
                EditableItem()
                  ..type = ItemType.image
                  ..position = const Offset(0.0, 0));
          }

          Size size = await getImageDimensions(File(_control.mediaPath));

          _tempItemProvider.draggableWidget.first.mediaWidth = size.width;
          _tempItemProvider.draggableWidget.first.mediaHeight = size.height;
          setState(() {
            _processing = false;
          });
        } else if (fileType[0] == "video") {
          _control.originalVideoPath = widget.mediaPath!;

          _control.videoEditController = VideoEditorController.file(
            File(widget.mediaPath!),
            minDuration: const Duration(seconds: 1),
            maxDuration: const Duration(seconds: 30),
          );

          await _control.videoEditController.initialize().then((_) async {
            await Navigator.push(
                context,
                MaterialPageRoute<List>(
                  builder: (context) => VideoEditor(
                    controlNotifier: _control,
                    itemProvider: _tempItemProvider,
                  ),
                )).then((value) async {
              debugPrint("returned value == $value == ${_control.mediaPath}");

              if (value == null) {
                // scrollProvider.pageController.animateToPage(1,
                //     duration: const Duration(milliseconds: 5),
                //     curve: Curves.easeIn);
              } else {
                _control.videoPath = value[0];
                _control.mediaPath = value[1];

                var videoController =
                    VideoPlayerController.file(File(_control.videoPath));
                await videoController.initialize();

                _tempItemProvider.draggableWidget.insert(
                    0,
                    EditableItem()
                      ..type = ItemType.video
                      ..position = const Offset(0.0, 0));

                _tempItemProvider.draggableWidget.first.videoController =
                    videoController;
              }
            });
          }).catchError((error) {
            // handle minumum duration bigger than video duration error
            Navigator.pop(context);
          }, test: (e) => e is VideoMinDurationError);
          setState(() {
            _processing = false;
          });
        } else {
          return;
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    // var _control = Provider.of<ControlNotifier>(context, listen: false);
    // _control.videoEditController.dispose();
    // print("dispose");
  }

  Future<Size> getImageDimensions(File imageFile) async {
    final Uint8List bytes = await imageFile.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.Image image = (await codec.getNextFrame()).image;
    final int width = image.width;
    final int height = image.height;
    return Size(width.toDouble(), height.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final ScreenUtil screenUtil = ScreenUtil();
    return Scaffold(
      body: PopScope(
        onPopInvoked: (didPop) {
          _popScope;
        },
        child: Material(
          color: widget.editorBackgroundColor == Colors.transparent
              ? Colors.black
              : widget.editorBackgroundColor ?? Colors.black,
          child: Consumer6<
              ControlNotifier,
              DraggableWidgetNotifier,
              ScrollNotifier,
              GradientNotifier,
              PaintingNotifier,
              TextEditingNotifier>(
            builder: (context, controlNotifier, itemProvider, scrollProvider,
                colorProvider, paintingProvider, editingProvider, child) {
              return SafeArea(
                //top: false,
                child: _processing == true
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : ScrollablePageView(
                        scrollPhysics: controlNotifier.mediaPath.isEmpty &&
                            itemProvider.draggableWidget.isEmpty &&
                            !controlNotifier.isPainting &&
                            !controlNotifier.isTextEditing,
                        pageController: scrollProvider.pageController,
                        gridController: scrollProvider.gridController,
                        mainView: Column(
                          children: [
                            Expanded(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ///gradient container
                                  /// this container will contain all widgets(image/texts/draws/sticker)
                                  /// wrap this widget with coloredFilter
                                  GestureDetector(
                                    onScaleStart: (details) {
                                      controlNotifier.isScaling =
                                          !controlNotifier.isScaling;
                                      _onScaleStart(details);
                                    },
                                    onScaleUpdate: _onScaleUpdate,
                                    onScaleEnd: (details) {
                                      controlNotifier.isScaling =
                                          !controlNotifier.isScaling;
                                      _onScaleEnded(details);
                                    },
                                    onTapUp: (TapUpDetails details) {
                                      double screenWidth =
                                          MediaQuery.of(context).size.width;
                                      double tapPosition =
                                          details.globalPosition.dx;

                                      controlNotifier.isTextEdit = false;

                                      if (tapPosition < screenWidth / 2) {
                                        // Left part of the screen was tapped
                                        if (controlNotifier.mediaPath == "") {
                                          if (mounted &&
                                              controlNotifier
                                                  .mediaPath.isEmpty) {
                                            scrollProvider.pageController
                                                .animateToPage(1,
                                                    duration: const Duration(
                                                        milliseconds: 200),
                                                    curve: Curves.ease);
                                          }
                                        } else {
                                          if (controlNotifier.gradientIndex ==
                                              0) {
                                            setState(() {
                                              controlNotifier.gradientIndex =
                                                  controlNotifier
                                                          .gradientColors!
                                                          .length -
                                                      1;
                                            });
                                          } else {
                                            setState(() {
                                              controlNotifier.gradientIndex -=
                                                  1;
                                              if (controlNotifier
                                                  .mediaPath.isNotEmpty) {
                                                controlNotifier.isVideoTheme =
                                                    false;
                                              }
                                            });
                                          }
                                        }
                                      } else {
                                        // Right part of the screen was tapped
                                        if (controlNotifier.mediaPath == "") {
                                          if (mounted &&
                                              controlNotifier
                                                  .mediaPath.isEmpty) {
                                            scrollProvider.pageController
                                                .animateToPage(1,
                                                    duration: const Duration(
                                                        milliseconds: 200),
                                                    curve: Curves.ease);
                                          }
                                        } else {
                                          if (controlNotifier.gradientIndex >=
                                              controlNotifier
                                                      .gradientColors!.length -
                                                  1) {
                                            setState(() {
                                              controlNotifier.gradientIndex = 0;
                                            });
                                          } else {
                                            setState(() {
                                              controlNotifier.gradientIndex +=
                                                  1;
                                              if (controlNotifier
                                                  .mediaPath.isNotEmpty) {
                                                controlNotifier.isVideoTheme =
                                                    false;
                                              }
                                            });
                                          }
                                        }
                                      }
                                    },
                                    onTap: () {
                                      // controlNotifier.isTextEditing =
                                      //     !controlNotifier.isTextEditing;
                                    },
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(25),
                                        child: SizedBox(
                                          width: 396,
                                          height: 704,
                                          child: RepaintBoundary(
                                            key: contentKey,
                                            child: ColorFiltered(
                                              colorFilter:
                                                  CustomColorFilters.getFilter(
                                                      FilterType.values[
                                                          controlNotifier
                                                              .filterIndex]),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                decoration: BoxDecoration(
                                                  gradient: controlNotifier
                                                          .mediaPath.isEmpty
                                                      ? LinearGradient(
                                                          colors: controlNotifier
                                                                  .gradientColors![
                                                              controlNotifier
                                                                  .gradientIndex],
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                        )
                                                      : controlNotifier
                                                                  .isVideoTheme ==
                                                              false
                                                          ? LinearGradient(
                                                              colors: controlNotifier
                                                                      .gradientColors![
                                                                  controlNotifier
                                                                      .gradientIndex],
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                            )
                                                          : LinearGradient(
                                                              colors: [
                                                                colorProvider
                                                                    .color1,
                                                                colorProvider
                                                                    .color2,
                                                                colorProvider
                                                                    .color3,
                                                                colorProvider
                                                                    .color4,
                                                                colorProvider
                                                                    .color5,
                                                                colorProvider
                                                                    .color6,
                                                              ],
                                                              begin: Alignment
                                                                  .topCenter,
                                                              end: Alignment
                                                                  .bottomCenter,
                                                            ),
                                                ),
                                                child: GestureDetector(
                                                  onScaleStart: (details) {
                                                    controlNotifier.isScaling =
                                                        !controlNotifier
                                                            .isScaling;
                                                    _onScaleStart(details);
                                                  },
                                                  onScaleUpdate: (details) {
                                                    _onScaleUpdate(details);
                                                  },
                                                  onScaleEnd: (details) {
                                                    controlNotifier.isScaling =
                                                        !controlNotifier
                                                            .isScaling;
                                                    _onScaleEnded(details);
                                                  },
                                                  child: Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      /// in this case photo view works as a main background container to manage
                                                      /// the gestures of all movable items.
                                                      PhotoView.customChild(
                                                        child: Container(),
                                                        backgroundDecoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .transparent,
                                                          border: Border.all(
                                                            color: Colors
                                                                .white, // Set the color of the border
                                                            width:
                                                                .0, // Set the width of the border
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  12.0), // Set the border radius
                                                        ),
                                                      ),

                                                      ///list items
                                                      ...itemProvider
                                                          .draggableWidget
                                                          .map((editableItem) {
                                                        return DraggableWidget(
                                                          context: context,
                                                          draggableWidget:
                                                              editableItem,
                                                          onPointerDown:
                                                              (details) {
                                                            _updateItemPosition(
                                                              editableItem,
                                                              details,
                                                            );
                                                          },
                                                          onPointerUp:
                                                              (details) {
                                                            _deleteItemOnCoordinates(
                                                              editableItem,
                                                              details,
                                                            );
                                                          },
                                                          onPointerMove:
                                                              (details) {
                                                            _deletePosition(
                                                              editableItem,
                                                              details,
                                                            );
                                                          },
                                                          contentKey:
                                                              contentKey,
                                                        );
                                                      }),

                                                      /// finger paint
                                                      IgnorePointer(
                                                        ignoring: true,
                                                        child: Align(
                                                          alignment: Alignment
                                                              .topCenter,
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          25),
                                                            ),
                                                            child:
                                                                RepaintBoundary(
                                                              child: SizedBox(
                                                                width: screenUtil
                                                                    .screenWidth,
                                                                child: StreamBuilder<
                                                                    List<
                                                                        PaintingModel>>(
                                                                  stream: paintingProvider
                                                                      .linesStreamController
                                                                      .stream,
                                                                  builder: (context,
                                                                      snapshot) {
                                                                    return CustomPaint(
                                                                      painter:
                                                                          Sketcher(
                                                                        lines: paintingProvider
                                                                            .lines,
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  /// middle text
                                  if (itemProvider.draggableWidget.isEmpty &&
                                      !controlNotifier.isTextEditing &&
                                      paintingProvider.lines.isEmpty)
                                    IgnorePointer(
                                      ignoring: true,
                                      child: Align(
                                        alignment: const Alignment(0, -0.1),
                                        child: Text('Tap to pick media',
                                            style: TextStyle(
                                                fontFamily: 'Alegreya',
                                                package: 'stories_editor',
                                                fontWeight: FontWeight.w500,
                                                fontSize: 30,
                                                color: Colors.white
                                                    .withOpacity(0.5),
                                                shadows: <Shadow>[
                                                  Shadow(
                                                      offset: const Offset(
                                                          1.0, 1.0),
                                                      blurRadius: 3.0,
                                                      color: Colors.black45
                                                          .withOpacity(0.3))
                                                ])),
                                      ),
                                    ),

                                  /// top tools
                                  Visibility(
                                    visible: !controlNotifier.isTextEditing &&
                                        !controlNotifier.isPainting,
                                    child: Align(
                                        alignment: Alignment.topCenter,
                                        child: TopTools(
                                          contentKey: contentKey,
                                          context: context,
                                        )),
                                  ),

                                  /// delete item when the item is in position
                                  DeleteItem(
                                    activeItem: _activeItem,
                                    animationsDuration:
                                        const Duration(milliseconds: 300),
                                    isDeletePosition: _isDeletePosition,
                                  ),

                                  /// show text editor
                                  Visibility(
                                    visible: controlNotifier.isTextEditing,
                                    child: TextEditor(
                                      context: context,
                                    ),
                                  ),

                                  /// show painting sketch
                                  Visibility(
                                    visible: controlNotifier.isPainting,
                                    child: const Painting(),
                                  ),

                                  // Visibility(
                                  //   visible: !controlNotifier.isTextEditing &&
                                  //       !controlNotifier.isScaling,
                                  //   child: Align(
                                  //     alignment: Alignment.bottomCenter,
                                  //     child: Container(
                                  //       height:
                                  //           MediaQuery.of(context).size.height * 0.1,
                                  //       color: Colors.transparent,
                                  //       child: const Filters(),
                                  //     ),
                                  //   ),
                                  // )
                                ],
                              ),
                            ),

                            /// bottom tools
                            if (!kIsWeb &&
                                !controlNotifier.isTextEditing &&
                                !controlNotifier.isScaling)
                              BottomTools(
                                contentKey: contentKey,
                                onDone: (bytes) {
                                  setState(() {
                                    widget.onDone!(bytes);
                                  });
                                },
                                onDoneButtonStyle: widget.onDoneButtonStyle,
                                editorBackgroundColor:
                                    widget.editorBackgroundColor,
                              ),
                          ],
                        ),
                        gallery: GalleryMediaPicker(
                          mediaPickerParams: MediaPickerParamsModel(
                            gridViewController: scrollProvider.gridController,
                            thumbnailQuality: 300,
                            singlePick: true,
                            appBarHeight: 100,
                            albumDividerColor: Colors.white30,
                            appBarIconColor: Colors.white,
                            gridViewPhysics:
                                itemProvider.draggableWidget.isEmpty
                                    ? const NeverScrollableScrollPhysics()
                                    : const ScrollPhysics(),
                            appBarLeadingWidget: Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 15, right: 15),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: AnimatedOnTapButton(
                                  onTap: () {
                                    scrollProvider.pageController.animateToPage(
                                        0,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeIn);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.2,
                                        )),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          pathList: (path) async {
                            debugPrint(path.first.path);
                            if (mounted) {
                              if (path.first.type == "image") {
                                controlNotifier.mediaPath =
                                    path.first.path.toString();

                                if (mounted &&
                                    controlNotifier.mediaPath.isNotEmpty) {
                                  itemProvider.draggableWidget.insert(
                                      0,
                                      EditableItem()
                                        ..type = ItemType.image
                                        ..position = const Offset(0.0, 0));
                                }

                                Size size = await getImageDimensions(
                                    File(controlNotifier.mediaPath));

                                itemProvider.draggableWidget.first.mediaWidth =
                                    size.width;
                                itemProvider.draggableWidget.first.mediaHeight =
                                    size.height;

                                scrollProvider.pageController.animateToPage(0,
                                    duration: const Duration(milliseconds: 5),
                                    curve: Curves.easeIn);
                              } else if (path.first.type == "video") {
                                controlNotifier.originalVideoPath =
                                    path.first.path;

                                controlNotifier.videoEditController =
                                    VideoEditorController.file(
                                  File(path.first.path.toString()),
                                  minDuration: const Duration(seconds: 1),
                                  maxDuration: const Duration(seconds: 30),
                                );

                                await controlNotifier.videoEditController
                                    .initialize()
                                    .then((_) async {
                                  await Navigator.push(
                                      context,
                                      MaterialPageRoute<List>(
                                        builder: (context) => VideoEditor(
                                          controlNotifier: controlNotifier,
                                          itemProvider: itemProvider,
                                        ),
                                      )).then((value) async {
                                    debugPrint(
                                        "returned value == $value == ${controlNotifier.mediaPath}");

                                    if (value == null) {
                                      scrollProvider.pageController
                                          .animateToPage(1,
                                              duration: const Duration(
                                                  milliseconds: 5),
                                              curve: Curves.easeIn);
                                    } else {
                                      controlNotifier.videoPath = value[0];
                                      controlNotifier.mediaPath = value[1];

                                      var videoController =
                                          VideoPlayerController.file(
                                              File(controlNotifier.videoPath));
                                      await videoController.initialize();

                                      itemProvider.draggableWidget.insert(
                                          0,
                                          EditableItem()
                                            ..type = ItemType.video
                                            ..position = const Offset(0.0, 0));

                                      itemProvider.draggableWidget.first
                                          .videoController = videoController;

                                      setState(() {});

                                      scrollProvider.pageController
                                          .animateToPage(0,
                                              duration: const Duration(
                                                  milliseconds: 5),
                                              curve: Curves.easeIn);
                                    }
                                  });
                                }).catchError((error) {
                                  // handle minumum duration bigger than video duration error
                                  Navigator.pop(context);
                                }, test: (e) => e is VideoMinDurationError);
                              } else {
                                return;
                              }
                            } else {
                              return;
                            }
                          },
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// validate pop scope gesture
  Future<bool> _popScope() async {
    final controlNotifier =
        Provider.of<ControlNotifier>(context, listen: false);

    /// change to false text editing
    if (controlNotifier.isTextEditing) {
      controlNotifier.isTextEditing = !controlNotifier.isTextEditing;
      return false;
    }

    /// change to false painting
    else if (controlNotifier.isPainting) {
      controlNotifier.isPainting = !controlNotifier.isPainting;
      return false;
    }

    /// show close dialog
    else if (!controlNotifier.isTextEditing && !controlNotifier.isPainting) {
      return widget.onBackPress ??
          exitDialog(context: context, contentKey: contentKey);
    }
    return false;
  }

  /// start item scale
  void _onScaleStart(ScaleStartDetails details) {
    if (_activeItem == null) {
      return;
    }
    _initPos = details.focalPoint;
    _currentPos = _activeItem!.position;
    _currentScale = _activeItem!.scale;
    _currentRotation = _activeItem!.rotation;
  }

  void _onScaleEnded(ScaleEndDetails details) {}

  /// update item scale
  void _onScaleUpdate(ScaleUpdateDetails details) {
    final ScreenUtil screenUtil = ScreenUtil();
    if (_activeItem == null) {
      return;
    }
    final delta = details.focalPoint - _initPos;

    final left = (delta.dx / screenUtil.screenWidth) + _currentPos.dx;
    final top = (delta.dy / screenUtil.screenHeight) + _currentPos.dy;

    setState(() {
      _activeItem!.position = Offset(left, top);
      _activeItem!.rotation = details.rotation + _currentRotation;
      _activeItem!.scale = details.scale * _currentScale;
    });
  }

  /// active delete widget with offset position
  void _deletePosition(EditableItem item, PointerMoveEvent details) {
    if (item.type == ItemType.text &&
        item.position.dy >= 0.75.h &&
        item.position.dx >= -0.4.w &&
        item.position.dx <= 0.2.w) {
      setState(() {
        _isDeletePosition = true;
        item.deletePosition = true;
      });
    } else if (item.type == ItemType.gif &&
        item.position.dy >= 0.62.h &&
        item.position.dx >= -0.35.w &&
        item.position.dx <= 0.15) {
      setState(() {
        _isDeletePosition = true;
        item.deletePosition = true;
      });
    } else {
      setState(() {
        _isDeletePosition = false;
        item.deletePosition = false;
      });
    }
  }

  /// delete item widget with offset position
  void _deleteItemOnCoordinates(EditableItem item, PointerUpEvent details) {
    var _itemProvider =
        Provider.of<DraggableWidgetNotifier>(context, listen: false)
            .draggableWidget;
    _inAction = false;
    if (item.type == ItemType.image) {
    } else if (item.type == ItemType.text &&
            item.position.dy >= 0.75.h &&
            item.position.dx >= -0.4.w &&
            item.position.dx <= 0.2.w ||
        item.type == ItemType.gif &&
            item.position.dy >= 0.62.h &&
            item.position.dx >= -0.35.w &&
            item.position.dx <= 0.15) {
      setState(() {
        _itemProvider.removeAt(_itemProvider.indexOf(item));
        HapticFeedback.heavyImpact();
      });
    } else {
      setState(() {
        _activeItem = null;
      });
    }
    setState(() {
      _activeItem = null;
    });
  }

  /// update item position, scale, rotation
  void _updateItemPosition(EditableItem item, PointerDownEvent details) {
    if (_inAction) {
      return;
    }

    _inAction = true;
    _activeItem = item;
    _initPos = details.position;
    _currentPos = item.position;
    _currentScale = item.scale;
    _currentRotation = item.rotation;

    /// set vibrate
    HapticFeedback.lightImpact();
  }
}
