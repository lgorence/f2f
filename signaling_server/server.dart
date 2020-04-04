import 'dart:async';
import 'dart:io';

import 'dart:math';

const _randomWords = [
  "disapprove",
  "metal",
  "thread",
  "wide",
  "railway",
  "alluring",
  "dizzy",
  "badge",
  "poised",
  "charming",
  "plausible",
  "moan",
  "lean",
  "label",
  "flight",
  "substance",
  "violent",
  "account",
  "advise",
  "bedroom",
  "closed",
  "instruct",
  "caring",
  "coat",
  "magical",
  "position",
  "youthful",
  "twist",
  "furry",
  "naive",
  "seat",
  "knee",
  "sidewalk",
  "flame",
  "wicked",
  "lazy",
  "tiny",
  "healthy",
  "salt",
  "volleyball",
  "concerned",
  "rich",
  "polite",
  "stream",
  "cry",
  "call",
  "freezing",
  "teeny",
  "abounding",
  "unruly",
  "telling",
  "foot",
  "love",
  "sleet",
  "breathe",
  "great",
  "pinch",
  "chemical",
  "approve",
  "tin",
  "copper",
  "icy",
  "alive",
  "bare",
  "pin",
  "stingy",
  "automatic",
  "godly",
  "support",
  "bushes",
  "reflect",
  "mere",
  "food",
  "early",
  "zany",
  "deadpan",
  "nod",
  "introduce",
  "remarkable",
  "structure",
  "silk",
  "preserve",
  "sugar",
  "decorous",
  "known",
  "determined",
  "decision",
  "store",
  "steam",
  "legal",
  "spooky",
  "stretch",
  "open",
  "modern",
];

var random = Random();
var rooms = <String, Room>{};

Future<void> main(List<String> args) async {
  var httpServer = await HttpServer.bind(InternetAddress.anyIPv4, 8888);
  httpServer.listen(requestHandler);

  print('Listening on port 8888');

  Timer.periodic(Duration(minutes: 5), (timer) {
    var roomCount = rooms.length;
    rooms.removeWhere((name, room) => room.isActive);
    roomCount -= rooms.length;
    if (roomCount > 0) {
      print('Purged $roomCount rooms');
    }
  });
}

Future<void> requestHandler(HttpRequest request) async {
  request.response.headers.add('Access-Control-Allow-Origin', '*');

  try {
    if (request.requestedUri.path == '/ws') {
      var roomId = request.requestedUri.queryParameters['roomId'];
      if (rooms.containsKey(roomId)) {
        var room = rooms[roomId];
        var webSocket = await WebSocketTransformer.upgrade(request);
        room.addNewClient(webSocket);
      } else {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.writeln("Room $roomId does not exist.");
        await request.response.close();
      }
    } else if (request.requestedUri.path == '/createRoom') {
      var words = <String>[];
      for (var i = 0; i < 5; i++) {
        words.add(_randomWords[random.nextInt(_randomWords.length)]);
      }
      var roomId = words.join("-");
      rooms[roomId] = Room();
      request.response.write(roomId);
      await request.response.close();
    } else {
      request.response.statusCode = 404;
      await request.response.close();
    }
  } catch (e) {
    print('Error: $e');
  }
}

class Room {
  List<WebSocket> _webSockets = [];
  int _lastEventTs;

  Room() {
    _updateLastEventTs();
  }

  void _updateLastEventTs() {
    _lastEventTs = DateTime.now().millisecondsSinceEpoch;
  }

  bool get isActive =>
      DateTime.now().millisecondsSinceEpoch - _lastEventTs > 300000;

  void addNewClient(WebSocket webSocket) {
    _updateLastEventTs();
    print('newClient');

    _webSockets.add(webSocket);
    webSocket.listen((data) => broadcastToAll(webSocket, data),
        onDone: () => dropClient(webSocket));
  }

  void dropClient(WebSocket webSocket) {
    _updateLastEventTs();
    print('dropClient');

    _webSockets.remove(webSocket);
  }

  void broadcastToAll(WebSocket webSocket, dynamic data) {
    _updateLastEventTs();
    print('broadcast: $data');

    _webSockets.forEach((ws) {
      if (webSocket != ws) {
        ws.add(data);
      }
    });
  }
}
