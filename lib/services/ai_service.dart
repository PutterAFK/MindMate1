import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:my_app_new/core/utils/network_helper.dart';

class AIService {
  static const String _baseUrl = 'https://mental-ai1.onrender.com';
  static const String _apiKey = 'my-secret-key';

  Future<String> sendMessage({
    required String message,
    required String userId,
  }) async {
    // เช็ค Internet ก่อนเรียก API
    final hasInternet = await NetworkHelper.hasInternet();
    if (!hasInternet) {
      throw 'ไม่มีการเชื่อมต่ออินเตอร์เน็ต กรุณาตรวจสอบการเชื่อมต่อของคุณ';
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'message': message,
          'user_id': userId,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw 'การเชื่อมต่อใช้เวลานานเกินไป กรุณาลองใหม่อีกครั้ง';
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['reply'] ?? 'ขออภัยครับ ไม่ได้รับคำตอบจาก AI';
      } else if (response.statusCode == 401) {
        throw 'ไม่มีสิทธิ์เข้าถึง API';
      } else if (response.statusCode == 429) {
        throw 'มีการใช้งานมากเกินไป กรุณาลองใหม่ภายหลัง';
      } else if (response.statusCode >= 500) {
        throw 'เซิร์ฟเวอร์มีปัญหา กรุณาลองใหม่ภายหลัง';
      } else {
        throw 'เกิดข้อผิดพลาด (${response.statusCode})';
      }
    } on SocketException {
      throw 'ไม่มีการเชื่อมต่ออินเตอร์เน็ต';
    } on http.ClientException {
      throw 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้';
    } catch (e) {
      throw e.toString();
    }
  }
}