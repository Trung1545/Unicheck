class FaceEnrollmentResultModel {
  final bool success;
  final String status;
  final DateTime? registeredAt;
  final String version;
  final String modelName;
  final int embeddingDimension;
  final String tokenHash;
  final String? message;
  final String studentName;
  final String studentCode;

  const FaceEnrollmentResultModel({
    this.success = false,
    this.status = 'PENDING',
    this.registeredAt,
    this.version = 'v3.2',
    this.modelName = 'ArcFace MobileFaceNet (512-dim)',
    this.embeddingDimension = 512,
    this.tokenHash = '',
    this.message,
    this.studentName = '',
    this.studentCode = '',
  });

  factory FaceEnrollmentResultModel.fromJson(Map<String, dynamic> json) {
    DateTime? regAt;
    if (json['registeredAt'] != null) {
      regAt = DateTime.tryParse(json['registeredAt'].toString());
    }

    return FaceEnrollmentResultModel(
      success: json['success'] == true,
      status: (json['status'] ?? 'REGISTERED').toString(),
      registeredAt: regAt ?? DateTime.now(),
      version: (json['version'] ?? 'v3.2').toString(),
      modelName: (json['modelName'] ?? 'ArcFace MobileFaceNet (512-dim)').toString(),
      embeddingDimension: json['embeddingDimension'] is int
          ? json['embeddingDimension'] as int
          : 512,
      tokenHash: (json['tokenHash'] ?? '').toString(),
      message: json['message']?.toString(),
      studentName: (json['studentName'] ?? '').toString(),
      studentCode: (json['studentCode'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'status': status,
      'registeredAt': registeredAt?.toIso8601String(),
      'version': version,
      'modelName': modelName,
      'embeddingDimension': embeddingDimension,
      'tokenHash': tokenHash,
      'message': message,
      'studentName': studentName,
      'studentCode': studentCode,
    };
  }
}
