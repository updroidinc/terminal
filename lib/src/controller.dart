part of model;

class Controller {
  DivElement div;
  Model _model;
  Theme _theme;
  bool cursorBlink = true;
  Timer _blinkTimer, _blinkTimeout;
  bool blinkOn;

  Controller(this.div, Model model, Theme theme) {
    _model = model;
    _theme = theme;

    blinkOn = false;
    setUpBlink();
  }

  void setCursorBlink(bool b) {
    cursorBlink = b;

    cancelBlink();
    setUpBlink();
    refreshDisplay();
  }

  void setUpBlink() {
    if (!cursorBlink) return;

    _blinkTimeout = new Timer(new Duration(milliseconds: 1000), () {
      _blinkTimer = new Timer.periodic(new Duration(milliseconds: 500), (timer) {
        blinkOn = !blinkOn;
        refreshDisplay();
      });
    });
  }

  void cancelBlink() {
    if (_blinkTimeout != null) _blinkTimeout.cancel();
    if (_blinkTimer != null) _blinkTimer.cancel();
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
      if (_model.cursor.row == r && _model.cursor.col == c && blinkOn) {
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
  void refreshDisplay() {
    div.innerHtml = '';

    DivElement row;
    for (int r = 0; r < _model.numRows; r++) {
      row = _generateRow(r);
      row.classes.add('termrow');

      div.append(row);
    }
  }
}