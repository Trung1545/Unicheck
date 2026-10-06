class UserModel {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final String? role;
  final String? faceDataStatus;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    this.role,
    this.faceDataStatus,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: json['role'] as String?,
      faceDataStatus: json['faceDataStatus'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'role': role,
      'faceDataStatus': faceDataStatus,
    };
  }
}
