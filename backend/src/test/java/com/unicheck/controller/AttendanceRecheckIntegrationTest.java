package com.unicheck.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.model.dto.AttendanceCheckInRequest;
import com.unicheck.model.dto.AttendanceManualAdjustRequest;
import com.unicheck.model.dto.AttendanceRecheckCreateRequest;
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
import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class AttendanceRecheckIntegrationTest {

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
    private AttendanceRecheckRequestRepository attendanceRecheckRequestRepository;

    @Autowired
    private AttendanceAdjustmentHistoryRepository attendanceAdjustmentHistoryRepository;

    @Autowired
    private AttendanceVerificationAttemptRepository attendanceVerificationAttemptRepository;

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

    private User student;
    private User lecturer;
    private String studentToken;
    private String lecturerToken;

    private Semester semester;
    private Course course;
    private ClassSection classSection;
    private Room room;
    private SlotType slotType;
    private TimetableSlot slot;
    private AttendanceSession openSession;
    private WifiAccessPoint wifiAp;

    private static final String DUMMY_BASE64 = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=";

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("DELETE FROM attendance_verification_attempts");
        jdbcTemplate.execute("DELETE FROM attendance_adjustment_histories");
        jdbcTemplate.execute("DELETE FROM attendance_recheck_requests");
        jdbcTemplate.execute("DELETE FROM student_attendances");
        jdbcTemplate.execute("DELETE FROM attendance_sessions");
        jdbcTemplate.execute("DELETE FROM timetable_slots");
        jdbcTemplate.execute("DELETE FROM enrollments");
        jdbcTemplate.execute("DELETE FROM room_wifi_access_points");
        jdbcTemplate.execute("DELETE FROM wifi_access_points");
        jdbcTemplate.execute("DELETE FROM face_encodings");

        // 1. Users
        student = userRepository.findByUsername("test_recheck_student").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("STU-RC-01")
                        .username("test_recheck_student")
                        .email("recheck.stu@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Password123!"))
                        .fullName("Trần Thị Hoa")
                        .role(Role.STUDENT)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        lecturer = userRepository.findByUsername("test_recheck_lecturer").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("LEC-RC-01")
                        .username("test_recheck_lecturer")
                        .email("recheck.lec@unicheck.edu.vn")
                        .password(passwordEncoder.encode("Password123!"))
                        .fullName("Nguyễn Tấn Sơn")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        studentToken = "Bearer " + jwtUtil.generateAccessToken(student);
        lecturerToken = "Bearer " + jwtUtil.generateAccessToken(lecturer);

        // 2. Catalog
        semester = semesterRepository.findByCode("2026.FALL").orElseGet(() ->
                semesterRepository.save(Semester.builder()
                        .code("2026.FALL")
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
                        .numberOfSlots(45)
                        .status(CourseStatus.ACTIVE)
                        .build())
        );

        room = roomRepository.findByCode("AL-L201").orElseGet(() ->
                roomRepository.save(Room.builder()
                        .code("AL-L201")
                        .name("Phòng AL-L201")
                        .building("Tòa AL")
                        .capacity(40)
                        .status(RoomStatus.AVAILABLE)
                        .build())
        );

        slotType = slotTypeRepository.findAll().stream()
                .filter(st -> st.getSemester() != null && st.getSemester().getId().equals(semester.getId()) && st.getSlotIndex() == 2)
                .findFirst()
                .orElseGet(() -> slotTypeRepository.save(SlotType.builder()
                        .name("Ca 2 (09:45-12:10)")
                        .slotIndex(2)
                        .startTime(LocalTime.now().minusMinutes(10))
                        .endTime(LocalTime.now().plusHours(2))
                        .duration("145m")
                        .semester(semester)
                        .build())
                );

        classSection = classSectionRepository.findByClassName("SE1801-PRJ301").orElseGet(() ->
                classSectionRepository.save(ClassSection.builder()
                        .className("SE1801-PRJ301")
                        .course(course)
                        .semester(semester)
                        .lecturer(lecturer)
                        .numberOfSlots(30)
                        .maxStudents(35)
                        .currentEnrollment(1)
                        .status(ClassSectionStatus.OPEN)
                        .build())
        );

        // 3. Enrollment
        if (!enrollmentRepository.existsByClassSection_ClassNameAndStudent_Id(classSection.getClassName(), student.getId())) {
            enrollmentRepository.save(Enrollment.builder()
                    .classSection(classSection)
                    .student(student)
                    .studentCode(student.getCode())
                    .status(EnrollmentStatus.ENROLLED)
                    .build());
        }

        // 4. Timetable Slot
        slot = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection)
                .room(room)
                .slotType(slotType)
                .date(LocalDate.now())
                .dayOfWeek(LocalDate.now().getDayOfWeek().getValue())
                .slotNumber(2)
                .startTime(LocalTime.now().minusMinutes(10))
                .endTime(LocalTime.now().plusHours(2))
                .status(TimetableSlotStatus.SCHEDULED)
                .build()
        );

        // 5. Open Attendance Session
        openSession = attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.OPEN)
                .openedAt(LocalDateTime.now().minusMinutes(10))
                .qrRotationIntervalSeconds(10)
                .build()
        );

        // 6. Wi-Fi Access Point for Room
        wifiAp = wifiAccessPointRepository.save(WifiAccessPoint.builder()
                .ssid("FU-Student-AL")
                .bssid("00:1A:2B:3C:01:02")
                .name("AP AL-L201")
                .status(WifiApStatus.ACTIVE)
                .build()
        );

        roomWifiAccessPointRepository.save(RoomWifiAccessPoint.builder()
                .room(room)
                .wifiAccessPoint(wifiAp)
                .isPrimary(true)
                .build()
        );

        // 7. Registered Face-ID
        byte[] dummyEncoding = new byte[512 * 4];
        faceEncodingRepository.save(FaceEncoding.builder()
                .user(student)
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
    @DisplayName("TC-RECHECK-01: Giảng viên xem danh sách sinh viên phiên và điều chỉnh thủ công có ghi vết Audit")
    void lecturerGetStudentsAndManualAdjust_shouldSucceedWithAudit() throws Exception {
        // 1. Initial Get Students List
        mockMvc.perform(get("/api/v1/attendance/sessions/{id}/students", openSession.getId())
                        .header("Authorization", lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].studentCode", is("STU-RC-01")))
                .andExpect(jsonPath("$.data[0].status", is("ABSENT")));

        // 2. Lecturer Adjusts Status to PRESENT manually
        AttendanceManualAdjustRequest adjustRequest = AttendanceManualAdjustRequest.builder()
                .newStatus("PRESENT")
                .reason("Sinh viên báo cáo quên mang điện thoại, xác nhận trực tiếp tại lớp")
                .build();

        mockMvc.perform(patch("/api/v1/attendance/sessions/{sessionId}/students/{studentId}",
                        openSession.getId(), student.getId())
                        .header("Authorization", lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(adjustRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.status", is("PRESENT")))
                .andExpect(jsonPath("$.data.method", is("MANUAL")));

        // 3. Verify Database State
        List<AttendanceAdjustmentHistory> histories = attendanceAdjustmentHistoryRepository.findBySessionIdOrderByModifiedAtDesc(openSession.getId());
        assertEquals(1, histories.size());
        assertEquals("MANUAL_ADJUSTMENT", histories.get(0).getModificationType());
        assertEquals("PRESENT", histories.get(0).getNewStatus());
        assertEquals(lecturer.getId(), histories.get(0).getModifiedBy().getId());

        // 4. Verify History API Endpoint
        mockMvc.perform(get("/api/v1/attendance/sessions/{id}/history", openSession.getId())
                        .header("Authorization", lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].modificationType", is("MANUAL_ADJUSTMENT")));
    }

    @Test
    @DisplayName("TC-RECHECK-02: Giảng viên phát hành yêu cầu điểm danh lại và sinh viên nhận yêu cầu trên Mobile")
    void lecturerCreateRecheck_andStudentFetchesPending_shouldSucceed() throws Exception {
        // 1. Pre-condition: Student is marked ABSENT
        studentAttendanceRepository.save(StudentAttendance.builder()
                .session(openSession)
                .student(student)
                .status("ABSENT")
                .method("MANUAL")
                .build());

        // 2. Lecturer creates recheck request
        AttendanceRecheckCreateRequest recheckCreate = AttendanceRecheckCreateRequest.builder()
                .expirationMinutes(20)
                .reason("Sinh viên vào lớp sau 15p có giải trình, yêu cầu quét QR và nhận diện Face-ID")
                .build();

        mockMvc.perform(post("/api/v1/attendance/sessions/{sessionId}/students/{studentId}/recheck",
                        openSession.getId(), student.getId())
                        .header("Authorization", lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(recheckCreate)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.status", is("PENDING")))
                .andExpect(jsonPath("$.data.reason", containsString("Sinh viên vào lớp sau 15p")));

        // 3. Prevent duplicate PENDING recheck
        mockMvc.perform(post("/api/v1/attendance/sessions/{sessionId}/students/{studentId}/recheck",
                        openSession.getId(), student.getId())
                        .header("Authorization", lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(recheckCreate)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.errorCode", is("ERR_3029")));

        // 4. Student queries pending recheck requests
        mockMvc.perform(get("/api/v1/attendance/recheck-requests/pending")
                        .header("Authorization", studentToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].status", is("PENDING")))
                .andExpect(jsonPath("$.data[0].sessionId", is(openSession.getId().intValue())));
    }

    @Test
    @DisplayName("TC-RECHECK-03: Luồng Re-check End-to-End: Thất bại do Wi-Fi ghi attempt FAILED, Thành công cập nhật COMPLETED và Audit")
    void fullRecheckWorkflow_failureLogsAttempt_successCompletesAndAudits() throws Exception {
        // Setup initial ABSENT attendance
        studentAttendanceRepository.save(StudentAttendance.builder()
                .session(openSession)
                .student(student)
                .status("ABSENT")
                .method("MANUAL")
                .build());

        // 1. Issue recheck request
        AttendanceRecheckRequest recheck = attendanceRecheckRequestRepository.save(AttendanceRecheckRequest.builder()
                .session(openSession)
                .student(student)
                .requestedBy(lecturer)
                .status("PENDING")
                .reason("Yêu cầu kiểm tra lại sinh trắc học và vị trí phòng học")
                .expiresAt(LocalDateTime.now().plusMinutes(15))
                .build());

        // Mock AI Service responses
        when(aiServiceClient.checkLiveness(anyString(), anyDouble()))
                .thenReturn(AiCheckLivenessResponse.of(true, 0.95));
        when(aiServiceClient.verifyFace(anyList(), anyString(), anyDouble()))
                .thenReturn(AiVerifyFaceResponse.of(true, 0.91));

        // 2. Attempt 1: Failed Wi-Fi validation
        AttendanceCheckInRequest failReq = AttendanceCheckInRequest.builder()
                .sessionId(openSession.getId())
                .recheckRequestId(recheck.getId())
                .faceSampleBase64(DUMMY_BASE64)
                .wifiBssid("99:88:77:66:55:44") // Wrong AP
                .wifiSsid("Wrong_Cafe_Wifi")
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in")
                        .header("Authorization", studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(failReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode", is("ERR_3008")));

        // Verify attempt logged as FAILED, but recheck is still PENDING
        List<AttendanceVerificationAttempt> attempts = attendanceVerificationAttemptRepository.findByRecheckRequestIdOrderByAttemptedAtDesc(recheck.getId());
        assertEquals(1, attempts.size());
        assertEquals("FAILED", attempts.get(0).getVerificationStatus());
        assertEquals("ERR_3008", attempts.get(0).getFailureCode());

        AttendanceRecheckRequest currentRecheck = attendanceRecheckRequestRepository.findById(recheck.getId()).orElseThrow();
        assertEquals("PENDING", currentRecheck.getStatus());

        // 3. Attempt 2: Successful check-in with matching AP
        AttendanceCheckInRequest successReq = AttendanceCheckInRequest.builder()
                .sessionId(openSession.getId())
                .recheckRequestId(recheck.getId())
                .faceSampleBase64(DUMMY_BASE64)
                .wifiBssid("00:1A:2B:3C:01:02") // Correct Room AP
                .wifiSsid("FU-Student-AL")
                .deviceModel("Pixel 10 Pro")
                .build();

        mockMvc.perform(post("/api/v1/attendance/check-in")
                        .header("Authorization", studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(successReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.status", is("PRESENT")))
                .andExpect(jsonPath("$.data.method", is("FACE_QR")));

        // 4. Verify recheck request is marked COMPLETED
        AttendanceRecheckRequest completedRecheck = attendanceRecheckRequestRepository.findById(recheck.getId()).orElseThrow();
        assertEquals("COMPLETED", completedRecheck.getStatus());
        assertNotNull(completedRecheck.getCompletedAt());

        // 5. Verify Verification Attempts table contains both attempts
        List<AttendanceVerificationAttempt> allAttempts = attendanceVerificationAttemptRepository.findByRecheckRequestIdOrderByAttemptedAtDesc(recheck.getId());
        assertEquals(2, allAttempts.size());
        assertEquals("SUCCESS", allAttempts.get(0).getVerificationStatus());
        assertEquals("FAILED", allAttempts.get(1).getVerificationStatus());

        // 6. Verify Attendance Adjustment History logged RECHECK_COMPLETED
        List<AttendanceAdjustmentHistory> histories = attendanceAdjustmentHistoryRepository.findBySessionIdOrderByModifiedAtDesc(openSession.getId());
        assertTrue(histories.stream().anyMatch(h -> "RECHECK_COMPLETED".equals(h.getModificationType())
                && "PRESENT".equals(h.getNewStatus())
                && "ABSENT".equals(h.getOldStatus())));

        // 7. Verify single attendance row per student
        List<StudentAttendance> attendances = studentAttendanceRepository.findAll().stream()
                .filter(a -> a.getSession().getId().equals(openSession.getId()) && a.getStudent().getId().equals(student.getId()))
                .toList();
        assertEquals(1, attendances.size());
        assertEquals("PRESENT", attendances.get(0).getStatus());

        // 8. Re-attempt with now-COMPLETED recheck request should be rejected
        mockMvc.perform(post("/api/v1/attendance/check-in")
                        .header("Authorization", studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(successReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode", is("ERR_3028")));
    }
}
