part of model;

/// The data model class for an individual glyph within [Model].
class Glyph {
  static const SPACE = '&nbsp';
  static const AMP = '&amp';
  static const LT = '&lt';
  static const GT = '&gt';
  static const CURSOR = '▏';

  bool bright, dim, underscore, blink, reverse, hidden;
  String value, fgColor, bgColor;

  Glyph (this.value, DisplayAttributes attr) {
    bright = attr.bright;
    dim = attr.dim;
    underscore = attr.underscore;
    blink = attr.blink;
    reverse = attr.reverse;
    hidden = attr.hidden;
    fgColor = attr.fgColor;
    bgColor = attr.bgColor;
  }

  operator ==(Glyph other) {
    return (value == other.value
            && bright == other.bright
            && dim == other.dim
            && underscore == other.underscore
            && blink == other.blink
            && reverse == other.reverse
            && hidden == other.hidden
            && fgColor == other.fgColor
            && bgColor == other.bgColor);
  }

  bool hasSameAttributes(Glyph other) {
    return (bright == other.bright
            && dim == other.dim
            && underscore == other.underscore
            && blink == other.blink
            && reverse == other.reverse
            && hidden == other.hidden
            && fgColor == other.fgColor
            && bgColor == other.bgColor);
  }

  bool hasDefaults() {
    return (bright == false
            && dim == false
            && underscore == false
            && blink == false
            && reverse == false
            && hidden == false
            && fgColor == 'white'
            && bgColor == 'black');
  }

  int get hashCode {
    List members = [bright, dim, underscore, blink, reverse, hidden, fgColor, bgColor];
    return hashObjects(members);
  }

  String toString() {
    Map properties = {
      'value': value,
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
}