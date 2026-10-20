class TimetableSlotModel {
  final int id;
  final String? className;
  final String courseCode;
  final String courseName;
  final String? courseCategory;
  final int? semesterId;
  final String? semesterCode;
  final String? semesterName;
  final int? lecturerId;
  final String? lecturerCode;
  final String? lecturerName;
  final int? roomId;
  final String? roomCode;
  final String? roomName;
  final String? building;
  final int? roomCapacity;
  final String? attendanceMethod;
  final int? slotTypeId;
  final String? slotTypeName;
  final String? startTime;
  final String? endTime;
  final String? duration;
  final DateTime? date;
  final int? dayOfWeek;
  final int? slotNumber;
  final int? endSlotNumber;
  final String? periodDisplay;
  final int? currentEnrollment;
  final int? maxStudents;
  final String? status;
  final String? note;
  final bool hasAttendanceSession;
  final bool hasConflict;
  final String? conflictType;
  final String? conflictMessage;

  const TimetableSlotModel({
    required this.id,
    this.className,
    required this.courseCode,
    required this.courseName,
    this.courseCategory,
    this.semesterId,
    this.semesterCode,
    this.semesterName,
    this.lecturerId,
    this.lecturerCode,
    this.lecturerName,
    this.roomId,
    this.roomCode,
    this.roomName,
    this.building,
    this.roomCapacity,
    this.attendanceMethod,
    this.slotTypeId,
    this.slotTypeName,
    this.startTime,
    this.endTime,
    this.duration,
    this.date,
    this.dayOfWeek,
    this.slotNumber,
    this.endSlotNumber,
    this.periodDisplay,
    this.currentEnrollment,
    this.maxStudents,
    this.status,
    this.note,
    this.hasAttendanceSession = false,
    this.hasConflict = false,
    this.conflictType,
    this.conflictMessage,
  });

  factory TimetableSlotModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['date'] != null) {
      if (json['date'] is String) {
        parsedDate = DateTime.tryParse(json['date'] as String);
      }
    }

    return TimetableSlotModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      className: json['className'] as String?,
      courseCode: (json['courseCode'] ?? '') as String,
      courseName: (json['courseName'] ?? '') as String,
      courseCategory: json['courseCategory'] as String?,
      semesterId: (json['semesterId'] as num?)?.toInt(),
      semesterCode: json['semesterCode'] as String?,
      semesterName: json['semesterName'] as String?,
      lecturerId: (json['lecturerId'] as num?)?.toInt(),
      lecturerCode: json['lecturerCode'] as String?,
      lecturerName: json['lecturerName'] as String?,
      roomId: (json['roomId'] as num?)?.toInt(),
      roomCode: json['roomCode'] as String?,
      roomName: json['roomName'] as String?,
      building: json['building'] as String?,
      roomCapacity: (json['roomCapacity'] as num?)?.toInt(),
      attendanceMethod: json['attendanceMethod'] as String?,
      slotTypeId: (json['slotTypeId'] as num?)?.toInt(),
      slotTypeName: json['slotTypeName'] as String?,
      startTime: _formatTime(json['startTime']),
      endTime: _formatTime(json['endTime']),
      duration: json['duration'] as String?,
      date: parsedDate,
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt(),
      slotNumber: (json['slotNumber'] as num?)?.toInt(),
      endSlotNumber: (json['endSlotNumber'] as num?)?.toInt(),
      periodDisplay: json['periodDisplay'] as String?,
      currentEnrollment: (json['currentEnrollment'] as num?)?.toInt(),
      maxStudents: (json['maxStudents'] as num?)?.toInt(),
      status: json['status'] as String?,
      note: json['note'] as String?,
      hasAttendanceSession: json['hasAttendanceSession'] == true,
      hasConflict: json['hasConflict'] == true,
      conflictType: json['conflictType'] as String?,
      conflictMessage: json['conflictMessage'] as String?,
    );
  }

  static String? _formatTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      if (raw.length >= 5) {
        return raw.substring(0, 5);
      }
      return raw;
    }
    return raw.toString();
  }

  String get timeSlot {
    final start = startTime ?? '--:--';
    final end = endTime ?? '--:--';
    return '$start - $end';
  }

  String get roomDisplay {
    final room = roomName ?? roomCode ?? 'Phòng học';
    if (building != null && building!.isNotEmpty) {
      return '$room ($building)';
    }
    return room;
  }

  String get lecturerDisplay => lecturerName ?? 'Chưa phân công';

  String get periodsDisplay {
    if (periodDisplay != null && periodDisplay!.isNotEmpty) {
      return periodDisplay!;
    }
    if (slotNumber != null && endSlotNumber != null) {
      return 'Tiết $slotNumber - $endSlotNumber';
    }
    if (slotNumber != null) {
      return 'Tiết $slotNumber';
    }
    return 'Lịch cố định';
  }

  bool isScheduledOn(DateTime d) {
    if (date == null) return false;
    return date!.year == d.year && date!.month == d.month && date!.day == d.day;
  }
}
