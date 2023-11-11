import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fraction/fraction.dart';
import 'package:path/path.dart' as path;
import 'package:video_player/video_player.dart';

import '../main.dart';

Future<void> _getImageDimension(File file,
    {required Function(Size) onResult}) async {
  var decodedImage = await decodeImageFromList(file.readAsBytesSync());
  onResult(Size(decodedImage.width.toDouble(), decodedImage.height.toDouble()));
}

String _fileMBSize(File file) =>
    ' ${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB';

class VideoResultPopup extends StatefulWidget {
  const VideoResultPopup({Key? key, required this.video, required this.caption})
      : super(key: key);

  final File video;
  final String caption;

  @override
  State<VideoResultPopup> createState() => _VideoResultPopupState();
}

class _VideoResultPopupState extends State<VideoResultPopup> {
  VideoPlayerController? videoController;
  FileImage? _fileImage;
  Size _fileDimension = Size.zero;
  late final bool _isGif =
      path.extension(widget.video.path).toLowerCase() == ".gif";
  late String _fileMbSize;

  @override
  void initState() {
    super.initState();
    if (_isGif) {
      _getImageDimension(
        widget.video,
        onResult: (d) => setState(() => _fileDimension = d),
      );
    } else {
      videoController = VideoPlayerController.file(widget.video);
      videoController?.initialize().then((_) {
        _fileDimension = videoController?.value.size ?? Size.zero;
        setState(() {});
        videoController?.play();
        videoController?.setLooping(true);
      });
    }
    _fileMbSize = _fileMBSize(widget.video);
  }

  @override
  void dispose() {
    if (_isGif) {
      _fileImage?.evict();
    } else {
      videoController?.pause();
      videoController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Result'),
        actions: [
          IconButton(
            onPressed: () {
              if (_isGif) {
                return;
              }
              if (videoController!.value.isPlaying) {
                videoController?.pause();
              } else {
                videoController?.play();
              }
            },
            icon: Icon(
              videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
          ),
          IconButton(
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => const Example()));
              },
              icon: const Icon(Icons.close))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              GestureDetector(
                onDoubleTap: () {
                  if (_isGif) {
                    return;
                  }
                  if (videoController!.value.isPlaying) {
                    videoController?.pause();
                  } else {
                    videoController?.play();
                  }
                },
                child: AspectRatio(
                  aspectRatio: _fileDimension.aspectRatio == 0
                      ? 1
                      : _fileDimension.aspectRatio,
                  child: _isGif
                      ? Image.file(widget.video)
                      : VideoPlayer(videoController!),
                ),
              ),
              Positioned(
                bottom: 0,
                child: FileDescription(
                  description: {
                    'Video path': widget.video.path,
                    if (!_isGif)
                      'Video duration':
                          '${((videoController?.value.duration.inMilliseconds ?? 0) / 1000).toStringAsFixed(2)}s',
                    'Video ratio':
                        Fraction.fromDouble(_fileDimension.aspectRatio)
                            .reduce()
                            .toString(),
                    'Video dimension': _fileDimension.toString(),
                    'Video size': _fileMbSize,
                    'Caption': widget.caption
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CoverResultPopup extends StatefulWidget {
  const CoverResultPopup({Key? key, required this.cover}) : super(key: key);

  final File cover;

  @override
  State<CoverResultPopup> createState() => _CoverResultPopupState();
}

class _CoverResultPopupState extends State<CoverResultPopup> {
  late final Uint8List _imagebytes = widget.cover.readAsBytesSync();
  Size? _fileDimension;
  late String _fileMbSize;

  @override
  void initState() {
    super.initState();
    _getImageDimension(
      widget.cover,
      onResult: (d) => setState(() => _fileDimension = d),
    );
    _fileMbSize = _fileMBSize(widget.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Stack(
          children: [
            Image.memory(_imagebytes),
            Positioned(
              bottom: 0,
              child: FileDescription(
                description: {
                  'Cover path': widget.cover.path,
                  'Cover ratio':
                      Fraction.fromDouble(_fileDimension?.aspectRatio ?? 0)
                          .reduce()
                          .toString(),
                  'Cover dimension': _fileDimension.toString(),
                  'Cover size': _fileMbSize,
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FileDescription extends StatelessWidget {
  const FileDescription({Key? key, required this.description})
      : super(key: key);

  final Map<String, String> description;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(fontSize: 11),
      child: Container(
        width: MediaQuery.of(context).size.width - 60,
        padding: const EdgeInsets.all(10),
        color: Colors.black.withOpacity(0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: description.entries
              .map(
                (entry) => Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${entry.key}: ',
                        style: const TextStyle(fontSize: 11),
                      ),
                      TextSpan(
                        text: entry.value,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
