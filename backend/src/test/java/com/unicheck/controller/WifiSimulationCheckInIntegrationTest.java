package com.unicheck.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.exception.ErrorCode;
import com.unicheck.model.dto.AttendanceCheckInRequest;
import com.unicheck.model.dto.QrValidationRequest;
import com.unicheck.model.dto.ai.AiCheckLivenessResponse;
import com.unicheck.model.dto.ai.AiVerifyFaceResponse;
import com.unicheck.model.entity.*;
import com.unicheck.model.enums.*;
import com.unicheck.repository.*;
import com.unicheck.security.JwtUtil;
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

import java.time.LocalDate;
import java.time.LocalTime;
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
public class WifiSimulationCheckInIntegrationTest {

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

    @MockBean
    private AiServiceClient aiServiceClient;

    private User demoStudent;
    private User demoLecturer;
    private String demoStudentToken;
    private String demoLecturerToken;

    private ClassSection demoClass;
    private ClassSection otherClass;
    private Room demoRoom;
    private AttendanceSession demoSession;
    private AttendanceSession otherSession;

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
        demoStudent = userRepository.findByUsername("test_demo_student").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("HE180001")
                        .username("test_demo_student")
                        .email("demo.student@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Password123!"))
                        .fullName("Nguyễn Văn Test")
                        .role(Role.STUDENT)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        demoLecturer = userRepository.findByUsername("test_demo_lecturer").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("GV001")
                        .username("test_demo_lecturer")
                        .email("demo.lecturer@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Password123!"))
                        .fullName("Nguyễn Tấn Sơn")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        demoStudentToken = jwtUtil.generateAccessToken(demoStudent);
        demoLecturerToken = jwtUtil.generateAccessToken(demoLecturer);

        // 2. Academic structure
        Semester semester = semesterRepository.findByCode("FA26").orElseGet(() ->
                semesterRepository.save(Semester.builder()
                        .code("FA26")
                        .name("Fall 2026")
                        .startDate(LocalDate.now().minusMonths(1))
                        .endDate(LocalDate.now().plusMonths(3))
                        .status(SemesterStatus.UPCOMING)
                        .build())
        );

        Course course = courseRepository.findByCode("PRJ301").orElseGet(() ->
                courseRepository.save(Course.builder()
                        .code("PRJ301")
                        .name("Java Web Application Development")
                        .credits(3)
                        .numberOfSlots(45)
                        .status(CourseStatus.ACTIVE)
                        .build())
        );

        demoClass = classSectionRepository.findByClassName("SE1801-PRJ301").orElseGet(() ->
                classSectionRepository.save(ClassSection.builder()
                        .className("SE1801-PRJ301")
                        .course(course)
                        .semester(semester)
                        .status(ClassSectionStatus.OPEN)
                        .numberOfSlots(15)
                        .maxStudents(50)
                        .build())
        );

        otherClass = classSectionRepository.findByClassName("OTHER-CLASS-99").orElseGet(() ->
                classSectionRepository.save(ClassSection.builder()
                        .className("OTHER-CLASS-99")
                        .course(course)
                        .semester(semester)
                        .status(ClassSectionStatus.OPEN)
                        .numberOfSlots(15)
                        .maxStudents(50)
                        .build())
        );

        demoRoom = roomRepository.findByCode("AL-L201").orElseGet(() ->
                roomRepository.save(Room.builder()
                        .code("AL-L201")
                        .name("Phòng AL-L201 Tòa Alpha")
                        .capacity(40)
                        .status(RoomStatus.AVAILABLE)
                        .build())
        );

        SlotType slotType = slotTypeRepository.findAll().stream()
                .filter(st -> st.getSlotIndex() != null && st.getSlotIndex() == 1)
                .findFirst()
                .orElseGet(() -> slotTypeRepository.save(SlotType.builder()
                        .name("Ca 1")
                        .slotIndex(1)
                        .startTime(LocalTime.now().minusMinutes(5))
                        .endTime(LocalTime.now().plusHours(2))
                        .duration("145m")
                        .semester(semester)
                        .build())
                );
        slotType.setStartTime(LocalTime.now().minusMinutes(5));
        slotType.setEndTime(LocalTime.now().plusHours(2));
        slotTypeRepository.save(slotType);

        // 3. Timetable slot for demo class
        TimetableSlot slot = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(demoClass)
                .room(demoRoom)
                .slotType(slotType)
                .date(LocalDate.now())
                .dayOfWeek(LocalDate.now().getDayOfWeek().getValue())
                .slotNumber(1)
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        demoSession = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot)
                .lecturer(demoLecturer)
                .status(AttendanceSessionStatus.OPEN)
                .qrRotationIntervalSeconds(10)
                .build());

        // 4. Timetable slot for other class
        TimetableSlot otherSlot = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(otherClass)
                .room(demoRoom)
                .slotType(slotType)
                .date(LocalDate.now())
                .dayOfWeek(LocalDate.now().getDayOfWeek().getValue())
                .slotNumber(1)
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        otherSession = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(otherSlot)
                .lecturer(demoLecturer)
                .status(AttendanceSessionStatus.OPEN)
                .qrRotationIntervalSeconds(10)
                .build());

        // 5. Enrollments
        enrollmentRepository.save(Enrollment.builder()
                .student(demoStudent)
                .studentCode(demoStudent.getCode())
                .classSection(demoClass)
                .status(EnrollmentStatus.ENROLLED)
                .build());

        enrollmentRepository.save(Enrollment.builder()
                .student(demoStudent)
                .studentCode(demoStudent.getCode())
                .classSection(otherClass)
                .status(EnrollmentStatus.ENROLLED)
                .build());

        // 6. Registered Face Encoding (512-dim dummy bytes)
        byte[] dummyEncoding = new byte[512 * 4];
        faceEncodingRepository.save(FaceEncoding.builder()
                .user(demoStudent)
                .encodingData(dummyEncoding)
                .livenessVerified(true)
                .build());

        // 7. Physical Wi-Fi AP for demoRoom (AL-L201)
        WifiAccessPoint physicalAp = wifiAccessPointRepository.save(WifiAccessPoint.builder()
                .ssid("FU-Student-AL")
                .bssid("00:1A:2B:3C:01:02")
                .name("AP Tòa Alpha Tầng 2")
                .location("Tòa AL L2")
                .status(WifiApStatus.ACTIVE)
                .build());

        roomWifiAccessPointRepository.save(RoomWifiAccessPoint.builder()
                .room(demoRoom)
                .wifiAccessPoint(physicalAp)
                .signalStrength(-50)
                .isPrimary(true)
                .build());

        // 8. Attendance Configuration: Wi-Fi location enabled
        attendanceConfigRepository.findByConfigKey("DEFAULT").ifPresentOrElse(
                cfg -> {
                    cfg.setWifiLocationEnabled(true);
                    cfg.setMaxAttempts(3);
                    attendanceConfigRepository.save(cfg);
                },
                () -> attendanceConfigRepository.save(AttendanceConfig.builder()
                        .configKey("DEFAULT")
                        .wifiLocationEnabled(true)
                        .maxAttempts(3)
                        .build())
        );

        // 9. AI Service mock (ArcFace & MiniFASNet)
        when(aiServiceClient.checkLiveness(anyString(), anyDouble()))
                .thenReturn(AiCheckLivenessResponse.of(true, 0.95));

        when(aiServiceClient.verifyFace(anyList(), anyString(), anyDouble()))
                .thenReturn(AiVerifyFaceResponse.of(true, 0.92));
    }

    @Test
    @DisplayName("1. Physical Wi-Fi match: Sinh viên kết nối đúng AP vật lý phòng học điểm danh thành công")
    void testPhysicalWifiMatchPasses() throws Exception {
        AttendanceCheckInRequest request = AttendanceCheckInRequest.builder()
                .sessionId(demoSession.getId())
                .wifiBssid("00:1A:2B:3C:01:02")
                .wifiSsid("FU-Student-AL")
                .faceSampleBase64(DUMMY_BASE64)
                .deviceModel("Pixel 10 Pro Physical")
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + demoStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("PRESENT"))
                .andExpect(jsonPath("$.data.className").value("SE1801-PRJ301"))
                .andExpect(jsonPath("$.data.roomCode").value("AL-L201"))
                .andExpect(jsonPath("$.data.note", not(containsString("Wi-Fi mô phỏng Demo"))));

        // Verify DB
        StudentAttendance record = studentAttendanceRepository.findAll().getFirst();
        assertEquals("PRESENT", record.getStatus());
        assertEquals("00:1A:2B:3C:01:02", record.getWifiBssid());
        assertTrue(record.getNote().contains("Mobile Face-ID"));
    }

    @Test
    @DisplayName("2. DEMO_WIFI_SIMULATION: Android Emulator với BSSID 02:00:00:00:00:00 được backend chấp thuận cho lớp demo SE1801-PRJ301")
    void testWifiSimulationPassesForAllowedClass() throws Exception {
        AttendanceCheckInRequest request = AttendanceCheckInRequest.builder()
                .sessionId(demoSession.getId())
                .wifiBssid("02:00:00:00:00:00")
                .wifiSsid("AndroidWifi")
                .faceSampleBase64(DUMMY_BASE64)
                .deviceModel("Android Emulator (Demo)")
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + demoStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("PRESENT"))
                .andExpect(jsonPath("$.data.className").value("SE1801-PRJ301"))
                .andExpect(jsonPath("$.data.note").value(containsString("Wi-Fi mô phỏng Demo")))
                .andExpect(jsonPath("$.data.message").value(containsString("Wi-Fi mô phỏng Demo")));

        // Verify DB note
        StudentAttendance record = studentAttendanceRepository.findAll().getFirst();
        assertEquals("PRESENT", record.getStatus());
        assertEquals("02:00:00:00:00:00", record.getWifiBssid());
        assertTrue(record.getNote().contains("Wi-Fi mô phỏng Demo"));
    }

    @Test
    @DisplayName("3. DEMO_WIFI_SIMULATION: Lớp không thuộc whitelist allowed-class-name bị từ chối nếu dùng Wi-Fi mô phỏng")
    void testWifiSimulationRejectedForUnallowedClass() throws Exception {
        AttendanceCheckInRequest request = AttendanceCheckInRequest.builder()
                .sessionId(otherSession.getId())
                .wifiBssid("02:00:00:00:00:00")
                .wifiSsid("AndroidWifi")
                .faceSampleBase64(DUMMY_BASE64)
                .deviceModel("Android Emulator (Demo)")
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + demoStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value(ErrorCode.WIFI_NOT_MATCHED.getCode()))
                .andExpect(jsonPath("$.message").value(containsString("Vị trí Wi-Fi không khớp với phòng học")));
    }

    @Test
    @DisplayName("4. BSSID ngẫu nhiên không thuộc AP phòng và không khớp mô phỏng sẽ bị từ chối")
    void testUnknownBssidRejected() throws Exception {
        AttendanceCheckInRequest request = AttendanceCheckInRequest.builder()
                .sessionId(demoSession.getId())
                .wifiBssid("99:88:77:66:55:44")
                .wifiSsid("CoffeeShop_WiFi")
                .faceSampleBase64(DUMMY_BASE64)
                .deviceModel("Pixel 10 Pro")
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + demoStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value(ErrorCode.WIFI_NOT_MATCHED.getCode()));
    }

    @Test
    @DisplayName("5. API /attendance/qr/validate trả về cờ wifiSimulationAllowed và thông tin phòng học cho Flutter")
    void testQrValidationReturnsWifiSimulationAllowed() throws Exception {
        var qrResp = dynamicQrService.generateOrGetActiveQrToken(
                new com.unicheck.security.UserPrincipal(demoLecturer),
                demoSession.getId()
        );

        QrValidationRequest request = QrValidationRequest.builder()
                .qrToken(qrResp.getQrToken())
                .sessionId(demoSession.getId())
                .build();

        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + demoStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.valid").value(true))
                .andExpect(jsonPath("$.data.sessionId").value(demoSession.getId()))
                .andExpect(jsonPath("$.data.className").value("SE1801-PRJ301"))
                .andExpect(jsonPath("$.data.roomCode").value("AL-L201"))
                .andExpect(jsonPath("$.data.roomId").value(demoRoom.getId()))
                .andExpect(jsonPath("$.data.wifiSimulationAllowed").value(true))
                .andExpect(jsonPath("$.data.simulatedSsid").value("AndroidWifi"))
                .andExpect(jsonPath("$.data.simulatedBssid").value("02:00:00:00:00:00"));
    }

    @Test
    @DisplayName("6. Chống điểm danh trùng: Điểm danh lần 2 bị từ chối ALREADY_CHECKED_IN")
    void testDuplicateCheckInPrevented() throws Exception {
        AttendanceCheckInRequest request = AttendanceCheckInRequest.builder()
                .sessionId(demoSession.getId())
                .wifiBssid("02:00:00:00:00:00")
                .wifiSsid("AndroidWifi")
                .faceSampleBase64(DUMMY_BASE64)
                .deviceModel("Android Emulator (Demo)")
                .build();

        // First check-in
        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + demoStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk());

        // Second check-in -> ALREADY_CHECKED_IN (409 CONFLICT)
        mockMvc.perform(post("/api/v1/attendance/check-in-face")
                        .header("Authorization", "Bearer " + demoStudentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.errorCode").value(ErrorCode.ALREADY_CHECKED_IN.getCode()));
    }
}
