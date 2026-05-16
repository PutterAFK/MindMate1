class Validators {
  // ตรวจสอบ Email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอก Email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'รูปแบบ Email ไม่ถูกต้อง';
    }
    return null;
  }

  // ตรวจสอบ Password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอก Password';
    }
    if (value.length < 6) {
      return 'Password ต้องมีอย่างน้อย 6 ตัวอักษร';
    }
    return null;
  }

  // ตรวจสอบ Confirm Password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'กรุณายืนยัน Password';
    }
    if (value != password) {
      return 'Password ไม่ตรงกัน';
    }
    return null;
  }
}