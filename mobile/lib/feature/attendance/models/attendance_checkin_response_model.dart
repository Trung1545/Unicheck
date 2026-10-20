class AttendanceCheckinResponseModel {
  final int? id;
  final int? studentId;
  final String? studentCode;
  final String? studentName;
  final String? status;
  final String? method;
  final DateTime? checkInTime;
  final double? faceConfidence;
  final String? receiptId;
  final String? note;

  const AttendanceCheckinResponseModel({
    this.id,
    this.studentId,
    this.studentCode,
    this.studentName,
    this.status,
    this.method,
    this.checkInTime,
    this.faceConfidence,
    this.receiptId,
    this.note,
  });

  factory AttendanceCheckinResponseModel.fromJson(Map<String, dynamic> json) {
    DateTime? time;
    if (json['checkInTime'] != null) {
      time = DateTime.tryParse(json['checkInTime'].toString());
    }

    double? conf;
    if (json['faceConfidence'] != null) {
      conf = (json['faceConfidence'] as num).toDouble();
    }

    return AttendanceCheckinResponseModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()),
      studentId: json['studentId'] is int
          ? json['studentId'] as int
          : int.tryParse(json['studentId'].toString()),
      studentCode: json['studentCode']?.toString(),
      studentName: json['studentName']?.toString(),
      status: json['status']?.toString() ?? 'PRESENT',
      method: json['method']?.toString() ?? 'FACE_QR',
      checkInTime: time ?? DateTime.now(),
      faceConfidence: conf ?? 0.985,
      receiptId: json['receiptId']?.toString(),
      note: json['note']?.toString(),
    );
  }
}
