import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/config_service.dart';
import '../services/webrtc_service.dart';
import 'summary_screen.dart';

class CallScreen extends StatefulWidget {
  final WebSocketChannel channel;
  final String role;
  final String partnerId;

  const CallScreen({
    super.key,
    required this.channel,
    required this.role,
    required this.partnerId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin {
  late WebRTCService _webRTCService;
  late AnimationController _pulseController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  int _secondsRemaining = Config.callDuration;
  Timer? _timer;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _playRingingSound();
    _initWebRTC();
    _startTimer();
    _listenToSignaling();
    WakelockPlus.enable();
  }

  void _playRingingSound() async {
    // Play a ringing sound while waiting for connection
    // For now using a public URL as a placeholder
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(UrlSource(Config.ringingSoundUrl));
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  void _stopRingingSound() {
    _audioPlayer.stop();
  }

  void _initWebRTC() async {
    _webRTCService = WebRTCService(channel: widget.channel);
    _webRTCService.onRemoteStream = (stream) {
      setState(() {
        _isConnected = true;
        _stopRingingSound();
      });
      print("Remote stream received");
    };
    await _webRTCService.init();
    
    if (widget.role == 'caller') {
      await _webRTCService.createOffer();
    }
  }

  void _listenToSignaling() {
    widget.channel.stream.listen((message) {
      final data = jsonDecode(message);
      switch (data['type']) {
        case 'offer':
          _webRTCService.handleOffer(data['sdp']);
          break;
        case 'answer':
          _webRTCService.handleAnswer(data['sdp']);
          break;
        case 'ice-candidate':
          _webRTCService.addCandidate(data['candidate']);
          break;
        case 'call_ended':
          _endCall();
          break;
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _endCall();
        }
      });
    });
  }

  void _endCall() {
    _timer?.cancel();
    _stopRingingSound();
    _webRTCService.dispose();
    widget.channel.sink.add(jsonEncode({'type': 'end_call'}));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SummaryScreen(duration: Config.callDuration - _secondsRemaining),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _audioPlayer.dispose();
    _webRTCService.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F0F1E), Color(0xFF1E1E2E)],
              ),
            ),
          ),
          
          // Blurred Decorative Elements
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6A11CB).withValues(alpha: 0.15),
              ),
            ),
          ),

          // Main UI
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                
                // Pulsating Avatar
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!_isConnected)
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 140 * (1 + _pulseController.value * 0.3),
                              height: 140 * (1 + _pulseController.value * 0.3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF6A11CB).withValues(alpha: 1 - _pulseController.value),
                                  width: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          child: const Icon(Icons.person, size: 80, color: Colors.white24),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                Text(
                  _isConnected ? 'متصل الآن' : 'جارٍ الاتصال بمجهول...',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isConnected ? 'مكالمة نشطة' : 'البحث عن أفضل جودة صوت',
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),

                const Spacer(),

                // Timer with Visual Progress
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: _secondsRemaining / Config.callDuration,
                          strokeWidth: 8,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _secondsRemaining <= 10 ? Colors.redAccent : const Color(0xFF6A11CB),
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Text(
                              '00:${_secondsRemaining.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: _secondsRemaining <= 10 ? Colors.redAccent : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        label: 'كتم',
                        isActive: _isMuted,
                        onTap: () {
                          setState(() {
                            _isMuted = !_isMuted;
                            _webRTCService.localStream?.getAudioTracks()[0].enabled = !_isMuted;
                          });
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.call_end,
                        label: 'إنهاء',
                        isEnd: true,
                        onTap: _endCall,
                      ),
                      _buildActionButton(
                        icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                        label: 'سبيكر',
                        isActive: _isSpeakerOn,
                        onTap: () {
                          setState(() {
                            _isSpeakerOn = !_isSpeakerOn;
                            Helper.setSpeakerphoneOn(_isSpeakerOn);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isEnd = false,
    bool isActive = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isEnd ? 80 : 65,
            height: isEnd ? 80 : 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEnd 
                  ? Colors.redAccent 
                  : (isActive ? Colors.white : Colors.white.withValues(alpha: 0.1)),
              boxShadow: isEnd ? [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ] : [],
            ),
            child: Icon(
              icon, 
              color: isEnd ? Colors.white : (isActive ? Colors.black : Colors.white), 
              size: isEnd ? 35 : 28
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }
}
