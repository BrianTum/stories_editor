// ignore_for_file: unused_local_variable

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

import '../../presentation/filters/model.dart';
// import '../../presentation/utils/constants/app_enums.dart';
import '../../presentation/video_editor/widgets/export_result.dart';
import '../models/video_dimensions_list.dart';
import '../providers/notifiers/control_provider.dart';
import '../providers/notifiers/draggable_widget_notifier.dart';
import '../providers/notifiers/gradient_notifier.dart';

Future<Map<String, Object>> saveVideo(
    ControlNotifier controlNotifier,
    DraggableWidgetNotifier itemProvider,
    GradientNotifier colorProvider,
    GlobalKey contentKey,
    BuildContext context) async {
  var color1 = controlNotifier.mediaPath.isEmpty
      ? controlNotifier.gradientColors![controlNotifier.gradientIndex].first
      : colorProvider.color1;
  var color2 = controlNotifier.mediaPath.isEmpty
      ? controlNotifier.gradientColors![controlNotifier.gradientIndex].last
      : colorProvider.color2;

  List<Color> colors = controlNotifier.isVideoTheme
      ? [
          colorProvider.color1,
          colorProvider.color2,
          colorProvider.color3,
          colorProvider.color4,
          colorProvider.color5,
          colorProvider.color6
        ]
      : controlNotifier.gradientColors![controlNotifier.gradientIndex];

  var backgroundImage = await createGradientImage(colors);

  ColorFilter? filter = CustomColorFilters.getFilter(
      FilterType.values[controlNotifier.filterIndex]);

  String filterString = generateFFmpegColorFilter(filter);

  int duration = itemProvider
      .draggableWidget.first.videoController!.value.duration.inSeconds;

  var rotation = itemProvider.draggableWidget.first.rotation;

  var heightRaw = itemProvider.draggableWidget.first.mediaHeight *
      itemProvider.draggableWidget.first.scale;

  var height = roundToNearestEven(heightRaw);

  var widthRaw = itemProvider.draggableWidget.first.mediaWidth *
      itemProvider.draggableWidget.first.scale;

  debugPrint(
      "width raw $widthRaw and height raw $heightRaw aspect ratio is ${widthRaw / heightRaw}");

  var width = roundToNearestEven(widthRaw);

  RenderBox parentBox =
      contentKey.currentContext!.findRenderObject() as RenderBox;
  RenderBox childBox = itemProvider
      .draggableWidget.first.itemKey.currentContext!
      .findRenderObject() as RenderBox;

  Offset childOffset = childBox.localToGlobal(Offset.zero, ancestor: parentBox);

  var centerX = childOffset.dx;
  var centerY = childOffset.dy;

  double a = centerX; // New top-left X position
  double b = centerY; // New top-left Y position
  double lengths = widthRaw; // Length of the rectangle
  double widths = -heightRaw; // Width of the rectangle

  debugPrint("a is $a b is $b lengths $lengths and widths is $widths");

  List<Offset> rotatedCorners =
      getRotatedCornerOffsets(a, b, lengths, widths, rotation);

  Offset minOffset = getMinOffset(rotatedCorners);

  double originalWidth = 396;
  double originalHeight = 704;

  debugPrint(
      "input video aspect ratio is ${itemProvider.draggableWidget.first.videoController!.value.aspectRatio}");

  var inputAspectRatio =
      itemProvider.draggableWidget.first.videoController!.value.aspectRatio;
  var scalingRatio = itemProvider.draggableWidget.first.scale;

  var extraScaling = 1.0;

  if (widthRaw < originalWidth || heightRaw < originalHeight) {
    if (lengths > widths) {
      extraScaling = lengths / originalWidth;
    } else {
      extraScaling = widths / originalHeight;
    }
  }

  Map<int, int> inputMap = {
    itemProvider.draggableWidget.first.videoController!.value.size.width
            .toInt():
        itemProvider.draggableWidget.first.videoController!.value.size.height
            .toInt()
  };

  Map<int, int>? selectedPair =
      selectSuitableKeyValuePair(inputMap, deviceDimensionsList);

  debugPrint("input maps $inputMap : Selected Pair: $selectedPair");

  // New view dimensions
  double newWidth = selectedPair!.keys.first.toDouble();
  double newHeight = selectedPair.values.first.toDouble();

  var pX = (minOffset.dx / originalWidth) * newWidth;
  var pY = (minOffset.dy / originalHeight) * newHeight;

  var finalVideoWidth = 0.0;
  var finalVideoHeight = 0.0;

  if (inputMap.keys.first > inputMap.values.first) {
    if (rotation == 0.0) {
      finalVideoWidth = newWidth * scalingRatio * extraScaling;
      finalVideoHeight = finalVideoWidth / inputAspectRatio;
    } else {
      finalVideoWidth = newWidth * extraScaling;
      finalVideoHeight = finalVideoWidth / inputAspectRatio;
    }
  } else {
    if (rotation == 0.0) {
      debugPrint("heigth is greater than with zero rotation is $rotation ");
      finalVideoWidth = newWidth * scalingRatio * extraScaling;
      finalVideoHeight = finalVideoWidth / inputAspectRatio;
      // finalVideoWidth = finalVideoHeight * inputAspectRatio;
    } else {
      debugPrint("heigth is greater than with some rotation of $rotation ");
      finalVideoWidth = newWidth * extraScaling;
      finalVideoHeight = finalVideoWidth / inputAspectRatio;
    }
  }

  debugPrint(
      "final video width params are : ${inputMap.keys.first} : $scalingRatio : $extraScaling}");
  debugPrint(
      "final video height params are : ${inputMap.values.first} : $scalingRatio : $extraScaling}");

  debugPrint(
      "final video width $finalVideoWidth : final video height $finalVideoHeight and aspect ratio ${finalVideoWidth / finalVideoHeight}");

  var data = {
    'type': "video",
    'backgroundImage': backgroundImage,
    'videoPath': controlNotifier.videoPath,
    'filterString': filterString,
    'duration': duration,
    'frameWidth': selectedPair.keys.first,
    'frameHeight': selectedPair.values.first,
    'videoHeight': finalVideoHeight,
    'videoWidth': finalVideoWidth,
    'centerX': centerX,
    'centerY': centerY,
    'rotation': rotation,
    'minOffsetDx': pX,
    'minOffsetDy': pY,
    'context': context,
    'caption': controlNotifier.textCaption
  };

  return data;

  // generateGradientVideo(
  //     backgroundImage,
  //     controlNotifier.videoPath,
  //     filterString,
  //     duration,
  //     height,
  //     width,
  //     centerX,
  //     centerY,
  //     rotation,
  //     minOffset.dx,
  //     minOffset.dy,
  //     context);
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

Offset getMinOffset(List<Offset> offsets) {
  double minX = double.infinity;
  double minY = double.infinity;

  for (Offset offset in offsets) {
    if (offset.dx < minX) {
      minX = offset.dx;
    }
    if (offset.dy < minY) {
      minY = offset.dy;
    }
  }

  return Offset(minX, minY);
}

List<Offset> getRotatedCornerOffsets(
    double a, double b, double l, double w, double r) {
  List<Offset> corners = [];

  double cosR = cos(r);
  double sinR = sin(r);

  // Top-left corner
  corners.add(Offset(a, b));

  // Top-right corner
  double xTR = a + (w * sinR);
  double yTR = b - (w * cosR);
  corners.add(Offset(xTR, yTR));

  // Bottom-right corner
  double xBR = xTR + (l * cosR);
  double yBR = yTR + (l * sinR);
  corners.add(Offset(xBR, yBR));

  // Bottom-left corner
  double xBL = a + (l * cosR);
  double yBL = b + (l * sinR);
  corners.add(Offset(xBL, yBL));

  return corners;
}

int roundToNearestEven(double value) {
  int roundedValue = value.round();

  if (roundedValue.isOdd) {
    roundedValue -= 1;
  }

  return roundedValue;
}

Future<String> createGradientImage(List<Color> colors) async {
  var gradient = LinearGradient(
    colors: colors,
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final screenUtil = ScreenUtil();

  const size = Size(396, 704); // Specify the desired size of the image
  final rect = Offset.zero & size;

  final paint = Paint()..shader = gradient.createShader(rect);
  canvas.drawRect(rect, paint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());

  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/gradient_image.png';

  File(filePath).writeAsBytes(bytes);

  // await ImageGallerySaver.saveImage(bytes,
  //     quality: 100, name: "stories_creator${DateTime.now()}.png");

  return filePath;
}

String flutterToFFmpegColorFilter(List<double> matrix) {
  // Remove the last 11 values to fit FFmpeg syntax
  List<double> modifiedMatrix = matrix.sublist(0, 9);

  // Generate the FFmpeg color filter string
  String colorFilterString = "'${modifiedMatrix.join(",")}'";
  return colorFilterString;
}

// String generateFFmpegColorFilter(ColorFilter? filter) {
//   String valuesString = filter
//       .toString()
//       .replaceAll("ColorFilter.matrix([", "")
//       .replaceAll("])", "");

//   List<String> valuesList = valuesString.split(", ");

//   List<double> matrix = valuesList.map((value) => double.parse(value)).toList();

//   final rr = matrix[0].toStringAsFixed(2);
//   final rb = matrix[1].toStringAsFixed(2);
//   final gr = matrix[5].toStringAsFixed(2);
//   final gb = matrix[6].toStringAsFixed(2);
//   final br = matrix[10].toStringAsFixed(2);
//   final bb = matrix[11].toStringAsFixed(2);

//   return 'colorchannelmixer=rr=$rr:rb=$rb:gr=$gr:gb=$gb:br=$br:bb=$bb';
// }

String generateFFmpegColorFilter(ColorFilter? filter) {
  String valuesString = filter
      .toString()
      .replaceAll("ColorFilter.matrix([", "")
      .replaceAll("])", "");

  List<String> valuesList = valuesString.split(", ");

  List<double> matrix = valuesList.map((value) => double.parse(value)).toList();

  final rr = matrix[0].toStringAsFixed(3);
  final rg = matrix[1].toStringAsFixed(3);
  final rb = matrix[2].toStringAsFixed(3);
  final ra = matrix[3].toStringAsFixed(3);
  final gr = matrix[5].toStringAsFixed(3);
  final gg = matrix[6].toStringAsFixed(3);
  final gb = matrix[7].toStringAsFixed(3);
  final ga = matrix[8].toStringAsFixed(3);
  final br = matrix[10].toStringAsFixed(3);
  final bg = matrix[11].toStringAsFixed(3);
  final bb = matrix[12].toStringAsFixed(3);
  final ba = matrix[13].toStringAsFixed(3);

  return 'colorchannelmixer=$rr:$rg:$rb:$ra:$gr:$gg:$gb:$ga:$br:$bg:$bb:$ba';
}

Future<void> generateGradientVideo(
    String background,
    String videoPath,
    String filter,
    int duration,
    mediaHeight,
    mediaWidth,
    centerX,
    centerY,
    rotation,
    overlayX,
    overlayY,
    BuildContext context) async {
  final screenUtil = ScreenUtil();

  // Specify the output file path
  final String dir = (await getTemporaryDirectory()).path;
  DateTime now = DateTime.now();
  String timestamp = now.microsecondsSinceEpoch.toString();
  String outputPath = '$dir/stories_creator_$timestamp.mp4';

  String ffmpegCommand =
      '-loop 1 -i "$background" -i "$videoPath" -filter_complex "[0:v]$filter, scale=396:704[bg];[1:v]$filter, scale=$mediaWidth:$mediaHeight, setsar=1, rotate=$rotation:c=none:ow=rotw($rotation):oh=roth($rotation), format=rgba, unsharp=5:5:0.1:3:3:0.0[v1];[bg][v1]overlay=x=$overlayX:y=$overlayY:enable=\'between(t,0,$duration)\'" -c:a copy -t $duration $outputPath';

  // Execute the FFmpeg command
  ffmpegExecute(ffmpegCommand, outputPath, context);
}

ffmpegExecute(String command, String outputPath, BuildContext context) async {
  if (kDebugMode) {
    print("execute");
  }
  FFmpegKit.execute(command).then((session) async {
    final returnCode = await session.getReturnCode();

    await session.getLogs().then((value) {
      for (var element in value) {
        if (kDebugMode) {
          print("mssg == ${element.getMessage()}");
        }
      }
    });

    if (ReturnCode.isSuccess(returnCode)) {
      // SUCCESS
      if (kDebugMode) {
        print("success");
      }
      showDialog(
        context: context,
        builder: (_) => VideoResultPopup(video: File(outputPath)),
      );
    } else if (ReturnCode.isCancel(returnCode)) {
      // CANCEL
    } else {
      // ERROR
    }
  });
}
