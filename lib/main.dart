import 'package:f2f/connection/peer.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'face2face',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  RtcClient _client = new RtcClient();
  bool _initialized = false;

  Future<void> _initCall() async {
    if (_initialized) {
      await _client.close();
    }

    await _client.create();
    setState(() {
      _initialized = true;
    });
  }

  Future<void> _startOffer() async {
    await _client.offer();
  }

  Future<void> _ping() async {
    await _client.ping();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FlatButton(
              child: Text(
                'Init Call'
              ),
              onPressed: _initialized ? null : _initCall,
            ),
            FlatButton(
              child: Text(
                'Offer'
              ),
              onPressed: _startOffer,
            ),
            FlatButton(
              child: Text(
                'Ping'
              ),
              onPressed: _ping,
            ),
          ],
        ),
      ),
    );
  }
}
