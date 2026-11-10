package com.unicheck.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.model.dto.AttendanceSessionOpenRequest;
import com.unicheck.model.dto.QrValidationRequest;
import com.unicheck.model.entity.*;
import com.unicheck.model.enums.*;
import com.unicheck.repository.*;
import com.unicheck.security.DynamicQrRedisService;
import com.unicheck.security.JwtUtil;
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
import java.time.LocalTime;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class DynamicQrIntervalConfigIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private AttendanceSessionRepository attendanceSessionRepository;

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

    private User admin;
    private User lecturer;
    private User otherLecturer;
    private User student;

    private Semester semester;
    private Course course;
    private ClassSection classSection;
    private Room room;
    private SlotType slotType;

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("DELETE FROM student_attendances");
        jdbcTemplate.execute("DELETE FROM attendance_sessions");
        jdbcTemplate.execute("DELETE FROM timetable_slots");
        jdbcTemplate.execute("DELETE FROM enrollments");

        // 1. Users setup
        admin = userRepository.findByUsername("admin_interval_test").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("ADM-INT-01")
                        .username("admin_interval_test")
                        .email("admin.int@unicheck.edu.vn")
                        .password(passwordEncoder.encode("admin123"))
                        .fullName("Quản trị viên Kiểm thử Interval")
                        .role(Role.ADMIN)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        lecturer = userRepository.findByUsername("lecturer_int_01").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("LEC-INT-01")
                        .username("lecturer_int_01")
                        .email("lecturer.int01@unicheck.edu.vn")
                        .password(passwordEncoder.encode("lecturer123"))
                        .fullName("TS. Nguyễn Tấn Sơn")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        otherLecturer = userRepository.findByUsername("lecturer_int_02").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("LEC-INT-02")
                        .username("lecturer_int_02")
                        .email("lecturer.int02@unicheck.edu.vn")
                        .password(passwordEncoder.encode("lecturer123"))
                        .fullName("ThS. Giảng viên Khác")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        student = userRepository.findByUsername("student_int_01").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("STU-INT-01")
                        .username("student_int_01")
                        .email("student.int01@unicheck.edu.vn")
                        .password(passwordEncoder.encode("student123"))
                        .fullName("Lê Sinh Viên Demo")
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
        semester = semesterRepository.findByCode("FA26_INT").orElseGet(() ->
                semesterRepository.save(Semester.builder()
                        .code("FA26_INT")
                        .name("Fall 2026 Interval")
                        .startDate(LocalDate.of(2026, 9, 1))
                        .endDate(LocalDate.of(2026, 12, 31))
                        .status(SemesterStatus.ACTIVE)
                        .build())
        );

        course = courseRepository.findByCode("PRJ301_INT").orElseGet(() ->
                courseRepository.save(Course.builder()
                        .code("PRJ301_INT")
                        .name("Java Web Application Development")
                        .credits(3)
                        .numberOfSlots(45)
                        .status(CourseStatus.ACTIVE)
                        .build())
        );

        room = roomRepository.findByCode("AL-L201_INT").orElseGet(() ->
                roomRepository.save(Room.builder()
                        .code("AL-L201_INT")
                        .name("Phòng AL-L201")
                        .building("Alpha")
                        .capacity(40)
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

        classSection = classSectionRepository.findByClassName("SE1801-PRJ301-INT").orElseGet(() ->
                classSectionRepository.save(ClassSection.builder()
                        .className("SE1801-PRJ301-INT")
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
    }

    private AttendanceSession createCreatedSession(int slotNumber, LocalDate date) {
        TimetableSlot slot = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection)
                .room(room)
                .slotType(slotType)
                .slotNumber(slotNumber)
                .date(date)
                .startTime(LocalTime.now().minusMinutes(10))
                .endTime(LocalTime.now().plusHours(2))
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        return attendanceSessionRepository.save(AttendanceSession.builder()
                .timetableSlot(slot)
                .lecturer(lecturer)
                .status(AttendanceSessionStatus.CREATED)
                .qrRotationIntervalSeconds(10)
                .build());
    }

    @Test
    @DisplayName("1. Mở phiên điểm danh với thời gian mặc định 10 giây")
    void testOpenSessionWithDefault10SecondsInterval() throws Exception {
        AttendanceSession session = createCreatedSession(1, LocalDate.of(2026, 11, 10));

        mockMvc.perform(post("/api/v1/attendance/sessions/{id}/open", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("OPEN"))
                .andExpect(jsonPath("$.data.qrRotationIntervalSeconds").value(10));

        // Kiểm tra QR token được sinh theo interval 10s
        MvcResult qrResult = mockMvc.perform(get("/api/v1/attendance/sessions/{id}/qr", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.rotationIntervalSeconds").value(10))
                .andExpect(jsonPath("$.data.remainingSeconds", lessThanOrEqualTo(10)))
                .andReturn();

        String qrToken = objectMapper.readTree(qrResult.getResponse().getContentAsString())
                .path("data").path("qrToken").asText();
        assertNotNull(qrToken);

        // Sinh viên xác thực QR thành công
        QrValidationRequest valReq = QrValidationRequest.builder()
                .sessionId(session.getId())
                .qrToken(qrToken)
                .build();

        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(valReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.valid").value(true));
    }

    @Test
    @DisplayName("2. Mở phiên điểm danh với thời gian 30 giây")
    void testOpenSessionWith30SecondsInterval() throws Exception {
        AttendanceSession session = createCreatedSession(2, LocalDate.of(2026, 11, 11));

        AttendanceSessionOpenRequest request = AttendanceSessionOpenRequest.builder()
                .qrRotationIntervalSeconds(30)
                .build();

        mockMvc.perform(post("/api/v1/attendance/sessions/{id}/open", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("OPEN"))
                .andExpect(jsonPath("$.data.qrRotationIntervalSeconds").value(30));

        mockMvc.perform(get("/api/v1/attendance/sessions/{id}/qr", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.rotationIntervalSeconds").value(30))
                .andExpect(jsonPath("$.data.remainingSeconds", lessThanOrEqualTo(30)));
    }

    @Test
    @DisplayName("3. Mở phiên điểm danh với thời gian 60 giây")
    void testOpenSessionWith60SecondsInterval() throws Exception {
        AttendanceSession session = createCreatedSession(3, LocalDate.of(2026, 11, 12));

        AttendanceSessionOpenRequest request = AttendanceSessionOpenRequest.builder()
                .qrRotationIntervalSeconds(60)
                .build();

        mockMvc.perform(post("/api/v1/attendance/sessions/{id}/open", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.qrRotationIntervalSeconds").value(60));

        mockMvc.perform(get("/api/v1/attendance/sessions/{id}/qr", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.rotationIntervalSeconds").value(60))
                .andExpect(jsonPath("$.data.remainingSeconds", lessThanOrEqualTo(60)));
    }

    @Test
    @DisplayName("4. Mở phiên điểm danh với thời gian 120 giây")
    void testOpenSessionWith120SecondsInterval() throws Exception {
        AttendanceSession session = createCreatedSession(4, LocalDate.of(2026, 11, 13));

        AttendanceSessionOpenRequest request = AttendanceSessionOpenRequest.builder()
                .qrRotationIntervalSeconds(120)
                .build();

        mockMvc.perform(post("/api/v1/attendance/sessions/{id}/open", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.qrRotationIntervalSeconds").value(120));

        mockMvc.perform(get("/api/v1/attendance/sessions/{id}/qr", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.rotationIntervalSeconds").value(120));
    }

    @Test
    @DisplayName("5. Mở phiên điểm danh với thời gian tối đa 300 giây (5 phút)")
    void testOpenSessionWith300SecondsInterval() throws Exception {
        AttendanceSession session = createCreatedSession(5, LocalDate.of(2026, 11, 14));

        AttendanceSessionOpenRequest request = AttendanceSessionOpenRequest.builder()
                .qrRotationIntervalSeconds(300)
                .build();

        mockMvc.perform(post("/api/v1/attendance/sessions/{id}/open", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.qrRotationIntervalSeconds").value(300));

        mockMvc.perform(get("/api/v1/attendance/sessions/{id}/qr", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.rotationIntervalSeconds").value(300));
    }

    @Test
    @DisplayName("6. Từ chối cấu hình thời gian < 10 giây")
    void testRejectIntervalUnder10Seconds() throws Exception {
        AttendanceSession session = createCreatedSession(6, LocalDate.of(2026, 11, 15));

        AttendanceSessionOpenRequest request = AttendanceSessionOpenRequest.builder()
                .qrRotationIntervalSeconds(5) // Quá nhỏ < 10
                .build();

        mockMvc.perform(post("/api/v1/attendance/sessions/{id}/open", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("7. Từ chối cấu hình thời gian > 300 giây")
    void testRejectIntervalOver300Seconds() throws Exception {
        AttendanceSession session = createCreatedSession(7, LocalDate.of(2026, 11, 16));

        AttendanceSessionOpenRequest request = AttendanceSessionOpenRequest.builder()
                .qrRotationIntervalSeconds(500) // Quá lớn > 300
                .build();

        mockMvc.perform(post("/api/v1/attendance/sessions/{id}/open", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("8. Mã QR hết hạn không thể xác thực (QR_TOKEN_EXPIRED)")
    void testExpiredQrTokenCannotBeValidated() throws Exception {
        AttendanceSession session = createCreatedSession(8, LocalDate.of(2026, 11, 17));

        mockMvc.perform(post("/api/v1/attendance/sessions/{id}/open", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk());

        // Tạo mã QR đã hết hạn (TTL âm 30s trước)
        Instant past = Instant.now().minusSeconds(30);
        String expiredToken = qrTokenService.generateQrToken(
                session.getId(),
                past,
                Duration.ofSeconds(10), // Đã hết hạn 20 giây trước
                Duration.ofSeconds(10)
        );

        QrValidationRequest valReq = QrValidationRequest.builder()
                .sessionId(session.getId())
                .qrToken(expiredToken)
                .build();

        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(valReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_3021")); // QR_TOKEN_EXPIRED
    }

    @Test
    @DisplayName("9. Đóng phiên điểm danh thì QR hết hiệu lực ngay lập tức (SESSION_NOT_OPEN)")
    void testCloseSessionInvalidatesQrImmediately() throws Exception {
        AttendanceSession session = createCreatedSession(9, LocalDate.of(2026, 11, 18));

        // Mở phiên với interval 60s
        mockMvc.perform(post("/api/v1/attendance/sessions/{id}/open", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new AttendanceSessionOpenRequest(60))))
                .andExpect(status().isOk());

        // Lấy QR token đang hiệu lực
        MvcResult qrRes = mockMvc.perform(get("/api/v1/attendance/sessions/{id}/qr", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andReturn();

        String qrToken = objectMapper.readTree(qrRes.getResponse().getContentAsString())
                .path("data").path("qrToken").asText();

        // Đóng phiên điểm danh
        mockMvc.perform(post("/api/v1/attendance/sessions/{id}/close", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("CLOSED"));

        // Xác thực QR vừa lấy -> Bị từ chối vì phiên đã đóng (ERR_3006 SESSION_NOT_OPEN)
        QrValidationRequest valReq = QrValidationRequest.builder()
                .sessionId(session.getId())
                .qrToken(qrToken)
                .build();

        mockMvc.perform(post("/api/v1/attendance/qr/validate")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(valReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("ERR_3024"));

        // Yêu cầu QR token mới từ phiên đã đóng cũng bị từ chối
        mockMvc.perform(get("/api/v1/attendance/sessions/{id}/qr", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("ERR_3024"));
    }

    @Test
    @DisplayName("10. Cập nhật chu kỳ thay đổi mã QR khi phiên đang mở (updateQrInterval)")
    void testUpdateQrIntervalWhileOpen() throws Exception {
        AttendanceSession session = createCreatedSession(10, LocalDate.of(2026, 11, 19));

        // Mở ban đầu 10s
        mockMvc.perform(post("/api/v1/attendance/sessions/{id}/open", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.qrRotationIntervalSeconds").value(10));

        // Cập nhật thành 60s
        mockMvc.perform(put("/api/v1/attendance/sessions/{id}/qr-interval", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new AttendanceSessionOpenRequest(60))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.qrRotationIntervalSeconds").value(60));

        // Fetch QR token ngay sau đó phải có rotationIntervalSeconds == 60
        mockMvc.perform(get("/api/v1/attendance/sessions/{id}/qr", session.getId())
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.rotationIntervalSeconds").value(60));
    }

    @Test
    @DisplayName("11. Giảng viên khác không được phép mở hoặc chỉnh sửa chu kỳ QR (FORBIDDEN)")
    void testUnauthorizedLecturerCannotOpenOrUpdateInterval() throws Exception {
        AttendanceSession session = createCreatedSession(11, LocalDate.of(2026, 11, 20));

        mockMvc.perform(post("/api/v1/attendance/sessions/{id}/open", session.getId())
                        .header("Authorization", "Bearer " + otherLecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new AttendanceSessionOpenRequest(60))))
                .andExpect(status().isForbidden());

        mockMvc.perform(put("/api/v1/attendance/sessions/{id}/qr-interval", session.getId())
                        .header("Authorization", "Bearer " + otherLecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new AttendanceSessionOpenRequest(60))))
                .andExpect(status().isForbidden());
    }
}
