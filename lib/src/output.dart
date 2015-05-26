library output;

import 'dart:async';
import 'dart:convert';

import 'package:terminal/src/model.dart';
import 'package:terminal/src/controller.dart';

part 'escape_handler.dart';

class OutputHandler {
  static const int ESC = 27;

  StreamController<List<int>> stdout;

  OutputHandler() {
    stdout = new StreamController<List<int>>.broadcast();
  }

  /// Processes [output] by coordinating handling of strings
  /// and escape parsing.
  void processStdOut(List<int> output, Controller controller, StreamController stdin, Model model, DisplayAttributes currAttributes, bool resizing) {
    //print(output.toString());
    int nextEsc;
    while (output.isNotEmpty) {
      nextEsc = output.indexOf(ESC);
      if (nextEsc == -1) {
        _handleOutString(output, model, controller, currAttributes, resizing);
        return;
      } else {
        _handleOutString(output.sublist(0, nextEsc),  model, controller, currAttributes, resizing);
        output = _parseEscape(output.sublist(nextEsc), controller, stdin, model, currAttributes);
      }
    }
  }

  /// Parses out escape sequences. When it finds one,
  /// it handles it and returns the remainder of [output].
  List<int> _parseEscape(List<int> output, Controller controller, StreamController stdin, Model model, DisplayAttributes currAttributes) {
    List<int> escape;
    int termIndex;
    for (int i = 1; i <= output.length; i++) {
      termIndex = i;
      escape = output.sublist(0, i);

      bool escapeHandled = EscapeHandler.handleEscape(escape, stdin, model, currAttributes);
      if (escapeHandled) {
        controller.refreshDisplay();
        break;
      }
    }
    return output.sublist(termIndex);
  }

  /// Appends a new [SpanElement] with the contents of [_outString]
  /// to the [_buffer] and updates the display.
  void _handleOutString(List<int> string, Model model, Controller controller, DisplayAttributes currAttributes, bool resizing) {
    var codes = UTF8.decode(string).codeUnits;
    for (var code in codes) {
      String char = new String.fromCharCode(code);

      if (code == 8) {
        model.backspace();
        continue;
      }

      switch (code) {
        case 32:
          char = Glyph.SPACE;
          break;
        case 60:
          char = Glyph.LT;
          break;
        case 62:
          char = Glyph.GT;
          break;
        case 38:
          char = Glyph.AMP;
          break;
        case 10:
          if (resizing) {
            resizing = false;
            continue;
          }
          model.cursorNewLine();
          continue;
        case 13:
          model.cursorCarriageReturn();
          continue;
        case 7:
          continue;
        case 8:
          continue;
      }

      // To differentiate between an early CR (like from a prompt) and linewrap.
      if (model.cursor.col >= model.numCols - 1) {
        model.cursorCarriageReturn();
        model.cursorNewLine();
      } else {
        Glyph g = new Glyph(char, currAttributes);
        model.setGlyphAt(g, model.cursor.row, model.cursor.col);
        model.cursorForward();
      }
    }

    controller.refreshDisplay();
  }
}