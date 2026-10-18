class UserModel {
  final int id;
  final String? code;
  final String username;
  final String fullName;
  final String email;
  final String role;
  final String? status;
  final String? faceDataStatus;
  final bool? isPasswordChanged;
  final String? avatar;

  UserModel({
    required this.id,
    this.code,
    required this.username,
    required this.fullName,
    required this.email,
    this.role = 'STUDENT',
    this.status,
    this.faceDataStatus,
    this.isPasswordChanged,
    this.avatar,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isLecturer => role.toUpperCase() == 'LECTURER';
  bool get isStudent => role.toUpperCase() == 'STUDENT';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['userId'] ?? json['id'] ?? 0) as int,
      code: json['code'] as String?,
      username: (json['username'] ?? '') as String,
      fullName: (json['fullName'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: (json['role'] ?? 'STUDENT') as String,
      status: json['status'] as String?,
      faceDataStatus: json['faceDataStatus'] as String?,
      isPasswordChanged: json['isPasswordChanged'] as bool?,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'username': username,
      'fullName': fullName,
      'email': email,
      'role': role,
      'status': status,
      'faceDataStatus': faceDataStatus,
      'isPasswordChanged': isPasswordChanged,
      'avatar': avatar,
    };
  }
}
