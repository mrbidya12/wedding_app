import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class NetworkService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
  static String get _host {
    if (Platform.isAndroid) return "10.0.2.2";
    return "localhost";
  }

  // Gateway Port (Auth/API)
  static String get apiBaseUrl => "http://$_host:4000/api";
  
  // Chat Service Port (WebSockets)
  static String get chatSocketUrl => "http://$_host:30000";

  IO.Socket? socket;

  /// Connect to your Docker Auth Container
  Future<String?> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Docker Gateway: Login Success");
        return data['token'];
      }
      return null;
    } catch (e) {
      print("❌ Docker Connection Error: $e");
      return null;
    }
  }

  /// Connect to your Docker Chat Container via WebSockets
  void connectToChat(String jwtToken) {
    if (socket?.connected ?? false) return;

    socket = IO.io(chatSocketUrl, 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': jwtToken})
        .enableAutoConnect()
        .build()
    );

    socket!.onConnect((_) => print('✅ Connected to Docker Chat Container'));
    socket!.onConnectError((err) => print('⚠️ Chat Connection Error: $err'));
  }

  void disconnect() {
    socket?.dispose();
    socket = null;
  }
}
