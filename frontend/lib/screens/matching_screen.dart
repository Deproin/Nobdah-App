import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/config_service.dart';
import 'call_screen.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  late WebSocketChannel channel;
  bool isSearching = true;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    // Use the public tunnel URL for internet connectivity
    String url = Config.wsUrl;
    
    // Auto-fallback to local for emulator debugging if needed
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && Config.baseUrl.contains('loca.lt') == false) {
      url = 'ws://10.0.2.2:8000/ws';
    }
    channel = WebSocketChannel.connect(Uri.parse(url));
    
    // Start matchmaking
    channel.sink.add(jsonEncode({'type': 'start_matchmaking'}));

    channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'match_found') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CallScreen(
                channel: channel,
                role: data['role'],
                partnerId: data['partner_id'],
              ),
            ),
          );
        }
      }
    }, onError: (error) {
      print('WS Error: $error');
      _handleError();
    }, onDone: () {
      print('WS Closed');
      _handleError();
    });
  }

  void _handleError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل الاتصال بالخادم')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    // We don't close the channel here because we pass it to CallScreen
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFF0F0F1E)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)),
            ),
            const SizedBox(height: 30),
            const Text(
              'جاري البحث عن شخص ما...',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 50),
            TextButton(
              onPressed: () {
                channel.sink.close();
                Navigator.pop(context);
              },
              child: const Text(
                'إلغاء',
                style: TextStyle(color: Colors.white54, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
