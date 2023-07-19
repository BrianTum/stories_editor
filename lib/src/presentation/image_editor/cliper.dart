import 'package:flutter/material.dart';

class InteractiveClipPath extends StatefulWidget {
  const InteractiveClipPath({super.key});

  @override
  _InteractiveClipPathState createState() => _InteractiveClipPathState();
}

class _InteractiveClipPathState extends State<InteractiveClipPath> {
  double _topClip = 0.0;
  double _leftClip = 0.0;
  double _rightClip = 0.0;
  double _bottomClip = 0.0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            // Update the clip values based on the gesture details
            _topClip += details.delta.dy;
            _leftClip += details.delta.dx;
            _rightClip -= details.delta.dx;
            _bottomClip -= details.delta.dy;
          });
        },
        child: ClipPath(
          clipper: CustomPathClipper(
            topClip: _topClip,
            leftClip: _leftClip,
            rightClip: _rightClip,
            bottomClip: _bottomClip,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            width: MediaQuery.of(context).size.width * 0.7,

            color: Colors.white, // Background color of the entire container
          ),
        ),
      ),
    );
  }
}

class CustomPathClipper extends CustomClipper<Path> {
  final double topClip;
  final double leftClip;
  final double rightClip;
  final double bottomClip;

  CustomPathClipper({
    required this.topClip,
    required this.leftClip,
    required this.rightClip,
    required this.bottomClip,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    // Create the clip path using the clip values
    path.moveTo(0, topClip);
    path.lineTo(leftClip, 0);
    path.lineTo(size.width - rightClip, 0);
    path.lineTo(size.width, topClip);
    path.lineTo(size.width, size.height - bottomClip);
    path.lineTo(size.width - rightClip, size.height);
    path.lineTo(leftClip, size.height);
    path.lineTo(0, size.height - bottomClip);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomPathClipper oldClipper) {
    // We only need to update the clip path if the clip values change
    return topClip != oldClipper.topClip ||
        leftClip != oldClipper.leftClip ||
        rightClip != oldClipper.rightClip ||
        bottomClip != oldClipper.bottomClip;
  }
}
