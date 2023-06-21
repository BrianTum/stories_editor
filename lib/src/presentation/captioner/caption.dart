import 'package:flutter/material.dart';

class Captioner extends StatelessWidget {
  const Captioner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white54,
      child: const Center(child: Text("Caption here")),
    );
  }
}
