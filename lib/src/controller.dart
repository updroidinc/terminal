library terminal.src.controller;

import 'dart:async';
import 'dart:html';

import 'theme.dart';
import 'model/model.dart';

class Controller {
  DivElement div;
  DivElement cursor;
  Model _model;
  Theme _theme;
  bool resizing;
  bool cursorBlink = true;
  Timer _blinkTimer, _blinkTimeout;
  bool blinkOn;

  /// Returns current [Theme].
  Theme get theme => _theme;
  /// Sets a [Terminal]'s [Theme]. Default: Solarized-Dark.
  void set theme(Theme thm) => setTheme(thm);

  Controller(this.div, this.cursor, Model model, Theme theme) {
    _model = model;
    _theme = theme;
    resizing = false;

    blinkOn = false;
    setUpBlink();
  }

  void setTheme(Theme thm) {
    _theme = thm;
    div.style.backgroundColor = _theme.backgroundColor;
    div.style.color = _theme.colors['white'];
    refreshDisplay();
  }

  void setCursorBlink(bool b) {
    cursorBlink = b;

    cancelBlink();
    setUpBlink();
  }

  void setUpBlink() {
    if (!cursorBlink) return;

    _blinkTimeout = new Timer(new Duration(milliseconds: 1000), () {
      _blinkTimer = new Timer.periodic(new Duration(milliseconds: 500), (timer) {
        blinkOn = !blinkOn;
        _drawCursor();
      });
    });
  }

  void cancelBlink() {
    if (_blinkTimeout != null) _blinkTimeout.cancel();
    if (_blinkTimer != null) _blinkTimer.cancel();
  }

  void _drawCursor() {
    if (document.activeElement == div) {
      cursor.style.visibility = blinkOn ? 'visible' : 'hidden';
    } else {
      cursor.style.visibility = 'visible';
    }

    cursor.style.color = _theme.colors['white'];
    // TODO: make offset calculation dynamic.
    cursor.style.left = ((_model.cursor.col * _theme.charWidth) + 5).toString() + 'px';
    cursor.style.top = ((_model.cursor.row * _theme.charHeight) + 5).toString() + 'px';
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

      str += curr.value;
      prev = curr;
    }

    return row;
  }

  /// Refreshes the entire console [DivElement] by setting its
  /// contents to null and regenerating each row [DivElement].
  void refreshDisplay() {
    div.innerHtml = '';

    DivElement row;
    for (int r = 0; r < _model.numRows; r++) {
      row = _generateRow(r);
      row.classes.add('termrow');

      div.append(row);
    }

    _drawCursor();
  }
}