part of input;

// Remapping of Dart keyCodes (whatever they really are)
// to UTF8 integers of their Non-Shift equivalents.
const Map<int, int> NOSHIFT_KEYS = const {
  65: 97,   // A => a
  66: 98,   // B => b
  67: 99,   // C => c
  68: 100,  // D => d
  69: 101,  // E => e
  70: 102,  // F => f
  71: 103,  // G => g
  72: 104,  // H => h
  73: 105,  // I => i
  74: 106,  // J => j
  75: 107,  // K => k
  76: 108,  // L => l
  77: 109,  // M => m
  78: 110,  // N => n
  79: 111,  // O => o
  80: 112,  // P => p
  81: 113,  // Q => q
  82: 114,  // R => r
  83: 115,  // S => s
  84: 116,  // T => t
  85: 117,  // U => u
  86: 118,  // V => v
  87: 119,  // W => w
  88: 120,  // X => x
  89: 121,  // Y => y
  90: 122,  // Z => z

  // Num Lock
  96: 48,   // ` => 0
  97: 49,   // a => 1
  98: 50,   // b => 2
  99: 51,   // c => 3
  100: 52,  // d => 4
  101: 53,  // e => 5
  102: 54,  // f => 6
  103: 55,  // g => 7
  104: 56,  // h => 8
  105: 57,  // i => 9
  110: 46, // n => .
  111: 47,  // o => /
  106: 42,  // j => *
  109: 45,  // m => -
  107: 43,  // k => +

  186: 59,  // : => ;
  187: 61,  // + => =
  188: 44,  // < => ,
  189: 45,  // _ => -
  190: 46,  // > => .
  191: 47,  // ? => /
  192: 96,  // ~ => `
  219: 91,  // { => [
  220: 92,  // | => \
  221: 93,  // } => ]
  222: 39   // " => '
};

// Remapping of Dart keyCodes (whatever they really are)
// to UTF8 integers of their Non-Shift equivalents.
const SHIFT_KEYS = const {
  48: 41,   // 0 => )
  49: 33,   // 1 => !
  50: 64,   // 2 => @
  51: 35,   // 3 => #
  52: 36,   // 4 => $
  53: 37,   // 5 => %
  54: 94,   // 6 => ^
  55: 38,   // 7 => &
  56: 42,   // 8 => *
  57: 40,   // 9 => (
  186: 58,  // :
  187: 43,  // +
  188: 60,  // <
  189: 95,  // _
  190: 62,  // >
  191: 63,  // ?
  192: 126, // ~
  219: 123, // {
  220: 124, // |
  221: 125, // }
  222: 34   // "
};

Map<int, List> CURSOR_KEYS_NORMAL = {
  38: [27, 91, 65], // UP
  40: [27, 91, 66], // DOWN
  37: [27, 91, 68], // LEFT
  39: [27, 91, 67]  // RIGHT
};

Map<int, List> CURSOR_KEYS_APP = {
  38: [107], // UP
  40: [106], // DOWN
  37: [104], // LEFT
  39: [108]  // RIGHT
};

const Map<int, String> NON_MODIFIABLE_KEYS = const {
  8: 'BACKSPACE',
  9: 'TAB',
  13: 'ENTER',
  19: 'PAUSE',
  20: 'CAPS_LOCK',
  27: 'ESC',
  32: 'SPACE',
  33: 'PAGE_UP',
  34: 'PAGE_DOWN',
  35: 'END',
  36: 'HOME',
  37: 'LEFT',
  38: 'UP',
  39: 'RIGHT',
  40: 'DOWN',
  45: 'INSERT',
  46: 'DELETE',
  91: 'LWIN',
  92: 'RWIN',
  112: 'F1',
  113: 'F2',
  114: 'F3',
  115: 'F4',
  116: 'F5',
  117: 'F6',
  118: 'F7',
  119: 'F8',
  120: 'F9',
  121: 'F10',
  122: 'F11',
  123: 'F12',
  144: 'NUM_LOCK',
  145: 'SCROLL_LOCK'
};