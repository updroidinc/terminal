library model;

import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'package:quiver/core.dart';
import 'package:terminal/theme.dart';

part 'controller.dart';
part 'display_attributes.dart';
part 'escape_handler.dart';
part 'glyph.dart';
part 'input_keys.dart';

class Cursor {
  int row = 0;
  int col = 0;

  String toString () {
    return 'row: $row, col: $col';
  }
}

enum KeypadMode { NUMERIC, APPLICATION }
enum CursorkeysMode { NORMAL, APPLICATION }

/// Represents the data model for [Terminal].
class Model {
  static const int _MAXBUFFER = 500;

  bool get atBottom =>_forwardBuffer.isEmpty;

  Cursor cursor;
  int numRows, numCols;
  KeypadMode keypad;
  CursorkeysMode cursorkeys;


  // Implemented as stacks in scrolling.
  List<List> _reverseBuffer;
  List<List> _forwardBuffer;

  // Implemented as a queue in scrolling.
  List<List> _frame;

  // Tab locations.
  List<List> _tabs;

  int _scrollStart, _scrollEnd;

  Model (this.numRows, this.numCols) {
    cursor = new Cursor();
    keypad = KeypadMode.NUMERIC;
    cursorkeys = CursorkeysMode.NORMAL;

    _reverseBuffer = [];
    _forwardBuffer = [];
    _frame = [];

    _initModel();
  }

  Model.fromOldModel(this.numRows, this.numCols, Model oldModel) {
    cursor = new Cursor();

    oldModel.scrollToBottom();
    // Puts all old content into the reverse buffer and starts clean.
    _reverseBuffer = oldModel._reverseBuffer;
    // Don't add blank lines.
    for (List<Glyph> row in oldModel._frame) {
      bool blank = true;
      for (Glyph g in row) {
        if (g.value != Glyph.SPACE && g.value != Glyph.CURSOR) {
          blank = false;
          break;
        }
      }
      if (!blank) _reverseBuffer.add(row);
    }

    // Trim off oldest content to keep buffer below max.
    if (_reverseBuffer.length > _MAXBUFFER) {
      _reverseBuffer = _reverseBuffer.sublist(_reverseBuffer.length - _MAXBUFFER);
    }
    _forwardBuffer = [];
    _frame = [];

    _initModel();
  }

  /// Returns the [Glyph] at row, col.
  Glyph getGlyphAt(int row, int col) {
    if (col >= _frame[row].length) {
      _frame[row].add(new Glyph(Glyph.SPACE, new DisplayAttributes()));
    }
    return _frame[row][col];
  }

  /// Sets a [Glyph] at location row, col.
  void setGlyphAt(Glyph g, int row, int col) {
    // TODO: add guards for setting Glyphs that are out of bounds
    // after a resize.
    if (_forwardBuffer.isEmpty) {
      _frame[row][col] = g;
      return;
    }

    _forwardBuffer.first[col] = g;
  }

  void backspace() {
    //setGlyphAt(new Glyph(Glyph.SPACE, new DisplayAttributes()), cursor.row, cursor.col);
    cursorBackward();
  }

  void cursorHome(int row, int col) {
    // Detect screen scrolling when _scrollEnd switches from last line to second-to-last line.
    if (_scrollEnd == numRows - 2) {
      if (row == _scrollEnd) {
        scrollDown(1);
      } else if (row == _scrollStart) {
        scrollUp(1);
      }
    }

    cursor.row = row;
    cursor.col = col;
  }

  void cursorUp([int count]) {
    if (cursor.row <= 0) return;

    if (count == null) {
      cursor.row--;
    } else {
      cursor.row = (cursor.row - count <= 0) ? 0 : cursor.row - count;
    }
  }

  void cursorDown([int count]) {
    if (cursor.row >= numRows) return;

    if (count == null) {
      cursor.row++;
    } else {
      cursor.row = (cursor.row + count >= numRows) ? numRows - 1 : cursor.row + count;
    }
  }

