library input;

import 'dart:html';
import 'dart:async';

import 'package:terminal/src/model.dart';

part 'input_keys.dart';

class InputHandler {
  StreamController<List<int>> stdin;

  InputHandler() {
    stdin = new StreamController<List<int>>();
  }

  /// Handles a given [KeyboardEvent].
  void handleInput(KeyboardEvent e, Model model, StreamController stdout) {
    int key = e.keyCode;

    // Don't let solo modifier keys through (Shift=16, Ctrl=17, Meta=91, Alt=18).
    if (key == 16 || key == 17 || key == 91 || key == 18) return;

    // Don't let other keys that don't make sense in a vt100 terminal through.
    // (INSERT=45, PAGEUP=33, PAGEDOWN=34).
    if (key == 45 || key == 33 || key == 34) return;

    // Special handling of DELETE, HOME, and END keys.
    // TODO: fix this when xterm emulation is supported.
    switch (key) {
      case 46:
        _handleDeleteKey(stdout);
        return;
      case 36:
        _handleHomeKey(stdout);
        return;
      case 35:
        _handleEndKey(stdout);
        return;
    }

    // Arrow keys.
    if (CURSOR_KEYS_NORMAL.containsKey(key)) {
      bool normKeys = model.cursorkeys == CursorkeysMode.NORMAL;
      stdin.add(normKeys ? CURSOR_KEYS_NORMAL[key] : CURSOR_KEYS_APP[key]);
      return;
    }

    // keyCode behaves very oddly.
    if (!e.shiftKey) {
      if (NOSHIFT_KEYS.containsKey(key)) {
        key = NOSHIFT_KEYS[key];
      }
    } else {
      if (SHIFT_KEYS.containsKey(key)) {
        key = SHIFT_KEYS[key];
      }
    }

    // Carriage Return (13) => New Line (10).
    if (key == 13) key = 10;

    // Ctrl-V, Ctrl-C, Ctrl-Z.
    if (e.ctrlKey) {
      if (key == 86) {
        document.execCommand('paste', null, "");
        return;
      }
      if (key == 67) key = 3;
      if (key == 90) key = 26;
    }

    stdin.add([key]);
  }

  Future<bool> _listenForBell(StreamController stdout) {
    return stdout.stream.first.then((e) => e.contains(7));
  }

  void _handleDeleteKey(StreamController stdout) {
    stdin.add([27, 91, 67, 8]);
  }

  Future _handleHomeKey(StreamController stdout) async {
    stdin.add([27, 91, 68]);
    while (!await _listenForBell(stdout)) {
      stdin.add([27, 91, 68]);
    }
  }

  Future _handleEndKey(StreamController stdout) async {
    stdin.add([27, 91, 67]);
    while (!await _listenForBell(stdout)) {
      stdin.add([27, 91, 67]);
    }
  }
}