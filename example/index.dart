import 'dart:html';
import 'dart:async';
import 'dart:typed_data';
import 'package:terminal/terminal.dart';
import 'package:terminal/theme.dart';

void main() {
  Terminal _term = new Terminal(querySelector('#console'))
    ..scrollSpeed = 3
    ..cursorBlink = true
    ..theme = new Theme.SolarizedDark();

  WebSocket _ws = _initWebSocket('ws://localhost:12061/pty');

  _term.stdin.stream.listen((data) {
    print(data.toString());
    _ws.sendByteBuffer(new Uint8List.fromList(data).buffer);
  });

  _ws.onMessage.listen((e) {
    ByteBuffer buf = e.data;
    _term.stdout.add(buf.asUint8List());
  });

}

WebSocket _initWebSocket(String url, [int retrySeconds = 2]) {
    bool encounteredError = false;

    WebSocket _ws = new WebSocket(url);
    _ws.binaryType = "arraybuffer";

    _ws.onClose.listen((e) {
      print('Console-$num disconnected. Retrying...');
      if (!encounteredError) {
        new Timer(new Duration(seconds:retrySeconds), () => _initWebSocket(url, retrySeconds * 2));
      }
      encounteredError = true;
    });

    _ws.onError.listen((e) {
      print('Console-$num disconnected. Retrying...');
      if (!encounteredError) {
        new Timer(new Duration(seconds:retrySeconds), () => _initWebSocket(url, retrySeconds * 2));
      }
      encounteredError = true;
    });

    return _ws;
  }