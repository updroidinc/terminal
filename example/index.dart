import 'dart:html';
import 'dart:async';
import 'dart:typed_data';
import 'package:terminal/terminal.dart';
import 'package:terminal/theme.dart';

WebSocket ws;
InputElement address;
ButtonElement connect, invert;
SpanElement status;
Terminal term;

void main() {
  address = querySelector('#address');
  connect = querySelector('#connect');
  invert = querySelector('#invert');
  status = querySelector('#status');

  term = new Terminal(querySelector('#console'))
    ..scrollSpeed = 3
    ..cursorBlink = true
    ..theme = new Theme.SolarizedDark();

  List<int> size = term.currentSize();
  int rows = size[0];
  int cols = size[1];
  print('Terminal spawned with size: $rows x $cols');
  print('└─> cmdr-pty size should be set to $rows x ${cols - 1}');

  address.onKeyPress
  .where((e) => e.keyCode == KeyCode.ENTER)
  .listen((_) => restartWebsocket());

  connect.onClick.listen((_) => restartWebsocket());
  invert.onClick.listen((_) => invertTheme());

  // Terminal input.
  term.stdin.stream.listen((data) {
    ws.sendByteBuffer(new Uint8List.fromList(data).buffer);
  });
}

void updateStatusConnect() {
  status.classes.add('connected');
  status.text = 'Connected';
  print('Terminal connected to server with status ${ws.readyState}.');
}

void updateStatusDisconnect() {
  status.classes.remove('connected');
  status.text = 'Disconnected';
  print('Terminal disconnected due to CLOSE.');
}

void restartWebsocket() {
  if (address.value == '') return;

  if (ws != null && ws.readyState == WebSocket.OPEN) ws.close();
  initWebSocket('ws://${address.value}/pty');
}

void initWebSocket(String url, [int retrySeconds = 2]) {
  bool encounteredError = false;

  ws = new WebSocket(url);
  ws.binaryType = "arraybuffer";

  ws.onOpen.listen((e) => updateStatusConnect());

  // Terminal output.
  ws.onMessage.listen((e) {
    ByteBuffer buf = e.data;
    term.stdout.add(buf.asUint8List());
  });

  ws.onClose.listen((e) => updateStatusDisconnect());

  ws.onError.listen((e) {
    print('Terminal disconnected due to ERROR. Retrying...');
    if (!encounteredError) {
      new Timer(new Duration(seconds:retrySeconds), () => initWebSocket(url, 4));
    }
    encounteredError = true;
  });
}

void invertTheme() {
  term.theme = term.theme.name == 'solarized-light' ? new Theme.SolarizedDark() : new Theme.SolarizedLight();
}