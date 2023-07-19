import 'package:flutter/material.dart';
import 'package:modal_gif_picker/modal_gif_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:stories_editor/src/presentation/utils/constants/app_enums.dart';

class EditableItem {
  /// delete
  bool deletePosition = false;

  GlobalKey itemKey = GlobalKey();

  /// item position
  Offset position = const Offset(0.0, 0.0);
  Offset focalPoint = const Offset(0.0, 0.0);
  double scale = 1;
  double rotation = 0;
  ItemType type = ItemType.text;

  /// text
  String text = '';
  List<String> textList = [];
  Color textColor = Colors.transparent;
  TextAlign textAlign = TextAlign.center;
  double fontSize = 20;
  int fontFamily = 0;
  int fontAnimationIndex = 0;
  Color backGroundColor = Colors.transparent;
  TextAnimationType animationType = TextAnimationType.none;

  /// Gif
  GiphyGif gif = GiphyGif(id: '0');

  /// video
  VideoPlayerController? videoController;
  double mediaHeight = 0.0;
  double mediaWidth = 0.0;
}
