import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/widgets/weekly_day_picker_strip.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/enrollment_model.dart';
import '../models/timetable_slot_model.dart';
import '../services/dashboard_api_service.dart';

class DashboardController extends GetxController {
  final DashboardApiService apiService;

  final RxList<TimetableSlotModel> allSlots = <TimetableSlotModel>[].obs;
  final RxList<EnrollmentModel> enrollments = <EnrollmentModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxInt selectedTab = 0.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  late final Rx<DateTime> currentWeekStart;

  final RxString courseSearchQuery = ''.obs;
  final RxString courseFilterCategory = 'all'.obs;

  DashboardController({
    DashboardApiService? apiService,
  }) : apiService = apiService ??
            DashboardApiService(
              apiClient: Get.isRegistered<ApiClient>()
                  ? Get.find<ApiClient>()
                  : ApiClient(
                      tokenStorage: Get.isRegistered<TokenStorage>()
                          ? Get.find<TokenStorage>()
                          : PlatformTokenStorage(),
                    ),
            ) {
    final now = DateTime.now();
    currentWeekStart = _getMonday(now).obs;
  }

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  static DateTime _getMonday(DateTime d) {
    final clean = DateTime(d.year, d.month, d.day);
    return clean.subtract(Duration(days: clean.weekday - 1));
  }

  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final monday = currentWeekStart.value;
      // Fetch 2 weeks around current week for smooth scrolling
      final start = monday.subtract(const Duration(days: 7));
      final end = monday.add(const Duration(days: 14));

      final authController = Get.isRegistered<AuthController>()
          ? Get.find<AuthController>()
          : null;
      if (authController != null) {
        try {
          await authController.refreshProfile();
        } catch (_) {}
      }
      final studentId = authController?.user.value?.id;

      final results = await Future.wait([
        apiService.getMyTimetable(startDate: start, endDate: end),
        apiService.getMyEnrollments(studentId: studentId),
      ]);

      allSlots.value = results[0] as List<TimetableSlotModel>;
      enrollments.value = results[1] as List<EnrollmentModel>;
    } catch (e) {
      if (kDebugMode) {
        print('DashboardController load error: $e');
      }
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Filtered Slots for Today
  List<TimetableSlotModel> get todaySlots {
    final now = DateTime.now();
    final todayClean = DateTime(now.year, now.month, now.day);
    final slots = allSlots.where((s) => s.isScheduledOn(todayClean)).toList();
    slots.sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));
    return slots;
  }

  // Filtered Slots for Selected Date
  List<TimetableSlotModel> get selectedDaySlots {
    final d = selectedDate.value;
    final selectedClean = DateTime(d.year, d.month, d.day);
    final slots =
        allSlots.where((s) => s.isScheduledOn(selectedClean)).toList();
    slots.sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));
    return slots;
  }

  // Next Upcoming or Active Class Session
  TimetableSlotModel? get nextClassSession {
    final tSlots = todaySlots;
    if (tSlots.isEmpty) {
      // If nothing today, return earliest in week or null
      return allSlots.isNotEmpty ? allSlots.first : null;
    }

    final now = DateTime.now();
    final currentTimeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Find first slot whose end time is in the future
    for (final slot in tSlots) {
      final end = slot.endTime ?? '23:59';
      if (end.compareTo(currentTimeStr) >= 0) {
        return slot;
      }
    }

    return tSlots.last;
  }

  // Active Attendance Session (if any slot has attendance open)
  TimetableSlotModel? get activeAttendanceSession {
    for (final slot in todaySlots) {
      if (slot.hasAttendanceSession) {
        return slot;
      }
    }
    return null;
  }

  // 7-day strip data for current active week
  List<DayScheduleInfo> get weeklyDays {
    final monday = currentWeekStart.value;
    final now = DateTime.now();
    final todayClean = DateTime(now.year, now.month, now.day);
    const dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return List.generate(7, (index) {
      final date = monday.add(Duration(days: index));
      final count = allSlots.where((s) => s.isScheduledOn(date)).length;
      final isToday = date.year == todayClean.year &&
          date.month == todayClean.month &&
          date.day == todayClean.day;

      return DayScheduleInfo(
        dayLabel: dayLabels[index],
        dayNumber: date.day,
        date: date,
        classCount: count,
        isToday: isToday,
      );
    });
  }

  int get selectedDayIndex {
    final sel = selectedDate.value;
    final mon = currentWeekStart.value;
    final diff = sel.difference(mon).inDays;
    if (diff >= 0 && diff < 7) {
      return diff;
    }
    return 0;
  }

  void selectDay(int index) {
    if (index >= 0 && index < 7) {
      selectedDate.value = currentWeekStart.value.add(Duration(days: index));
    }
  }

  void previousWeek() {
    currentWeekStart.value =
        currentWeekStart.value.subtract(const Duration(days: 7));
    selectedDate.value =
        selectedDate.value.subtract(const Duration(days: 7));
    loadDashboardData();
  }

  void nextWeek() {
    currentWeekStart.value =
        currentWeekStart.value.add(const Duration(days: 7));
    selectedDate.value =
        selectedDate.value.add(const Duration(days: 7));
    loadDashboardData();
  }

  void goToToday() {
    final now = DateTime.now();
    currentWeekStart.value = _getMonday(now);
    selectedDate.value = now;
  }

  void setCourseSearch(String q) {
    courseSearchQuery.value = q.trim();
  }

  void setCourseFilter(String filter) {
    courseFilterCategory.value = filter;
  }

  List<EnrollmentModel> get filteredCourses {
    var list = enrollments.toList();
    final q = courseSearchQuery.value.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) {
        final code = c.courseCode.toLowerCase();
        final name = c.courseName.toLowerCase();
        final cls = (c.className ?? '').toLowerCase();
        return code.contains(q) || name.contains(q) || cls.contains(q);
      }).toList();
    }

    if (courseFilterCategory.value == 'active') {
      list = list.where((c) => c.isActive).toList();
    } else if (courseFilterCategory.value == 'completed') {
      list = list.where((c) => c.status == 'COMPLETED').toList();
    }

    return list;
  }
}
