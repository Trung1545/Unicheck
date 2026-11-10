class AttendanceRecheckModel {
  final int requestId;
  final int? sessionId;
  final int studentId;
  final String studentCode;
  final String studentName;
  final String courseCode;
  final String courseName;
  final String className;
  final String roomCode;
  final String reason;
  final String status;
  final DateTime? requestedAt;
  final DateTime? expiresAt;
  final DateTime? completedAt;
  final String requestedByName;

  const AttendanceRecheckModel({
    required this.requestId,
    this.sessionId,
    required this.studentId,
    required this.studentCode,
    required this.studentName,
    required this.courseCode,
    required this.courseName,
    required this.className,
    required this.roomCode,
    required this.reason,
    required this.status,
    this.requestedAt,
    this.expiresAt,
    this.completedAt,
    required this.requestedByName,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isPending => status == 'PENDING' && !isExpired;

  factory AttendanceRecheckModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecheckModel(
      requestId: (json['requestId'] as num?)?.toInt() ?? 0,
      sessionId: (json['sessionId'] as num?)?.toInt(),
      studentId: (json['studentId'] as num?)?.toInt() ?? 0,
      studentCode: json['studentCode'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      courseCode: json['courseCode'] as String? ?? '',
      courseName: json['courseName'] as String? ?? '',
      className: json['className'] as String? ?? '',
      roomCode: json['roomCode'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      requestedAt: json['requestedAt'] != null
          ? DateTime.tryParse(json['requestedAt'].toString())
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      requestedByName: json['requestedByName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'sessionId': sessionId,
      'studentId': studentId,
      'studentCode': studentCode,
      'studentName': studentName,
      'courseCode': courseCode,
      'courseName': courseName,
      'className': className,
      'roomCode': roomCode,
      'reason': reason,
      'status': status,
      'requestedAt': requestedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'requestedByName': requestedByName,
    };
  }
}
