package com.unicheck.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.model.dto.TimetableConflictCheckRequest;
import com.unicheck.model.dto.TimetableSlotCreateRequest;
import com.unicheck.model.dto.TimetableSlotUpdateRequest;
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
import java.time.LocalTime;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class TimetableIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private TimetableSlotRepository timetableSlotRepository;

    @Autowired
    private SlotTypeRepository slotTypeRepository;

    @Autowired
    private HolidayRepository holidayRepository;

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
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    private String adminToken;
    private String lecturerToken;
    private String studentToken;

    private User admin;
    private User lecturer;
    private User otherLecturer;
    private User student;

    private Semester semester;
    private Course course;
    private Course otherCourse;
    private ClassSection classSection1;
    private ClassSection classSection2;
    private Room roomA;
    private Room roomB;
    private Room smallRoom;
    private SlotType slotTypeMorning;

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("DELETE FROM attendance_sessions");
        timetableSlotRepository.deleteAll();
        enrollmentRepository.deleteAll();
        classSectionRepository.deleteAll();
        courseRepository.deleteAll();
        holidayRepository.deleteAll();
        slotTypeRepository.deleteAll();
        semesterRepository.deleteAll();
        roomRepository.deleteAll();

        // 1. Users
        admin = userRepository.findByUsername("admin_tt_test").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("ADM-TT-01")
                        .username("admin_tt_test")
                        .email("admin.tt@unicheck.edu.vn")
                        .password(passwordEncoder.encode("admin123"))
                        .fullName("Quản trị viên TKB")
                        .role(Role.ADMIN)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );
        adminToken = jwtUtil.generateAccessToken(admin);

        lecturer = userRepository.findByUsername("gv_tt_nam").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("GV-TT-01")
                        .username("gv_tt_nam")
                        .email("nam.lh@unicheck.edu.vn")
                        .password(passwordEncoder.encode("lecturer123"))
                        .fullName("TS. Lê Hoàng Nam")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );
        lecturerToken = jwtUtil.generateAccessToken(lecturer);

        otherLecturer = userRepository.findByUsername("gv_tt_hung").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("GV-TT-02")
                        .username("gv_tt_hung")
                        .email("hung.nv@unicheck.edu.vn")
                        .password(passwordEncoder.encode("lecturer123"))
                        .fullName("PGS.TS. Nguyễn Văn Hưng")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        student = userRepository.findByUsername("sv_tt_dat").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("SV-TT-01")
                        .username("sv_tt_dat")
                        .email("dat.tt@unicheck.edu.vn")
                        .password(passwordEncoder.encode("student123"))
                        .fullName("Nguyễn Thành Đạt")
                        .role(Role.STUDENT)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );
        studentToken = jwtUtil.generateAccessToken(student);

        // 2. Semester: 2026-09-01 -> 2026-12-31
        semester = semesterRepository.save(Semester.builder()
                .code("FA26")
                .name("Học kỳ Thu 2026")
                .startDate(LocalDate.of(2026, 9, 1))
                .endDate(LocalDate.of(2026, 12, 31))
                .status(SemesterStatus.ACTIVE)
                .build());

        // 3. Holiday: 2026-09-02
        holidayRepository.save(Holiday.builder()
                .semester(semester)
                .holidayDate(LocalDate.of(2026, 9, 2))
                .description("Quốc khánh 2/9")
                .isRecurring(false)
                .build());

        // 4. SlotType
        slotTypeMorning = slotTypeRepository.save(SlotType.builder()
                .name("Tiết 1-3")
                .slotIndex(1)
                .startTime(LocalTime.of(7, 0))
                .endTime(LocalTime.of(9, 25))
                .duration("135'")
                .semester(semester)
                .build());

        // 5. Rooms
        roomA = roomRepository.save(Room.builder()
                .code("C3-102")
                .name("Phòng học C3-102")
                .capacity(80)
                .building("Tòa C")
                .status(RoomStatus.AVAILABLE)
                .type(RoomType.THEORY)
                .build());

        roomB = roomRepository.save(Room.builder()
                .code("A1-405")
                .name("Phòng học A1-405")
                .capacity(90)
                .building("Tòa A")
                .status(RoomStatus.AVAILABLE)
                .type(RoomType.THEORY)
                .build());

        smallRoom = roomRepository.save(Room.builder()
                .code("P-TINY")
                .name("Phòng học Nhỏ")
                .capacity(10)
                .building("Tòa B")
                .status(RoomStatus.AVAILABLE)
                .type(RoomType.THEORY)
                .build());

        // 6. Courses
        course = courseRepository.save(Course.builder()
                .code("IT301")
                .name("Cấu trúc dữ liệu & Giải thuật")
                .credits(3)
                .numberOfSlots(45)
                .status(CourseStatus.ACTIVE)
                .build());

        otherCourse = courseRepository.save(Course.builder()
                .code("CS205")
                .name("Cơ sở dữ liệu")
                .credits(3)
                .numberOfSlots(45)
                .status(CourseStatus.ACTIVE)
                .build());

        // 7. ClassSections
        classSection1 = classSectionRepository.save(ClassSection.builder()
                .className("IT301.01")
                .course(course)
                .semester(semester)
                .lecturer(lecturer)
                .numberOfSlots(45)
                .maxStudents(60)
                .currentEnrollment(35)
                .status(ClassSectionStatus.OPEN)
                .build());

        classSection2 = classSectionRepository.save(ClassSection.builder()
                .className("CS205.01")
                .course(otherCourse)
                .semester(semester)
                .lecturer(lecturer) // Same lecturer to test lecturer conflicts
                .numberOfSlots(45)
                .maxStudents(50)
                .currentEnrollment(30)
                .status(ClassSectionStatus.OPEN)
                .build());

        // 8. Enrollment for Student in classSection1
        enrollmentRepository.save(Enrollment.builder()
                .classSection(classSection1)
                .student(student)
                .studentCode(student.getCode())
                .status(EnrollmentStatus.ENROLLED)
                .build());
    }

    // =========================================================================
    // Test 1: CRUD Success
    // =========================================================================

    @Test
    @DisplayName("1. Admin tạo mới tiết học thành công với đầy đủ ràng buộc")
    void testCreateTimetableSlot_Success() throws Exception {
        LocalDate studyDate = LocalDate.of(2026, 10, 5); // Monday, inside semester, not holiday

        TimetableSlotCreateRequest req = TimetableSlotCreateRequest.builder()
                .className(classSection1.getClassName())
                .roomId(roomA.getId())
                .slotTypeId(slotTypeMorning.getId())
                .date(studyDate)
                .slotNumber(1)
                .endSlotNumber(3)
                .note("Học lý thuyết chương 1")
                .build();

        mockMvc.perform(post("/api/v1/timetable/slots")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.className", is(classSection1.getClassName())))
                .andExpect(jsonPath("$.data.roomCode", is("C3-102")))
                .andExpect(jsonPath("$.data.slotNumber", is(1)))
                .andExpect(jsonPath("$.data.date", is("2026-10-05")))
                .andExpect(jsonPath("$.data.status", is("SCHEDULED")));
    }

    // =========================================================================
    // Test 2: Room Collision Detection (ERR_6003)
    // =========================================================================

    @Test
    @DisplayName("2. Phát hiện xung đột trùng phòng học cùng thời gian (ERR_6003)")
    void testCreateTimetableSlot_RoomScheduleConflict() throws Exception {
        LocalDate studyDate = LocalDate.of(2026, 10, 12);

        // Slot 1: Lớp 1 học tại Room A
        timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection1)
                .room(roomA)
                .date(studyDate)
                .dayOfWeek(1)
                .slotNumber(1)
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        // Slot 2: Cố tình xếp lớp khác vào cùng Room A, cùng ngày, cùng tiết
        ClassSection csOtherLecturer = classSectionRepository.save(ClassSection.builder()
                .className("OTHER.01")
                .course(course)
                .semester(semester)
                .lecturer(otherLecturer)
                .numberOfSlots(45)
                .maxStudents(40)
                .build());

        TimetableSlotCreateRequest req = TimetableSlotCreateRequest.builder()
                .className(csOtherLecturer.getClassName())
                .roomId(roomA.getId())
                .date(studyDate)
                .slotNumber(1)
                .build();

        mockMvc.perform(post("/api/v1/timetable/slots")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_6003")));
    }

    // =========================================================================
    // Test 3: Lecturer Collision Detection (ERR_6004)
    // =========================================================================

    @Test
    @DisplayName("3. Phát hiện xung đột trùng lịch giảng viên tại 2 phòng khác nhau (ERR_6004)")
    void testCreateTimetableSlot_LecturerScheduleConflict() throws Exception {
        LocalDate studyDate = LocalDate.of(2026, 10, 14);

        // TS. Nam dạy lớp 1 tại Room A vào Tiết 4
        timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection1)
                .room(roomA)
                .date(studyDate)
                .dayOfWeek(3)
                .slotNumber(4)
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        // Cố tình xếp TS. Nam dạy lớp 2 tại Room B vào cùng Tiết 4
        TimetableSlotCreateRequest req = TimetableSlotCreateRequest.builder()
                .className(classSection2.getClassName()) // same lecturer Nam
                .roomId(roomB.getId()) // different room B
                .date(studyDate)
                .slotNumber(4)
                .build();

        mockMvc.perform(post("/api/v1/timetable/slots")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_6004")));
    }

    // =========================================================================
    // Test 4: Class Collision Detection (ERR_6005)
    // =========================================================================

    @Test
    @DisplayName("4. Phát hiện xung đột trùng lịch một lớp học phần (ERR_6005)")
    void testCreateTimetableSlot_ClassScheduleConflict() throws Exception {
        LocalDate studyDate = LocalDate.of(2026, 10, 16);

        // Lớp 1 đã có lịch học Tiết 7
        timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection1)
                .room(roomA)
                .date(studyDate)
                .dayOfWeek(5)
                .slotNumber(7)
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        // Cố tình xếp lớp 1 học tiếp ở phòng khác cùng Tiết 7
        TimetableSlotCreateRequest req = TimetableSlotCreateRequest.builder()
                .className(classSection1.getClassName())
                .roomId(roomB.getId())
                .date(studyDate)
                .slotNumber(7)
                .build();

        mockMvc.perform(post("/api/v1/timetable/slots")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_6005")));
    }

    // =========================================================================
    // Test 5: Date Outside Semester (ERR_6006)
    // =========================================================================

    @Test
    @DisplayName("5. Kiểm tra ngày học nằm ngoài học kỳ bị chặn (ERR_6006)")
    void testCreateTimetableSlot_DateOutsideSemester() throws Exception {
        LocalDate pastDate = LocalDate.of(2026, 8, 15); // Before semester startDate (2026-09-01)

        TimetableSlotCreateRequest req = TimetableSlotCreateRequest.builder()
                .className(classSection1.getClassName())
                .roomId(roomA.getId())
                .date(pastDate)
                .slotNumber(1)
                .build();

        mockMvc.perform(post("/api/v1/timetable/slots")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_6006")));
    }

    // =========================================================================
    // Test 6: Holiday Rule (ERR_6007)
    // =========================================================================

    @Test
    @DisplayName("6. Kiểm tra quy tắc ngày nghỉ lễ bị chặn (ERR_6007)")
    void testCreateTimetableSlot_DateOnHoliday() throws Exception {
        LocalDate holiday = LocalDate.of(2026, 9, 2); // Quốc khánh 2/9

        TimetableSlotCreateRequest req = TimetableSlotCreateRequest.builder()
                .className(classSection1.getClassName())
                .roomId(roomA.getId())
                .date(holiday)
                .slotNumber(1)
                .build();

        mockMvc.perform(post("/api/v1/timetable/slots")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_6007")));
    }

    // =========================================================================
    // Test 7: Room Capacity Insufficient (ERR_6008)
    // =========================================================================

    @Test
    @DisplayName("7. Kiểm tra phòng học không đủ sức chứa cho sĩ số lớp học phần (ERR_6008)")
    void testCreateTimetableSlot_RoomCapacityInsufficient() throws Exception {
        LocalDate studyDate = LocalDate.of(2026, 10, 20);

        // classSection1 has 35 students enrolled, smallRoom capacity is 10
        TimetableSlotCreateRequest req = TimetableSlotCreateRequest.builder()
                .className(classSection1.getClassName())
                .roomId(smallRoom.getId())
                .date(studyDate)
                .slotNumber(1)
                .build();

        mockMvc.perform(post("/api/v1/timetable/slots")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_6008")));
    }

    // =========================================================================
    // Test 8: Room Not Available (ERR_6009)
    // =========================================================================

    @Test
    @DisplayName("8. Kiểm tra phòng học ở trạng thái bảo trì hoặc ngưng hoạt động bị chặn (ERR_6009)")
    void testCreateTimetableSlot_RoomNotAvailable() throws Exception {
        Room maintRoom = roomRepository.save(Room.builder()
                .code("P-MAINT")
                .name("Phòng bảo trì")
                .capacity(50)
                .status(RoomStatus.MAINTENANCE)
                .build());

        LocalDate studyDate = LocalDate.of(2026, 10, 20);

        TimetableSlotCreateRequest req = TimetableSlotCreateRequest.builder()
                .className(classSection1.getClassName())
                .roomId(maintRoom.getId())
                .date(studyDate)
                .slotNumber(1)
                .build();

        mockMvc.perform(post("/api/v1/timetable/slots")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_6009")));
    }

    // =========================================================================
    // Test 9: Update Slot & Attendance Session Safeguard (ERR_6010)
    // =========================================================================

    @Test
    @DisplayName("9. Không cho thay đổi hoặc xóa lịch đã có phiên điểm danh phát sinh (ERR_6010)")
    void testAttendanceSessionDependencySafeguard() throws Exception {
        LocalDate studyDate = LocalDate.of(2026, 10, 22);

        TimetableSlot slot = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection1)
                .room(roomA)
                .date(studyDate)
                .dayOfWeek(4)
                .slotNumber(1)
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        // Simulate an attendance session opened for this slot
        jdbcTemplate.update(
                "INSERT INTO attendance_sessions (timetable_slot_id, lecturer_id, opened_at, status) VALUES (?, ?, CURRENT_TIMESTAMP, 'OPEN')",
                slot.getId(), lecturer.getId()
        );

        // 1. Thử thay đổi ngày học -> Bị chặn với ERR_6010
        TimetableSlotUpdateRequest updateReq = TimetableSlotUpdateRequest.builder()
                .date(LocalDate.of(2026, 10, 23))
                .build();

        mockMvc.perform(put("/api/v1/timetable/slots/" + slot.getId())
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_6010")));

        // 2. Thử xóa lịch học -> Bị chặn với ERR_6010
        mockMvc.perform(delete("/api/v1/timetable/slots/" + slot.getId())
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_6010")));
    }

    // =========================================================================
    // Test 10: RBAC Enforcement
    // =========================================================================

    @Test
    @DisplayName("10. Kiểm tra phân quyền RBAC: Giảng viên và Sinh viên không được phép tạo/sửa/xóa lịch")
    void testRBAC_Restrictions() throws Exception {
        LocalDate studyDate = LocalDate.of(2026, 10, 26);

        TimetableSlotCreateRequest req = TimetableSlotCreateRequest.builder()
                .className(classSection1.getClassName())
                .roomId(roomA.getId())
                .date(studyDate)
                .slotNumber(1)
                .build();

        // 1. Giảng viên gọi POST /slots -> 403 Forbidden
        mockMvc.perform(post("/api/v1/timetable/slots")
                        .header("Authorization", "Bearer " + lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isForbidden());

        // 2. Sinh viên gọi POST /slots -> 403 Forbidden
        mockMvc.perform(post("/api/v1/timetable/slots")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isForbidden());
    }

    // =========================================================================
    // Test 11: Personal Timetable (/me) for Student & Lecturer
    // =========================================================================

    @Test
    @DisplayName("11. Sinh viên và Giảng viên xem thời khóa biểu cá nhân của chính mình (/me)")
    void testGetMyTimetable() throws Exception {
        LocalDate studyDate = LocalDate.of(2026, 10, 27);

        // Slot 1: Lớp 1 (Giảng viên Nam, Sinh viên Đạt đã ghi danh)
        timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection1)
                .room(roomA)
                .date(studyDate)
                .dayOfWeek(2)
                .slotNumber(1)
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        // Slot 2: Lớp 2 (Giảng viên Nam, Sinh viên Đạt CHƯA ghi danh)
        timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection2)
                .room(roomB)
                .date(studyDate)
                .dayOfWeek(2)
                .slotNumber(4)
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        // Sinh viên gọi /me -> chỉ thấy Slot 1 (lớp IT301.01)
        mockMvc.perform(get("/api/v1/timetable/me")
                        .header("Authorization", "Bearer " + studentToken)
                        .param("startDate", "2026-10-26")
                        .param("endDate", "2026-10-31"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].className", is("IT301.01")));

        // Giảng viên Nam gọi /me -> thấy cả Slot 1 và Slot 2
        mockMvc.perform(get("/api/v1/timetable/me")
                        .header("Authorization", "Bearer " + lecturerToken)
                        .param("startDate", "2026-10-26")
                        .param("endDate", "2026-10-31"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", hasSize(2)));
    }

    // =========================================================================
    // Test 12: Real-time Pre-flight Conflict Check API
    // =========================================================================

    @Test
    @DisplayName("12. Kiểm tra API kiểm tra xung đột thời gian thực (/conflicts/check)")
    void testCheckConflictApi() throws Exception {
        LocalDate studyDate = LocalDate.of(2026, 11, 2);

        timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection1)
                .room(roomA)
                .date(studyDate)
                .dayOfWeek(1)
                .slotNumber(1)
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        TimetableConflictCheckRequest req = TimetableConflictCheckRequest.builder()
                .className(classSection2.getClassName())
                .roomId(roomA.getId()) // room A conflict
                .date(studyDate)
                .slotNumber(1)
                .build();

        mockMvc.perform(post("/api/v1/timetable/conflicts/check")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.hasConflict", is(true)))
                .andExpect(jsonPath("$.data.conflictType", is("ROOM_CONFLICT")));
    }

    // =========================================================================
    // Test 13: KPI Stats & Slot Types
    // =========================================================================

    @Test
    @DisplayName("13. Lấy thống kê KPI và danh mục ca học (Slot Types) thành công")
    void testSlotTypesAndStats() throws Exception {
        mockMvc.perform(get("/api/v1/timetable/slot-types")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("semesterId", String.valueOf(semester.getId())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", hasSize(greaterThanOrEqualTo(1))));

        mockMvc.perform(get("/api/v1/timetable/stats")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("semesterId", String.valueOf(semester.getId()))
                        .param("weekStartDate", "2026-10-05"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.totalSlotsWeek", notNullValue()))
                .andExpect(jsonPath("$.data.roomUtilizationRate", notNullValue()));
    }

    // =========================================================================
    // Test 14: Enum Compliance and Timetable Slots Query (BUG-02 Regression Test)
    // =========================================================================

    @Test
    @DisplayName("14. Truy vấn danh sách tiết học với các trạng thái hợp lệ (SCHEDULED, COMPLETED, CANCELLED, RESCHEDULED)")
    void testTimetableSlotsWithValidStatuses() throws Exception {
        LocalDate baseDate = LocalDate.of(2026, 11, 9);

        // 1. SCHEDULED slot (trước đây từng bị nhầm thành IN_PROGRESS gây lỗi 500 BUG-02)
        timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection1)
                .room(roomA)
                .date(baseDate)
                .dayOfWeek(1)
                .slotNumber(1)
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        // 2. COMPLETED slot
        timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection1)
                .room(roomA)
                .date(baseDate.plusDays(1))
                .dayOfWeek(2)
                .slotNumber(2)
                .status(TimetableSlotStatus.COMPLETED)
                .build());

        // 3. CANCELLED slot
        timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection1)
                .room(roomA)
                .date(baseDate.plusDays(2))
                .dayOfWeek(3)
                .slotNumber(3)
                .status(TimetableSlotStatus.CANCELLED)
                .build());

        // 4. RESCHEDULED slot
        timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection1)
                .room(roomA)
                .date(baseDate.plusDays(3))
                .dayOfWeek(4)
                .slotNumber(4)
                .status(TimetableSlotStatus.RESCHEDULED)
                .build());

        // Truy vấn tất cả các slots trong tuần: Phải trả về HTTP 200, không bị lỗi 500 do enum mismatch
        mockMvc.perform(get("/api/v1/timetable/slots")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("startDate", "2026-11-09")
                        .param("endDate", "2026-11-15"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", hasSize(4)))
                .andExpect(jsonPath("$.data[?(@.status == 'SCHEDULED')]", hasSize(1)))
                .andExpect(jsonPath("$.data[?(@.status == 'COMPLETED')]", hasSize(1)))
                .andExpect(jsonPath("$.data[?(@.status == 'CANCELLED')]", hasSize(1)))
                .andExpect(jsonPath("$.data[?(@.status == 'RESCHEDULED')]", hasSize(1)));

        // Lọc theo status=SCHEDULED
        mockMvc.perform(get("/api/v1/timetable/slots")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("startDate", "2026-11-09")
                        .param("endDate", "2026-11-15")
                        .param("status", "SCHEDULED"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].status", is("SCHEDULED")));
    }
}

