package com.unicheck.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.exception.AppException;
import com.unicheck.exception.ErrorCode;
import com.unicheck.model.dto.AttendanceCheckInRequest;
import com.unicheck.model.dto.ai.AiCheckLivenessResponse;
import com.unicheck.model.dto.ai.AiVerifyFaceResponse;
import com.unicheck.model.entity.*;
import com.unicheck.model.enums.*;
import com.unicheck.repository.*;
import com.unicheck.security.JwtUtil;
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

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class AttendanceCheckInIntegrationTest {

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

    @MockBean
    private AiServiceClient aiServiceClient;

    private User enrolledStudent;
    private User unenrolledStudent;
    private User lecturer;
    private String enrolledStudentToken;
    private String unenrolledStudentToken;
    private String lecturerToken;

    private Semester semester;
    private Course course;
    private ClassSection classSection;
    private Room room;
    private SlotType slotType;
    private TimetableSlot slot;
    private AttendanceSession openSession;
    private AttendanceSession closedSession;
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
        enrolledStudent = userRepository.findByUsername("test_checkin_student_01").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("STU-CK-01")
                        .username("test_checkin_student_01")
                        .email("checkin.stu01@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Password123!"))
                        .fullName("Nguyễn Văn An")
                        .role(Role.STUDENT)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        unenrolledStudent = userRepository.findByUsername("test_checkin_student_02").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("STU-CK-02")
                        .username("test_checkin_student_02")
                        .email("checkin.stu02@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Password123!"))
                        .fullName("Trần Thị Bích")
                        .role(Role.STUDENT)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        lecturer = userRepository.findByUsername("test_checkin_lecturer").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("LEC-CK-01")
                        .username("test_checkin_lecturer")
                        .email("checkin.lec@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Password123!"))
                        .fullName("TS. Lê Hoàng Nam")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        enrolledStudentToken = jwtUtil.generateAccessToken(enrolledStudent);
        unenrolledStudentToken = jwtUtil.generateAccessToken(unenrolledStudent);
        lecturerToken = jwtUtil.generateAccessToken(lecturer);

        // 2. Academic Catalog
        semester = semesterRepository.findByCode("2024.1").orElseGet(() ->
                semesterRepository.save(Semester.builder()
                        .code("2024.1")
                        .name("Học kỳ I 2024-2025")
                        .startDate(LocalDate.now().minusMonths(1))
                        .endDate(LocalDate.now().plusMonths(3))
                        .status(SemesterStatus.ACTIVE)
                        .build())
        );

        course = courseRepository.findByCode("CS202").orElseGet(() ->
                courseRepository.save(Course.builder()
                        .code("CS202")
                        .name("Cấu trúc dữ liệu và giải thuật")
                        .credits(4)
                        .numberOfSlots(60)
                        .status(CourseStatus.ACTIVE)
                        .build())
        );

        room = roomRepository.findByCode("B1-202").orElseGet(() ->
                roomRepository.save(Room.builder()
                        .code("B1-202")
                        .name("Phòng học lý thuyết B1-202")
                        .building("Tòa B1")
                        .capacity(80)
                        .status(RoomStatus.AVAILABLE)
                        .build())
        );

        slotType = slotTypeRepository.findAll().stream()
                .filter(st -> st.getSemester() != null && st.getSemester().getId().equals(semester.getId()) && st.getSlotIndex() == 1)
                .findFirst()
                .orElseGet(() -> slotTypeRepository.save(SlotType.builder()
                        .name("Ca 1 (Tiết 1-3)")
                        .slotIndex(1)
                        .startTime(LocalTime.now().minusMinutes(5)) // On-time session
                        .endTime(LocalTime.now().plusHours(2))
                        .duration("120m")
                        .semester(semester)
                        .build())
                );

        classSection = classSectionRepository.findByClassName("CS202.01").orElseGet(() ->
                classSectionRepository.save(ClassSection.builder()
                        .className("CS202.01")
                        .course(course)
                        .semester(semester)
                        .lecturer(lecturer)
                        .numberOfSlots(15)
                        .maxStudents(60)
                        .currentEnrollment(1)
                        .status(ClassSectionStatus.OPEN)
                        .build())
        );

        // 3. Enrollment for enrolledStudent
        if (!enrollmentRepository.existsByClassSection_ClassNameAndStudent_Id(classSection.getClassName(), enrolledStudent.getId())) {
            enrollmentRepository.save(Enrollment.builder()
                    .classSection(classSection)
                    .student(enrolledStudent)
                    .studentCode(enrolledStudent.getCode())
                    .status(EnrollmentStatus.ENROLLED)
                    .build());
        }

        // 4. Timetable Slots
        slot = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection)
                .room(room)
                .slotType(slotType)
                .date(LocalDate.now())
                .dayOfWeek(LocalDate.now().getDayOfWeek().getValue())
                .slotNumber(1)
                .status(TimetableSlotStatus.SCHEDULED)
                .build()
        );

        // 5. Open Session
        openSession = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.OPEN)
                .openedAt(LocalDateTime.now().minusMinutes(10))
                .build()
        );

        // 6. Wi-Fi Access Point for Room
        wifiAp = wifiAccessPointRepository.save(WifiAccessPoint.builder()
                .ssid("UniCheck_Classroom_5G")
                .bssid("00:11:22:33:44:55")
                .name("AP Tòa B1 Phòng 202")
                .status(WifiApStatus.ACTIVE)
                .build()
        );

        roomWifiAccessPointRepository.save(RoomWifiAccessPoint.builder()
                .room(room)
                .wifiAccessPoint(wifiAp)
                .isPrimary(true)
                .build()
        );

        // 7. Registered Face-ID for enrolled student (512-dim embedding dummy bytes)
        byte[] dummyEncoding = new byte[512 * 4];
        faceEncodingRepository.save(FaceEncoding.builder()
                .user(enrolledStudent)
                .encodingData(dummyEncoding)
                .livenessVerified(true)
                .build()
        );

        // 8. Attendance Configuration
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
        config.setMaxAttempts(3);
        config.setAbsentThresholdMinutes(15);
        attendanceConfigRepository.save(config);
    }

    @Test
    @DisplayName("TC-CK-01: Điểm danh thành công khi đủ điều kiện (PRESENT, mã biên nhận, ghi vào DB)")
    void checkIn_whenValid_shouldPersistAndReturn200() throws Exception {
        // Mock AI Service responses
        when(aiServiceClient.checkLiveness(anyString(), anyDouble()))
                .thenReturn(AiCheckLivenessResponse.of(true, 0.96));
        when(aiServiceClient.verifyFace(anyList(), anyString(), anyDouble()))
                .thenReturn(AiVerifyFaceResponse.of(true, 0.92));

        AttendanceCheckInRequest request = AttendanceCheckInRequest.builder()
                .sessionId(openSession.getId())
                .wifiBssid("00:11:22:33:44:55")
                .wifiSsid("UniCheck_Classroom_5G")
                .faceSampleBase64(DUMMY_BASE64)
                .deviceModel("Pixel 8 Pro")
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in")
                        .header("Authorization", "Bearer " + enrolledStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("PRESENT"))
                .andExpect(jsonPath("$.data.method").value("FACE_QR"))
                .andExpect(jsonPath("$.data.studentCode").value(enrolledStudent.getCode()))
                .andExpect(jsonPath("$.data.receiptId", startsWith("#ATT-")))
                .andExpect(jsonPath("$.data.courseCode").value("CS202"))
                .andExpect(jsonPath("$.data.className").value("CS202.01"));

        // Xác thực trong CSDL
        assertTrue(studentAttendanceRepository.existsBySessionIdAndStudentId(openSession.getId(), enrolledStudent.getId()));
        StudentAttendance att = studentAttendanceRepository.findBySessionIdAndStudentId(openSession.getId(), enrolledStudent.getId()).orElseThrow();
        assertEquals("PRESENT", att.getStatus());
        assertEquals("FACE_QR", att.getMethod());
        assertEquals("00:11:22:33:44:55", att.getWifiBssid());
        assertNotNull(att.getCheckInTime());
    }

    @Test
    @DisplayName("TC-CK-02: Điểm danh qua route alias Mobile /attendance/check-in-face thành công")
    void checkIn_viaMobileRouteAlias_shouldReturn200() throws Exception {
        when(aiServiceClient.checkLiveness(anyString(), anyDouble()))
                .thenReturn(AiCheckLivenessResponse.of(true, 0.95));
        when(aiServiceClient.verifyFace(anyList(), anyString(), anyDouble()))
                .thenReturn(AiVerifyFaceResponse.of(true, 0.89));

        AttendanceCheckInRequest request = AttendanceCheckInRequest.builder()
                .sessionId(openSession.getId())
                .wifiBssid("00:11:22:33:44:55")
                .faceSampleBase64(DUMMY_BASE64)
                .build();

        mockMvc.perform(post("/api/attendance/check-in-face")
                        .header("Authorization", "Bearer " + enrolledStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("PRESENT"));
    }

    @Test
    @DisplayName("TC-CK-03: Chống điểm danh trùng lặp (Idempotency) -> Trả về 409 CONFLICT ERR_3007")
    void checkIn_whenDuplicate_shouldReturn409() throws Exception {
        when(aiServiceClient.checkLiveness(anyString(), anyDouble()))
                .thenReturn(AiCheckLivenessResponse.of(true, 0.96));
        when(aiServiceClient.verifyFace(anyList(), anyString(), anyDouble()))
                .thenReturn(AiVerifyFaceResponse.of(true, 0.92));

        AttendanceCheckInRequest request = AttendanceCheckInRequest.builder()
                .sessionId(openSession.getId())
                .wifiBssid("00:11:22:33:44:55")
                .faceSampleBase64(DUMMY_BASE64)
                .build();

        // Lần 1: Thành công
        mockMvc.perform(post("/api/v1/attendance/check-in")
                        .header("Authorization", "Bearer " + enrolledStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk());

        // Lần 2: Báo lỗi đã điểm danh
        mockMvc.perform(post("/api/v1/attendance/check-in")
                        .header("Authorization", "Bearer " + enrolledStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.errorCode").value("ERR_3007"));
    }

    @Test
    @DisplayName("TC-CK-04: Từ chối khi phiên điểm danh đã đóng hoặc chưa mở -> 400 ERR_3006")
    void checkIn_whenSessionClosed_shouldReturn400() throws Exception {
        openSession.setStatus(AttendanceSessionStatus.CLOSED);
        attendanceSessionRepository.save(openSession);

        AttendanceCheckInRequest request = AttendanceCheckInRequest.builder()
                .sessionId(openSession.getId())
                .wifiBssid("00:11:22:33:44:55")
                .faceSampleBase64(DUMMY_BASE64)
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in")
                        .header("Authorization", "Bearer " + enrolledStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("ERR_3006"));
    }

    @Test
    @DisplayName("TC-CK-05: Từ chối khi sinh viên không ghi danh vào lớp học phần -> 403 FORBIDDEN")
    void checkIn_whenStudentNotEnrolled_shouldReturn403() throws Exception {
        AttendanceCheckInRequest request = AttendanceCheckInRequest.builder()
                .sessionId(openSession.getId())
                .wifiBssid("00:11:22:33:44:55")
                .faceSampleBase64(DUMMY_BASE64)
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in")
                        .header("Authorization", "Bearer " + unenrolledStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("TC-CK-06: Từ chối khi sinh viên chưa đăng ký Face-ID -> 400 ERR_3005")
    void checkIn_whenFaceNotRegistered_shouldReturn400() throws Exception {
        faceEncodingRepository.deleteAll();

        AttendanceCheckInRequest request = AttendanceCheckInRequest.builder()
                .sessionId(openSession.getId())
                .wifiBssid("00:11:22:33:44:55")
                .faceSampleBase64(DUMMY_BASE64)
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in")
                        .header("Authorization", "Bearer " + enrolledStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("ERR_3005"));
    }

    @Test
    @DisplayName("TC-CK-07: Từ chối khi BSSID Wi-Fi không khớp với phòng học -> 400 ERR_3008")
    void checkIn_whenWifiMismatch_shouldReturn400() throws Exception {
        AttendanceCheckInRequest request = AttendanceCheckInRequest.builder()
                .sessionId(openSession.getId())
                .wifiBssid("AA:BB:CC:DD:EE:FF") // Spoofed / Home Wi-Fi BSSID
                .faceSampleBase64(DUMMY_BASE64)
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in")
                        .header("Authorization", "Bearer " + enrolledStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("ERR_3008"));
    }

    @Test
    @DisplayName("TC-CK-08: Từ chối khi kiểm tra thực thể sống AI thất bại (Spoofing) -> 400 ERR_3003")
    void checkIn_whenLivenessFailed_shouldReturn400() throws Exception {
        when(aiServiceClient.checkLiveness(anyString(), anyDouble()))
                .thenReturn(AiCheckLivenessResponse.of(false, 0.35));

        AttendanceCheckInRequest request = AttendanceCheckInRequest.builder()
                .sessionId(openSession.getId())
                .wifiBssid("00:11:22:33:44:55")
                .faceSampleBase64(DUMMY_BASE64)
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in")
                        .header("Authorization", "Bearer " + enrolledStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("ERR_3003"));
    }

    @Test
    @DisplayName("TC-CK-09: Từ chối khi khuôn mặt không khớp với vector gốc -> 400 ERR_3004")
    void checkIn_whenFaceMismatch_shouldReturn400() throws Exception {
        when(aiServiceClient.checkLiveness(anyString(), anyDouble()))
                .thenReturn(AiCheckLivenessResponse.of(true, 0.94));
        when(aiServiceClient.verifyFace(anyList(), anyString(), anyDouble()))
                .thenReturn(AiVerifyFaceResponse.of(false, 0.42));

        AttendanceCheckInRequest request = AttendanceCheckInRequest.builder()
                .sessionId(openSession.getId())
                .wifiBssid("00:11:22:33:44:55")
                .faceSampleBase64(DUMMY_BASE64)
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in")
                        .header("Authorization", "Bearer " + enrolledStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("ERR_3004"));
    }

    @Test
    @DisplayName("TC-CK-10: Cơ chế bảo vệ Fail-Closed khi AI Service mất kết nối -> 503 ERR_3011")
    void checkIn_whenAiServiceFails_shouldReturn503FailClosed() throws Exception {
        when(aiServiceClient.checkLiveness(anyString(), anyDouble()))
                .thenThrow(new AppException(ErrorCode.AI_SERVICE_UNAVAILABLE, "AI Service unreachable"));

        AttendanceCheckInRequest request = AttendanceCheckInRequest.builder()
                .sessionId(openSession.getId())
                .wifiBssid("00:11:22:33:44:55")
                .faceSampleBase64(DUMMY_BASE64)
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in")
                        .header("Authorization", "Bearer " + enrolledStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.errorCode").value("ERR_3011"));
    }
}
