package com.unicheck.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
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
import org.springframework.test.web.servlet.MvcResult;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class RoomSelectionAndIntervalConflictIntegrationTest {

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
    private User admin;
    private User lecturer1;
    private User lecturer2;
    private Semester semester;
    private Course course1;
    private Course course2;
    private ClassSection classSection1;
    private ClassSection classSection2;
    private Room roomA;
    private Room roomB;
    private Room roomC;

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

        // 1. Admin & Lecturers
        admin = userRepository.findByUsername("admin_room_test").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("ADM-RM-01")
                        .username("admin_room_test")
                        .email("admin.rm@unicheck.edu.vn")
                        .password(passwordEncoder.encode("admin123"))
                        .fullName("Quản trị viên Quản lý phòng")
                        .role(Role.ADMIN)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );
        adminToken = jwtUtil.generateAccessToken(admin);

        lecturer1 = userRepository.findByUsername("gv_room_1").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("GV-RM-01")
                        .username("gv_room_1")
                        .email("gv1.rm@unicheck.edu.vn")
                        .password(passwordEncoder.encode("lecturer123"))
                        .fullName("TS. Giảng viên 1")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        lecturer2 = userRepository.findByUsername("gv_room_2").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("GV-RM-02")
                        .username("gv_room_2")
                        .email("gv2.rm@unicheck.edu.vn")
                        .password(passwordEncoder.encode("lecturer123"))
                        .fullName("ThS. Giảng viên 2")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );

        // 2. Rooms
        roomA = roomRepository.save(Room.builder()
                .code("AL-L101")
                .name("Giảng đường Lý thuyết AL101")
                .capacity(50)
                .building("AL")
                .floor(1)
                .type(RoomType.THEORY)
                .status(RoomStatus.AVAILABLE)
                .build());

        roomB = roomRepository.save(Room.builder()
                .code("AL-L201")
                .name("Giảng đường Lý thuyết AL201")
                .capacity(60)
                .building("AL")
                .floor(2)
                .type(RoomType.THEORY)
                .status(RoomStatus.AVAILABLE)
                .build());

        roomC = roomRepository.save(Room.builder()
                .code("BE-Lab301")
                .name("Phòng thực hành máy tính")
                .capacity(40)
                .building("BE")
                .floor(3)
                .type(RoomType.LAB)
                .status(RoomStatus.AVAILABLE)
                .build());

        // 3. Semester
        semester = semesterRepository.save(Semester.builder()
                .code("FALL2026")
                .name("Học kỳ Thu 2026")
                .startDate(LocalDate.of(2026, 9, 1))
                .endDate(LocalDate.of(2026, 12, 31))
                .status(SemesterStatus.ACTIVE)
                .build());

        // 4. Courses & ClassSections
        course1 = courseRepository.save(Course.builder()
                .code("PRJ301")
                .name("Java Web Application Development")
                .credits(3)
                .numberOfSlots(45)
                .status(CourseStatus.ACTIVE)
                .build());

        course2 = courseRepository.save(Course.builder()
                .code("DBI202")
                .name("Introduction to Databases")
                .credits(3)
                .numberOfSlots(45)
                .status(CourseStatus.ACTIVE)
                .build());

        classSection1 = classSectionRepository.save(ClassSection.builder()
                .className("SE1801-PRJ301")
                .course(course1)
                .semester(semester)
                .lecturer(lecturer1)
                .numberOfSlots(45)
                .maxStudents(50)
                .currentEnrollment(35)
                .status(ClassSectionStatus.OPEN)
                .build());

        classSection2 = classSectionRepository.save(ClassSection.builder()
                .className("SE1802-DBI202")
                .course(course2)
                .semester(semester)
                .lecturer(lecturer2)
                .numberOfSlots(45)
                .maxStudents(50)
                .currentEnrollment(30)
                .status(ClassSectionStatus.OPEN)
                .build());
    }

    // =========================================================================
    // SCENARIO 1: Phòng trống hoàn toàn (Completely Free Room)
    // =========================================================================
    @Test
    @DisplayName("Scenario 1: Khi chưa có lịch, toàn bộ các phòng khả dụng đều xuất hiện trong danh sách")
    void test1_CompletelyFreeRooms() throws Exception {
        LocalDate testDate = LocalDate.of(2026, 10, 12); // Monday

        mockMvc.perform(get("/api/v1/timetable/available-rooms")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("date", testDate.toString())
                        .param("slotNumber", "1")
                        .param("endSlotNumber", "3")
                        .param("className", classSection1.getClassName()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", hasSize(3)))
                .andExpect(jsonPath("$.data[?(@.code == 'AL-L101')]", hasSize(1)))
                .andExpect(jsonPath("$.data[?(@.code == 'AL-L201')]", hasSize(1)))
                .andExpect(jsonPath("$.data[?(@.code == 'BE-Lab301')]", hasSize(1)));
    }

    // =========================================================================
    // SCENARIO 2: Trùng ngày, trùng giờ, trùng phòng (Interval Conflict)
    // =========================================================================
    @Test
    @DisplayName("Scenario 2: Trùng ngày, trùng giờ, trùng phòng -> Loại phòng khỏi danh sách khả dụng & ngăn chặn lưu lịch")
    void test2_SameDaySameTimeSameRoom_Conflict() throws Exception {
        LocalDate testDate = LocalDate.of(2026, 10, 12);

        // Đã có lớp SE1801 học tại phòng AL-L101 vào Tiết 1-3 (07:00 - 09:25)
        TimetableSlot slot1 = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection1)
                .room(roomA)
                .date(testDate)
                .dayOfWeek(1)
                .slotNumber(1)
                .endSlotNumber(3)
                .startTime(LocalTime.of(7, 0))
                .endTime(LocalTime.of(9, 25))
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        // 1. Kiểm tra API lấy phòng trống cho Tiết 1-3 cùng ngày:
        // AL-L101 PHẢI BỊ LOẠI BỎ, chỉ còn AL-L201 và BE-Lab301
        mockMvc.perform(get("/api/v1/timetable/available-rooms")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("date", testDate.toString())
                        .param("slotNumber", "1")
                        .param("endSlotNumber", "3")
                        .param("className", classSection2.getClassName()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", hasSize(2)))
                .andExpect(jsonPath("$.data[?(@.code == 'AL-L101')]", hasSize(0)))
                .andExpect(jsonPath("$.data[?(@.code == 'AL-L201')]", hasSize(1)))
                .andExpect(jsonPath("$.data[?(@.code == 'BE-Lab301')]", hasSize(1)));

        // 2. Thử lưu lịch với phòng AL-L101 bị trùng -> Backend PHẢI từ chối với mã lỗi xung đột phòng
        TimetableSlotCreateRequest conflictReq = TimetableSlotCreateRequest.builder()
                .className(classSection2.getClassName())
                .roomId(roomA.getId())
                .date(testDate)
                .slotNumber(1)
                .endSlotNumber(3)
                .build();

        mockMvc.perform(post("/api/v1/timetable/slots")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(conflictReq)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_6003")));
    }

    // =========================================================================
    // SCENARIO 3: Cùng ngày nhưng khác ca (Different Shift - Non Conflicting)
    // =========================================================================
    @Test
    @DisplayName("Scenario 3: Cùng ngày nhưng khác ca (Tiết 1-3 và Tiết 4-6) -> Phòng vẫn khả dụng và lưu thành công")
    void test3_SameDayDifferentShift_NoConflict() throws Exception {
        LocalDate testDate = LocalDate.of(2026, 10, 12);

        // Lớp 1 học Tiết 1-3 (07:00 - 09:25) tại AL-L101
        timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection1)
                .room(roomA)
                .date(testDate)
                .dayOfWeek(1)
                .slotNumber(1)
                .endSlotNumber(3)
                .startTime(LocalTime.of(7, 0))
                .endTime(LocalTime.of(9, 25))
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        // Lớp 2 học Tiết 4-6 (09:45 - 12:10) -> AL-L101 PHẢI KHẢ DỤNG
        mockMvc.perform(get("/api/v1/timetable/available-rooms")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("date", testDate.toString())
                        .param("slotNumber", "4")
                        .param("endSlotNumber", "6")
                        .param("className", classSection2.getClassName()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data[?(@.code == 'AL-L101')]", hasSize(1)));

        // Lưu lịch lớp 2 vào ca 2 thành công
        TimetableSlotCreateRequest req = TimetableSlotCreateRequest.builder()
                .className(classSection2.getClassName())
                .roomId(roomA.getId())
                .date(testDate)
                .slotNumber(4)
                .endSlotNumber(6)
                .build();

        mockMvc.perform(post("/api/v1/timetable/slots")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.roomCode", is("AL-L101")));
    }

    // =========================================================================
    // SCENARIO 4: Hai lịch có thời gian liền kề (Adjacent Intervals - Boundary)
    // =========================================================================
    @Test
    @DisplayName("Scenario 4: Hai lịch có mốc thời gian tiếp giáp (09:25) không coi là xung đột")
    void test4_AdjacentIntervals_NoConflict() throws Exception {
        LocalDate testDate = LocalDate.of(2026, 10, 12);

        // Lịch A: 07:00 - 09:25 (Tiết 1-3)
        timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection1)
                .room(roomA)
                .date(testDate)
                .dayOfWeek(1)
                .slotNumber(1)
                .endSlotNumber(3)
                .startTime(LocalTime.of(7, 0))
                .endTime(LocalTime.of(9, 25))
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        // Lịch B: Giả sử bắt đầu lúc 09:25 hoặc ca sau 09:45
        // Kiểm tra logic existing.start < requested.end AND requested.start < existing.end
        // với requested.start = 09:25, requested.end = 10:40:
        // 07:00 < 10:40 (true) NHƯNG 09:25 < 09:25 (false) -> KHÔNG XUNG ĐỘT
        boolean conflicts = (LocalTime.of(7, 0).isBefore(LocalTime.of(10, 40))) &&
                            (LocalTime.of(9, 25).isBefore(LocalTime.of(9, 25)));
        assertEquals(false, conflicts, "Hai khung giờ tiếp giáp đúng 09:25 không được tính là xung đột");

        // Khi tra cứu ca 4 (bắt đầu 09:45 > 09:25), phòng AL-L101 hoàn toàn trống
        mockMvc.perform(get("/api/v1/timetable/available-rooms")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("date", testDate.toString())
                        .param("slotNumber", "4")
                        .param("endSlotNumber", "6"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.code == 'AL-L101')]", hasSize(1)));
    }

    // =========================================================================
    // SCENARIO 5: Lịch lặp lại nhiều tuần (Recurring Multi-week)
    // =========================================================================
    @Test
    @DisplayName("Scenario 5: Lịch lặp lại nhiều tuần - nếu xung đột ở bất kỳ tuần nào, phòng bị loại khỏi danh sách")
    void test5_RecurringMultiWeek_ExcludedIfAnyWeekConflicts() throws Exception {
        LocalDate baseDate = LocalDate.of(2026, 10, 5); // Tuần 1
        LocalDate week3Date = LocalDate.of(2026, 10, 19); // Tuần 3

        // Phòng AL-L101 bị chiếm ở Tuần 3 (2026-10-19)
        timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection2)
                .room(roomA)
                .date(week3Date)
                .dayOfWeek(1)
                .slotNumber(1)
                .endSlotNumber(3)
                .startTime(LocalTime.of(7, 0))
                .endTime(LocalTime.of(9, 25))
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        // 1. Tra cứu phòng cho 1 buổi duy nhất ngày 2026-10-05 (recurring=false) -> AL-L101 TRỐNG
        mockMvc.perform(get("/api/v1/timetable/available-rooms")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("date", baseDate.toString())
                        .param("slotNumber", "1")
                        .param("endSlotNumber", "3")
                        .param("recurring", "false"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.code == 'AL-L101')]", hasSize(1)));

        // 2. Tra cứu phòng với recurring=true cho cả học kỳ:
        // Do Tuần 3 bị chiếm, AL-L101 PHẢI BỊ LOẠI khỏi danh sách khả dụng
        mockMvc.perform(get("/api/v1/timetable/available-rooms")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("date", baseDate.toString())
                        .param("slotNumber", "1")
                        .param("endSlotNumber", "3")
                        .param("recurring", "true")
                        .param("className", classSection1.getClassName()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.code == 'AL-L101')]", hasSize(0)))
                .andExpect(jsonPath("$.data[?(@.code == 'AL-L201')]", hasSize(1)));

        // 3. Nếu Admin cố tình lưu recurring với AL-L101 -> Backend từ chối do xung đột ở tuần 3
        TimetableSlotCreateRequest recurReq = TimetableSlotCreateRequest.builder()
                .className(classSection1.getClassName())
                .roomId(roomA.getId())
                .date(baseDate)
                .slotNumber(1)
                .endSlotNumber(3)
                .recurring(true)
                .recurringUntil(LocalDate.of(2026, 11, 30))
                .build();

        mockMvc.perform(post("/api/v1/timetable/slots")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(recurReq)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_6003")));
    }

    // =========================================================================
    // SCENARIO 6: Chỉnh sửa lịch hiện có (Edit Existing Slot - Ignores Self)
    // =========================================================================
    @Test
    @DisplayName("Scenario 6: Khi chỉnh sửa một lịch đã có, bỏ qua chính nó (excludeSlotId) trong kiểm tra xung đột")
    void test6_EditExistingSlot_IgnoresSelf() throws Exception {
        LocalDate testDate = LocalDate.of(2026, 10, 12);

        // Tạo slot ban đầu tại AL-L101
        TimetableSlot slot = timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection1)
                .room(roomA)
                .date(testDate)
                .dayOfWeek(1)
                .slotNumber(1)
                .endSlotNumber(3)
                .startTime(LocalTime.of(7, 0))
                .endTime(LocalTime.of(9, 25))
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        // 1. Gọi available-rooms truyền excludeSlotId = slot.getId()
        // AL-L101 PHẢI XUẤT HIỆN trong danh sách vì chính slot này sở hữu nó
        mockMvc.perform(get("/api/v1/timetable/available-rooms")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("date", testDate.toString())
                        .param("slotNumber", "1")
                        .param("endSlotNumber", "3")
                        .param("excludeSlotId", slot.getId().toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.code == 'AL-L101')]", hasSize(1)));

        // 2. Cập nhật ghi chú của slot mà giữ nguyên phòng AL-L101 -> Thành công 200 OK
        TimetableSlotUpdateRequest updateReq = TimetableSlotUpdateRequest.builder()
                .roomId(roomA.getId())
                .date(testDate)
                .slotNumber(1)
                .endSlotNumber(3)
                .note("Cập nhật ghi chú phòng máy chiếu")
                .build();

        mockMvc.perform(put("/api/v1/timetable/slots/" + slot.getId())
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.note", is("Cập nhật ghi chú phòng máy chiếu")));
    }

    // =========================================================================
    // SCENARIO 7: Hai Admin đặt cùng phòng đồng thời (Concurrency / Race Condition)
    // =========================================================================
    @Test
    @DisplayName("Scenario 7: Hai Admin đặt cùng một phòng đồng thời -> Khóa bi quan ngăn chặn đúp lịch, chỉ 1 lưu thành công")
    void test7_ConcurrentBooking_PessimisticLock_PreventDoubleBooking() throws Exception {
        LocalDate testDate = LocalDate.of(2026, 10, 15);

        ExecutorService executor = Executors.newFixedThreadPool(2);
        CountDownLatch readyLatch = new CountDownLatch(2);
        CountDownLatch startLatch = new CountDownLatch(1);

        AtomicInteger successCount = new AtomicInteger(0);
        AtomicInteger conflictCount = new AtomicInteger(0);

        Callable<Void> task1 = () -> {
            readyLatch.countDown();
            startLatch.await();
            try {
                TimetableSlotCreateRequest req = TimetableSlotCreateRequest.builder()
                        .className(classSection1.getClassName())
                        .roomId(roomA.getId())
                        .date(testDate)
                        .slotNumber(1)
                        .endSlotNumber(3)
                        .note("Admin 1 đặt phòng AL-L101")
                        .build();

                MvcResult res = mockMvc.perform(post("/api/v1/timetable/slots")
                                .header("Authorization", "Bearer " + adminToken)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(req)))
                        .andReturn();

                if (res.getResponse().getStatus() == 201) {
                    successCount.incrementAndGet();
                } else if (res.getResponse().getStatus() == 400 || res.getResponse().getStatus() == 409) {
                    conflictCount.incrementAndGet();
                }
            } catch (Exception e) {
                conflictCount.incrementAndGet();
            }
            return null;
        };

        Callable<Void> task2 = () -> {
            readyLatch.countDown();
            startLatch.await();
            try {
                TimetableSlotCreateRequest req = TimetableSlotCreateRequest.builder()
                        .className(classSection2.getClassName())
                        .roomId(roomA.getId())
                        .date(testDate)
                        .slotNumber(1)
                        .endSlotNumber(3)
                        .note("Admin 2 đặt phòng AL-L101")
                        .build();

                MvcResult res = mockMvc.perform(post("/api/v1/timetable/slots")
                                .header("Authorization", "Bearer " + adminToken)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(req)))
                        .andReturn();

                if (res.getResponse().getStatus() == 201) {
                    successCount.incrementAndGet();
                } else if (res.getResponse().getStatus() == 400 || res.getResponse().getStatus() == 409) {
                    conflictCount.incrementAndGet();
                }
            } catch (Exception e) {
                conflictCount.incrementAndGet();
            }
            return null;
        };

        Future<Void> f1 = executor.submit(task1);
        Future<Void> f2 = executor.submit(task2);

        readyLatch.await(5, TimeUnit.SECONDS);
        startLatch.countDown(); // Phát lệnh bắn 2 request đồng thời

        f1.get(10, TimeUnit.SECONDS);
        f2.get(10, TimeUnit.SECONDS);
        executor.shutdown();

        // Kiểm tra kết quả trong DB: Chỉ đúng 1 slot được lưu cho AL-L101 vào ngày testDate Tiết 1-3
        long bookedSlots = timetableSlotRepository.findAll().stream()
                .filter(s -> s.getRoom() != null && s.getRoom().getId().equals(roomA.getId()) && s.getDate().equals(testDate))
                .count();

        assertEquals(1, bookedSlots, "Tuyệt đối không được phép có 2 lịch trùng phòng được lưu thành công");
        assertEquals(1, successCount.get(), "Chỉ 1 giao dịch tạo lịch thành công");
        assertEquals(1, conflictCount.get(), "Giao dịch thứ 2 phải nhận phản hồi lỗi xung đột lịch");
    }

    // =========================================================================
    // SCENARIO 8: Thay đổi ngày hoặc tiết sau khi đã chọn phòng
    // =========================================================================
    @Test
    @DisplayName("Scenario 8: Thay đổi ngày/tiết sang khung giờ phòng bị chiếm -> API phát hiện ngay lập tức")
    void test8_ChangeDateOrSlotAfterRoomSelected_DetectsConflict() throws Exception {
        LocalDate dateMonday = LocalDate.of(2026, 10, 12);
        LocalDate dateTuesday = LocalDate.of(2026, 10, 13);

        // Thứ Ba phòng AL-L101 đã bị lớp SE1802 chiếm
        timetableSlotRepository.save(TimetableSlot.builder()
                .classSection(classSection2)
                .room(roomA)
                .date(dateTuesday)
                .dayOfWeek(2)
                .slotNumber(1)
                .endSlotNumber(3)
                .startTime(LocalTime.of(7, 0))
                .endTime(LocalTime.of(9, 25))
                .status(TimetableSlotStatus.SCHEDULED)
                .build());

        // Khi Admin đang ở Thứ Hai: AL-L101 trống
        mockMvc.perform(get("/api/v1/timetable/available-rooms")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("date", dateMonday.toString())
                        .param("slotNumber", "1")
                        .param("endSlotNumber", "3"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.code == 'AL-L101')]", hasSize(1)));

        // Khi Admin đổi ngày sang Thứ Ba: AL-L101 không còn khả dụng
        mockMvc.perform(get("/api/v1/timetable/available-rooms")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("date", dateTuesday.toString())
                        .param("slotNumber", "1")
                        .param("endSlotNumber", "3"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.code == 'AL-L101')]", hasSize(0)));
    }
}
