import 'dart:io';

import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/log.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/session.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/statistics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../widgets/export_result.dart';

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
    caption,
    BuildContext context) async {
  // Specify the output file path
  final String dir = (await getTemporaryDirectory()).path;
  DateTime now = DateTime.now();
  String timestamp = now.microsecondsSinceEpoch.toString();
  String outputPath = '$dir/stories_creator_$timestamp.mp4';

  String ffmpegCommand =
      '-loop 1 -i "$background" -i "$videoPath" -filter_complex "[0:v]$filter, scale=396:704[bg];[1:v]$filter, scale=$mediaWidth:$mediaHeight, setsar=1, rotate=$rotation:c=none:ow=rotw($rotation):oh=roth($rotation), format=rgba, unsharp=5:5:0.1:3:3:0.0[v1];[bg][v1]overlay=x=$overlayX:y=$overlayY:enable=\'between(t,0,$duration)\'" -c:a copy -t $duration $outputPath';

  // Execute the FFmpeg command
  ffmpegExecute(ffmpegCommand, outputPath, caption, context);
}

ffmpegExecute(String command, String outputPath, String caption,
    BuildContext context) async {
  if (kDebugMode) {
    print("execute");
  }

  await FFmpegKit.executeAsync(command, (Session session) async {
    // CALLED WHEN SESSION IS EXECUTED
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      // SUCCESS
      if (kDebugMode) {
        print("success");
      }
      showDialog(
        context: context,
        builder: (_) =>
            VideoResultPopup(video: File(outputPath), caption: caption),
      );
    } else if (ReturnCode.isCancel(returnCode)) {
      // CANCEL
    } else {
      // ERROR
    }
  }, (Log log) {
    if (kDebugMode) {
      print("log == ${log.getMessage()}");
    }
    // CALLED WHEN SESSION PRINTS LOGS
  }, (Statistics statistics) {
    // CALLED WHEN SESSION GENERATES STATISTICS
    if (kDebugMode) {
      print("log == ${statistics.getTime()}");
    }
  });
}
