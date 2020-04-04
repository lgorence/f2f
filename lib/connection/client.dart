import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter_webrtc/webrtc.dart';

typedef void OnMediaStream(MediaStream mediaStream);

Future<String> createRoom() async {
  // dart:io based code
  /*var request = await HttpClient().getUrl(Uri.parse('http://localhost:8888/createRoom'));
  var response = await request.close();
  return response.transform(utf8.decoder).join();*/
  return html.HttpRequest.getString('https://signal.prod.f2f.gorence.io/createRoom');
}

class RtcClient {
  final constraints = {
    'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
    'optional': []
  };

  OnMediaStream onLocalStream;
  OnMediaStream onRemoteStream;

  MediaStream _localStream;
  html.WebSocket _signalWs;
  RTCPeerConnection _peerConnection;
  RTCDataChannel _dataChannel;

  RtcClient();

  Future<void> join(String roomId) async {
    _localStream = await _createLocalStream();
    if (onLocalStream != null) {
      onLocalStream(_localStream);
    }

    _signalWs = new html.WebSocket('wss://signal.prod.f2f.gorence.io/ws?roomId=$roomId');
    _signalWs.onMessage.listen(_onSignalMessage);

    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'}
      ]
    }, {
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true}
      ]
    });
    _peerConnection.addStream(_localStream);

    _peerConnection.onIceCandidate = _onCandidate;
    _peerConnection.onDataChannel = _onDataChannel;
    _peerConnection.onRenegotiationNeeded = _onNegotiationNeeded;
    _peerConnection.onAddStream = _onAddStream;
    _peerConnection.onAddTrack = _onAddTrack;

    _peerConnection.onSignalingState = (state) {
      print('signalingState: $state');
    };
    _peerConnection.onIceConnectionState = (state) {
      print('iceConnState: $state');
    };
    _peerConnection.onIceGatheringState = (state) {
      print('iceGatherState: $state');
    };
  }

  Future<void> offer() async {
    _dataChannel = await _createDataChannel();

    var offer = await _peerConnection.createOffer(constraints);
    print('offer: ${offer.sdp}');

    await _peerConnection.setLocalDescription(offer);
    _sendSignal({'type': 'offer', 'payload': offer.toMap()});
  }

  Future<void> answer() async {
    var answer = await _peerConnection.createAnswer(constraints);
    _peerConnection.setLocalDescription(answer);
    _sendSignal({'type': 'answer', 'payload': answer.toMap()});
  }

  void setMute(bool muted) {
    // TODO: Why would we have more than one audio track?
    _localStream.getAudioTracks()[0].enabled = !muted;
  }

  Future<void> ping() async {
    print('sentPing');
    await _sendChannelData({'type': 'ping'});
  }

  Future<void> close() async {
    await _peerConnection.close();
    _signalWs.close();
  }

  Future<void> _onCandidate(RTCIceCandidate iceCandidate) async {
    print('iceCandidate: ${iceCandidate.candidate}');
    _sendSignal({
      'type': 'iceCandidate',
      'payload': iceCandidate.toMap()
    });
  }

  Future<void> _onDataChannel(RTCDataChannel dataChannel) async {
    print('dataChannel: $dataChannel');
    _dataChannel = dataChannel;

    dataChannel.messageStream.listen(_onDataChannelMessage);
  }

  Future<void> _onNegotiationNeeded() async {
    print('negotiationNeeded');
  }

  Future<void> _onAddStream(MediaStream stream) async {
    print('onAddStream');

    if (stream.id != _localStream.id && onRemoteStream != null) {
      onRemoteStream(stream);
    }
    // TODO: for some reason when we call onRemoteStream above, in our widget
    // it overwrites the local stream that's already there, so we call it again,
    // and this fixes it. *shrug*
    if (onLocalStream != null) {
      onLocalStream(_localStream);
    }
  }

  Future<void> _onAddTrack(MediaStream stream, MediaStreamTrack track) async {
    print('onAddTrack');
  }

  void _sendSignal(Map<String, dynamic> data) {
    print('sentSignal: $data');
    _signalWs.send(jsonEncode(data));
  }

  Future<void> _sendChannelData(Map<String, dynamic> data) async {
    await _dataChannel.send(RTCDataChannelMessage(jsonEncode(data)));
  }

  Future<MediaStream> _createLocalStream() async {
    var mediaConstraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': 480,
          'minHeight': 360,
          'minFrameRate': 15
        },
      },
    };

    return navigator.getUserMedia(mediaConstraints);
  }

  Future<RTCDataChannel> _createDataChannel() async {
    var dataChannelConfig = RTCDataChannelInit();
    var dataChannel = await _peerConnection.createDataChannel(
        'dataChannel', dataChannelConfig);
    dataChannel.messageStream.listen(_onDataChannelMessage);

    return dataChannel;
  }

  Future<void> _onSignalMessage(html.MessageEvent event) async {
    var data = jsonDecode(event.data as String);
    print('signal: $data');
    var payload = data['payload'];

    if (data['type'] == 'offer') {
      await _peerConnection.setRemoteDescription(_convertMapToSession(payload));
      await answer();
    } else if (data['type'] == 'answer') {
      await _peerConnection.setRemoteDescription(_convertMapToSession(payload));
    } else if (data['type'] == 'iceCandidate') {
      await _peerConnection.addCandidate(_convertMapToCandidate(payload));
    }
  }

  Future<void> _onDataChannelMessage(RTCDataChannelMessage message) async {
    print('dataChannelRaw: ${message.text}');
    var data = jsonDecode(message.text);
    print('dataChannelDecode: $data');

    if (data['type'] == 'ping') {
      await _sendChannelData({'type': 'pong'});
    }
  }

  RTCSessionDescription _convertMapToSession(Map<String, dynamic> map) {
    return RTCSessionDescription(map['sdp'], map['type']);
  }

  RTCIceCandidate _convertMapToCandidate(Map<String, dynamic> map) {
    return RTCIceCandidate(map['candidate'], map['sdpMid'], map['sdpMLineIndex']);
  }
}
