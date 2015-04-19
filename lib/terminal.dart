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
  static double charWidth = 6.778;
  static int charHeight = 14;

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
  bool get cursorBlink => _cursorBlink;
  /// Enable/disable cursor blink. Default: true
  void set cursorBlink(bool b) => _setCursorBlink(b);

  /// Returns current [Theme].
  Theme get theme => _theme;
  /// Sets a [Terminal]'s [Theme]. Default: Solarized-Dark.
  void set theme(Theme thm) => _setTheme(thm);

  // Private
  Model _model;
  DisplayAttributes _currAttributes;
  Theme _theme;
  Timer _blinkTimer, _blinkTimeout;
  bool _blinkOn;
  bool _resizing = false;
  bool _cursorBlink = true;

  static const int ESC = 27;

  Terminal (this.div) {
    stdout = new StreamController<List<int>>();
    stdin = new StreamController<List<int>>();

    _currAttributes = new DisplayAttributes();
    _theme = new Theme.SolarizedDark();
    _blinkOn = false;

    List<int> size = calculateSize();
    _model = new Model(size[0], size[1]);
    _refreshDisplay();

    _setUpBlink();

    _registerEventHandlers();
  }

  void resize(int newRows, int newCols) {
    _model = new Model.fromOldModel(newRows, newCols, _model);

    // User expects the prompt to appear after a resize.
    // Sending a \n results in a blank line above the first
    // prompt, so we handle this special case with a flag.
    _resizing = true;
    stdin.add([10]);
  }

  List<int> calculateSize() {
    int rows = (div.borderEdge.height - 10) ~/ charHeight;
    int cols = (div.borderEdge.width - 10) ~/ charWidth;

    // Set a default if the calculated size is unusable.
    if (rows < 10 || cols < 10) {
      rows = 25;
      cols = 80;
    }

    return [rows, cols];
  }

  List<int> currentSize() {
    return [_model.numRows, _model.numCols];
  }

  void _setTheme(Theme thm) {
    _theme = thm;
    div.style.backgroundColor = _theme.backgroundColor;
    div.style.color = _theme.colors['white'];
    _refreshDisplay();
  }

  void _setCursorBlink(bool b) {
    _cursorBlink = b;

    _cancelBlink();
    _setUpBlink();
    _refreshDisplay();
  }

  void _setUpBlink() {
    if (!_cursorBlink) return;

    _blinkTimeout = new Timer(new Duration(milliseconds: 1000), () {
      _blinkTimer = new Timer.periodic(new Duration(milliseconds: 500), (timer) {
        _blinkOn = !_blinkOn;
        _refreshDisplay();
      });
    });
  }

  void _cancelBlink() {
    if (_blinkTimeout != null) _blinkTimeout.cancel();
    if (_blinkTimer != null) _blinkTimer.cancel();
  }

  void _registerEventHandlers() {
    stdout.stream.listen((List<int> out) => _processStdOut(new List.from(out)));

    div.onKeyUp.listen((e) => _handleInput(e));

    div.onKeyDown.listen((e) {
      e.preventDefault();
    });

    div.onMouseWheel.listen((wheelEvent) {
      // Scrolling should target only the console.
      wheelEvent.preventDefault();

      cursorBlink = (_model.atBottom) ? true : false;
     _blinkOn = false;
      (wheelEvent.deltaY < 0) ? _model.scrollUp(scrollSpeed) : _model.scrollDown(scrollSpeed);
      _refreshDisplay();
    });

    div.onPaste.listen((e) {
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
    _cancelBlink();
    _blinkOn = true;
    _model.scrollToBottom();
    _setUpBlink();

    int key = e.keyCode;

    if (e.ctrlKey) {
      // Eat ctrl-v (paste).
      if (key == 86) return;

      if (key == 67) key = 3;
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
    if (key == 13) {
      key = 10;
    } else if (key == 38) {
      stdin.add([27, 91, 65]);
      return;
    }

    // Don't let solo modifier keys through (Shift=16, Ctrl=17, Meta=91, Alt=18).
    if (key != 16 && key != 17 && key != 91 && key != 18) {
      stdin.add([key]);
    }
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

      bool escapeHandled = EscapeHandler.handleEscape(escape, _model, _currAttributes);
      if (escapeHandled) {
        _refreshDisplay();
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
      _model.cursorForward();
    }

    _refreshDisplay();
  }

  /// Generates the HTML for an individual row given
  /// the [Glyph]s contained in the model at that
  /// corresponding row.
  DivElement _generateRow(int r) {
    Glyph prev, curr;

    DivElement row = new DivElement();
    String str = '';
    prev = _model.getGlyphAt(r, 0);
    for (int c = 0; c < _model.numCols; c++) {
      curr = _model.getGlyphAt(r, c);

      if (!curr.hasSameAttributes(prev) || c == _model.numCols - 1) {
        if (prev.hasDefaults()) {
          row.append(new DocumentFragment.html(str));
        } else {
          SpanElement span = new SpanElement();
          span.style.color = _theme.colors[prev.fgColor];
          span.style.backgroundColor = _theme.colors[prev.bgColor];
          span.append(new DocumentFragment.html(str));
          row.append(span);
        }

        str = '';
      }

      // Draw the cursor.
      if (_model.cursor.row == r && _model.cursor.col == c && _blinkOn) {
        str += Glyph.CURSOR;
      } else {
        str += curr.value;
      }

      prev = curr;
    }

    return row;
  }

  /// Refreshes the entire console [DivElement] by setting its
  /// contents to null and regenerating each row [DivElement].
  void _refreshDisplay() {
    // Don't try to draw the display if the enclosing tab is
    // inactive (where the content div is dimensionless).
    //print(div.parent.parent.classes.toString());
    if (!div.parent.parent.classes.contains('active')) return;

    div.innerHtml = '';

    DivElement row;
    for (int r = 0; r < _model.numRows; r++) {
      row = _generateRow(r);
      row.classes.add('termrow');

      div.append(row);
    }
  }
}
