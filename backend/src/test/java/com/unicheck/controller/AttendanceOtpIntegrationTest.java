package com.unicheck.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.model.dto.OtpValidationRequest;
import com.unicheck.model.dto.QrTokenResponse;
import com.unicheck.model.entity.*;
import com.unicheck.model.enums.*;
import com.unicheck.repository.*;
import com.unicheck.security.DynamicQrRedisService;
import com.unicheck.security.JwtUtil;
import com.unicheck.service.DynamicQrService;
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

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class AttendanceOtpIntegrationTest {

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
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private DynamicQrRedisService dynamicQrRedisService;

    @Autowired
    private DynamicQrService dynamicQrService;

    private String adminToken;
    private String lecturerToken;
    private String studentToken;
    private String nonEnrolledStudentToken;

    private User lecturer;
    private User student;
    private User nonEnrolledStudent;

    private ClassSection classSection;
    private TimetableSlot openSlot;
    private TimetableSlot closedSlot;
    private AttendanceSession openSession;
    private AttendanceSession closedSession;

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("DELETE FROM student_attendances");
        jdbcTemplate.execute("DELETE FROM attendance_sessions");
        jdbcTemplate.execute("DELETE FROM timetable_slots");
        jdbcTemplate.execute("DELETE FROM enrollments");

        User admin = userRepository.findByUsername("admin_otp_test").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("ADM-OTP-01")
                        .username("admin_otp_test")
                        .email("admin.otp@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Admin@123"))
                        .fullName("Quản trị viên OTP Test")
                        .role(Role.ADMIN)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        lecturer = userRepository.findByUsername("lecturer_otp_test").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("LEC-OTP-01")
                        .username("lecturer_otp_test")
                        .email("lecturer.otp@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Password@123"))
                        .fullName("TS. Nguyễn Văn Hùng")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        student = userRepository.findByUsername("student_otp_test").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("STU-OTP-01")
                        .username("student_otp_test")
                        .email("student.otp@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Password@123"))
                        .fullName("Trần Minh Quân")
                        .role(Role.STUDENT)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        nonEnrolledStudent = userRepository.findByUsername("student_otp_other").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("STU-OTP-02")
                        .username("student_otp_other")
                        .email("student.other@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Password@123"))
                        .fullName("Hoàng Kim Liên")
                        .role(Role.STUDENT)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        adminToken = jwtUtil.generateAccessToken(admin);
        lecturerToken = jwtUtil.generateAccessToken(lecturer);
        studentToken = jwtUtil.generateAccessToken(student);
        nonEnrolledStudentToken = jwtUtil.generateAccessToken(nonEnrolledStudent);

        Semester semester = semesterRepository.findByCode("2024.1").orElseGet(() ->
                semesterRepository.save(Semester.builder()
                        .code("2024.1")
                        .name("Học kỳ I 2024-2025")
                        .startDate(LocalDate.of(2024, 9, 1))
                        .endDate(LocalDate.of(2025, 1, 15))
                        .status(SemesterStatus.ACTIVE)
                        .build())
        );

        Course course = courseRepository.findByCode("PRJ301").orElseGet(() ->
                courseRepository.save(Course.builder()
                        .code("PRJ301")
                        .name("Java Web Application Development")
                        .credits(3)
                        .numberOfSlots(30)
                        .status(CourseStatus.ACTIVE)
                        .build())
        );

        Room room = roomRepository.findByCode("A2-304").orElseGet(() ->
                roomRepository.save(Room.builder()
                        .code("A2-304")
                        .name("Phòng thực hành A2-304")
                        .building("Tòa A2")
                        .capacity(60)
                        .status(RoomStatus.AVAILABLE)
                        .build())
        );

        SlotType slotType = slotTypeRepository.findAll().stream()
                .filter(st -> st.getSemester() != null && st.getSemester().getId().equals(semester.getId()) && st.getSlotIndex() == 1)
                .findFirst()
                .orElseGet(() -> slotTypeRepository.save(SlotType.builder()
                        .name("Ca 1 (Tiết 1-3)")
                        .slotIndex(1)
                        .startTime(LocalTime.of(0, 0))
                        .endTime(LocalTime.of(23, 59))
                        .duration("145m")
                        .semester(semester)
                        .build())
                );

        classSection = classSectionRepository.findByClassName("PRJ301-SE1801").orElseGet(() ->
                classSectionRepository.save(ClassSection.builder()
                        .className("PRJ301-SE1801")
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

        // Ghi danh student vào classSection
        enrollmentRepository.save(Enrollment.builder()
                .classSection(classSection)
                .student(student)
                .studentCode(student.getCode())
                .status(EnrollmentStatus.ENROLLED)
                .build());

        openSlot = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection)
                .room(room)
                .slotType(slotType)
                .date(LocalDate.now())
                .startTime(LocalTime.of(0, 0))
                .endTime(LocalTime.of(23, 59))
                .dayOfWeek(1)
                .slotNumber(1)
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        closedSlot = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection)
                .room(room)
                .slotType(slotType)
                .date(LocalDate.now().minusDays(1))
                .startTime(LocalTime.of(7, 0))
                .endTime(LocalTime.of(9, 25))
                .dayOfWeek(7)
                .slotNumber(1)
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        openSession = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(openSlot)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.OPEN)
                .openedAt(LocalDateTime.now().minusMinutes(10))
                .createdAt(LocalDateTime.now().minusMinutes(15))
                .qrRotationIntervalSeconds(15)
                .build());

        closedSession = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(closedSlot)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.CLOSED)
                .openedAt(LocalDateTime.now().minusHours(2))
                .closedAt(LocalDateTime.now().minusHours(1))
                .createdAt(LocalDateTime.now().minusHours(2))
                .qrRotationIntervalSeconds(15)
                .build());

        // Invalidate previous cache
        dynamicQrRedisService.invalidate(openSession.getId());
        dynamicQrRedisService.clearOtpFailure(student.getId());
        dynamicQrRedisService.clearOtpFailure(nonEnrolledStudent.getId());
    }

    // =========================================================================
    // 1. Giảng viên mở phiên lấy QR -> Nhận mã OTP 6 chữ số hợp lệ
    // =========================================================================
    @Test
    @DisplayName("1. Giảng viên mở phiên lấy QR -> Nhận mã OTP 6 chữ số định dạng đúng")
    void testLecturerGetsQrWithValidSixDigitOtp() throws Exception {
        MvcResult result = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.sessionId").value(openSession.getId()))
                .andExpect(jsonPath("$.data.qrToken").isString())
                .andExpect(jsonPath("$.data.otpCode").isString())
                .andExpect(jsonPath("$.data.otpCode", matchesPattern("^[0-9]{6}$")))
                .andReturn();

        String content = result.getResponse().getContentAsString();
        String otpCode = objectMapper.readTree(content).path("data").path("otpCode").asText();
        assertNotNull(otpCode);
        assertEquals(6, otpCode.length());
    }

    // =========================================================================
    // 2. Sinh viên đã ghi danh nhập mã OTP hợp lệ -> Xác thực thành công (200 OK)
    // =========================================================================
    @Test
    @DisplayName("2. Sinh viên đã ghi danh nhập mã OTP hợp lệ -> Xác thực thành công kèm thông tin lớp và token")
    void testEnrolledStudentValidatesOtpSuccessfully() throws Exception {
        // Lecturer generates QR & OTP
        MvcResult qrResult = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();

        String activeOtp = objectMapper.readTree(qrResult.getResponse().getContentAsString())
                .path("data").path("otpCode").asText();

        // Student submits OTP
        OtpValidationRequest request = OtpValidationRequest.builder()
                .otpCode(activeOtp)
                .sessionId(openSession.getId())
                .build();

        mockMvc.perform(post("/api/v1/attendance/otp/validate")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.valid").value(true))
                .andExpect(jsonPath("$.data.sessionId").value(openSession.getId()))
                .andExpect(jsonPath("$.data.className").value("PRJ301-SE1801"))
                .andExpect(jsonPath("$.data.courseCode").value("PRJ301"))
                .andExpect(jsonPath("$.data.qrToken").isString())
                .andExpect(jsonPath("$.data.verificationMethod").value("OTP"));
    }

    // =========================================================================
    // 3. Sinh viên nhập sai mã OTP -> Bị từ chối (400 Bad Request)
    // =========================================================================
    @Test
    @DisplayName("3. Sinh viên nhập sai mã OTP -> Bị từ chối kèm thông báo rõ ràng")
    void testStudentSubmitsInvalidOtpRejected() throws Exception {
        // Make sure session has active OTP
        mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk());

        OtpValidationRequest request = OtpValidationRequest.builder()
                .otpCode("999999")
                .sessionId(openSession.getId())
                .build();

        mockMvc.perform(post("/api/v1/attendance/otp/validate")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message", containsString("không chính xác")));
    }

    // =========================================================================
    // 4. Mã OTP định dạng sai (không đủ 6 chữ số) -> Bị từ chối validate
    // =========================================================================
    @Test
    @DisplayName("4. Mã OTP định dạng không đủ 6 chữ số -> Bị từ chối")
    void testMalformedOtpRejected() throws Exception {
        OtpValidationRequest request = OtpValidationRequest.builder()
                .otpCode("123")
                .sessionId(openSession.getId())
                .build();

        mockMvc.perform(post("/api/v1/attendance/otp/validate")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    // =========================================================================
    // 5. Sinh viên chưa ghi danh vào lớp nhập OTP -> Bị từ chối (403 Forbidden)
    // =========================================================================
    @Test
    @DisplayName("5. Sinh viên chưa ghi danh vào lớp nhập OTP -> 403 Forbidden")
    void testNonEnrolledStudentRejected() throws Exception {
        MvcResult qrResult = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();

        String activeOtp = objectMapper.readTree(qrResult.getResponse().getContentAsString())
                .path("data").path("otpCode").asText();

        OtpValidationRequest request = OtpValidationRequest.builder()
                .otpCode(activeOtp)
                .sessionId(openSession.getId())
                .build();

        mockMvc.perform(post("/api/v1/attendance/otp/validate")
                        .header("Authorization", "Bearer " + nonEnrolledStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message", containsString("ghi danh")));
    }

    // =========================================================================
    // 6. Chống tấn công Brute-force: Nhập sai 5 lần -> Lần 6 bị Rate Limited (429)
    // =========================================================================
    @Test
    @DisplayName("6. Chống Brute-force: Nhập sai 5 lần -> Bị khóa rate limit (429 Too Many Requests)")
    void testAntiBruteForceRateLimiting() throws Exception {
        // Ensure active QR exists
        mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk());

        OtpValidationRequest wrongReq = OtpValidationRequest.builder()
                .otpCode("888888")
                .sessionId(openSession.getId())
                .build();

        // 5 failed attempts
        for (int i = 0; i < 5; i++) {
            mockMvc.perform(post("/api/v1/attendance/otp/validate")
                            .header("Authorization", "Bearer " + studentToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(wrongReq)))
                    .andExpect(status().isBadRequest());
        }

        // 6th attempt -> 429 Too Many Requests
        mockMvc.perform(post("/api/v1/attendance/otp/validate")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(wrongReq)))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.message", containsString("quá 5 lần")));
    }

    // =========================================================================
    // 7. Phiên đã đóng (CLOSED) -> Không thể xác thực OTP
    // =========================================================================
    @Test
    @DisplayName("7. Phiên điểm danh đã đóng (CLOSED) -> Từ chối xác thực OTP")
    void testClosedSessionRejectsOtp() throws Exception {
        OtpValidationRequest request = OtpValidationRequest.builder()
                .otpCode("123456")
                .sessionId(closedSession.getId())
                .build();

        mockMvc.perform(post("/api/v1/attendance/otp/validate")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("không ở trạng thái mở")));
    }

    // =========================================================================
    // 8. Sinh viên đã điểm danh thành công -> Không thể điểm danh trùng bằng OTP
    // =========================================================================
    @Test
    @DisplayName("8. Sinh viên đã điểm danh PRESENT -> Không thể điểm danh lại bằng OTP")
    void testDuplicateAttendancePrevented() throws Exception {
        // Mark student as PRESENT
        studentAttendanceRepository.save(StudentAttendance.builder()
                .session(openSession)
                .student(student)
                .status("PRESENT")
                .method("FACE_OTP")
                .checkInTime(LocalDateTime.now().minusMinutes(5))
                .build());

        MvcResult qrResult = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();

        String activeOtp = objectMapper.readTree(qrResult.getResponse().getContentAsString())
                .path("data").path("otpCode").asText();

        OtpValidationRequest request = OtpValidationRequest.builder()
                .otpCode(activeOtp)
                .sessionId(openSession.getId())
                .build();

        mockMvc.perform(post("/api/v1/attendance/otp/validate")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message", containsString("đã điểm danh thành công")));
    }

    // =========================================================================
    // 9. Đồng bộ vòng đời: OTP thay đổi đồng bộ theo chu kỳ xoay vòng QR
    // =========================================================================
    @Test
    @DisplayName("9. OTP và QR cùng tồn tại và xoay vòng theo chu kỳ")
    void testOtpRotationLifecycle() throws Exception {
        MvcResult firstCall = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();

        String firstOtp = objectMapper.readTree(firstCall.getResponse().getContentAsString())
                .path("data").path("otpCode").asText();
        String firstToken = objectMapper.readTree(firstCall.getResponse().getContentAsString())
                .path("data").path("qrToken").asText();

        // Immediate subsequent call within rotation window returns identical OTP and QR
        MvcResult secondCall = mockMvc.perform(get("/api/v1/attendance/sessions/{sessionId}/qr", openSession.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();

        String secondOtp = objectMapper.readTree(secondCall.getResponse().getContentAsString())
                .path("data").path("otpCode").asText();
        String secondToken = objectMapper.readTree(secondCall.getResponse().getContentAsString())
                .path("data").path("qrToken").asText();

        assertEquals(firstOtp, secondOtp, "Trong cùng chu kỳ xoay vòng, mã OTP phải giữ nguyên");
        assertEquals(firstToken, secondToken, "Trong cùng chu kỳ xoay vòng, QR token phải giữ nguyên");
    }
}
