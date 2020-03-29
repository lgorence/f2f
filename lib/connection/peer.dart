import 'dart:convert';
import 'dart:html';

import 'package:flutter_webrtc/webrtc.dart';

class RtcClient {
  final constraints = {
    "mandatory": {"OfferToReceiveAudio": true, "OfferToReceiveVideo": true},
    "optional": []
  };

  WebSocket _signalWs;
  RTCPeerConnection _peerConnection;
  RTCDataChannel _dataChannel;

  RtcClient();

  Future<void> create() async {
    _signalWs = new WebSocket('ws://palpatine.gorence.xyz:8888/ws');
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

    _dataChannel = await _createDataChannel();

    _peerConnection.onIceCandidate = _onCandidate;
    _peerConnection.onDataChannel = _onDataChannel;
    _peerConnection.onRenegotiationNeeded = _onNegotiationNeeded;

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

  Future<void> _onCandidate(RTCIceCandidate iceCandidate) async {
    print('iceCandidate: ${iceCandidate.candidate}');
    _sendSignal({
      'type': 'iceCandidate',
      'payload': iceCandidate.toMap()
    });
  }

  Future<void> _onDataChannel(RTCDataChannel dataChannel) async {
    print('dataChannel: $dataChannel');
  }

  Future<void> _onNegotiationNeeded() async {
    print('negotiationNeeded');
  }

  void _sendSignal(Map<String, dynamic> data) {
    print('sentSignal: $data');
    _signalWs.send(jsonEncode(data));
  }

  Future<RTCDataChannel> _createDataChannel() async {
    var dataChannelConfig = RTCDataChannelInit();
    var dataChannel = await _peerConnection.createDataChannel(
        'dataChannel', dataChannelConfig);
    dataChannel.onDataChannelState = (state) async {
      print(state.toString());
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        await dataChannel.send(RTCDataChannelMessage('test'));
      }
    };
    dataChannel.onMessage = (message) async {
      print('dataChannel onMessage: ${message.text}');
    };

    return dataChannel;
  }

  Future<void> _onSignalMessage(MessageEvent event) async {
    var data = jsonDecode(event.data as String);
    print('signal: $data');
    var payload = data['payload'];

    if (data['type'] == 'offer') {
      await _peerConnection.setRemoteDescription(convertMapToSession(payload));
      await answer();
    } else if (data['type'] == 'answer') {
      await _peerConnection.setRemoteDescription(convertMapToSession(payload));
    } else if (data['type'] == 'iceCandidate') {
      await _peerConnection.addCandidate(convertMapToCandidate(payload));
    }
  }

  RTCSessionDescription convertMapToSession(Map<String, dynamic> map) {
    return RTCSessionDescription(map['sdp'], map['type']);
  }

  RTCIceCandidate convertMapToCandidate(Map<String, dynamic> map) {
    return RTCIceCandidate(map['candidate'], map['sdpMid'], map['sdpMLineIndex']);
  }
}
