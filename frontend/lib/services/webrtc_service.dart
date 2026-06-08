import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'config_service.dart';

class WebRTCService {
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  Function(MediaStream)? onRemoteStream;
  Function(RTCIceCandidate)? onIceCandidate;
  final WebSocketChannel channel;

  WebRTCService({required this.channel});

  final Map<String, dynamic> _configuration = Config.iceConfiguration;

  Future<void> init() async {
    peerConnection = await createPeerConnection(_configuration);

    peerConnection!.onIceCandidate = (candidate) {
      channel.sink.add(jsonEncode({
        'type': 'ice-candidate',
        'candidate': candidate.toMap(),
      }));
    };

    peerConnection!.onAddStream = (stream) {
      onRemoteStream?.call(stream);
    };

    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': false,
    };

    localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    localStream!.getTracks().forEach((track) {
      peerConnection!.addTrack(track, localStream!);
    });
  }

  Future<void> createOffer() async {
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    channel.sink.add(jsonEncode({
      'type': 'offer',
      'sdp': offer.sdp,
    }));
  }

  Future<void> handleOffer(String sdp) async {
    await peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
    RTCSessionDescription answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);
    channel.sink.add(jsonEncode({
      'type': 'answer',
      'sdp': answer.sdp,
    }));
  }

  Future<void> handleAnswer(String sdp) async {
    await peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
  }

  Future<void> addCandidate(Map<String, dynamic> candidateData) async {
    RTCIceCandidate candidate = RTCIceCandidate(
      candidateData['candidate'],
      candidateData['sdpMid'],
      candidateData['sdpMLineIndex'],
    );
    await peerConnection!.addCandidate(candidate);
  }

  void dispose() {
    localStream?.dispose();
    peerConnection?.dispose();
  }
}
