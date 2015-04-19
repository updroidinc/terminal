import 'dart:html';
import 'dart:async';
import 'dart:typed_data';
import 'package:terminal/terminal.dart';
import 'package:terminal/theme.dart';

void main() {
  Terminal term = new Terminal(querySelector('#console'))
    ..scrollSpeed = 3
    ..cursorBlink = true
    ..theme = new Theme.SolarizedDark();

  WebSocket ws = initWebSocket('ws://localhost:12061/pty');

  term.stdin.stream.listen((data) {
    print(data.toString());
    ws.sendByteBuffer(new Uint8List.fromList(data).buffer);
  });

  ws.onMessage.listen((e) {
    ByteBuffer buf = e.data;
    term.stdout.add(buf.asUint8List());
  });

}

WebSocket initWebSocket(String url, [int retrySeconds = 2]) {
    bool encounteredError = false;

    WebSocket ws = new WebSocket(url);
    ws.binaryType = "arraybuffer";

    ws.onClose.listen((e) {
      print('Console-$num disconnected. Retrying...');
      if (!encounteredError) {
        new Timer(new Duration(seconds:retrySeconds), () => initWebSocket(url, retrySeconds * 2));
      }
      encounteredError = true;
    });

    ws.onError.listen((e) {
      print('Console-$num disconnected. Retrying...');
      if (!encounteredError) {
        new Timer(new Duration(seconds:retrySeconds), () => initWebSocket(url, retrySeconds * 2));
      }
      encounteredError = true;
    });

    return ws;
  }