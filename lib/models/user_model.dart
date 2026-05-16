import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String nickname;
  final String firstName;
  final String lastName;
  final int age;
  final String gender;
  final List<String> problems;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.nickname,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.gender,
    required this.problems,
    required this.createdAt,
  });

  // แปลงเป็น Map เพื่อบันทึกลง Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'gender': gender,
      'problems': problems,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // แปลงจาก Firestore มาเป็น UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      nickname: map['nickname'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      problems: List<String>.from(map['problems'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}