library terminal;

import 'dart:html';
import 'dart:async';
import 'dart:convert';

import 'theme.dart';
import 'package:terminal/src/model.dart';

/// A class for rendering a terminal emulator in a [DivElement] (param).
/// [stdout] needs to receive individual UTF8 integers and will handle
/// them appropriately.
class Terminal {
  /// The [DivElement] within which all [Terminal] graphical elements
  /// are rendered.
  DivElement div;

  /// A stream of [String], JSON-encoded UTF8 bytes (List<int>).
  StreamController<List<int>> stdout;

  /// A stream of [String], JSON-encoded UTF8 bytes (List<int>).
  StreamController<List<int>> stdin;

  /// An int that sets the number of lines scrolled per mouse
  /// wheel event. Default: 3
  int scrollSpeed = 3;

  /// Returns true if cursor blink is enabled.
  bool get cursorBlink => _controller.cursorBlink;
  /// Enable/disable cursor blink. Default: true
  void set cursorBlink(bool b) => _controller.setCursorBlink(b);

  /// Returns current [Theme].
  Theme get theme => _controller.theme;
  /// Sets a [Terminal]'s [Theme]. Default: Solarized-Dark.
  void set theme(Theme thm) => _controller.setTheme(thm);

  // Private
  Model _model;
  DivElement _terminal;
  DivElement _cursor;
  Controller _controller;
  DisplayAttributes _currAttributes;
  Theme _theme;

  bool _resizing;

  static const int ESC = 27;

  Terminal (this.div) {
    _terminal = _createTerminalOutputDiv();
    _cursor = _createTerminalCursorDiv();

    stdout = new StreamController<List<int>>();
    stdin = new StreamController<List<int>>();

    _currAttributes = new DisplayAttributes();
    _theme = new Theme.SolarizedDark();

    List<int> size = calculateSize();
    _model = new Model(size[0], size[1]);
    _controller = new Controller(_terminal, _cursor, _model, _theme);

    _resizing = false;

    _controller.refreshDisplay();

    _registerEventHandlers();
  }

  List<int> currentSize() {
    return [_model.numRows, _model.numCols];
  }

  void resize(int newRows, int newCols) {
    _model = new Model.fromOldModel(newRows, newCols, _model);
    _controller.cancelBlink();
    _controller = new Controller(_terminal, _cursor, _model, _theme);

    // User expects the prompt to appear after a resize.
    // Sending a \n results in a blank line above the first
    // prompt, so we handle this special case with a flag.
    _resizing = true;
    stdin.add([10]);
  }

  List<int> calculateSize() {
    int rows = (_terminal.contentEdge.height) ~/ _theme.charHeight - 1;
    int cols = (_terminal.contentEdge.width) ~/ _theme.charWidth + 1;

    // Set a default if the calculated size is unusable.
    if (rows < 10 || cols < 10) {
      rows = 25;
      cols = 80;
    }

    return [rows, cols];
  }

  DivElement _createTerminalOutputDiv() {
    // contenteditable is important for clipboard paste functionality.
    DivElement termOutput = new DivElement()
      ..tabIndex = 0
      ..classes.add('terminal-output')
      ..contentEditable = 'true'
      ..spellcheck = false;

    div.children.add(termOutput);
    return termOutput;
  }

  DivElement _createTerminalCursorDiv() {
    DivElement termCursor = new DivElement()
      ..classes.add('terminal-cursor')
      ..text = Glyph.CURSOR;

    div.children.add(termCursor);
    return termCursor;
  }

  void _registerEventHandlers() {
    stdout.stream.listen((List<int> out) => _processStdOut(new List.from(out)));

    _terminal.onKeyDown.listen((e) {
      e.preventDefault();
      _handleInput(e);
    });

    _terminal.onMouseWheel.listen((wheelEvent) {
      // Scrolling should target only the console.
      wheelEvent.preventDefault();

      cursorBlink = (_model.atBottom) ? true : false;
     _controller.blinkOn = false;
      (wheelEvent.deltaY < 0) ? _model.scrollUp(scrollSpeed) : _model.scrollDown(scrollSpeed);
      _controller.refreshDisplay();
    });

    _terminal.onPaste.listen((e) {
      String pasteString = e.clipboardData.getData('text');
      for (int i in pasteString.runes) {
        stdin.add([i]);
      }
    });
  }

  /// Handles a given [KeyboardEvent].
  void _handleInput(KeyboardEvent e) {
    // Deactivate blinking while the user is typing.
    // Reactivate after an idle period.
    _controller.cancelBlink();
    _controller.blinkOn = true;
    _model.scrollToBottom();
    _controller.setUpBlink();

    int key = e.keyCode;

    // Don't let solo modifier keys through (Shift=16, Ctrl=17, Meta=91, Alt=18).
    if (key == 16 || key == 17 || key == 91 || key == 18) {
      return;
    }

    // Carriage Return (13) => New Line (10).
    if (key == 13) {
      key = 10;
    } else if (key == 38) {
      // Up Arrow
      if (_model.cursorkeys == CursorkeysMode.NORMAL) {
        stdin.add([27, 91, 65]);
        return;
      } else {
        //stdin.add([27, 48, 65]);
        key = 107;
      }
    } else if (key == 40) {
      // Down Arrow
      if (_model.cursorkeys == CursorkeysMode.NORMAL) {
        stdin.add([27, 91, 66]);
        return;
      } else {
        //stdin.add([27, 48, 66]);
        key = 106;
      }

    } else if (key == 37) {
      // Left Arrow
      if (_model.cursorkeys == CursorkeysMode.NORMAL) {
        stdin.add([27, 91, 68]);
        return;
      } else {
        //stdin.add([27, 48, 68]);
        key = 104;
      }
    } else if (key == 39) {
      // Right Arrow
      if (_model.cursorkeys == CursorkeysMode.NORMAL) {
        stdin.add([27, 91, 67]);
        return;
      } else {
        //stdin.add([27, 48, 67]);
        key = 108;
      }
    }

    if (e.ctrlKey) {
      // Ctrl-V (paste).
      if (key == 86) {
        document.execCommand('paste', null, "");
        return;
      }
      // Ctrl-C
      if (key == 67) key = 3;
      // Ctrl-Z
      if (key == 90) key = 26;
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

    stdin.add([key]);
  }

  /// Processes [output] by coordinating handling of strings
  /// and escape parsing.
  void _processStdOut(List<int> output) {
    int nextEsc;
    while (output.isNotEmpty) {
      nextEsc = output.indexOf(ESC);
      if (nextEsc == -1) {
        _handleOutString(output);
        return;
      } else {
        _handleOutString(output.sublist(0, nextEsc));
        output = _parseEscape(output.sublist(nextEsc));
      }
    }
  }

  /// Parses out escape sequences. When it finds one,
  /// it handles it and returns the remainder of [output].
  List<int> _parseEscape(List<int> output) {
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
  void _handleOutString(List<int> string) {
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

      Glyph g = new Glyph(char, _currAttributes);
      _model.setGlyphAt(g, _model.cursor.row, _model.cursor.col);
      if (_model.cursor.col < _model.numCols - 1) {
        _model.cursorForward();
      } else {
        _model.cursorCarriageReturn();
        _model.cursorNewLine();
      }
    }

    _controller.refreshDisplay();
  }
}
