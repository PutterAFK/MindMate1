import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:my_app_new/core/utils/network_helper.dart';

class AIService {
  static const String _baseUrl =
      'https://mental-ai1.onrender.com';

  static const String _apiKey =
      'my-secret-key';

  Future<String> sendMessage({
    required String message,
    required String userId,
  }) async {

    final hasInternet =
        await NetworkHelper.hasInternet();

    if (!hasInternet) {
      throw 'ไม่มีอินเตอร์เน็ต';
    }

    try {
      print("Connecting...");
      print("URL: $_baseUrl/chat");

      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $_apiKey',
        },
        body: jsonEncode({
          'message': message,
          'user_id': userId,
        }),
      ).timeout(
        const Duration(seconds: 60),
      );

      print(
          "STATUS: ${response.statusCode}");
      print(
          "BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body);

        return data['reply'] ??
            'AI ไม่ตอบกลับ';
      }

      if (response.statusCode == 401) {
        throw 'API KEY ไม่ตรงกับ server';
      }

      if (response.statusCode >= 500) {
        throw 'Server error';
      }

      throw 'Error ${response.statusCode}';

    } on TimeoutException {
      throw 'Server ใช้เวลาตอบนานเกินไป';
    } on SocketException {
      throw 'ไม่มีอินเตอร์เน็ต';
    } catch (e) {
      throw e.toString();
    }
  }
}
