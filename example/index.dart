import 'dart:html';
import 'package:terminal/terminal.dart';
import 'package:terminal/theme.dart';

void main() {
  new Terminal(querySelector('#console'))
    ..scrollSpeed = 3
    ..cursorBlink = true
    ..theme = new Theme.SolarizedDark();
}