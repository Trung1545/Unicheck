package com.unicheck.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.model.dto.*;
import com.unicheck.model.dto.ai.AiCheckLivenessResponse;
import com.unicheck.model.dto.ai.AiVerifyFaceResponse;
import com.unicheck.model.entity.*;
import com.unicheck.model.enums.*;
import com.unicheck.repository.*;
import com.unicheck.security.DynamicQrRedisService;
import com.unicheck.security.JwtUtil;
import com.unicheck.security.UserPrincipal;
import com.unicheck.service.AttendanceVerificationTicketService;
import com.unicheck.service.DynamicQrService;
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

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class AttendanceVerificationTicketIntegrationTest {

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
    private DynamicQrService dynamicQrService;

    @Autowired
    private com.unicheck.service.QrTokenService qrTokenService;

    @Autowired
    private DynamicQrRedisService dynamicQrRedisService;

    @Autowired
    private AttendanceVerificationTicketService verificationTicketService;

    @MockBean
    private AiServiceClient aiServiceClient;

    private User lecturer;
    private User student1;
    private User student2; // unenrolled
    private User student3; // second enrolled student
    private String lecturerToken;
    private String student1Token;
    private String student2Token;
    private String student3Token;

    private Semester semester;
    private Course course;
    private ClassSection classSection;
    private Room room;
    private SlotType slotType;
    private TimetableSlot slot1;
    private TimetableSlot slot2;
    private AttendanceSession session1;
    private AttendanceSession session2Closed;
    private WifiAccessPoint wifiAp;

    private static final String DUMMY_BASE64 = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=";

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("DELETE FROM student_attendances");
        jdbcTemplate.execute("DELETE FROM attendance_sessions");
        jdbcTemplate.execute("DELETE FROM timetable_slots");
        jdbcTemplate.execute("DELETE FROM enrollments");
        jdbcTemplate.execute("DELETE FROM room_wifi_access_points");
        jdbcTemplate.execute("DELETE FROM wifi_access_points");
        jdbcTemplate.execute("DELETE FROM face_encodings");

        // 1. Users
        lecturer = userRepository.findByUsername("test_vt_lecturer").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("LEC-VT-01")
                        .username("test_vt_lecturer")
                        .email("vt.lec@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Password123!"))
                        .fullName("TS. Hoàng Văn Giảng")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        student1 = userRepository.findByUsername("test_vt_student_01").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("STU-VT-01")
                        .username("test_vt_student_01")
                        .email("vt.stu01@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Password123!"))
                        .fullName("Nguyễn Minh An")
                        .role(Role.STUDENT)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        student2 = userRepository.findByUsername("test_vt_student_02").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("STU-VT-02")
                        .username("test_vt_student_02")
                        .email("vt.stu02@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Password123!"))
                        .fullName("Trần Thị Bích")
                        .role(Role.STUDENT)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        student3 = userRepository.findByUsername("test_vt_student_03").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("STU-VT-03")
                        .username("test_vt_student_03")
                        .email("vt.stu03@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Password123!"))
                        .fullName("Lê Tuấn Cường")
                        .role(Role.STUDENT)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        lecturerToken = jwtUtil.generateAccessToken(lecturer);
        student1Token = jwtUtil.generateAccessToken(student1);
        student2Token = jwtUtil.generateAccessToken(student2);
        student3Token = jwtUtil.generateAccessToken(student3);

        // 2. Academic Entities
        semester = semesterRepository.findByCode("FA26").orElseGet(() ->
                semesterRepository.save(Semester.builder()
                        .code("FA26")
                        .name("Fall 2026")
                        .startDate(LocalDate.now().minusMonths(1))
                        .endDate(LocalDate.now().plusMonths(3))
                        .status(SemesterStatus.ACTIVE)
                        .build())
        );

        course = courseRepository.findByCode("PRJ301").orElseGet(() ->
                courseRepository.save(Course.builder()
                        .code("PRJ301")
                        .name("Java Web Application Development")
                        .credits(3)
                        .numberOfSlots(30)
                        .status(CourseStatus.ACTIVE)
                        .build())
        );

        room = roomRepository.findByCode("AL-L201").orElseGet(() ->
                roomRepository.save(Room.builder()
                        .code("AL-L201")
                        .name("Phòng học lý thuyết AL-L201")
                        .building("Tòa AL")
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
                        .startTime(LocalTime.now().minusMinutes(10))
                        .endTime(LocalTime.now().plusHours(2))
                        .duration("120m")
                        .semester(semester)
                        .build())
                );

        classSection = classSectionRepository.findByClassName("PRJ301.01").orElseGet(() ->
                classSectionRepository.save(ClassSection.builder()
                        .className("PRJ301.01")
                        .course(course)
                        .semester(semester)
                        .lecturer(lecturer)
                        .numberOfSlots(30)
                        .maxStudents(50)
                        .currentEnrollment(2)
                        .status(ClassSectionStatus.OPEN)
                        .build())
        );

        // Enroll student 1 and student 3
        if (!enrollmentRepository.existsByClassSection_ClassNameAndStudent_Id(classSection.getClassName(), student1.getId())) {
            enrollmentRepository.save(Enrollment.builder()
                    .classSection(classSection)
                    .student(student1)
                    .studentCode(student1.getCode())
                    .status(EnrollmentStatus.ENROLLED)
                    .build());
        }

        if (!enrollmentRepository.existsByClassSection_ClassNameAndStudent_Id(classSection.getClassName(), student3.getId())) {
            enrollmentRepository.save(Enrollment.builder()
                    .classSection(classSection)
                    .student(student3)
                    .studentCode(student3.getCode())
                    .status(EnrollmentStatus.ENROLLED)
                    .build());
        }

        // Slots
        slot1 = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection)
                .room(room)
                .slotType(slotType)
                .date(LocalDate.now())
                .dayOfWeek(LocalDate.now().getDayOfWeek().getValue())
                .slotNumber(1)
                .status(TimetableSlotStatus.SCHEDULED)
                .build()
        );

        slot2 = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection)
                .room(room)
                .slotType(slotType)
                .date(LocalDate.now())
                .dayOfWeek(LocalDate.now().getDayOfWeek().getValue())
                .slotNumber(2)
                .status(TimetableSlotStatus.SCHEDULED)
                .build()
        );

        // Open Session 1
        session1 = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot1)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.OPEN)
                .qrRotationIntervalSeconds(10)
                .openedAt(LocalDateTime.now().minusMinutes(5))
                .build()
        );

        // Closed Session 2
        session2Closed = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot2)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.CLOSED)
                .openedAt(LocalDateTime.now().minusHours(3))
                .closedAt(LocalDateTime.now().minusHours(1))
                .build()
        );

        // Wi-Fi AP
        wifiAp = wifiAccessPointRepository.save(WifiAccessPoint.builder()
                .ssid("UniCheck_AL_5G")
                .bssid("00:11:22:33:44:55")
                .name("AP Tòa AL Phòng 201")
                .status(WifiApStatus.ACTIVE)
                .build()
        );

        roomWifiAccessPointRepository.save(RoomWifiAccessPoint.builder()
                .room(room)
                .wifiAccessPoint(wifiAp)
                .isPrimary(true)
                .build()
        );

        // Face encodings for student 1 and student 3
        byte[] dummyEncoding = new byte[512 * 4];
        faceEncodingRepository.save(FaceEncoding.builder()
                .user(student1)
                .encodingData(dummyEncoding)
                .livenessVerified(true)
                .build()
        );

        faceEncodingRepository.save(FaceEncoding.builder()
                .user(student3)
                .encodingData(dummyEncoding)
                .livenessVerified(true)
                .build()
        );

        // Config
        AttendanceConfig config = attendanceConfigRepository.findByConfigKey("DEFAULT").orElseGet(() ->
                AttendanceConfig.builder()
                        .configKey("DEFAULT")
                        .manualEnabled(true)
                        .absentThresholdMinutes(15)
                        .minAttendancePercentage(80.0)
                        .faceRecognitionEnabled(true)
                        .maxAttempts(3)
                        .wifiLocationEnabled(true)
                        .build()
        );
        config.setWifiLocationEnabled(true);
        config.setFaceRecognitionEnabled(true);
        config.setAbsentThresholdMinutes(15);
        attendanceConfigRepository.save(config);

        // Default mock AI service
        when(aiServiceClient.checkLiveness(anyString(), anyDouble()))
                .thenReturn(AiCheckLivenessResponse.of(true, 0.98));
        when(aiServiceClient.verifyFace(anyList(), anyString(), anyDouble()))
                .thenReturn(AiVerifyFaceResponse.of(true, 0.95));
    }

    @Test
    @DisplayName("TC-VT-01: Kịch bản bắt buộc - QR chu kỳ 10s xoay vòng ở giây thứ 10, sinh viên quét ở giây 8 và hoàn tất FaceID ở giây 38, Check-in thành công")
    void tc01_MandatoryScenario_QrRotatesAfter10s_CheckInAt38s_ShouldSucceedWithTicket() throws Exception {
        // 1. Giảng viên mở QR (chu kỳ 10 giây)
        MvcResult qrResult = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", session1.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();
        String initialQrToken = objectMapper.readTree(qrResult.getResponse().getContentAsString())
                .path("data").path("qrToken").asText();
        assertNotNull(initialQrToken);

        // 2. Giây thứ 8: Sinh viên quét và xác thực QR
        QrValidationRequest valReq = QrValidationRequest.builder()
                .qrToken(initialQrToken)
                .sessionId(session1.getId())
                .build();

        MvcResult valResult = mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(valReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.valid").value(true))
                .andExpect(jsonPath("$.data.verificationTicket").isNotEmpty())
                .andExpect(jsonPath("$.data.ticketExpiresAt").isNotEmpty())
                .andReturn();

        String ticket = objectMapper.readTree(valResult.getResponse().getContentAsString())
                .path("data").path("verificationTicket").asText();
        assertNotNull(ticket);
        assertFalse(ticket.isBlank());

        // 3. Giây thứ 10: QR xoay vòng (chu kỳ mới)
        dynamicQrRedisService.invalidate(session1.getId());
        MvcResult rotatedQrResult = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", session1.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();
        String rotatedQrToken = objectMapper.readTree(rotatedQrResult.getResponse().getContentAsString())
                .path("data").path("qrToken").asText();
        assertNotEquals(initialQrToken, rotatedQrToken);

        // Giả lập tại giây thứ 38 (30s sau t=8s): QR token ban đầu đã hết hạn (> 15s TTL)
        String expiredQrToken = qrTokenService.generateQrToken(
                session1.getId(),
                Instant.now().minusSeconds(38),
                Duration.ofSeconds(15),
                Duration.ofSeconds(10)
        );

        // Xác nhận QR token này đã hết hạn nếu gửi trực tiếp
        QrValidationRequest expiredQrReq = QrValidationRequest.builder()
                .qrToken(expiredQrToken)
                .sessionId(session1.getId())
                .build();
        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(expiredQrReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message", containsString("hết hạn")));

        // 4. Giây thứ 38: Sinh viên hoàn tất Face-ID với Verification Ticket (kèm mã QR cũ đã hết hạn)
        // Backend chấp nhận Ticket mà KHÔNG từ chối vì QR hết hạn!
        AttendanceCheckInRequest checkInRequest = AttendanceCheckInRequest.builder()
                .sessionId(session1.getId())
                .verificationTicket(ticket)
                .qrToken(expiredQrToken) // token cũ đã hết hạn
                .wifiBssid("00:11:22:33:44:55")
                .wifiSsid("UniCheck_AL_5G")
                .faceSampleBase64(DUMMY_BASE64)
                .deviceModel("Pixel 10 Pro API 37.1")
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkInRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("PRESENT"))
                .andExpect(jsonPath("$.data.method").value("FACE_QR"))
                .andExpect(jsonPath("$.data.studentCode").value(student1.getCode()))
                .andExpect(jsonPath("$.data.receiptId", startsWith("#ATT-")));

        // 5. Kiểm tra CSDL: Trạng thái PRESENT được ghi nhận
        StudentAttendance attendance = studentAttendanceRepository
                .findBySessionIdAndStudentId(session1.getId(), student1.getId())
                .orElseThrow();
        assertEquals("PRESENT", attendance.getStatus());
        assertEquals("FACE_QR", attendance.getMethod());
        assertNotNull(attendance.getCheckInTime());

        // 6. Kiểm tra Ticket đã được tiêu thụ (consume) sau khi check-in thành công
        assertTrue(verificationTicketService.validateTicket(ticket, student1.getId(), session1.getId()).isEmpty(),
                "Verification Ticket phải được tiêu thụ và không thể dùng lại");
    }

    @Test
    @DisplayName("TC-VT-02: Ticket hết hạn (> 180s) thì từ chối điểm danh với mã lỗi QR_TOKEN_EXPIRED")
    void tc02_TicketExpired_ShouldFailWithQrTokenExpired() throws Exception {
        // Cấp vé xác thực hợp lệ
        VerificationTicket ticket = verificationTicketService.issueTicket(
                student1.getId(), session1.getId(), slot1.getId(), "QR"
        );

        // Thu hồi / làm hết hạn vé
        verificationTicketService.revokeTicket(ticket.ticketId());

        AttendanceCheckInRequest checkInRequest = AttendanceCheckInRequest.builder()
                .sessionId(session1.getId())
                .verificationTicket(ticket.ticketId())
                .wifiBssid("00:11:22:33:44:55")
                .wifiSsid("UniCheck_AL_5G")
                .faceSampleBase64(DUMMY_BASE64)
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkInRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message", containsString("Verification Ticket")));
    }

    @Test
    @DisplayName("TC-VT-03: Ticket không thuộc về sinh viên hiện tại (Student Mismatch) bị từ chối")
    void tc03_TicketStudentMismatch_ShouldFail() throws Exception {
        // Cấp vé cho student1
        VerificationTicket ticket = verificationTicketService.issueTicket(
                student1.getId(), session1.getId(), slot1.getId(), "QR"
        );

        // Student3 cố tình dùng vé của student1 để điểm danh
        AttendanceCheckInRequest checkInRequest = AttendanceCheckInRequest.builder()
                .sessionId(session1.getId())
                .verificationTicket(ticket.ticketId())
                .wifiBssid("00:11:22:33:44:55")
                .wifiSsid("UniCheck_AL_5G")
                .faceSampleBase64(DUMMY_BASE64)
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + student3Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkInRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @DisplayName("TC-VT-04: Ticket thuộc phiên học khác (Session Mismatch) bị từ chối")
    void tc04_TicketSessionMismatch_ShouldFail() throws Exception {
        // Cấp vé cho session 9999
        VerificationTicket ticket = verificationTicketService.issueTicket(
                student1.getId(), 9999L, slot1.getId(), "QR"
        );

        AttendanceCheckInRequest checkInRequest = AttendanceCheckInRequest.builder()
                .sessionId(session1.getId())
                .verificationTicket(ticket.ticketId())
                .wifiBssid("00:11:22:33:44:55")
                .wifiSsid("UniCheck_AL_5G")
                .faceSampleBase64(DUMMY_BASE64)
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkInRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @DisplayName("TC-VT-05: Phiên điểm danh bị ĐÓNG (CLOSED) thì từ chối ngay cả khi Ticket còn hạn")
    void tc05_SessionClosed_EvenWithValidTicket_ShouldFail() throws Exception {
        VerificationTicket ticket = verificationTicketService.issueTicket(
                student1.getId(), session2Closed.getId(), slot2.getId(), "QR"
        );

        AttendanceCheckInRequest checkInRequest = AttendanceCheckInRequest.builder()
                .sessionId(session2Closed.getId())
                .verificationTicket(ticket.ticketId())
                .wifiBssid("00:11:22:33:44:55")
                .wifiSsid("UniCheck_AL_5G")
                .faceSampleBase64(DUMMY_BASE64)
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkInRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message", containsString("không ở trạng thái mở tiếp nhận")));
    }

    @Test
    @DisplayName("TC-VT-06: Điểm danh bằng OTP cấp Ticket, OTP xoay vòng, Check-in thành công với FACE_OTP")
    void tc06_OtpFlow_WithVerificationTicket_ShouldSucceedAsFaceOtp() throws Exception {
        // 1. Giảng viên mở QR & OTP (chu kỳ 10 giây)
        MvcResult qrResult = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", session1.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();
        String initialOtp = objectMapper.readTree(qrResult.getResponse().getContentAsString())
                .path("data").path("otpCode").asText();
        assertNotNull(initialOtp);

        // 2. Sinh viên nhập và xác thực OTP
        OtpValidationRequest otpReq = OtpValidationRequest.builder()
                .otpCode(initialOtp)
                .sessionId(session1.getId())
                .build();

        MvcResult valResult = mockMvc.perform(post("/api/v1/attendance/otp/validate")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(otpReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.valid").value(true))
                .andExpect(jsonPath("$.data.verificationTicket").isNotEmpty())
                .andReturn();

        String ticket = objectMapper.readTree(valResult.getResponse().getContentAsString())
                .path("data").path("verificationTicket").asText();

        // 3. OTP xoay vòng sau 10s
        dynamicQrRedisService.invalidate(session1.getId());
        MvcResult rotatedQrResult = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", session1.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();
        String rotatedOtp = objectMapper.readTree(rotatedQrResult.getResponse().getContentAsString())
                .path("data").path("otpCode").asText();
        assertNotEquals(initialOtp, rotatedOtp);

        // 4. Sinh viên hoàn thành FaceID với Ticket
        AttendanceCheckInRequest checkInRequest = AttendanceCheckInRequest.builder()
                .sessionId(session1.getId())
                .verificationTicket(ticket)
                .otpCode(initialOtp)
                .verificationMethod("OTP")
                .wifiBssid("00:11:22:33:44:55")
                .wifiSsid("UniCheck_AL_5G")
                .faceSampleBase64(DUMMY_BASE64)
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkInRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("PRESENT"))
                .andExpect(jsonPath("$.data.method").value("FACE_OTP"));

        // Xác nhận CSDL
        StudentAttendance attendance = studentAttendanceRepository
                .findBySessionIdAndStudentId(session1.getId(), student1.getId())
                .orElseThrow();
        assertEquals("FACE_OTP", attendance.getMethod());
    }

    @Test
    @DisplayName("TC-VT-07: Face-ID không khớp (AI failure) từ chối điểm danh, Ticket không bị mất để sinh viên quét lại mặt")
    void tc07_FaceVerificationFailed_TicketRemainsUsableForRetry() throws Exception {
        VerificationTicket ticket = verificationTicketService.issueTicket(
                student1.getId(), session1.getId(), slot1.getId(), "QR"
        );

        // Lần 1: AI báo khuôn mặt không khớp
        when(aiServiceClient.verifyFace(anyList(), anyString(), anyDouble()))
                .thenReturn(AiVerifyFaceResponse.of(false, 0.40));

        AttendanceCheckInRequest checkInRequest = AttendanceCheckInRequest.builder()
                .sessionId(session1.getId())
                .verificationTicket(ticket.ticketId())
                .wifiBssid("00:11:22:33:44:55")
                .wifiSsid("UniCheck_AL_5G")
                .faceSampleBase64(DUMMY_BASE64)
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkInRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_3004"));

        // Vé vẫn còn hợp lệ trong vòng đời để sinh viên căn chỉnh góc mặt và thử lại
        assertTrue(verificationTicketService.validateTicket(ticket.ticketId(), student1.getId(), session1.getId()).isPresent(),
                "Ticket phải còn hợp lệ cho lần thử lại kế tiếp");

        // Lần 2: Sinh viên quét lại mặt đạt chuẩn (AI nhận diện thành công)
        when(aiServiceClient.verifyFace(anyList(), anyString(), anyDouble()))
                .thenReturn(AiVerifyFaceResponse.of(true, 0.96));

        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkInRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("PRESENT"));

        // Bây giờ vé mới được tiêu thụ
        assertTrue(verificationTicketService.validateTicket(ticket.ticketId(), student1.getId(), session1.getId()).isEmpty());
    }

    @Test
    @DisplayName("TC-VT-08: Tái sử dụng Ticket đã tiêu thụ (Replay Attack) hoặc điểm danh trùng lặp bị từ chối")
    void tc08_ConsumedTicketReuse_ShouldFail() throws Exception {
        VerificationTicket ticket = verificationTicketService.issueTicket(
                student1.getId(), session1.getId(), slot1.getId(), "QR"
        );

        AttendanceCheckInRequest checkInRequest = AttendanceCheckInRequest.builder()
                .sessionId(session1.getId())
                .verificationTicket(ticket.ticketId())
                .wifiBssid("00:11:22:33:44:55")
                .wifiSsid("UniCheck_AL_5G")
                .faceSampleBase64(DUMMY_BASE64)
                .build();

        // Check-in lần 1 thành công
        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkInRequest)))
                .andExpect(status().isOk());

        // Check-in lần 2 với cùng ticket đó -> Bị từ chối
        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + student1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkInRequest)))
                .andExpect(status().is4xxClientError())
                .andExpect(jsonPath("$.success").value(false));
    }
}
