import 'package:flutter/material.dart';
import 'webrtc_manager.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<WebRTCManager> _webRTCManagers = [
    WebRTCManager(cam: '43'),
    WebRTCManager(cam: '40'),
    WebRTCManager(cam: '1'),
    WebRTCManager(cam: '2'),
  ];

  @override
  void initState() {
    super.initState();
    for (var manager in _webRTCManagers) {
      manager.initialize();
    }
  }

  @override
  void dispose() {
    for (var manager in _webRTCManagers) {
      manager.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1c222f),
      appBar: AppBar(
        backgroundColor: Color(0xFF283144),
        title: Center(
          child: Text('Live video streamer',
              style: TextStyle(color: Colors.white)),
        ),
      ),
      body: Wrap(
        runSpacing: 10.0,
        children: _webRTCManagers
            .map((manager) => SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  height: MediaQuery.of(context).size.height / 2,
                  child: Container(
                    color: Color(
                        0xFF11151D), // Cambia a cualquier color que desees
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: RTCVideoView(manager.remoteRenderer),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
