class ApiConfig {
  // For Android emulator:
  static const String baseUrl = 'http://10.0.2.2:4000/api';
  
  // For iOS simulator:
  // static const String baseUrl = 'http://localhost:4000/api';
  
  // For physical device (replace with your computer's IP):
  // static const String baseUrl = 'http://192.168.1.100:4000/api';

  static const String wsUrl = 'ws://10.0.2.2:4000/api/chat'; // WebSocket
}
