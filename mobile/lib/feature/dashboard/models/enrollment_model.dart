class EnrollmentModel {
  final int id;
  final String? className;
  final int? courseId;
  final String courseCode;
  final String courseName;
  final int? semesterId;
  final String? semesterCode;
  final int? studentId;
  final String? studentCode;
  final String? studentName;
  final String? studentEmail;
  final String? studentClass;
  final String? avatar;
  final String? faceDataStatus;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  const EnrollmentModel({
    required this.id,
    this.className,
    this.courseId,
    required this.courseCode,
    required this.courseName,
    this.semesterId,
    this.semesterCode,
    this.studentId,
    this.studentCode,
    this.studentName,
    this.studentEmail,
    this.studentClass,
    this.avatar,
    this.faceDataStatus,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      className: json['className'] as String?,
      courseId: (json['courseId'] as num?)?.toInt(),
      courseCode: (json['courseCode'] ?? '') as String,
      courseName: (json['courseName'] ?? '') as String,
      semesterId: (json['semesterId'] as num?)?.toInt(),
      semesterCode: json['semesterCode'] as String?,
      studentId: (json['studentId'] as num?)?.toInt(),
      studentCode: json['studentCode'] as String?,
      studentName: json['studentName'] as String?,
      studentEmail: json['studentEmail'] as String?,
      studentClass: json['studentClass'] as String?,
      avatar: json['avatar'] as String?,
      faceDataStatus: json['faceDataStatus'] as String?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  bool get isActive => status == null || status == 'ACTIVE' || status == 'ENROLLED';
}
