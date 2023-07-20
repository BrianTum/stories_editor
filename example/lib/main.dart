import 'dart:io';

import 'package:flutter/material.dart';
import 'package:stories_editor/stories_editor.dart';

import 'services/video_process.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter stories editor Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Example(),
    );
  }
}

class Example extends StatefulWidget {
  const Example({Key? key}) : super(key: key);

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              Map? returnedMap = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => StoriesEditor(
                          //fontFamilyList: const ['Shizuru', 'Aladin'],
                          galleryThumbnailQuality: 300,
                          //isCustomFontList: true,
                          onDone: (uri) {
                            debugPrint("uri here");
                            // ignore: deprecated_member_use
                            // Share.shareFiles([uri]);
                          },
                        )),
              );

              if (returnedMap!['type'] == 'photo') {
                showDialog(
                  context: context,
                  builder: (_) => Center(
                      child: Stack(
                    children: [
                      Image.file(File(returnedMap['url'])),
                      Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.white24,
                            height: 60,
                            child: Center(
                              child: Text(
                                returnedMap['caption'],
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 20),
                              ),
                            ),
                          ))
                    ],
                  )),
                );
              } else if (returnedMap['type'] == 'video') {
                generateGradientVideo(
                  returnedMap['backgroundImage'],
                  returnedMap['videoPath'],
                  returnedMap['filterString'],
                  returnedMap['duration'],
                  returnedMap['height'],
                  returnedMap['width'],
                  returnedMap['centerX'],
                  returnedMap['centerY'],
                  returnedMap['rotation'],
                  returnedMap['minOffsetDx'],
                  returnedMap['minOffsetDy'],
                  returnedMap['caption'],
                  context,
                );
              } else {
                String value1 = returnedMap['type'];
                String value2 = returnedMap['url'];

                debugPrint("value1 == $value1 == value2 == $value2");
              }
            },
            child: const Text('Open Stories Editor'),
          ),
        ));
  }
}
