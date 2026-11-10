package com.unicheck.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.model.dto.AttendanceCheckInRequest;
import com.unicheck.model.dto.QrValidationRequest;
import com.unicheck.model.dto.ai.AiCheckLivenessResponse;
import com.unicheck.model.dto.ai.AiVerifyFaceResponse;
import com.unicheck.model.entity.*;
import com.unicheck.model.enums.*;
import com.unicheck.repository.*;
import com.unicheck.security.JwtUtil;
import com.unicheck.service.StaticTestQrService;
import com.unicheck.service.ai.AiServiceClient;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class StaticTestQrIntegrationTest {

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
    private EnrollmentRepository enrollmentRepository;

    @Autowired
    private AttendanceConfigRepository attendanceConfigRepository;

    @Autowired
    private FaceEncodingRepository faceEncodingRepository;

    @Autowired
    private WifiAccessPointRepository wifiAccessPointRepository;

    @Autowired
    private RoomWifiAccessPointRepository roomWifiAccessPointRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private StaticTestQrService staticTestQrService;

    @MockBean
    private AiServiceClient aiServiceClient;

    private User admin;
    private User lecturer;
    private User otherLecturer;
    private User testStudent;
    private User unenrolledStudent;

    private String adminToken;
    private String lecturerToken;
    private String otherLecturerToken;
    private String testStudentToken;
    private String unenrolledStudentToken;

    private AttendanceSession e2eOpenSession;
    private AttendanceSession regularOpenSession;
    private AttendanceSession closedSession;

    private static final String DUMMY_BASE64 = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP...";

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("DELETE FROM student_attendances");
        jdbcTemplate.execute("DELETE FROM attendance_sessions");
        jdbcTemplate.execute("DELETE FROM timetable_slots");
        jdbcTemplate.execute("DELETE FROM enrollments");

        // 1. Users
        admin = userRepository.findByUsername("admin_static_test").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("ADM-STAT-01")
                        .username("admin_static_test")
                        .email("admin.stat@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Password@123"))
                        .fullName("Quản trị viên Kiểm thử")
                        .role(Role.ADMIN)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        lecturer = userRepository.findByUsername("gv_sonnt_stat").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("TEST_LEC_01")
                        .username("gv_sonnt_stat")
                        .email("sonnt.stat@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Password@123"))
                        .fullName("Nguyễn Tấn Sơn")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        otherLecturer = userRepository.findByUsername("gv_other_stat").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("TEST_LEC_99")
                        .username("gv_other_stat")
                        .email("other.stat@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Password@123"))
                        .fullName("Giảng viên khác")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        testStudent = userRepository.findByUsername("sv_he180002_stat").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("HE180002")
                        .username("sv_he180002_stat")
                        .email("he180002.stat@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Password@123"))
                        .fullName("Trần Bảo Long")
                        .role(Role.STUDENT)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        unenrolledStudent = userRepository.findByUsername("sv_unenrolled_stat").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("HE180999")
                        .username("sv_unenrolled_stat")
                        .email("unenrolled.stat@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Password@123"))
                        .fullName("Sinh viên ngoài lớp")
                        .role(Role.STUDENT)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        adminToken = jwtUtil.generateAccessToken(admin);
        lecturerToken = jwtUtil.generateAccessToken(lecturer);
        otherLecturerToken = jwtUtil.generateAccessToken(otherLecturer);
        testStudentToken = jwtUtil.generateAccessToken(testStudent);
        unenrolledStudentToken = jwtUtil.generateAccessToken(unenrolledStudent);

        // 2. Catalog
        Semester semester = semesterRepository.findByCode("FALL2026").orElseGet(() ->
                semesterRepository.save(Semester.builder()
                        .code("FALL2026")
                        .name("Học kỳ Fall 2026")
                        .startDate(LocalDate.now().minusDays(10))
                        .endDate(LocalDate.now().plusMonths(3))
                        .status(SemesterStatus.ACTIVE)
                        .build())
        );

        Course course = courseRepository.findByCode("IT301").orElseGet(() ->
                courseRepository.save(Course.builder()
                        .code("IT301")
                        .name("Lập trình Web nâng cao")
                        .credits(3)
                        .numberOfSlots(30)
                        .status(CourseStatus.ACTIVE)
                        .build())
        );

        Room room = roomRepository.findByCode("BE-E2E").orElseGet(() ->
                roomRepository.save(Room.builder()
                        .code("BE-E2E")
                        .name("Phòng thực hành Emulator E2E")
                        .building("Tòa Alpha")
                        .capacity(40)
                        .status(RoomStatus.AVAILABLE)
                        .build())
        );

        SlotType slotType = slotTypeRepository.findAll().stream()
                .filter(st -> st.getSemester() != null && st.getSemester().getId().equals(semester.getId()))
                .findFirst()
                .orElseGet(() -> slotTypeRepository.save(SlotType.builder()
                        .name("Slot E2E (07:30 - 09:00)")
                        .slotIndex(1)
                        .startTime(LocalTime.now().minusMinutes(5))
                        .endTime(LocalTime.now().plusHours(2))
                        .duration("90m")
                        .semester(semester)
                        .build())
        );

        // 3. ClassSection: UNICHECK-E2E-01
        ClassSection e2eClass = classSectionRepository.findByClassName("UNICHECK-E2E-01").orElseGet(() ->
                classSectionRepository.save(ClassSection.builder()
                        .className("UNICHECK-E2E-01")
                        .course(course)
                        .semester(semester)
                        .lecturer(lecturer)
                        .numberOfSlots(30)
                        .maxStudents(40)
                        .currentEnrollment(1)
                        .status(ClassSectionStatus.OPEN)
                        .build())
        );

        // Regular class (not UNICHECK-E2E-01)
        ClassSection regularClass = classSectionRepository.findByClassName("IT301-REGULAR").orElseGet(() ->
                classSectionRepository.save(ClassSection.builder()
                        .className("IT301-REGULAR")
                        .course(course)
                        .semester(semester)
                        .lecturer(lecturer)
                        .numberOfSlots(30)
                        .maxStudents(40)
                        .currentEnrollment(1)
                        .status(ClassSectionStatus.OPEN)
                        .build())
        );

        // Enroll testStudent to UNICHECK-E2E-01
        if (!enrollmentRepository.existsByClassSection_ClassNameAndStudent_Id(e2eClass.getClassName(), testStudent.getId())) {
            enrollmentRepository.save(Enrollment.builder()
                    .classSection(e2eClass)
                    .student(testStudent)
                    .studentCode(testStudent.getCode())
                    .status(EnrollmentStatus.ENROLLED)
                    .build());
        }

        // 4. Timetable Slots & Sessions
        TimetableSlot e2eSlot = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(e2eClass)
                .slotType(slotType)
                .room(room)
                .date(LocalDate.now())
                .slotNumber(1)
                .build());

        e2eOpenSession = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(e2eSlot)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.OPEN)
                .openedAt(LocalDateTime.now().minusMinutes(5))
                .build());

        TimetableSlot regSlot = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(regularClass)
                .slotType(slotType)
                .room(room)
                .date(LocalDate.now())
                .slotNumber(2)
                .build());

        regularOpenSession = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(regSlot)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.OPEN)
                .openedAt(LocalDateTime.now().minusMinutes(5))
                .build());

        TimetableSlot closedSlot = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(e2eClass)
                .slotType(slotType)
                .room(room)
                .date(LocalDate.now().minusDays(1))
                .slotNumber(3)
                .build());

        closedSession = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(closedSlot)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.CLOSED)
                .openedAt(LocalDateTime.now().minusHours(2))
                .closedAt(LocalDateTime.now().minusHours(1))
                .build());

        // 5. Biometric Face Profile & Wi-Fi AP for testStudent
        byte[] dummyEncoding = new byte[512 * 4];
        FaceEncoding fe = faceEncodingRepository.findByUserId(testStudent.getId()).orElseGet(() ->
                FaceEncoding.builder()
                        .user(testStudent)
                        .build()
        );
        fe.setEncodingData(dummyEncoding);
        faceEncodingRepository.save(fe);

        // Wi-Fi AP
        WifiAccessPoint ap = wifiAccessPointRepository.findByBssidIgnoreCase("AA:BB:CC:DD:EE:01").orElseGet(() ->
                wifiAccessPointRepository.save(WifiAccessPoint.builder()
                        .bssid("AA:BB:CC:DD:EE:01")
                        .ssid("UniCheck_E2E_TestLab")
                        .status(WifiApStatus.ACTIVE)
                        .build())
        );

        if (!roomWifiAccessPointRepository.existsByRoomIdAndWifiAccessPointId(room.getId(), ap.getId())) {
            roomWifiAccessPointRepository.save(RoomWifiAccessPoint.builder()
                    .room(room)
                    .wifiAccessPoint(ap)
                    .isPrimary(true)
                    .build());
        }

        // Attendance config
        AttendanceConfig config = attendanceConfigRepository.findByConfigKey("DEFAULT").orElseGet(() ->
                AttendanceConfig.builder()
                        .configKey("DEFAULT")
                        .wifiLocationEnabled(true)
                        .faceRecognitionEnabled(true)
                        .maxAttempts(3)
                        .absentThresholdMinutes(15)
                        .build()
        );
        config.setWifiLocationEnabled(true);
        attendanceConfigRepository.save(config);
    }

    // =========================================================================
    // 1. Phân quyền & Điều kiện kích hoạt Static Test QR
    // =========================================================================

    @Test
    @DisplayName("TC-ST-01: Giảng viên phụ trách UNICHECK-E2E-01 lấy được Static Test QR thành công")
    void testLecturerCanGetStaticTestQr() throws Exception {
        MvcResult res = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/static-qr", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.mode").value("STATIC_TEST_QR"))
                .andExpect(jsonPath("$.data.rotationIntervalSeconds").value(0))
                .andExpect(jsonPath("$.data.qrToken", startsWith("STQR:" + e2eOpenSession.getId() + ":")))
                .andExpect(jsonPath("$.data.remainingSeconds", greaterThan(1000)))
                .andReturn();

        String token = objectMapper.readTree(res.getResponse().getContentAsString()).get("data").get("qrToken").asText();
        assertNotNull(token);
    }

    @Test
    @DisplayName("TC-ST-02: Endpoint /sessions/{id}/qr?mode=STATIC_TEST_QR trả về Static Test QR")
    void testSessionQrWithModeParam() throws Exception {
        mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", e2eOpenSession.getId())
                        .param("mode", "STATIC_TEST_QR")
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.mode").value("STATIC_TEST_QR"))
                .andExpect(jsonPath("$.data.qrToken", startsWith("STQR:" + e2eOpenSession.getId() + ":")));
    }

    @Test
    @DisplayName("TC-ST-03: Kiểm tra trạng thái capability cho phép bật Static Test QR trên UNICHECK-E2E-01")
    void testStaticQrStatusAllowedForE2EClass() throws Exception {
        mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/static-qr/status", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.allowed").value(true))
                .andExpect(jsonPath("$.data.className").value("UNICHECK-E2E-01"));
    }

    @Test
    @DisplayName("TC-ST-04: Lớp khác (không phải UNICHECK-E2E-01) bị TỪ CHỐI phát Static Test QR (403 Forbidden)")
    void testNonE2EClassRejectedForStaticQr() throws Exception {
        mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/static-qr", regularOpenSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isForbidden());

        mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/static-qr/status", regularOpenSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.allowed").value(false));
    }

    @Test
    @DisplayName("TC-ST-05: Tài khoản STUDENT bị CẤM tuyệt đối gọi API phát hành Static Test QR (403 Forbidden)")
    void testStudentCannotIssueStaticQr() throws Exception {
        mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/static-qr", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + testStudentToken))
                .andExpect(status().isForbidden());

        mockMvc.perform(post("/api/v1/attendance/sessions/{sessionId}/static-qr/regenerate", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + testStudentToken))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("TC-ST-06: Giảng viên khác không phụ trách lớp bị TỪ CHỐI (403 Forbidden)")
    void testUnauthorizedLecturerCannotIssueStaticQr() throws Exception {
        mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/static-qr", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + otherLecturerToken))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("TC-ST-07: Phiên đã CLOSED không được phép phát hành Static Test QR (400 Bad Request)")
    void testClosedSessionCannotIssueStaticQr() throws Exception {
        mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/static-qr", closedSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isBadRequest());
    }

    // =========================================================================
    // 2. Tính chất Static: QR KHÔNG xoay vòng và duy trì token ổn định
    // =========================================================================

    @Test
    @DisplayName("TC-ST-08: Token Static Test QR không tự xoay vòng (gọi nhiều lần nhận cùng 1 token)")
    void testStaticQrDoesNotRotate() throws Exception {
        MvcResult res1 = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/static-qr", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();
        String token1 = objectMapper.readTree(res1.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        // Gọi lại lần 2
        MvcResult res2 = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/static-qr", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();
        String token2 = objectMapper.readTree(res2.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        assertEquals(token1, token2, "Static Test QR token phải giữ nguyên cố định trong thời gian kiểm thử");
    }

    @Test
    @DisplayName("TC-ST-09: Giảng viên có thể Tái tạo (Regenerate) Static QR mới và vô hiệu hóa token cũ")
    void testRegenerateStaticQr() throws Exception {
        MvcResult res1 = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/static-qr", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();
        String oldToken = objectMapper.readTree(res1.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        // Bấm Tạo lại QR
        MvcResult res2 = mockMvc.perform(post("/api/v1/attendance/sessions/{sessionId}/static-qr/regenerate", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();
        String newToken = objectMapper.readTree(res2.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        assertNotEquals(oldToken, newToken, "Token mới phải khác token cũ sau khi regenerate");

        // Xác thực token cũ -> Bị từ chối (400)
        QrValidationRequest oldReq = QrValidationRequest.builder()
                .sessionId(e2eOpenSession.getId())
                .qrToken(oldToken)
                .build();
        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + testStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(oldReq)))
                .andExpect(status().isBadRequest());

        // Xác thực token mới -> Hợp lệ (200)
        QrValidationRequest newReq = QrValidationRequest.builder()
                .sessionId(e2eOpenSession.getId())
                .qrToken(newToken)
                .build();
        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + testStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(newReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.valid").value(true));
    }

    @Test
    @DisplayName("TC-ST-10: Thu hồi (Revoke) Static QR khiến token lập tức vô hiệu")
    void testRevokeStaticQr() throws Exception {
        MvcResult res1 = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/static-qr", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();
        String token = objectMapper.readTree(res1.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        // Thu hồi
        mockMvc.perform(post("/api/v1/attendance/sessions/{sessionId}/static-qr/revoke", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk());

        // Validate -> Báo lỗi không hợp lệ
        QrValidationRequest req = QrValidationRequest.builder()
                .sessionId(e2eOpenSession.getId())
                .qrToken(token)
                .build();
        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + testStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    // =========================================================================
    // 3. Negative Tests (Phase 7)
    // =========================================================================

    @Test
    @DisplayName("TC-ST-11: Token bị chỉnh sửa (Tampered) -> Bị từ chối (400)")
    void testTamperedStaticTokenRejected() throws Exception {
        MvcResult res = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/static-qr", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();
        String validToken = objectMapper.readTree(res.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        String tamperedToken = validToken + "99bad";

        QrValidationRequest req = QrValidationRequest.builder()
                .sessionId(e2eOpenSession.getId())
                .qrToken(tamperedToken)
                .build();
        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + testStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("TC-ST-12: Token đúng nhưng gửi sai sessionId (Session Mismatch) -> Bị từ chối (400)")
    void testSessionMismatchRejected() throws Exception {
        MvcResult res = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/static-qr", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();
        String token = objectMapper.readTree(res.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        QrValidationRequest req = QrValidationRequest.builder()
                .sessionId(999999L)
                .qrToken(token)
                .build();
        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + testStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("TC-ST-13: Khi phiên bị đóng (CLOSED), token Static QR lập tức bị vô hiệu")
    void testSessionCloseInvalidatesStaticQr() throws Exception {
        MvcResult res = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/static-qr", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();
        String token = objectMapper.readTree(res.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        // Đóng phiên điểm danh
        mockMvc.perform(post("/api/v1/attendance/sessions/{id}/close", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk());

        // Xác thực token sau khi đóng phiên -> Báo lỗi
        QrValidationRequest req = QrValidationRequest.builder()
                .sessionId(e2eOpenSession.getId())
                .qrToken(token)
                .build();
        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + testStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    // =========================================================================
    // 4. Attendance End-to-End Check-In với Static Test QR (Phase 6)
    // =========================================================================

    @Test
    @DisplayName("TC-ST-14: E2E - Sinh viên sv_he180002 điểm danh thành công với Static Test QR")
    void testStudentCheckInWithStaticTestQrSuccess() throws Exception {
        // AI Service mocks
        when(aiServiceClient.checkLiveness(anyString(), anyDouble()))
                .thenReturn(AiCheckLivenessResponse.of(true, 0.95));
        when(aiServiceClient.verifyFace(anyList(), anyString(), anyDouble()))
                .thenReturn(AiVerifyFaceResponse.of(true, 0.93));

        // 1. Giảng viên lấy Static Test QR
        MvcResult res = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/static-qr", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();
        String staticToken = objectMapper.readTree(res.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        // 2. Sinh viên gửi checkin kèm staticToken
        AttendanceCheckInRequest checkinReq = AttendanceCheckInRequest.builder()
                .sessionId(e2eOpenSession.getId())
                .qrToken(staticToken)
                .wifiBssid("AA:BB:CC:DD:EE:01")
                .wifiSsid("UniCheck_E2E_TestLab")
                .faceSampleBase64(DUMMY_BASE64)
                .deviceModel("Android Emulator (Pixel 8)")
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + testStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkinReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("PRESENT"))
                .andExpect(jsonPath("$.data.studentCode").value("HE180002"))
                .andExpect(jsonPath("$.data.className").value("UNICHECK-E2E-01"));

        // Xác thực trong CSDL PostgreSQL/H2
        assertTrue(studentAttendanceRepository.existsBySessionIdAndStudentId(e2eOpenSession.getId(), testStudent.getId()));
        StudentAttendance att = studentAttendanceRepository.findBySessionIdAndStudentId(e2eOpenSession.getId(), testStudent.getId()).orElseThrow();
        assertEquals("PRESENT", att.getStatus());
        assertEquals("AA:BB:CC:DD:EE:01", att.getWifiBssid());
    }

    @Test
    @DisplayName("TC-ST-15: E2E - Sinh viên gửi Static Test QR nhưng sai Wi-Fi -> Bị từ chối (400 WIFI_NOT_MATCHED)")
    void testStudentCheckInWithWrongWifiRejected() throws Exception {
        MvcResult res = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/static-qr", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();
        String staticToken = objectMapper.readTree(res.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        AttendanceCheckInRequest checkinReq = AttendanceCheckInRequest.builder()
                .sessionId(e2eOpenSession.getId())
                .qrToken(staticToken)
                .wifiBssid("99:99:99:99:99:99") // Sai BSSID
                .faceSampleBase64(DUMMY_BASE64)
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + testStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkinReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("ERR_3008"));
    }

    @Test
    @DisplayName("TC-ST-16: E2E - Sinh viên chưa ghi danh vào UNICHECK-E2E-01 -> Bị từ chối (403 Forbidden)")
    void testUnenrolledStudentCheckInRejected() throws Exception {
        MvcResult res = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/static-qr", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();
        String staticToken = objectMapper.readTree(res.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        AttendanceCheckInRequest checkinReq = AttendanceCheckInRequest.builder()
                .sessionId(e2eOpenSession.getId())
                .qrToken(staticToken)
                .wifiBssid("AA:BB:CC:DD:EE:01")
                .faceSampleBase64(DUMMY_BASE64)
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + unenrolledStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkinReq)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("TC-ST-17: E2E - Chống điểm danh trùng lặp (Idempotency) -> Báo lỗi 409 Conflict")
    void testDuplicateCheckInRejected() throws Exception {
        when(aiServiceClient.checkLiveness(anyString(), anyDouble()))
                .thenReturn(AiCheckLivenessResponse.of(true, 0.95));
        when(aiServiceClient.verifyFace(anyList(), anyString(), anyDouble()))
                .thenReturn(AiVerifyFaceResponse.of(true, 0.93));

        MvcResult res = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/static-qr", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();
        String staticToken = objectMapper.readTree(res.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        AttendanceCheckInRequest checkinReq = AttendanceCheckInRequest.builder()
                .sessionId(e2eOpenSession.getId())
                .qrToken(staticToken)
                .wifiBssid("AA:BB:CC:DD:EE:01")
                .faceSampleBase64(DUMMY_BASE64)
                .build();

        // Lần 1: Thành công
        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + testStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkinReq)))
                .andExpect(status().isOk());

        // Lần 2: Báo trùng lặp (409)
        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + testStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkinReq)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.errorCode").value("ERR_3007"));
    }

    @Test
    @DisplayName("TC-ST-18: Xác minh QR không tự động tạo bản ghi PRESENT giả")
    void testStaticQrValidationDoesNotCreateAttendance() throws Exception {
        long initialCount = studentAttendanceRepository.count();

        MvcResult res = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/static-qr", e2eOpenSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();
        String staticToken = objectMapper.readTree(res.getResponse().getContentAsString()).get("data").get("qrToken").asText();

        QrValidationRequest valReq = QrValidationRequest.builder()
                .sessionId(e2eOpenSession.getId())
                .qrToken(staticToken)
                .build();

        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + testStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(valReq)))
                .andExpect(status().isOk());

        // Số lượng attendance trong DB vẫn nguyên vẹn
        assertEquals(initialCount, studentAttendanceRepository.count());
    }
}
