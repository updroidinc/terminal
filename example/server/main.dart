#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

import 'package:http_server/http_server.dart';

Process pty;
Socket socket;
WebSocket websocket;

/// Initializes and HTTP server to serve the gui and handle [WebSocket] requests.
void initServer() {
  // Set up an HTTP webserver and listen for standard page requests or upgraded
  // [WebSocket] requests.
  HttpServer.bind(InternetAddress.ANY_IP_V4, 8080).then((HttpServer server) {
    print("HttpServer listening on port:${server.port}...");
    server.asBroadcastStream()
    .listen((HttpRequest request) => routeRequest(request))
    .asFuture()  // Automatically cancels on error.
    .catchError((_) => print("caught error"));
  });
}

/// Routes a request between standard requests and upgraded (websocket) requests.
void routeRequest(HttpRequest request) {
  // WebSocket requests are considered "upgraded" HTTP requests.
  if (!WebSocketTransformer.isUpgradeRequest(request)) {
    handleStandardRequest(request);
    return;
  }

  print('Upgraded request received: ${request.uri.path}');
  WebSocketTransformer.upgrade(request).then((WebSocket w) {
    websocket = w;
    startPty();
  });
}

/// Returns a [VirtualDirectory] set up with a path from [results].
VirtualDirectory getVirDir() {
  String guiPath = '${Directory.current.path}/example/server/web';
  VirtualDirectory virDir = new VirtualDirectory(Platform.script.resolve(guiPath).toFilePath())
    ..allowDirectoryListing = true
    ..followLinks = true
    ..jailRoot = false;

  // Redirects '/' to 'index.html'
  virDir.directoryHandler = (dir, request) {
    var indexUri = new Uri.file(dir.path).resolve('index.html');
    virDir.serveFile(new File(indexUri.toFilePath()), request);
  };

  return virDir;
}

/// Handler for standard HTTP requests, like file transfers.
void handleStandardRequest(HttpRequest request) {
  print('${request.method} request for: ${request.uri.path}');

  VirtualDirectory virDir = getVirDir();
  if (virDir != null) {
    virDir.serveRequest(request);
  } else {
    print('ERROR: no Virtual Directory to serve');
  }
}

/// Spawns an instance of cmdr-pty as the terminal backend.
/// cmdr-pty is a go program that provides a direct hook to a system pty.
/// See http://www.github.com/updroidinc/cmdr-pty
void startPty() {
  Process.start('cmdr-pty', ['-p', 'tcp'], environment: {'TERM':'vt100'}).then((Process p) {
    pty = p;

    pty.stderr.transform(UTF8.decoder).listen((data) => print('[cmdr-pty stderr]: $data'));
    pty.stdout.transform(UTF8.decoder).listen((data) {
      if (data.contains('listening on port: ')) {
        // Get the port returned by cmdr-pty.
        String port = data.replaceFirst('listening on port: ', '');

        // Connect and start handling IO.
        Socket.connect('127.0.0.1', int.parse(port)).then((s) => handleIO(s));
      }

      print('[cmdr-pty stdout]: $data');
    });
  }).catchError((error) {
    if (error is! ProcessException) throw error;
    print('cmdr-pty: run failed. check installation and/or path.');
    return;
  });
}

/// Manages the IO between websocket and socket for the terminal.
void handleIO(Socket s) {
  socket = s;
  print('server example connected to cmdr-pty via: ${socket.remoteAddress.address}:${socket.remotePort}');

  // Output from cmdr-pty -> the client connected via websocket.
  socket.listen((data) => websocket.add((data)));
  // Input from the client connected via websocket -> cmdr-pty.
  websocket.listen((data) => socket.add(data)).onDone(() => cleanUp());
}

/// Cleans up all the sockets and processes started by this program.
void cleanUp() {
  socket.close();
  websocket.close();
  pty.kill();
}

void main() {
  initServer();
}