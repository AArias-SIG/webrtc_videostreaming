import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'package:http/http.dart' as http;

class WebRTCManager {
  RTCPeerConnection? _peerConnection;
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final String cam;

  WebRTCManager({required this.cam});
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  initialize() async {
    await _initRenderer();
    _createPeerConnection().then((pc) {
      _peerConnection = pc;
      _createOffer();
    });
  }

  dispose() {
    _remoteRenderer.dispose();
  }

  _initRenderer() async {
    await _remoteRenderer.initialize();
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    Map<String, dynamic> config = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"}
      ],
    };

    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "offerToReceiveAudio": true,
      },
      "optional": [],
    };

    RTCPeerConnection pc = await createPeerConnection(
      config,
      offerSdpConstraints,
    );

    pc.onIceCandidate = (e) {
      if (e.candidate != null) {
        print('printing ICE candidates');
        print(json.encode({
          "candidate": e.candidate,
          "sdpMid": e.sdpMid,
          "sdpMLineInd": e.sdpMLineIndex,
        }));
      }
    };

    pc.onIceConnectionState = (e) {
      print('printing ICE connection state');
      print(e);
    };
    pc.onAddStream = (str) {
      print('add stream:  ${str.id}');
      _remoteRenderer.srcObject = str;
    };

    return pc;
  }

  void _createOffer() async {
    if (_peerConnection != null) {
      RTCSessionDescription desc =
          await _peerConnection!.createOffer({'offerToReceiveVideo': 1});

      final session = parse(desc.sdp!);
      print('sessions on creating offers');
      print(json.encode(session));

      await _peerConnection?.setLocalDescription(desc);

      // Send the offer to the remote server
      try {
        final response = await http.post(
          Uri.parse('http://64.156.221.242:5000/offer'),
          //Uri.parse('http://192.168.110.123:5000/offer'),
          headers: {
            'Content-Type':
                'application/json', // Specify the content type as JSON
          },
          body: jsonEncode({
            "sdp": desc.sdp,
            "type": desc.type,
            "cam": cam,
          }),
        );

        if (response.statusCode == 200) {
          final answer = jsonDecode(response.body);
          if (answer['sdp'] != null && answer['type'] != null) {
            _setRemoteDescription(answer['sdp'], answer['type']);
          } else {
            print('Invalid answer received from the server');
          }
        } else {
          print(
              'Failed to fetch answer from the server: ${response.reasonPhrase}');
        }
      } catch (e) {
        print('Failed to send offer: $e');
      }
    }
  }

  void _setRemoteDescription(String sdp, String type) async {
    if (_peerConnection != null) {
      RTCSessionDescription desc = RTCSessionDescription(sdp, type);
      print('setting remote description');
      print(desc.toMap());

      try {
        await _peerConnection!.setRemoteDescription(desc);
      } catch (e) {
        print('Failed to set remote description: $e');
      }
    }
  }
}
