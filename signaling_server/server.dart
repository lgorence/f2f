import 'dart:io';

List<WebSocket> _webSockets = [];

Future<void> main(List<String> args) async {
  var httpServer = await HttpServer.bind(InternetAddress.anyIPv4, 8888);

  httpServer.listen(requestHandler);
}

Future<void> requestHandler(HttpRequest request) async {
  if (request.requestedUri.path == '/ws') {
    var webSocket = await WebSocketTransformer.upgrade(request);
    addNewClient(webSocket);
    return;
  }
  request.response.statusCode = 404;
  await request.response.close();
}

void addNewClient(WebSocket webSocket) {
  print('newClient');

  _webSockets.add(webSocket);
  webSocket.listen((data) => broadcastToAll(webSocket, data), onDone: () => dropClient(webSocket));
}

void dropClient(WebSocket webSocket) {
  print('dropClient');

  _webSockets.remove(webSocket);
}

void broadcastToAll(WebSocket webSocket, dynamic data) {
  print('broadcast: $data');
  _webSockets.forEach((ws) {
    if (webSocket != ws) {
      ws.add(data);
    }
  });
}
