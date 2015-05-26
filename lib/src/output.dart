library output;

import 'dart:async';
import 'dart:convert';
import 'package:terminal/src/model.dart';

part 'escape_handler.dart';

class OutputHandler {
  static const int ESC = 27;

  /// Processes [output] by coordinating handling of strings
  /// and escape parsing.
  static void processStdOut(List<int> output, Controller _controller, StreamController stdin, Model _model, DisplayAttributes _currAttributes, bool _resizing) {
    //print(output.toString());
    int nextEsc;
    while (output.isNotEmpty) {
      nextEsc = output.indexOf(ESC);
      if (nextEsc == -1) {
        _handleOutString(output, _model, _controller, _currAttributes, _resizing);
        return;
      } else {
        _handleOutString(output.sublist(0, nextEsc),  _model, _controller, _currAttributes, _resizing);
        output = _parseEscape(output.sublist(nextEsc), _controller, stdin, _model, _currAttributes);
      }
    }
  }

  /// Parses out escape sequences. When it finds one,
  /// it handles it and returns the remainder of [output].
  static List<int> _parseEscape(List<int> output, Controller _controller, StreamController stdin, Model _model, DisplayAttributes _currAttributes) {
    List<int> escape;
    int termIndex;
    for (int i = 1; i <= output.length; i++) {
      termIndex = i;
      escape = output.sublist(0, i);

      bool escapeHandled = EscapeHandler.handleEscape(escape, stdin, _model, _currAttributes);
      if (escapeHandled) {
        _controller.refreshDisplay();
        break;
      }
    }
    return output.sublist(termIndex);
  }

  /// Appends a new [SpanElement] with the contents of [_outString]
  /// to the [_buffer] and updates the display.
  static void _handleOutString(List<int> string, Model _model, Controller _controller, DisplayAttributes _currAttributes, bool _resizing) {
    var codes = UTF8.decode(string).codeUnits;
    for (var code in codes) {
      String char = new String.fromCharCode(code);

      if (code == 8) {
        _model.backspace();
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
          if (_resizing) {
            _resizing = false;
            continue;
          }
          _model.cursorNewLine();
          continue;
        case 13:
          _model.cursorCarriageReturn();
          continue;
        case 7:
          continue;
        case 8:
          continue;
      }

      // To differentiate between an early CR (like from a prompt) and linewrap.
      if (_model.cursor.col >= _model.numCols - 1) {
        _model.cursorCarriageReturn();
        _model.cursorNewLine();
      } else {
        Glyph g = new Glyph(char, _currAttributes);
        _model.setGlyphAt(g, _model.cursor.row, _model.cursor.col);
        _model.cursorForward();
      }
    }

    _controller.refreshDisplay();
  }
}