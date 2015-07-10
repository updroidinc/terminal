library theme.dart;

/// A class for encapsulating various color themes
/// for [Terminal];
class Theme {
  String name;
  Map colors;
  String foregroundColor, backgroundColor;

  // Manually calculated via trial-and-error.
  // TODO: make the character size customizable.
  final double charWidth = 299 / 45;
  final int charHeight = 14;

  Theme(this.name, this.colors, this.foregroundColor, this.backgroundColor);

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

    foregroundColor = colors['white'];
    backgroundColor = colors['black'];
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

    foregroundColor = colors['white'];
    backgroundColor = colors['black'];
  }
}