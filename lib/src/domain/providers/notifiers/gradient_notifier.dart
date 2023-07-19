import 'package:flutter/material.dart';

class GradientNotifier extends ChangeNotifier {
  Color _color1 = const Color(0xFFFFFFFF);
  Color get color1 => _color1;
  set color1(Color color) {
    _color1 = color;
    notifyListeners();
  }

  Color _color2 = const Color(0xFFFFFFFF);
  Color get color2 => _color2;
  set color2(Color color) {
    _color2 = color;
    notifyListeners();
  }

  Color _color3 = const Color(0xFFFFFFFF);
  Color get color3 => _color3;
  set color3(Color color) {
    _color3 = color;
    notifyListeners();
  }

  Color _color4 = const Color(0xFFFFFFFF);
  Color get color4 => _color4;
  set color4(Color color) {
    _color4 = color;
    notifyListeners();
  }

  Color _color5 = const Color(0xFFFFFFFF);
  Color get color5 => _color5;
  set color5(Color color) {
    _color5 = color;
    notifyListeners();
  }

  Color _color6 = const Color(0xFFFFFFFF);
  Color get color6 => _color6;
  set color6(Color color) {
    _color6 = color;
    notifyListeners();
  }
}
