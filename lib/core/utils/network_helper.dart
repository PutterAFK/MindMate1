import 'dart:io';

class NetworkHelper {
  // เช็คว่ามี Internet ไหม
  static Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // แปลง Error เป็นข้อความภาษาไทย
  static String getErrorMessage(dynamic error) {
    final message = error.toString().toLowerCase();

    if (message.contains('socketexception') ||
        message.contains('network') ||
        message.contains('connection')) {
      return 'ไม่มีการเชื่อมต่ออินเตอร์เน็ต กรุณาตรวจสอบการเชื่อมต่อของคุณ';
    } else if (message.contains('timeout')) {
      return 'การเชื่อมต่อใช้เวลานานเกินไป กรุณาลองใหม่อีกครั้ง';
    } else if (message.contains('permission-denied')) {
      return 'ไม่มีสิทธิ์เข้าถึงข้อมูล';
    } else if (message.contains('not-found')) {
      return 'ไม่พบข้อมูลที่ต้องการ';
    } else if (message.contains('unavailable')) {
      return 'เซิร์ฟเวอร์ไม่พร้อมใช้งาน กรุณาลองใหม่ภายหลัง';
    } else if (message.contains('cancelled')) {
      return 'การดำเนินการถูกยกเลิก';
    } else {
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
    }
  }
}