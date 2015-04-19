import 'dart:html';
import 'dart:async';
import 'dart:typed_data';
import 'package:terminal/terminal.dart';
import 'package:terminal/theme.dart';

WebSocket ws;
Terminal term;

void main() {
  term = new Terminal(querySelector('#console'))
    ..scrollSpeed = 3
    ..cursorBlink = true
    ..theme = new Theme.SolarizedDark();

  initWebSocket('ws://localhost:12061/pty');

  term.stdin.stream.listen((data) {
    ws.sendByteBuffer(new Uint8List.fromList(data).buffer);
  });
}

void initWebSocket(String url, [int retrySeconds = 2]) {
    bool encounteredError = false;

    ws = new WebSocket(url);
    ws.binaryType = "arraybuffer";

    ws.onOpen.listen((e) {
      print('Console-$num connected to server with status ${ws.readyState}.');
    });

    ws.onMessage.listen((e) {
      ByteBuffer buf = e.data;
      term.stdout.add(buf.asUint8List());
    });

    ws.onClose.listen((e) {
      print('Console-$num disconnected due to CLOSE. Retrying...');
      if (!encounteredError) {
        new Timer(new Duration(seconds:retrySeconds), () => initWebSocket(url, retrySeconds * 2));
      }
      encounteredError = true;
    });

    ws.onError.listen((e) {
      print('Console-$num disconnected due to ERROR. Retrying...');
      if (!encounteredError) {
        new Timer(new Duration(seconds:retrySeconds), () => initWebSocket(url, retrySeconds * 2));
      }
      encounteredError = true;
    });
  }