# Terminal

A terminal emulator written in Dart.

Connect its I/O to a WebSocket or whatever you like. Originally developed for use with [cmdr-pty] in [UpDroid Commander].

![Imgur](http://i.imgur.com/Bz8St7a.gif)

## Package Usage

***Tested with Dart 1.10.1***

Terminal's only parameter is a DivElement - essentially a box that Terminal will be rendered in.

The major components are the I/O streams. They are expected to be hooked up to ByteBuffers of Uint8Lists. Best used by hooking up to a backend, like [cmdr-pty], that sends/receives data in UTF-8. But it could also be used with text/data that resides solely in the browser application.

Theme is a separate library that contains built-in color schemes.

There are other options like scroll speed, cursor blink, and the theme.

See example/ for more details.

## Examples

There are two examples, found in the example/ dir. Both of these require Dartium (special Dart-enabled build of Chromium) unless you know how to compile the examples using dart2js (you're on your own for that).

Common setup:
```bash
cd /path/to/terminal
pub get
```

### Server

This example demonstrates how to build a client-server application that serves a Terminal client and also connects this client to a pty [cmdr-pty] on the server side via TCP socket.

```bash
chmod +x example/server/main.dart
dart example/server/main.dart
```

A webserver will begin running, then you may open Dartium and point it to "localhost:8080".

### Websocket

This example demonstrates how to build a client-side-only Terminal application that connects directly to a pty backend via Websocket. In other words, this is like the server example, but with the built-in webserver removed.

Requires [cmdr-pty]. Follow the directions to run cmdr-pty in a regular terminal - the default settings should be fine.

Then run your own webserver (like [http-server] via npm) on `/path/to/terminal/example/websocket/web/index.html`.

## Known Issues

- Terminal only supports vt100 mode at the moment. Make sure to `export TERM=vt100` if using [cmdr-pty] before running it.
- Appearance is fine-tuned to the specific styling used in example/main.css. Deviation from the font-family and size will break Terminal's appearance at best.

## Contribute

Pull requests welcome! Though, I reserve the right to review and/or reject them at will.
Can also file issues with the issue tracker.

I prefer commit messages to start with the library/component mostly affected by the commit, but this style isn't required for contributions.

### TODO:

- Support for vt102, xterm.
- Add resizing to the example clients.
- Improve performance.
- More themes.
- Upgrade supported SDK version to 1.13.x.
  - Add dartfmt to [git pre-commit hook].
- Unit tests.

## Acknowledgements

Heavily inspired by the [term.js] project by (chjj) Christopher Jeffrey. But I needed a more flexible, native-Dart implementation for [UpDroid Commander].

[cmdr-pty]: https://github.com/updroidinc/cmdr-pty/
[UpDroid Commander]: http://updroid.com/upcom/
[term.js]: https://github.com/chjj/term.js/
[http-server]: https://www.npmjs.com/package/http-server
[git pre-commit hook]: http://blog.sethladd.com/2015/04/formatting-dart-code-before-every-git.html
