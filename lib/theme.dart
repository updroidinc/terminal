library theme.dart;

/// A class for encapsulating various color themes
/// for [Terminal];
class Theme {
  String name;
  Map colors;
  String backgroundColor;

  // Manually calculated via trial-and-error.
  double charWidth = 6.778;
  int charHeight = 14;

  Theme.SolarizedDark() {
    name = 'solarized-dark';
    colors = {
      'black'   : '#002b36',
      'red'     : '#dc322f',
      'green'   : '#859900',
      'yellow'  : '#b58900',
      'blue'    : '#268bd2',
      'magenta' : '#d33682',
      'cyan'    : '#2aa198',
      'white'   : '#93a1a1'
    };

    backgroundColor = '#002b36';
  }

  Theme.SolarizedLight() {
    name = 'solarized-light';
    colors = {
      'black'   : '#fdf6e3',
      'red'     : '#dc322f',
      'green'   : '#859900',
      'yellow'  : '#b58900',
      'blue'    : '#268bd2',
      'magenta' : '#d33682',
      'cyan'    : '#2aa198',
      'white'   : '#586e75'
    };

    backgroundColor = '#fdf6e3';
  }
}