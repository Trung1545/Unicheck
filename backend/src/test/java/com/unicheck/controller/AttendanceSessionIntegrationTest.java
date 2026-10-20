package com.unicheck.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.model.dto.AttendanceConfigDto;
import com.unicheck.model.dto.AttendanceSessionCreateRequest;
import com.unicheck.model.entity.*;
import com.unicheck.model.enums.*;
import com.unicheck.repository.*;
import com.unicheck.security.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class AttendanceSessionIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private AttendanceSessionRepository attendanceSessionRepository;

    @Autowired
    private StudentAttendanceRepository studentAttendanceRepository;

    @Autowired
    private AttendanceConfigRepository attendanceConfigRepository;

    @Autowired
    private TimetableSlotRepository timetableSlotRepository;

    @Autowired
    private ClassSectionRepository classSectionRepository;

    @Autowired
    private CourseRepository courseRepository;

    @Autowired
    private SemesterRepository semesterRepository;

    @Autowired
    private RoomRepository roomRepository;

    @Autowired
    private EnrollmentRepository enrollmentRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SlotTypeRepository slotTypeRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private org.springframework.transaction.support.TransactionTemplate transactionTemplate;

    private String adminToken;
    private String lecturerToken;
    private String otherLecturerToken;
    private String studentToken;

    private User admin;
    private User lecturer;
    private User otherLecturer;
    private User student;

    private Semester semester;
    private Course course;
    private ClassSection classSection;
    private ClassSection otherClassSection;
    private Room room;
    private SlotType slotType;
    private TimetableSlot slot1;
    private TimetableSlot slot2;
    private TimetableSlot cancelledSlot;

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("DELETE FROM student_attendances");
        jdbcTemplate.execute("DELETE FROM attendance_sessions");
        jdbcTemplate.execute("DELETE FROM timetable_slots");
        jdbcTemplate.execute("DELETE FROM enrollments");

        // 1. Users
        admin = userRepository.findByUsername("admin_ses_test").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("ADM-SES-01")
                        .username("admin_ses_test")
                        .email("admin.ses@unicheck.edu.vn")
                        .password(passwordEncoder.encode("admin123"))
                        .fullName("Quản trị viên Điểm danh")
                        .role(Role.ADMIN)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        lecturer = userRepository.findByUsername("lecturer_ses_01").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("LEC-SES-01")
                        .username("lecturer_ses_01")
                        .email("lecturer.ses01@unicheck.edu.vn")
                        .password(passwordEncoder.encode("lecturer123"))
                        .fullName("TS. Lê Hoàng Nam")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        otherLecturer = userRepository.findByUsername("lecturer_ses_02").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("LEC-SES-02")
                        .username("lecturer_ses_02")
                        .email("lecturer.ses02@unicheck.edu.vn")
                        .password(passwordEncoder.encode("lecturer123"))
                        .fullName("ThS. Đặng Thị Anh Thư")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        student = userRepository.findByUsername("student_ses_01").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("STU-SES-01")
                        .username("student_ses_01")
                        .email("student.ses01@unicheck.edu.vn")
                        .password(passwordEncoder.encode("student123"))
                        .fullName("Nguyễn Văn An")
                        .role(Role.STUDENT)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        adminToken = jwtUtil.generateAccessToken(admin);
        lecturerToken = jwtUtil.generateAccessToken(lecturer);
        otherLecturerToken = jwtUtil.generateAccessToken(otherLecturer);
        studentToken = jwtUtil.generateAccessToken(student);

        // 2. Academic Catalog
        semester = semesterRepository.findByCode("2024.1").orElseGet(() ->
                semesterRepository.save(Semester.builder()
                        .code("2024.1")
                        .name("Học kỳ I 2024-2025")
                        .startDate(LocalDate.of(2024, 9, 1))
                        .endDate(LocalDate.of(2025, 1, 15))
                        .status(SemesterStatus.ACTIVE)
                        .build())
        );

        course = courseRepository.findByCode("IT301").orElseGet(() ->
                courseRepository.save(Course.builder()
                        .code("IT301")
                        .name("Lập trình Web nâng cao")
                        .credits(3)
                        .numberOfSlots(45)
                        .status(CourseStatus.ACTIVE)
                        .build())
        );

        room = roomRepository.findByCode("A2-304").orElseGet(() ->
                roomRepository.save(Room.builder()
                        .code("A2-304")
                        .name("Phòng thực hành A2-304")
                        .building("Tòa A2")
                        .capacity(60)
                        .status(RoomStatus.AVAILABLE)
                        .build())
        );

        slotType = slotTypeRepository.findAll().stream()
                .filter(st -> st.getSemester() != null && st.getSemester().getId().equals(semester.getId()) && st.getSlotIndex() == 1)
                .findFirst()
                .orElseGet(() -> slotTypeRepository.save(SlotType.builder()
                        .name("Ca 1 (Tiết 1-3)")
                        .slotIndex(1)
                        .startTime(LocalTime.of(7, 0))
                        .endTime(LocalTime.of(9, 25))
                        .duration("145m")
                        .semester(semester)
                        .build())
                );

        // 3. Class Sections
        classSection = classSectionRepository.findByClassName("IT301.01").orElseGet(() ->
                classSectionRepository.save(ClassSection.builder()
                        .className("IT301.01")
                        .course(course)
                        .semester(semester)
                        .lecturer(lecturer)
                        .numberOfSlots(15)
                        .maxStudents(50)
                        .currentEnrollment(1)
                        .status(ClassSectionStatus.OPEN)
                        .build())
        );
        classSection.setLecturer(lecturer);
        classSection = classSectionRepository.save(classSection);

        otherClassSection = classSectionRepository.findByClassName("IT301.02").orElseGet(() ->
                classSectionRepository.save(ClassSection.builder()
                        .className("IT301.02")
                        .course(course)
                        .semester(semester)
                        .lecturer(otherLecturer)
                        .numberOfSlots(15)
                        .maxStudents(50)
                        .currentEnrollment(0)
                        .status(ClassSectionStatus.OPEN)
                        .build())
        );
        otherClassSection.setLecturer(otherLecturer);
        otherClassSection = classSectionRepository.save(otherClassSection);

        // 4. Enrollment
        if (!enrollmentRepository.existsByClassSection_ClassNameAndStudent_Id(classSection.getClassName(), student.getId())) {
            enrollmentRepository.save(Enrollment.builder()
                    .classSection(classSection)
                    .student(student)
                    .studentCode(student.getCode())
                    .status(EnrollmentStatus.ENROLLED)
                    .build());
        }

        // 5. Timetable Slots
        slot1 = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection)
                .room(room)
                .slotType(slotType)
                .date(LocalDate.of(2024, 10, 23))
                .dayOfWeek(3)
                .slotNumber(1)
                .status(TimetableSlotStatus.SCHEDULED)
                .note("Buổi thực hành 01")
                .build());

        slot2 = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection)
                .room(room)
                .slotType(slotType)
                .date(LocalDate.of(2024, 10, 30))
                .dayOfWeek(3)
                .slotNumber(1)
                .status(TimetableSlotStatus.SCHEDULED)
                .note("Buổi thực hành 02")
                .build());

        cancelledSlot = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection)
                .room(room)
                .slotType(slotType)
                .date(LocalDate.of(2024, 11, 6))
                .dayOfWeek(3)
                .slotNumber(1)
                .status(TimetableSlotStatus.CANCELLED)
                .note("Lớp nghỉ")
                .build());
    }

    // =========================================================================
    // TEST 1: ADMIN xem danh sách theo quyền
    // =========================================================================
    @Test
    @DisplayName("1. ADMIN xem danh sách theo quyền - Trả về HTTP 200 và danh sách phiên")
    void testAdminViewSessions() throws Exception {
        // Tạo phiên
        attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot1)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.CREATED)
                .build());

        mockMvc.perform(get("/api/v1/attendance/sessions")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content", hasSize(1)))
                .andExpect(jsonPath("$.data.content[0].className").value("IT301.01"));
    }

    // =========================================================================
    // TEST 2: LECTURER xem danh sách thuộc quyền (chỉ thấy phiên thuộc lớp phân công)
    // =========================================================================
    @Test
    @DisplayName("2. LECTURER xem danh sách thuộc quyền - Chỉ thấy các phiên lớp mình dạy")
    void testLecturerViewScopedSessions() throws Exception {
        // Tạo 1 phiên cho lecturer 1
        attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot1)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.CREATED)
                .build());

        // Slot cho other lecturer
        TimetableSlot slotOther = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(otherClassSection)
                .room(room)
                .slotType(slotType)
                .date(LocalDate.of(2024, 10, 24))
                .dayOfWeek(4)
                .slotNumber(1)
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slotOther)
                .lecturer(otherLecturer)
                .status(AttendanceSessionStatus.CREATED)
                .build());

        // Lecturer 1 chỉ thấy 1 phiên
        mockMvc.perform(get("/api/v1/attendance/sessions")
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content", hasSize(1)))
                .andExpect(jsonPath("$.data.content[0].className").value("IT301.01"));
    }

    // =========================================================================
    // TEST 3: STUDENT không thể tạo/mở/đóng phiên
    // =========================================================================
    @Test
    @DisplayName("3. STUDENT không thể tạo/mở/đóng phiên - Bị từ chối HTTP 403 Forbidden")
    void testStudentForbiddenFromSessionOperations() throws Exception {
        AttendanceSession session = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot1)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.CREATED)
                .build());

        AttendanceSessionCreateRequest createReq = AttendanceSessionCreateRequest.builder()
                .timetableSlotId(slot2.getId())
                .build();

        // Thử tạo phiên
        mockMvc.perform(post("/api/v1/attendance/sessions")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createReq)))
                .andExpect(status().isForbidden());

        // Thử mở phiên
        mockMvc.perform(post("/api/v1/attendance/sessions/" + session.getId() + "/open")
                        .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isForbidden());

        // Thử đóng phiên
        mockMvc.perform(post("/api/v1/attendance/sessions/" + session.getId() + "/close")
                        .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isForbidden());
    }

    // =========================================================================
    // TEST 4: Không được mở phiên của giảng viên khác
    // =========================================================================
    @Test
    @DisplayName("4. Không được mở phiên của giảng viên khác - HTTP 403 Forbidden")
    void testCannotOpenAnotherLecturersSession() throws Exception {
        AttendanceSession session = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot1)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.CREATED)
                .build());

        // Other lecturer thử mở
        mockMvc.perform(post("/api/v1/attendance/sessions/" + session.getId() + "/open")
                        .header("Authorization", "Bearer " + otherLecturerToken))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.errorCode").value("ERR_2001"));
    }

    // =========================================================================
    // TEST 5: Tạo phiên với timetable slot hợp lệ
    // =========================================================================
    @Test
    @DisplayName("5. Tạo phiên với timetable slot hợp lệ - Trả về HTTP 201 CREATED")
    void testCreateSessionSuccess() throws Exception {
        AttendanceSessionCreateRequest req = AttendanceSessionCreateRequest.builder()
                .timetableSlotId(slot1.getId())
                .autoOpen(false)
                .build();

        mockMvc.perform(post("/api/v1/attendance/sessions")
                        .header("Authorization", "Bearer " + lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("CREATED"))
                .andExpect(jsonPath("$.data.className").value("IT301.01"))
                .andExpect(jsonPath("$.data.canOpen").value(true))
                .andExpect(jsonPath("$.data.canClose").value(false));

        assertTrue(attendanceSessionRepository.existsByTimetableSlotId(slot1.getId()));
    }

    // =========================================================================
    // TEST 6: Từ chối timetable slot không tồn tại
    // =========================================================================
    @Test
    @DisplayName("6. Từ chối timetable slot không tồn tại - HTTP 404 NOT_FOUND")
    void testRejectNonExistentTimetableSlot() throws Exception {
        AttendanceSessionCreateRequest req = AttendanceSessionCreateRequest.builder()
                .timetableSlotId(999999L)
                .build();

        mockMvc.perform(post("/api/v1/attendance/sessions")
                        .header("Authorization", "Bearer " + lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("ERR_6001"));
    }

    // =========================================================================
    // TEST 7: Từ chối lớp không thuộc quyền
    // =========================================================================
    @Test
    @DisplayName("7. Từ chối lớp không thuộc quyền - Giảng viên khác tạo phiên lớp bị chặn HTTP 403")
    void testRejectClassNotAssignedToLecturer() throws Exception {
        AttendanceSessionCreateRequest req = AttendanceSessionCreateRequest.builder()
                .timetableSlotId(slot1.getId()) // slot1 thuộc classSection của lecturer1
                .build();

        // otherLecturer thử tạo
        mockMvc.perform(post("/api/v1/attendance/sessions")
                        .header("Authorization", "Bearer " + otherLecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.errorCode").value("ERR_3017"));
    }

    // =========================================================================
    // TEST 8: Từ chối tạo phiên trùng cho cùng một slot
    // =========================================================================
    @Test
    @DisplayName("8. Từ chối tạo phiên trùng - Slot đã có phiên bị từ chối HTTP 409 Conflict")
    void testRejectDuplicateSessionCreation() throws Exception {
        attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot1)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.CREATED)
                .build());

        AttendanceSessionCreateRequest req = AttendanceSessionCreateRequest.builder()
                .timetableSlotId(slot1.getId())
                .build();

        mockMvc.perform(post("/api/v1/attendance/sessions")
                        .header("Authorization", "Bearer " + lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.errorCode").value("ERR_3019"));
    }

    // =========================================================================
    // TEST 9: Mở phiên đúng trạng thái (CREATED -> OPEN)
    // =========================================================================
    @Test
    @DisplayName("9. Mở phiên đúng trạng thái - Trạng thái chuyển sang OPEN và có openedAt")
    void testOpenSessionSuccess() throws Exception {
        AttendanceSession session = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot1)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.CREATED)
                .build());

        mockMvc.perform(post("/api/v1/attendance/sessions/" + session.getId() + "/open")
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("OPEN"))
                .andExpect(jsonPath("$.data.openedAt").isNotEmpty())
                .andExpect(jsonPath("$.data.canClose").value(true));

        AttendanceSession updated = attendanceSessionRepository.findById(session.getId()).orElseThrow();
        assertEquals(AttendanceSessionStatus.OPEN, updated.getStatus());
        assertNotNull(updated.getOpenedAt());
    }

    // =========================================================================
    // TEST 10: Đóng phiên đúng trạng thái (OPEN -> CLOSED)
    // =========================================================================
    @Test
    @DisplayName("10. Đóng phiên đúng trạng thái - Trạng thái chuyển sang CLOSED và có closedAt")
    void testCloseSessionSuccess() throws Exception {
        AttendanceSession session = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot1)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.OPEN)
                .openedAt(LocalDateTime.now().minusMinutes(30))
                .build());

        mockMvc.perform(post("/api/v1/attendance/sessions/" + session.getId() + "/close")
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("CLOSED"))
                .andExpect(jsonPath("$.data.closedAt").isNotEmpty())
                .andExpect(jsonPath("$.data.canOpen").value(false))
                .andExpect(jsonPath("$.data.canClose").value(false));

        AttendanceSession updated = attendanceSessionRepository.findById(session.getId()).orElseThrow();
        assertEquals(AttendanceSessionStatus.CLOSED, updated.getStatus());
        assertNotNull(updated.getClosedAt());
    }

    // =========================================================================
    // TEST 11: Không mở lại phiên CLOSED trái phép
    // =========================================================================
    @Test
    @DisplayName("11. Không mở lại phiên CLOSED trái phép - Bị từ chối HTTP 400 Bad Request")
    void testCannotReopenClosedSession() throws Exception {
        AttendanceSession session = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot1)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.CLOSED)
                .openedAt(LocalDateTime.now().minusHours(2))
                .closedAt(LocalDateTime.now().minusHours(1))
                .build());

        mockMvc.perform(post("/api/v1/attendance/sessions/" + session.getId() + "/open")
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("ERR_3014"));
    }

    // =========================================================================
    // TEST 12: Không tạo phiên ngoài lịch học / slot bị hủy
    // =========================================================================
    @Test
    @DisplayName("12. Không tạo phiên ngoài lịch học / slot bị hủy - Bị từ chối HTTP 400")
    void testRejectSessionForCancelledSlot() throws Exception {
        AttendanceSessionCreateRequest req = AttendanceSessionCreateRequest.builder()
                .timetableSlotId(cancelledSlot.getId())
                .build();

        mockMvc.perform(post("/api/v1/attendance/sessions")
                        .header("Authorization", "Bearer " + lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("ERR_1001"));
    }

    // =========================================================================
    // TEST 13: Kiểm tra attendance_configs (lấy và cập nhật cấu hình bởi ADMIN)
    // =========================================================================
    @Test
    @DisplayName("13. Kiểm tra attendance_configs - ADMIN lấy và cập nhật thành công")
    void testAttendanceConfigsManagement() throws Exception {
        // Lấy config mặc định
        mockMvc.perform(get("/api/v1/attendance/configs")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.manualEnabled").value(true));

        // Cập nhật config
        AttendanceConfigDto updateDto = AttendanceConfigDto.builder()
                .manualEnabled(true)
                .absentThresholdMinutes(20)
                .minAttendancePercentage(75.0)
                .faceRecognitionEnabled(true)
                .maxAttempts(5)
                .wifiLocationEnabled(true)
                .build();

        mockMvc.perform(put("/api/v1/attendance/configs")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.absentThresholdMinutes").value(20))
                .andExpect(jsonPath("$.data.maxAttempts").value(5));

        // LECTURER không được sửa config
        mockMvc.perform(put("/api/v1/attendance/configs")
                        .header("Authorization", "Bearer " + lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateDto)))
                .andExpect(status().isForbidden());
    }

    // =========================================================================
    // TEST 14: Kiểm tra concurrent create/open/close
    // =========================================================================
    @Test
    @DisplayName("14. Kiểm tra concurrent create/open/close - Bảo vệ chống race condition")
    void testConcurrentSessionTransitions() throws Exception {
        AttendanceSession session = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot1)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.CREATED)
                .build());

        int threadCount = 10;
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        CountDownLatch latch = new CountDownLatch(1);
        AtomicInteger successCount = new AtomicInteger(0);
        AtomicInteger failureCount = new AtomicInteger(0);

        for (int i = 0; i < threadCount; i++) {
            executor.submit(() -> {
                try {
                    latch.await();
                    Integer updated = transactionTemplate.execute(status -> attendanceSessionRepository.openSessionAtomic(
                            session.getId(),
                            LocalDateTime.now(),
                            AttendanceSessionStatus.OPEN,
                            AttendanceSessionStatus.CREATED
                    ));
                    if (updated != null && updated == 1) {
                        successCount.incrementAndGet();
                    } else {
                        failureCount.incrementAndGet();
                    }
                } catch (Exception e) {
                    failureCount.incrementAndGet();
                }
            });
        }

        latch.countDown();
        executor.shutdown();
        assertTrue(executor.awaitTermination(5, TimeUnit.SECONDS));

        // Chính xác CHỈ 1 thread mở phiên thành công
        assertEquals(1, successCount.get(), "Chỉ đúng 1 luồng được mở phiên thành công");
        assertEquals(9, failureCount.get(), "Các luồng đồng thời còn lại phải bị từ chối");

        AttendanceSession finalSession = attendanceSessionRepository.findById(session.getId()).orElseThrow();
        assertEquals(AttendanceSessionStatus.OPEN, finalSession.getStatus());
    }

    // =========================================================================
    // TEST 15: Phân trang, bộ lọc và sắp xếp
    // =========================================================================
    @Test
    @DisplayName("15. Phân trang, bộ lọc và sắp xếp - Lọc chính xác theo semester, className, status")
    void testFilterAndPagination() throws Exception {
        attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot1)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.CREATED)
                .build());

        attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot2)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.CLOSED)
                .build());

        // Lọc status = CREATED
        mockMvc.perform(get("/api/v1/attendance/sessions")
                        .param("status", "CREATED")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content", hasSize(1)))
                .andExpect(jsonPath("$.data.content[0].status").value("CREATED"));

        // Lọc status = CLOSED
        mockMvc.perform(get("/api/v1/attendance/sessions")
                        .param("status", "CLOSED")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content", hasSize(1)))
                .andExpect(jsonPath("$.data.content[0].status").value("CLOSED"));
    }

    // =========================================================================
    // TEST 16: Kiểm tra foreign keys và mapping
    // =========================================================================
    @Test
    @org.springframework.transaction.annotation.Transactional
    @DisplayName("16. Kiểm tra foreign keys - Mapping đúng quan hệ với timetable_slots và users")
    void testForeignKeyIntegrity() throws Exception {
        AttendanceSession session = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot1)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.OPEN)
                .openedAt(LocalDateTime.now())
                .build());

        AttendanceSession found = attendanceSessionRepository.findById(session.getId()).orElseThrow();
        assertNotNull(found.getTimetableSlot());
        assertEquals("IT301.01", found.getTimetableSlot().getClassSection().getClassName());
        assertEquals(lecturer.getId(), found.getLecturer().getId());
    }

    // =========================================================================
    // TEST 17: Kiểm tra transaction rollback khi gặp lỗi
    // =========================================================================
    @Test
    @DisplayName("17. Kiểm tra transaction rollback - Khi xảy ra lỗi không lưu dữ liệu dở dang")
    void testTransactionRollbackOnFailure() throws Exception {
        long initialCount = attendanceSessionRepository.count();

        // Gửi request với slot không tồn tại
        AttendanceSessionCreateRequest req = AttendanceSessionCreateRequest.builder()
                .timetableSlotId(-999L)
                .build();

        mockMvc.perform(post("/api/v1/attendance/sessions")
                        .header("Authorization", "Bearer " + lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isNotFound());

        // Đảm bảo số lượng bản ghi không đổi
        assertEquals(initialCount, attendanceSessionRepository.count());
    }

    // =========================================================================
    // TEST 18: Kiểm tra dữ liệu lịch sử không bị xóa (student_attendances)
    // =========================================================================
    @Test
    @DisplayName("18. Kiểm tra dữ liệu lịch sử không bị xóa - Khi đóng phiên dữ liệu điểm danh giữ nguyên")
    void testHistoricalAttendanceDataPreservedOnClose() throws Exception {
        AttendanceSession session = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot1)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.OPEN)
                .openedAt(LocalDateTime.now().minusMinutes(20))
                .build());

        // Tạo 1 bản ghi điểm danh
        StudentAttendance attendance = studentAttendanceRepository.save(StudentAttendance.builder()
                .session(session)
                .student(student)
                .status("PRESENT")
                .method("FACE")
                .checkInTime(LocalDateTime.now().minusMinutes(10))
                .faceConfidence(0.98)
                .build());

        // Đóng phiên
        mockMvc.perform(post("/api/v1/attendance/sessions/" + session.getId() + "/close")
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("CLOSED"));

        // Xác nhận bản ghi student_attendances vẫn còn nguyên
        assertTrue(studentAttendanceRepository.existsById(attendance.getId()));
        StudentAttendance preserved = studentAttendanceRepository.findById(attendance.getId()).orElseThrow();
        assertEquals("PRESENT", preserved.getStatus());
        assertEquals(session.getId(), preserved.getSession().getId());
    }

    // =========================================================================
    // TEST 19: Kiểm tra Status endpoint (Contract cho TASK-06)
    // =========================================================================
    @Test
    @DisplayName("19. Kiểm tra Status endpoint - Cung cấp đầy đủ trường hợp đồng cho TASK-06 Dynamic QR")
    void testStatusEndpointContractForTask06() throws Exception {
        AttendanceSession session = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot1)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.OPEN)
                .openedAt(LocalDateTime.now().minusMinutes(5))
                .build());

        mockMvc.perform(get("/api/v1/attendance/sessions/" + session.getId() + "/status")
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(session.getId()))
                .andExpect(jsonPath("$.data.status").value("OPEN"))
                .andExpect(jsonPath("$.data.isOpen").value(true))
                .andExpect(jsonPath("$.data.isClosed").value(false))
                .andExpect(jsonPath("$.data.canGenerateQr").value(true))
                .andExpect(jsonPath("$.data.totalEnrolledStudents").value(1))
                .andExpect(jsonPath("$.data.totalAttendedStudents").value(0))
                .andExpect(jsonPath("$.data.attendancePercentage").value(0.0));
    }

    // =========================================================================
    // TEST 20: Kiểm tra /attendances và /recent-checkins endpoint alias
    // =========================================================================
    @Test
    @DisplayName("20. Kiểm tra /attendances và /recent-checkins alias endpoint hoạt động chính xác")
    void testAttendancesAndRecentCheckInsAlias() throws Exception {
        AttendanceSession session = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot1)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.OPEN)
                .openedAt(LocalDateTime.now().minusMinutes(5))
                .build());

        studentAttendanceRepository.save(StudentAttendance.builder()
                .session(session)
                .student(student)
                .status("PRESENT")
                .method("QR")
                .checkInTime(LocalDateTime.now())
                .faceConfidence(0.99)
                .build());

        // 1. Check /attendances
        mockMvc.perform(get("/api/v1/attendance/sessions/" + session.getId() + "/attendances")
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].studentCode").value(student.getCode()))
                .andExpect(jsonPath("$.data[0].status").value("PRESENT"));

        // 2. Check /recent-checkins
        mockMvc.perform(get("/api/v1/attendance/sessions/" + session.getId() + "/recent-checkins")
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].studentCode").value(student.getCode()));
    }
}
