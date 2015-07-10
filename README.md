# Terminal

A terminal emulator written in Dart.

Connect its I/O to a WebSocket or whatever you like. Originally developed for use with [cmdr-pty] in [UpDroid Commander].

![Imgur](http://i.imgur.com/Bz8St7a.gif)

## Usage

Terminal's only parameter is a DivElement - essentially a box that Terminal will be rendered in.

The major components are the I/O streams. They are expected to be hooked up to ByteBuffers of Uint8Lists. Best used by hooking up to a backend, like [cmdr-pty], that sends/receives data in UTF-8. But it could also be used with text/data that resides solely in the browser application.

Theme is a separate library that contains built-in color schemes.

There are other options like scroll speed, cursor blink, and the theme.

See example/ for more details.

## Examples

There are two examples, found in the example/ dir. Both of these require Dartium (special Dart-enabled build of Chromium) unless you know how to compile the examples using dart2js (you're on your own for that).

### Server

Run `dart /path/to/example/server/main.dart`. A webserver will begin running, then you may open Dartium and point it to "localhost:8080". This example demonstrates how to build a server application that serves a Terminal client application and also connects this client to a pty backend [cmdr-pty] via TCP socket.

### Websocket

Requires [cmdr-pty]. Follow the directions to run cmdr-pty in a regular terminal - the default settings should be fine. Then run your own webserver on example/websocket/web/index.html. You can use an IDE like DartEditor or WebStorm, or possibly Dartium itself.

This example demonstrates how to build a client-side-only Terminal application that connects directly to a pty backend via Websocket.

## Known Issues

- Terminal only supports vt100 mode at the moment. Make sure to `export TERM=vt100` if using [cmdr-pty] before running it.
- Appearance is fine-tuned to the specific styling used in example/main.css. Deviation from the font-family and size will break Terminal's appearance at best.

## Contribute

Pull requests welcome! Though, I reserve the right to review and/or reject them at will.
Can also file issues with the issue tracker.

I prefer commit messages to start with the library/component mostly affected by the commit, but this style isn't required for contributions.

### TODO:

- Add support for vt102, xterm.
- Move Terminal's styling into code for self-containment and improve flexibility.

## Acknowledgements

Heavily inspired by the [term.js] project by (chjj) Christopher Jeffrey. But I needed a more flexible, native-Dart implementation for [UpDroid Commander].

[cmdr-pty]: https://github.com/updroidinc/cmdr-pty/
[UpDroid Commander]: http://updroid.com/upcom/
[term.js]: https://github.com/chjj/term.js/
