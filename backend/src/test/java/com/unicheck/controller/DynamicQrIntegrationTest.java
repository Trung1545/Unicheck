package com.unicheck.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.model.dto.QrValidationRequest;
import com.unicheck.model.entity.*;
import com.unicheck.model.enums.*;
import com.unicheck.repository.*;
import com.unicheck.security.DynamicQrRedisService;
import com.unicheck.security.JwtUtil;
import com.unicheck.security.QrTokenClaims;
import com.unicheck.service.DynamicQrService;
import com.unicheck.service.QrTokenService;
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
import org.springframework.test.web.servlet.MvcResult;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
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
public class DynamicQrIntegrationTest {

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
    private UserRepository userRepository;

    @Autowired
    private SlotTypeRepository slotTypeRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private QrTokenService qrTokenService;

    @Autowired
    private DynamicQrRedisService dynamicQrRedisService;

    @Autowired
    private DynamicQrService dynamicQrService;

    private String adminToken;
    private String lecturerToken;
    private String otherLecturerToken;
    private String studentToken;
    private String student2Token;

    private User admin;
    private User lecturer;
    private User otherLecturer;
    private User student;
    private User student2;

    private Semester semester;
    private Course course;
    private ClassSection classSection;
    private Room room;
    private SlotType slotType;
    private TimetableSlot openSlot;
    private TimetableSlot closedSlot;
    private TimetableSlot createdSlot;

    private AttendanceSession openSession;
    private AttendanceSession closedSession;
    private AttendanceSession createdSession;

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("DELETE FROM student_attendances");
        jdbcTemplate.execute("DELETE FROM attendance_sessions");
        jdbcTemplate.execute("DELETE FROM timetable_slots");
        jdbcTemplate.execute("DELETE FROM enrollments");

        // 1. Users setup
        admin = userRepository.findByUsername("admin_qr_test").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("ADM-QR-01")
                        .username("admin_qr_test")
                        .email("admin.qr@unicheck.edu.vn")
                        .password(passwordEncoder.encode("admin123"))
                        .fullName("Quản trị viên Hệ thống")
                        .role(Role.ADMIN)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        lecturer = userRepository.findByUsername("lecturer_qr_01").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("LEC-QR-01")
                        .username("lecturer_qr_01")
                        .email("lecturer.qr01@unicheck.edu.vn")
                        .password(passwordEncoder.encode("lecturer123"))
                        .fullName("TS. Nguyễn Văn Minh")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        otherLecturer = userRepository.findByUsername("lecturer_qr_02").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("LEC-QR-02")
                        .username("lecturer_qr_02")
                        .email("lecturer.qr02@unicheck.edu.vn")
                        .password(passwordEncoder.encode("lecturer123"))
                        .fullName("ThS. Trần Thị Mai")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        student = userRepository.findByUsername("student_qr_01").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("STU-QR-01")
                        .username("student_qr_01")
                        .email("student.qr01@unicheck.edu.vn")
                        .password(passwordEncoder.encode("student123"))
                        .fullName("Lê Hoàng Nam")
                        .role(Role.STUDENT)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        student2 = userRepository.findByUsername("student_qr_02").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("STU-QR-02")
                        .username("student_qr_02")
                        .email("student.qr02@unicheck.edu.vn")
                        .password(passwordEncoder.encode("student123"))
                        .fullName("Võ Thu Hương")
                        .role(Role.STUDENT)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        adminToken = jwtUtil.generateAccessToken(admin);
        lecturerToken = jwtUtil.generateAccessToken(lecturer);
        otherLecturerToken = jwtUtil.generateAccessToken(otherLecturer);
        studentToken = jwtUtil.generateAccessToken(student);
        student2Token = jwtUtil.generateAccessToken(student2);

        // 2. Academic Catalog & Room setup
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