  void cursorForward([int count]) {
    if (cursor.col >= numCols - 1) return;

    if (count == null) {
      cursor.col++;
    } else {
      cursor.col = (cursor.col + count >= numCols) ? numCols - 1 : cursor.col + count;
    }
  }

  void cursorBackward([int count]) {
    if (cursor.col <= 0) return;

    if (count == null) {
      cursor.col--;
    } else {
      cursor.col = (cursor.col - count <= 0) ? 0 : cursor.col - count;
    }
  }

  void cursorCarriageReturn() {
    cursor.col = 0;
  }

  void cursorNewLine() {
    if (_forwardBuffer.isNotEmpty) {
      _forwardBuffer.insert(0, new List<Glyph>());
      for (int c = 0; c < numCols; c++) {
        _forwardBuffer.first.add(new Glyph(Glyph.SPACE, new DisplayAttributes()));
      }
      return;
    }

    if (cursor.row < numRows - 1) {
      cursor.row++;
    } else {
      _pushBuffer();
    }
  }

  void setTab() {
    _tabs.add([cursor.row, cursor.col]);
  }

  void clearAllTabs() {
    _tabs.clear();
  }

  /// Erases from the current cursor position to the end of the current line.
  void eraseEndOfLine() {
    //cursorBackward();
    for (int i = cursor.col; i < _frame[cursor.row].length; i++) {
      setGlyphAt(new Glyph(Glyph.SPACE, new DisplayAttributes()), cursor.row, i);
    }
  }

  void eraseDown() {
    int cursorRow = cursor.row;
    for (List<Glyph> r in _frame.sublist(cursorRow)) {
      for (int c = 0; c < r.length; c++) {
        r[c].value = Glyph.SPACE;
      }
    }
  }

  void eraseScreen() {
    for (List<Glyph> r in _frame) {
      for (int c = 0; c < r.length; c++) {
        r[c].value = Glyph.SPACE;
      }
    }

    cursor.row = 0;
    cursor.col = 0;
  }

  void setKeypadMode(KeypadMode mode) {
    keypad = mode;
  }

  void _pushBuffer() {
    _reverseBuffer.add(_frame[0]);
    if (_reverseBuffer.length > _MAXBUFFER) _reverseBuffer.removeAt(0);
    _frame.removeAt(0);

    List<Glyph> newRow = [];
    for (int c = 0; c < numCols; c++) {
      newRow.add(new Glyph(Glyph.SPACE, new DisplayAttributes()));
    }
    _frame.add(newRow);
  }

  void scrollScreen(int start, int end) {
    _scrollStart = start;
    _scrollEnd = end;
  }

  /// Manipulates the frame to handle scrolling
  /// upward of a single line.
  void scrollUp(int numLines) {
    for (int i = 0; i < numLines; i++) {
      _frame.removeAt(numRows - 2);
      _frame.insert(0, new List<Glyph>());
      for (int c = 0; c < numCols; c++) {
        _frame[0].add(new Glyph(Glyph.SPACE, new DisplayAttributes()));
      }
    }
  }

  /// Manipulates the frame to handle scrolling
  /// upward of a single line.
  void scrollDown(int numLines) {
    for (int i = 0; i < numLines; i++) {
      _frame.removeAt(0);
      _frame.insert(numRows - 2, new List<Glyph>());
      for (int c = 0; c < numCols; c++) {
        _frame[numRows - 2].add(new Glyph(Glyph.SPACE, new DisplayAttributes()));
      }
    }
  }

  void scrollToBottom() {
    while (_forwardBuffer.isNotEmpty) {
      _frame.add(_forwardBuffer.last);
      _forwardBuffer.removeLast();
      _reverseBuffer.add(_frame[0]);
      _frame.removeAt(0);
    }
  }

  /// Initializes the internal model with a List of Lists.
  /// Each location defaults to a Glyph.SPACE.
  void _initModel() {
    for (int r = 0; r < numRows; r++) {
      _frame.add(new List<Glyph>());
      for (int c = 0; c < numCols; c++) {
        _frame[r].add(new Glyph(Glyph.SPACE, new DisplayAttributes()));
      }
    }
  }
}