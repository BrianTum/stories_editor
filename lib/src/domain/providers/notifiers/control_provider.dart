import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stories_editor/src/presentation/utils/constants/app_colors.dart';
import 'package:stories_editor/src/presentation/utils/constants/font_family.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';

class ControlNotifier extends ChangeNotifier {
  String _giphyKey = '';

  /// is required add your giphy API KEY
  String get giphyKey => _giphyKey;
  set giphyKey(String key) {
    _giphyKey = key;
    notifyListeners();
  }

  int _filterIndex = 0;

  /// current filter index
  int get filterIndex => _filterIndex;

  /// get current filter index
  set filterIndex(int index) {
    /// set new current filter index
    _filterIndex = index;
    notifyListeners();
  }

  int _gradientIndex =
      Random().nextInt(AppColors.gradientBackgroundColors.length);

  /// current gradient index
  int get gradientIndex => _gradientIndex;

  /// get current gradient index
  set gradientIndex(int index) {
    /// set new current gradient index
    _gradientIndex = index;
    notifyListeners();
  }

  bool _isCaptioning = false;

  /// is text editor open
  bool get isCaptioning => _isCaptioning;

  /// get bool if is text editing
  set isCaptioning(bool val) {
    /// set bool if is text editing
    _isCaptioning = val;
    notifyListeners();
  }

  bool _isTextEdit = false;

  /// is text editor open
  bool get isTextEdit => _isTextEdit;

  /// get bool if is text editing
  set isTextEdit(bool val) {
    /// set bool if is text editing
    _isTextEdit = val;
    notifyListeners();
  }

  bool _isTextEditing = false;

  /// is text editor open
  bool get isTextEditing => _isTextEditing;

  /// get bool if is text editing
  set isTextEditing(bool val) {
    /// set bool if is text editing
    _isTextEditing = val;
    notifyListeners();
  }

  TextEditingController _textEditingController = TextEditingController();

  TextEditingController get textEditingController => _textEditingController;
  set textEditingController(TextEditingController text) {
    _textEditingController = text;
    notifyListeners();
  }

  bool _isScaling = false;

  /// is text editor open
  bool get isScaling => _isScaling;

  /// get bool if is text editing
  set isScaling(bool val) {
    /// set bool if is text editing
    _isScaling = val;
    notifyListeners();
  }

  bool _isPainting = false;

  /// is painter sketcher open
  bool get isPainting => _isPainting;
  set isPainting(bool painting) {
    _isPainting = painting;
    notifyListeners();
  }

  List<String>? _fontList = AppFonts.fontFamilyList;

  /// here you can define your own font family list
  List<String>? get fontList => _fontList;
  set fontList(List<String>? fonts) {
    _fontList = fonts;
    notifyListeners();
  }

  bool _isVideoTheme = true;

  /// if you add your custom list is required to specify your app package
  bool get isVideoTheme => _isVideoTheme;
  set isVideoTheme(bool key) {
    _isVideoTheme = key;
    notifyListeners();
  }

  VideoEditorController _videoEditController = VideoEditorController.file(
    File(""),
    minDuration: const Duration(seconds: 1),
    maxDuration: const Duration(seconds: 30),
  );

  VideoEditorController get videoEditController => _videoEditController;
  set videoEditController(VideoEditorController controller) {
    _videoEditController = controller;
    notifyListeners();
  }

  bool _isCustomFontList = false;

  /// if you add your custom list is required to specify your app package
  bool get isCustomFontList => _isCustomFontList;
  set isCustomFontList(bool key) {
    _isCustomFontList = key;
    notifyListeners();
  }

  List<List<Color>>? _gradientColors = AppColors.gradientBackgroundColors;

  /// here you can define your own background gradients
  List<List<Color>>? get gradientColors => _gradientColors;
  set gradientColors(List<List<Color>>? color) {
    _gradientColors = color;
    notifyListeners();
  }

  Widget? _middleBottomWidget;

  /// you can add a custom widget on the bottom
  Widget? get middleBottomWidget => _middleBottomWidget;
  set middleBottomWidget(Widget? widget) {
    _middleBottomWidget = widget;
    notifyListeners();
  }

  Future<bool>? _exitDialogWidget;

  /// you can create you own exit window
  Future<bool>? get exitDialogWidget => _exitDialogWidget;
  set exitDialogWidget(Future<bool>? widget) {
    _exitDialogWidget = widget;
    notifyListeners();
  }

  List<double>? _clippers = [0.0, 0.0, 0.0, 0.0];

  /// you can add your own color palette list
  List<double>? get clippersList => _clippers;
  set clippersList(List<double>? clips) {
    _clippers = clips;
    notifyListeners();
  }

  List<Color>? _colorList = AppColors.defaultColors;

  /// you can add your own color palette list
  List<Color>? get colorList => _colorList;
  set colorList(List<Color>? value) {
    _colorList = value;
    notifyListeners();
  }

  /// get asset path
  String _mediaPath = '';
  String get mediaPath => _mediaPath;
  set mediaPath(String media) {
    _mediaPath = media;
    notifyListeners();
  }

  /// get asset path
  String _originalVideoPath = '';
  String get originalVideoPath => _originalVideoPath;
  set originalVideoPath(String path) {
    _originalVideoPath = path;
    notifyListeners();
  }

  /// get video thumb path
  String _videoPath = '';
  String get videoPath => _videoPath;
  set videoPath(String media) {
    _videoPath = media;
    notifyListeners();
  }

  /// get video thumb path
  String _croppedVideoPath = '';
  String get croppedVideoPath => _croppedVideoPath;
  set croppedVideoPath(String media) {
    _croppedVideoPath = media;
    notifyListeners();
  }

  String _textCaption = 'Tap here to enter caption';
  String get textCaption => _textCaption;
  set textCaption(String caption) {
    _textCaption = caption;
    notifyListeners();
  }

  bool _isPhotoFilter = false;
  bool get isPhotoFilter => _isPhotoFilter;
  set isPhotoFilter(bool filter) {
    _isPhotoFilter = filter;
    notifyListeners();
  }
}