        // 3. Timetable Slots
        openSlot = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection)
                .room(room)
                .slotType(slotType)
                .date(LocalDate.now())
                .dayOfWeek(1)
                .slotNumber(1)
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        closedSlot = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection)
                .room(room)
                .slotType(slotType)
                .date(LocalDate.now().minusDays(1))
                .dayOfWeek(7)
                .slotNumber(1)
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        createdSlot = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection)
                .room(room)
                .slotType(slotType)
                .date(LocalDate.now().plusDays(1))
                .dayOfWeek(2)
                .slotNumber(1)
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        // 4. Attendance Sessions
        openSession = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(openSlot)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.OPEN)
                .openedAt(LocalDateTime.now().minusMinutes(10))
                .createdAt(LocalDateTime.now().minusMinutes(15))
                .build());

        closedSession = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(closedSlot)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.CLOSED)
                .openedAt(LocalDateTime.now().minusHours(2))
                .closedAt(LocalDateTime.now().minusHours(1))
                .createdAt(LocalDateTime.now().minusHours(2))
                .build());

        createdSession = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(createdSlot)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.CREATED)
                .createdAt(LocalDateTime.now())
                .build());
    }

    // =========================================================================
    // 1. LECTURER phát QR phiên của mình -> 200 OK
    // =========================================================================
    @Test
    @DisplayName("1. LECTURER phát QR phiên của mình -> 200 OK kèm token và thời hạn")
    void testLecturerIssuesQrForOwnSession() throws Exception {
        mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.sessionId").value(openSession.getId()))
                .andExpect(jsonPath("$.data.qrToken").isString())
                .andExpect(jsonPath("$.data.qrToken", not(emptyOrNullString())))
                .andExpect(jsonPath("$.data.status").value("OPEN"))
                .andExpect(jsonPath("$.data.rotationIntervalSeconds").value(greaterThan(0)))
                .andExpect(jsonPath("$.data.remainingSeconds").value(greaterThan(0)))
                .andExpect(jsonPath("$.data.issuedAt").exists())
                .andExpect(jsonPath("$.data.expiresAt").exists());
    }

    // =========================================================================
    // 2. LECTURER bị từ chối phát QR phiên người khác -> 403 Forbidden
    // =========================================================================
    @Test
    @DisplayName("2. LECTURER bị từ chối phát QR phiên của giảng viên khác -> 403 Forbidden")
    void testLecturerForbiddenFromIssuingOtherLecturersSession() throws Exception {
        mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + otherLecturerToken))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_3017"));
    }

    // =========================================================================
    // 3. STUDENT không được phát QR -> 403 Forbidden
    // =========================================================================
    @Test
    @DisplayName("3. STUDENT không được phát QR -> 403 Forbidden")
    void testStudentForbiddenFromIssuingQr() throws Exception {
        mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isForbidden());
    }

    // =========================================================================
    // 4. ADMIN có quyền phát QR cho phiên bất kỳ -> 200 OK
    // =========================================================================
    @Test
    @DisplayName("4. ADMIN có quyền phát QR cho phiên bất kỳ -> 200 OK")
    void testAdminCanIssueQrForAnySession() throws Exception {
        mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.sessionId").value(openSession.getId()));
    }

    // =========================================================================
    // 5. QR phiên CLOSED bị từ chối -> 400 Bad Request (SESSION_NOT_OPEN)
    // =========================================================================
    @Test
    @DisplayName("5. QR phiên CLOSED bị từ chối -> 400 Bad Request (SESSION_NOT_OPEN)")
    void testRejectQrForClosedSession() throws Exception {
        mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", closedSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_3024"));
    }

    // =========================================================================
    // 6. QR phiên CREATED chưa mở bị từ chối -> 400 Bad Request (SESSION_NOT_OPEN)
    // =========================================================================
    @Test
    @DisplayName("6. QR phiên CREATED chưa mở bị từ chối -> 400 Bad Request")
    void testRejectQrForCreatedSession() throws Exception {
        mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", createdSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_3024"));
    }

    // =========================================================================
    // 7. QR của session không tồn tại -> 404 NOT_FOUND
    // =========================================================================
    @Test
    @DisplayName("7. QR của session không tồn tại -> 404 NOT_FOUND")
    void testRejectQrForNonExistentSession() throws Exception {
        mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", 999999L)
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("ERR_3012"));
    }

    // =========================================================================
    // 8. Xác thực QR token hợp lệ -> 200 OK
    // =========================================================================
    @Test
    @DisplayName("8. Xác thực QR token hợp lệ -> 200 OK")
    void testValidateValidQrSuccess() throws Exception {
        // Sinh QR token hợp lệ
        MvcResult res = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();

        String json = res.getResponse().getContentAsString();
        String qrToken = objectMapper.readTree(json).get("data").get("qrToken").asText();

        // Validate
        QrValidationRequest request = QrValidationRequest.builder()
                .qrToken(qrToken)
                .sessionId(openSession.getId())
                .build();

        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.valid").value(true))
                .andExpect(jsonPath("$.data.sessionId").value(openSession.getId()))
                .andExpect(jsonPath("$.data.className").value("IT301.01"))
                .andExpect(jsonPath("$.data.roomName").value("Phòng thực hành A2-304"));
    }

    // =========================================================================
    // 9. QR hết hạn -> 400 Bad Request (QR_TOKEN_EXPIRED)
    // =========================================================================
    @Test
    @DisplayName("9. QR hết hạn -> 400 Bad Request (QR_TOKEN_EXPIRED)")
    void testValidateQrExpired() throws Exception {
        // Tạo token đã hết hạn (issued 10s trước, TTL 5s)
        Instant pastIssued = Instant.now().minusSeconds(10);
        String expiredToken = qrTokenService.generateQrToken(
                openSession.getId(),
                pastIssued,
                Duration.ofSeconds(5),
                Duration.ofSeconds(5)
        );

        QrValidationRequest request = QrValidationRequest.builder()
                .qrToken(expiredToken)
                .sessionId(openSession.getId())
                .build();

        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_3021"));
    }

    // =========================================================================
    // 10. QR chữ ký sai hoặc bị tamper -> 400 Bad Request (QR_TOKEN_INVALID)
    // =========================================================================
    @Test
    @DisplayName("10. QR chữ ký sai hoặc bị tamper -> 400 Bad Request (QR_TOKEN_INVALID)")
    void testValidateQrInvalidSignature() throws Exception {
        // Lấy token thật rồi sửa đổi 1 ký tự
        MvcResult res = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();

        String rawToken = objectMapper.readTree(res.getResponse().getContentAsString()).get("data").get("qrToken").asText();
        String tamperedToken = rawToken.substring(0, rawToken.length() - 5) + "abcde";

        QrValidationRequest request = QrValidationRequest.builder()
                .qrToken(tamperedToken)
                .sessionId(openSession.getId())
                .build();

        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_3020"));
    }

    // =========================================================================
    // 11. QR session mismatch (gửi token session A cho session B) -> 400 Bad Request
    // =========================================================================
    @Test
    @DisplayName("11. QR session mismatch -> 400 Bad Request (QR_SESSION_MISMATCH)")
    void testValidateQrSessionMismatch() throws Exception {
        MvcResult res = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();

        String qrToken = objectMapper.readTree(res.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        // Gửi token của openSession nhưng lại đòi validate cho closedSession ID
        QrValidationRequest request = QrValidationRequest.builder()
                .qrToken(qrToken)
                .sessionId(closedSession.getId())
                .build();

        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_3022"));
    }

    // =========================================================================
    // 12. Khi phiên đóng CLOSED, validate token cũ bị từ chối -> 400 Bad Request
    // =========================================================================
    @Test
    @DisplayName("12. Khi phiên đóng CLOSED, validate token cũ bị từ chối")
    void testValidateQrClosedSessionRejected() throws Exception {
        // 1. Sinh token khi OPEN
        MvcResult res = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();

        String qrToken = objectMapper.readTree(res.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        // 2. Giảng viên đóng phiên
        mockMvc.perform(post("/api/v1/attendance/sessions/{sessionId}/close", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("CLOSED"));

        // 3. Sinh viên cố dùng token vừa lấy để validate
        QrValidationRequest request = QrValidationRequest.builder()
                .qrToken(qrToken)
                .sessionId(openSession.getId())
                .build();

        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_3024"));
    }

    // =========================================================================
    // 13. Nhiều sinh viên khác nhau cùng validate cùng mã trong TTL -> Đều 200 OK
    // =========================================================================
    @Test
    @DisplayName("13. Nhiều sinh viên khác nhau cùng validate cùng mã trong TTL -> Đều 200 OK")
    void testMultipleStudentsCanValidateSameQr() throws Exception {
        MvcResult res = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();

        String qrToken = objectMapper.readTree(res.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        QrValidationRequest request = QrValidationRequest.builder()
                .qrToken(qrToken)
                .sessionId(openSession.getId())
                .build();

        // Sinh viên 1 validate
        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.valid").value(true));

        // Sinh viên 2 validate cùng mã
        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + student2Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.valid").value(true));
    }

    // =========================================================================
    // 14. Xác minh QR tuyệt đối KHÔNG tự tạo bản ghi student_attendance
    // =========================================================================
    @Test
    @DisplayName("14. Xác minh QR tuyệt đối KHÔNG tự tạo bản ghi student_attendance")
    void testQrValidationDoesNotCreateStudentAttendance() throws Exception {
        long initialCount = studentAttendanceRepository.count();

        MvcResult res = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();

        String qrToken = objectMapper.readTree(res.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        QrValidationRequest request = QrValidationRequest.builder()
                .qrToken(qrToken)
                .sessionId(openSession.getId())
                .build();

        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk());

        // Số lượng attendance vẫn phải giữ nguyên
        assertEquals(initialCount, studentAttendanceRepository.count());
    }

    // =========================================================================
    // 15. Dual-write in-memory fallback hoạt động an toàn
    // =========================================================================
    @Test
    @DisplayName("15. Dual-write in-memory fallback hoạt động an toàn khi Redis không khả dụng")
    void testDualWriteRedisResilienceFallback() {
        // Trực tiếp test save & read qua dynamicQrRedisService
        Instant now = Instant.now();
        String fakeToken = "dummy_token_resilience";
        dynamicQrRedisService.saveActiveQr(999L, fakeToken, now, now.plusSeconds(30), now.plusSeconds(10));

        DynamicQrRedisService.ActiveQrEntry entry = dynamicQrRedisService.getActiveQr(999L);
        assertNotNull(entry);
        assertEquals(fakeToken, entry.qrToken());
        assertFalse(entry.isTokenExpired(now));
    }

    // =========================================================================
    // 16. Token được cache ổn định trong chu kỳ rotation (Polling an toàn)
    // =========================================================================
    @Test
    @DisplayName("16. Token được cache ổn định trong chu kỳ rotation (Polling an toàn)")
    void testActiveQrCachedWithinRotationInterval() throws Exception {
        MvcResult res1 = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();

        String token1 = objectMapper.readTree(res1.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        // Gọi ngay lần 2
        MvcResult res2 = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();

        String token2 = objectMapper.readTree(res2.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        // Cùng chu kỳ rotation -> Token phải giống nhau hoàn toàn
        assertEquals(token1, token2);
    }

    // =========================================================================
    // 17. Token mới được sinh sau khi chu kỳ rotation kết thúc
    // =========================================================================
    @Test
    @DisplayName("17. Token mới được sinh sau khi chu kỳ rotation kết thúc")
    void testNewQrGeneratedAfterRotationInterval() throws Exception {
        MvcResult res1 = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();

        String token1 = objectMapper.readTree(res1.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        // Giả lập rotation đã hết hạn trong cache bằng cách ghi đè entry có rotationExpiresAt trong quá khứ
        Instant past = Instant.now().minusSeconds(1);
        dynamicQrRedisService.saveActiveQr(openSession.getId(), token1, past.minusSeconds(10), past.plusSeconds(10), past);

        // Gọi lại API lấy QR
        MvcResult res2 = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();

        String token2 = objectMapper.readTree(res2.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        // Token 2 phải là token mới khác token 1
        assertNotEquals(token1, token2);
    }

    // =========================================================================
    // 18. Đồng thời 10 luồng lấy QR -> Trả về token nhất quán không bị xung đột
    // =========================================================================
    @Test
    @DisplayName("18. Đồng thời 10 luồng lấy QR -> Trả về token nhất quán không bị xung đột")
    void testConcurrentQrIssuance() throws Exception {
        int threads = 10;
        ExecutorService executor = Executors.newFixedThreadPool(threads);
        CountDownLatch latch = new CountDownLatch(threads);
        List<String> tokens = new CopyOnWriteArrayList<>();

        for (int i = 0; i < threads; i++) {
            executor.submit(() -> {
                try {
                    MvcResult res = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                                    .header("Authorization", "Bearer " + lecturerToken))
                            .andExpect(status().isOk())
                            .andReturn();
                    String t = objectMapper.readTree(res.getResponse().getContentAsString()).get("data").get("qrToken").asText();
                    tokens.add(t);
                } catch (Exception e) {
                    fail("Concurrent request failed: " + e.getMessage());
                } finally {
                    latch.countDown();
                }
            });
        }

        assertTrue(latch.await(10, TimeUnit.SECONDS));
        executor.shutdown();

        assertEquals(threads, tokens.size());
        // Tất cả 10 luồng đều nhận cùng một token active
        String firstToken = tokens.get(0);
        for (String t : tokens) {
            assertEquals(firstToken, t);
        }
    }

    // =========================================================================
    // 19. Request chưa đăng nhập bị từ chối -> 401 Unauthorized
    // =========================================================================
    @Test
    @DisplayName("19. Request chưa đăng nhập bị từ chối -> 401 Unauthorized")
    void testUnauthenticatedRequestsRejected() throws Exception {
        mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId()))
                .andExpect(status().isUnauthorized());

        QrValidationRequest request = QrValidationRequest.builder()
                .qrToken("any_token")
                .sessionId(openSession.getId())
                .build();

        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized());
    }

    // =========================================================================
    // 20. Token không bị rò rỉ nguyên vẹn trong error payload hoặc exception
    // =========================================================================
    @Test
    @DisplayName("20. Token không bị rò rỉ nguyên vẹn trong error payload hoặc exception")
    void testNoTokenLeakInLogs() throws Exception {
        String secretTokenToMask = "eyJhbGciOiJIUzI1NiJ9.secret_payload_do_not_leak.sig";
        QrValidationRequest request = QrValidationRequest.builder()
                .qrToken(secretTokenToMask)
                .sessionId(openSession.getId())
                .build();

        MvcResult res = mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andReturn();

        String body = res.getResponse().getContentAsString();
        // Thông điệp trả về cho người dùng không chứa chuỗi token nhạy cảm
        assertFalse(body.contains("secret_payload_do_not_leak"));
    }
}
