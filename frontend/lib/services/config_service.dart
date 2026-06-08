class Config {
  static const String baseUrl = 'sharp-zoos-sin.loca.lt';
  static const String wsUrl = 'wss://$baseUrl/ws';
  static const String ringingSoundUrl = 'https://www.soundjay.com/phone/phone-calling-1.mp3';
  
  // Call duration in seconds
  static const int callDuration = 60;
  
  // STUN servers for WebRTC
  static const Map<String, dynamic> iceConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ]
  };
}
