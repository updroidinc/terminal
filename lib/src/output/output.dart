library terminal.src.output.output;

import 'dart:async';
import 'dart:convert';

import '../model/model.dart';
import '../controller.dart';

part 'escape_handler.dart';

class OutputHandler {
  static const int ESC = 27;

  StreamController<List<int>> stdout;

  List<int> _incompleteEscape;

  OutputHandler() {
    stdout = new StreamController<List<int>>.broadcast();
    _incompleteEscape = [];
  }

  /// Processes [output] by coordinating handling of strings
  /// and escape parsing.
  void processStdOut(List<int> output, Controller controller, StreamController stdin, Model model, DisplayAttributes currAttributes) {
    //print('incoming output: ' + output.toString());

    // Insert the incompleteEscape from last processing if exists.
    List<int> outputToProcess = new List.from(_incompleteEscape);
    _incompleteEscape = [];
    outputToProcess.addAll(output);

    int nextEsc;
    while (outputToProcess.isNotEmpty) {
      nextEsc = outputToProcess.indexOf(ESC);
      if (nextEsc == -1) {
        _handleOutString(outputToProcess, model, controller, currAttributes);
        return;
      } else {
        _handleOutString(outputToProcess.sublist(0, nextEsc),  model, controller, currAttributes);
        outputToProcess = _parseEscape(outputToProcess.sublist(nextEsc), controller, stdin, model, currAttributes);
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
        return output.sublist(termIndex);
      }
    }

    _incompleteEscape = new List.from(output);
    return [];
  }

  /// Appends a new [SpanElement] with the contents of [_outString]
  /// to the [_buffer] and updates the display.
  void _handleOutString(List<int> string, Model model, Controller controller, DisplayAttributes currAttributes) {
    //print('string: ' + string.toString());
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
          if (controller.resizing) {
            controller.resizing = false;
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