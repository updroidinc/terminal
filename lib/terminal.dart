library terminal;

import 'dart:html';
import 'dart:async';

import 'theme.dart';
import 'package:terminal/src/model.dart';
import 'package:terminal/src/input.dart';
import 'package:terminal/src/output.dart';

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

  Terminal (this.div) {
    _terminal = _createTerminalOutputDiv();
    _cursor = _createTerminalCursorDiv();

    stdout = new StreamController<List<int>>.broadcast();
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
    // The +1 on width is needed because bash throws an extra space
    // ahead of a linewrap for some reason. So if bash cols = 80,
    // then terminal cols = 81.
    int rows = _terminal.contentEdge.height ~/ _theme.charHeight;
    int cols = _terminal.contentEdge.width ~/ _theme.charWidth + 1;

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
    stdout.stream.listen((List<int> out) => OutputHandler.processStdOut(new List.from(out), _controller, stdin, _model, _currAttributes, _resizing));

    _terminal.onKeyDown.listen((e) {
      e.preventDefault();

      // Deactivate blinking while the user is typing.
      // Reactivate after an idle period.
      _controller.cancelBlink();
      _controller.blinkOn = true;
      _model.scrollToBottom();
      _controller.setUpBlink();

      InputHandler.handleInput(e, _model, stdin, stdout);
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
}
