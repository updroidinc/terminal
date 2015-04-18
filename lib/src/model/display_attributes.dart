part of terminal;

/// Holds the current state of [Terminal] display attributes.
class DisplayAttributes {
  bool bright, dim, underscore, blink, reverse, hidden;
  String fgColor, bgColor;

  DisplayAttributes ({this.bright: false, this.dim: false, this.underscore: false,
         this.blink: false, this.reverse: false, this.hidden: false,
         this.fgColor: 'white', this.bgColor: 'black'});

  String toString() {
    Map properties = {
      'bright': bright,
      'dim': dim,
      'underscore': underscore,
      'blink': blink,
      'reverse': reverse,
      'hidden': hidden,
      'fgColor': fgColor,
      'bgColor': bgColor
    };
    return JSON.encode(properties);
  }

  void resetAll() {
    bright = false;
    dim = false;
    underscore = false;
    blink = false;
    reverse = false;
    hidden = false;

    fgColor = 'white';
    bgColor = 'black';
  }
}