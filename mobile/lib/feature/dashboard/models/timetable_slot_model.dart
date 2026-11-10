import '../../../shared/widgets/attendance_status_badge.dart';

enum SlotTimeState {
  notStarted, // Chưa bắt đầu
  inProgress, // Đang diễn ra
  ended,      // Đã kết thúc
}

enum SlotAttendanceActionState {
  notStarted,      // Chưa bắt đầu (disabled)
  sessionNotOpen,  // Chưa mở điểm danh (disabled)
  canCheckIn,      // Điểm danh ngay (enabled)
  alreadyAttended, // Đã điểm danh (disabled)
  ended,           // Đã kết thúc (disabled)
  notEnrolled,     // Chưa ghi danh (disabled)
}

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
  final int? attendanceSessionId;
  final String? attendanceSessionStatus;
  final String? studentAttendanceStatus;
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
    this.attendanceSessionId,
    this.attendanceSessionStatus,
    this.studentAttendanceStatus,
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
      attendanceSessionId: (json['attendanceSessionId'] as num?)?.toInt(),
      attendanceSessionStatus: json['attendanceSessionStatus'] as String?,
      studentAttendanceStatus: json['studentAttendanceStatus'] as String?,
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

  static (int, int)? _parseHourMinute(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        return (h, m);
      }
    }
    return null;
  }

  /// Xác định trạng thái thời gian thực của ca học:
  /// - Chưa đến giờ: SlotTimeState.notStarted
  /// - Trong giờ học: SlotTimeState.inProgress
  /// - Hết giờ học: SlotTimeState.ended
  SlotTimeState getTimeState([DateTime? referenceTime]) {
    final now = referenceTime ?? DateTime.now();

    if (date != null) {
      final slotDay = DateTime(date!.year, date!.month, date!.day);
      final refDay = DateTime(now.year, now.month, now.day);
      if (slotDay.isBefore(refDay)) {
        return SlotTimeState.ended;
      }
      if (slotDay.isAfter(refDay)) {
        return SlotTimeState.notStarted;
      }
    }

    final startParsed = _parseHourMinute(startTime);
    final endParsed = _parseHourMinute(endTime);

    if (startParsed != null && endParsed != null) {
      final slotStart = DateTime(now.year, now.month, now.day, startParsed.$1, startParsed.$2);
      final slotEnd = DateTime(now.year, now.month, now.day, endParsed.$1, endParsed.$2);

      if (now.isBefore(slotStart)) {
        return SlotTimeState.notStarted;
      }
      if (now.isAfter(slotEnd)) {
        return SlotTimeState.ended;
      }
      return SlotTimeState.inProgress;
    }

    return SlotTimeState.inProgress;
  }

  /// Trạng thái tương tác điểm danh dựa trên 5 điều kiện:
  /// 1. Sinh viên ghi danh (isEnrolled)
  /// 2. Thời gian ca học thực tế
  /// 3. Trạng thái phiên điểm danh (OPEN)
  /// 4. Đã điểm danh hay chưa (studentAttendanceStatus)
  SlotAttendanceActionState getAttendanceActionState({
    required bool isEnrolled,
    DateTime? referenceTime,
  }) {
    if (studentAttendanceStatus != null && studentAttendanceStatus!.isNotEmpty) {
      final statusUpper = studentAttendanceStatus!.toUpperCase();
      if (statusUpper == 'PRESENT' || statusUpper == 'LATE') {
        return SlotAttendanceActionState.alreadyAttended;
      }
    }

    final timeState = getTimeState(referenceTime);
    if (timeState == SlotTimeState.ended) {
      return SlotAttendanceActionState.ended;
    }
    if (timeState == SlotTimeState.notStarted) {
      return SlotAttendanceActionState.notStarted;
    }

    if (!isEnrolled) {
      return SlotAttendanceActionState.notEnrolled;
    }

    final isOpen = (attendanceSessionStatus == 'OPEN') || hasAttendanceSession;
    if (isOpen) {
      return SlotAttendanceActionState.canCheckIn;
    }

    return SlotAttendanceActionState.sessionNotOpen;
  }

  /// Nút điểm danh có được kích hoạt để nhấn hay không
  bool canCheckInNow({
    required bool isEnrolled,
    DateTime? referenceTime,
  }) {
    return getAttendanceActionState(
          isEnrolled: isEnrolled,
          referenceTime: referenceTime,
        ) ==
        SlotAttendanceActionState.canCheckIn;
  }

  /// Nhãn hiển thị trên nút thao tác (5 trạng thái)
  String getAttendanceButtonText({
    required bool isEnrolled,
    DateTime? referenceTime,
  }) {
    final state = getAttendanceActionState(
      isEnrolled: isEnrolled,
      referenceTime: referenceTime,
    );
    switch (state) {
      case SlotAttendanceActionState.alreadyAttended:
        return 'Đã điểm danh';
      case SlotAttendanceActionState.canCheckIn:
        return 'Điểm danh ngay';
      case SlotAttendanceActionState.sessionNotOpen:
        return 'Chưa mở điểm danh';
      case SlotAttendanceActionState.notStarted:
        return 'Chưa bắt đầu';
      case SlotAttendanceActionState.ended:
        return 'Đã kết thúc';
      case SlotAttendanceActionState.notEnrolled:
        return 'Chưa ghi danh';
    }
  }

  /// Badge trạng thái học vụ
  AttendanceStatus getAttendanceBadgeStatus({
    required bool isEnrolled,
    DateTime? referenceTime,
  }) {
    if (studentAttendanceStatus != null && studentAttendanceStatus!.isNotEmpty) {
      final s = studentAttendanceStatus!.toUpperCase();
      if (s == 'PRESENT') return AttendanceStatus.present;
      if (s == 'LATE') return AttendanceStatus.late;
      if (s == 'ABSENT') return AttendanceStatus.absent;
    }

    final timeState = getTimeState(referenceTime);
    if (timeState == SlotTimeState.ended) {
      return AttendanceStatus.ended;
    }
    if (timeState == SlotTimeState.notStarted) {
      return AttendanceStatus.scheduled;
    }

    final isOpen = (attendanceSessionStatus == 'OPEN') || hasAttendanceSession;
    if (isOpen) {
      return AttendanceStatus.ongoing;
    }
    return AttendanceStatus.pending;
  }

  /// Nhãn badge trạng thái học vụ
  String getAttendanceBadgeLabel({
    required bool isEnrolled,
    DateTime? referenceTime,
  }) {
    if (studentAttendanceStatus != null && studentAttendanceStatus!.isNotEmpty) {
      final s = studentAttendanceStatus!.toUpperCase();
      if (s == 'PRESENT') return 'Có mặt đúng giờ';
      if (s == 'LATE') return 'Đi muộn';
      if (s == 'ABSENT') return 'Vắng không phép';
    }

    final timeState = getTimeState(referenceTime);
    if (timeState == SlotTimeState.ended) return 'Đã kết thúc';
    if (timeState == SlotTimeState.notStarted) return 'Chưa bắt đầu';

    final isOpen = (attendanceSessionStatus == 'OPEN') || hasAttendanceSession;
    if (isOpen) return 'Đang diễn ra';
    return 'Chưa mở điểm danh';
  }
}
