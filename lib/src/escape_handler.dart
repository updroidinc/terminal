part of model;

class EscapeHandler {
  // Taken from: http://www.termsys.demon.co.uk/vtansi.htm
  // And for VT102: http://www.ibiblio.org/pub/historic-linux/ftp-archives/tsx-11.mit.edu/Oct-07-1996/info/vt102.codes
  static Map constantEscapes = {
    // Device Status
    JSON.encode([27, 91, 99]): 'Query Device Code',
    JSON.encode([27, 91, 48, 99]): 'Query Device Code',
    JSON.encode([27, 90]): 'Query Device Code',
    JSON.encode([27, 91, 53, 110]): 'Query Device Status',
    JSON.encode([27, 91, 54, 110]): 'Query Cursor Position',
    // Terminal Setup
    JSON.encode([27, 99]): 'Reset Device',
    JSON.encode([27, 55, 104]): 'Enable Line Wrap',
    JSON.encode([27, 55, 108]): 'Disable Line Wrap',
    // Fonts
    JSON.encode([27, 40]): 'Font Set G0',
    JSON.encode([27, 41]): 'Font Set G1',
    // Cursor Control
    JSON.encode([27, 91, 115]): 'Save Cursor',
    JSON.encode([27, 91, 117]): 'Unsave Cursor',
    JSON.encode([27, 55]): 'Save Cursor & Attrs',
    JSON.encode([27, 56]): 'Restore Cursor & Attrs',
    // Scrolling
    JSON.encode([27, 91, 114]): 'Scroll Screen',
    JSON.encode([27, 68]): 'Scroll Down',
    JSON.encode([27, 77]): 'Scroll Up',
    // Tab Control
    JSON.encode([27, 72]): 'Set Tab',
    JSON.encode([27, 91, 103]): 'Clear Tab',
    JSON.encode([27, 91, 51, 103]): 'Clear All Tabs',
    // Keypad Character Selection
    JSON.encode([27, 61]): 'Keypad Application',
    JSON.encode([27, 62]): 'Keypad Numeric',
    // Erasing Text
    JSON.encode([27, 91, 75]): 'Erase End of Line',
    JSON.encode([27, 91, 49, 75]): 'Erase Start of Line',
    JSON.encode([27, 91, 50, 75]): 'Erase Line',
    JSON.encode([27, 91, 74]): 'Erase Down',
    JSON.encode([27, 91, 49, 74]): 'Erase Up',
    JSON.encode([27, 91, 50, 74]): 'Erase Screen',
    // Printing
    JSON.encode([27, 91, 105]): 'Print Screen',
    JSON.encode([27, 91, 49, 105]): 'Print Line',
    JSON.encode([27, 91, 52, 105]): 'Stop Print Log',
    JSON.encode([27, 91, 53, 105]): 'Start Print Log'
  };

  static Map variableEscapeTerminators = {
    // Device Status
    99: 'Report Device Code',
    82: 'Report Cursor Position',
    // Cursor Control
    72: 'Cursor Home',
    65: 'Cursor Up',
    66: 'Cursor Down',
    67: 'Cursor Forward',
    68: 'Cursor Backward',
    102: 'Force Cursor Position',
    // Scrolling
    114: 'Scroll Screen',
    // Define Key
    112: 'Set Key Definition',
    // Set Display Attribute
    109: 'Set Attribute Mode',
    // Reset and Set Modes
    104: 'Set Mode',
    108: 'Reset Mode'
  };

  static bool handleEscape(List<int> escape, StreamController<List<int>> stdin, Model model, DisplayAttributes currAttributes) {
    if (escape.length != 1 && escape.last == 27) {
      print('Unknown escape detected: ${escape.sublist(0, escape.length - 1).toString()}');
      return true;
    }

    String encodedEscape = JSON.encode(escape);
    if (constantEscapes.containsKey(encodedEscape)) {
      _handleConstantEscape(encodedEscape, stdin, model, currAttributes, escape);
      return true;
    } else if (variableEscapeTerminators.containsKey(escape.last)) {
      _handleVariableEscape(encodedEscape, escape, currAttributes, model);
      return true;
    }

    return false;
  }

  static void _handleVariableEscape(String encodedEscape, List<int> escape, DisplayAttributes currAttributes, Model model) {
    print('Variable escape: ${EscapeHandler.variableEscapeTerminators[escape.last]}');
    switch (EscapeHandler.variableEscapeTerminators[escape.last]) {
      case 'Set Attribute Mode':
        _setAttributeMode(escape, currAttributes);
        break;
      case 'Cursor Home':
        _cursorHome(escape, model);
        break;
      case 'Cursor Forward':
        _cursorForward(model);
        break;
      case 'Set Mode':
        _setMode(escape);
        break;
      case 'Reset Mode':
        _resetMode(escape);
        break;
      case 'Scroll Screen':
        _scrollScreen(escape);
        break;
      default:
        print('Variable escape : ${variableEscapeTerminators[escape.last]} (${escape.toString()}) not yet supported');
    }
  }

