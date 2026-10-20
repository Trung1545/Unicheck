class FaceStatusModel {
  final int? userId;
  final String? studentCode;
  final String? fullName;
  final String? faceDataStatus;
  final bool isRegistered;
  final DateTime? registeredAt;
  final String? version;

  const FaceStatusModel({
    this.userId,
    this.studentCode,
    this.fullName,
    this.faceDataStatus,
    this.isRegistered = false,
    this.registeredAt,
    this.version,
  });

  factory FaceStatusModel.fromJson(Map<String, dynamic> json) {
    DateTime? regAt;
    if (json['registeredAt'] != null && json['registeredAt'] is String) {
      regAt = DateTime.tryParse(json['registeredAt'] as String);
    }

    final isReg = json['isRegistered'] == true ||
        json['faceDataStatus'] == 'REGISTERED' ||
        json['faceDataStatus'] == 'COMPLETED';

    return FaceStatusModel(
      userId: (json['userId'] as num?)?.toInt(),
      studentCode: json['studentCode'] as String?,
      fullName: json['fullName'] as String?,
      faceDataStatus: json['faceDataStatus'] as String?,
      isRegistered: isReg,
      registeredAt: regAt,
      version: json['version'] as String?,
    );
  }
}
