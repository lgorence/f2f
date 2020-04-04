import 'package:f2f/connection/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:flutter_webrtc/rtc_video_view.dart'
    if (dart.library.js) 'package:flutter_webrtc/web/rtc_video_view.dart';

void main() {
  runApp(Face2FaceApp());
}

class Face2FaceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'f2f',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: HomePage(title: 'f2f'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _roomIdJoin = "";

  Future<void> _createCall() async {
    var roomId = await createRoom();

    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return InCallPage(roomId, true);
    }));
  }

  Future<void> _joinCall() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return InCallPage(_roomIdJoin, false);
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            FlatButton(
              child: Text('Create Call'),
              onPressed: _createCall,
            ),
            Container(
              width: 300,
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Room ID',
                ),
                onChanged: (text) {
                  setState(() {
                    _roomIdJoin = text;
                  });
                },
              ),
            ),
            FlatButton(
              child: Text('Join Call'),
              onPressed: _joinCall,
            ),
          ],
        ),
      ),
    );
  }
}

class InCallPage extends StatefulWidget {
  final String roomId;
  final bool showRoomIdPrompt;

  InCallPage(this.roomId, this.showRoomIdPrompt);

  @override
  _InCallPageState createState() => _InCallPageState();
}

class _InCallPageState extends State<InCallPage> {
  RtcClient _client = new RtcClient();
  bool _initialized = false;
  bool _muted = false;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    joinRoom(widget.roomId, widget.showRoomIdPrompt);
  }

  Future<void> joinRoom(String roomId, bool showRoomIdPrompt) async {
    if (_initialized) {
      await _client.close();
    }

    _client.onLocalStream = (stream) {
      print('newLocalStream: ${stream.id}');
      _localRenderer.srcObject = stream;
      _localRenderer.onStateChanged = () {
        if (WebRTC.platformIsWeb) {
          print('muted renderer');
          _localRenderer.isMuted = true;
        }
      };
    };
    _client.onRemoteStream = (stream) {
      print('newRemoteStream: ${stream.id}');
      _remoteRenderer.srcObject = stream;
    };

    await _client.join(roomId);
    setState(() {
      _initialized = true;
    });

    if (showRoomIdPrompt) {
      showDialog(
        context: context,
        //child:
        child: AlertDialog(
          content: SelectableText(
              'Room ID (give this to your meeting partner): $roomId'),
          actions: <Widget>[
            FlatButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        ),
      );
    }
  }

  Future<void> _offer() async {
    await _client.offer();
  }

  Future<void> _openDebug() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (context) => InCallDebugPage(_client)));
  }

  void _toggleMuted() {
    setState(() {
      _muted = !_muted;
      _client.setMute(_muted);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('In Call'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.call),
            onPressed: _offer,
            tooltip: 'Offer',
          ),
          IconButton(
            icon: Icon(_muted ? Icons.mic_off : Icons.mic),
            onPressed: _toggleMuted,
            tooltip: _muted ? 'Mute' : 'Unmute',
          ),
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: _openDebug,
            tooltip: 'Open Debug',
          ),
        ],
      ),
      body: Container(
        //width: 500,
        //height: 500,
        child: RTCVideoView(_remoteRenderer),
      ),
      floatingActionButton: Container(
        width: 150,
        height: 150,
        child: RTCVideoView(_localRenderer),
      ),
    );
  }
}

class InCallDebugPage extends StatelessWidget {
  final RtcClient _client;

  InCallDebugPage(this._client);

  Future<void> _ping() async {
    await _client.ping();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call Debug Page'),
      ),
      body: Column(
        children: <Widget>[
          FlatButton(
            child: Text('Ping'),
            onPressed: _ping,
          ),
        ],
      ),
    );
  }
}