  static void _handleConstantEscape(String encodedEscape, StreamController<List<int>> stdin, Model model, DisplayAttributes currAttributes, List<int> escape) {
    print('Constant escape: ${constantEscapes[encodedEscape]}');
    switch (constantEscapes[encodedEscape]) {
      case 'Query Cursor Position':
        _queryCursorPosition(stdin, model);
        break;
      case 'Set Tab':
        model.setTab();
        break;
      case 'Clear All Tabs':
        model.clearAllTabs();
        break;
      case 'Erase End of Line':
        _eraseEndOfLine(model, currAttributes);
        break;
      case 'Erase Down':
        model.eraseDown();
        break;
      case 'Erase Screen':
        model.eraseScreen();
        break;
      case 'Keypad Application':
        model.setKeypadMode(KeypadMode.APPLICATION);
        break;
      case 'Keypad Numeric':
        model.setKeypadMode(KeypadMode.NUMERIC);
        break;
      default:
        print('Constant escape : ${constantEscapes[encodedEscape]} (${escape.toString()}) not yet supported');
    }
  }

  static void _queryCursorPosition(StreamController<List<int>> stdin, Model model) {
    // Sends back a Report Cursor Position - <ESC>[{ROW};{COLUMN}R
    stdin.add([27, 91, model.cursor.row, 59, model.cursor.col, 82]);
  }

  static void _setMode(List<int> escape) {
    print('Set Mode: ${escape.toString()}');
  }

  static void _resetMode(List<int> escape) {
    print('Reset Mode: ${escape.toString()}');
  }

  static void _scrollScreen(List<int> escape) {
    int indexOfSemi = escape.indexOf(59);
    int start = int.parse(UTF8.decode(escape.sublist(2, indexOfSemi)));
    int end = int.parse(UTF8.decode(escape.sublist(indexOfSemi + 1, escape.length - 1)));
    print('Scrolling: $start to $end');
  }

  /// Sets the cursor position where subsequent text will begin.
  /// If no row/column parameters are provided (ie. <ESC>[H),
  /// the cursor will move to the home position, at the upper left of the screen.
  static void _cursorHome(List<int> escape, Model model) {
    int row, col;

    if (escape.length == 3) {
      row = 0;
      col = 0;
    } else {
      int indexOfSemi = escape.indexOf(59);
      row = int.parse(UTF8.decode(escape.sublist(2, indexOfSemi)));
      col = int.parse(UTF8.decode(escape.sublist(indexOfSemi + 1, escape.length - 1)));
    }

    model.cursor.row = row;
    model.cursor.col = col;
  }

  /// Moves the cursor forward by COUNT columns; the default count is 1.
  static void _cursorForward(Model model) {
    model.cursorForward();
  }

  /// Erases from the current cursor position to the end of the current line.
  static void _eraseEndOfLine(Model model, DisplayAttributes attr) {
    model.cursorBackward();
    // TODO: need to be able to use the same display attributes from the previous Glyph,
    // but right now it's too cumbersome.
    Glyph g = new Glyph(Glyph.SPACE, attr);
    model.setGlyphAt(g, model.cursor.row, model.cursor.col);
  }

  /// Sets multiple display attribute settings.
  /// Sets local [DisplayAttributes], given [escape].
  static void _setAttributeMode(List<int> escape, DisplayAttributes attr) {
    String decodedEsc = UTF8.decode(escape);

    if (decodedEsc.contains('0m')) {
      attr.resetAll();
    }

    if (decodedEsc.contains(';1')) attr.bright = true;
    if (decodedEsc.contains(';2')) attr.dim = true;
    if (decodedEsc.contains(';4')) attr.underscore = true;
    if (decodedEsc.contains(';5')) attr.blink = true;
    if (decodedEsc.contains(';7')) attr.reverse = true;
    if (decodedEsc.contains(';8')) attr.hidden = true;

    if (decodedEsc.contains(';30')) attr.fgColor = 'black';
    if (decodedEsc.contains(';31')) attr.fgColor = 'red';
    if (decodedEsc.contains(';32')) attr.fgColor = 'green';
    if (decodedEsc.contains(';33')) attr.fgColor = 'yellow';
    if (decodedEsc.contains(';34')) attr.fgColor = 'blue';
    if (decodedEsc.contains(';35')) attr.fgColor = 'magenta';
    if (decodedEsc.contains(';36')) attr.fgColor = 'cyan';
    if (decodedEsc.contains(';37')) attr.fgColor = 'white';

    if (decodedEsc.contains(';40')) attr.bgColor = 'black';
    if (decodedEsc.contains(';41')) attr.bgColor = 'red';
    if (decodedEsc.contains(';42')) attr.bgColor = 'green';
    if (decodedEsc.contains(';43')) attr.bgColor = 'yellow';
    if (decodedEsc.contains(';44')) attr.bgColor = 'blue';
    if (decodedEsc.contains(';45')) attr.bgColor = 'magenta';
    if (decodedEsc.contains(';46')) attr.bgColor = 'cyan';
    if (decodedEsc.contains(';47')) attr.bgColor = 'white';
  }
}