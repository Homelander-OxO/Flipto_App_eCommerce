import 'package:http/http.dart' as http;
import 'dart:convert';

class AppConfig {
  static String _baseUrl = 'https://pitch-outline-accessed-adding.trycloudflare.com';

  static Future<void> loadConfig() async {
    try {
      final response = await http.get(
          Uri.parse('https://api.github.com/repos/Homelander-OxO/flipto/contents/config.json'),
          headers: {'Accept': 'application/vnd.github.v3.raw'}
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final config = jsonDecode(response.body);
        _baseUrl = config['apiBaseUrl'];
        print('✅ Config loaded successfully: $_baseUrl');
      }
    } catch (e) {
      print('⚠️ Config load error: $e');
      print('Using fallback URL: $_baseUrl');
    }
  }

  static String get baseUrl => _baseUrl;
}