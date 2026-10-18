package com.unicheck.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.model.dto.*;
import com.unicheck.model.entity.Room;
import com.unicheck.model.entity.User;
import com.unicheck.model.entity.WifiAccessPoint;
import com.unicheck.model.enums.Role;
import com.unicheck.model.enums.RoomStatus;
import com.unicheck.model.enums.RoomType;
import com.unicheck.model.enums.UserStatus;
import com.unicheck.model.enums.WifiApStatus;
import com.unicheck.repository.RoomRepository;
import com.unicheck.repository.RoomWifiAccessPointRepository;
import com.unicheck.repository.UserRepository;
import com.unicheck.repository.WifiAccessPointRepository;
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

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.unicheck.model.entity.ClassSection;
import com.unicheck.model.entity.Course;
import com.unicheck.model.entity.Semester;
import com.unicheck.model.enums.ClassSectionStatus;
import com.unicheck.model.enums.CourseStatus;
import com.unicheck.model.enums.SemesterStatus;
import com.unicheck.repository.ClassSectionRepository;
import com.unicheck.repository.CourseRepository;
import com.unicheck.repository.SemesterRepository;
import java.time.LocalDate;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class FacilityIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private RoomRepository roomRepository;

    @Autowired
    private WifiAccessPointRepository wifiAccessPointRepository;

    @Autowired
    private RoomWifiAccessPointRepository roomWifiAccessPointRepository;

    @Autowired
    private CourseRepository courseRepository;

    @Autowired
    private SemesterRepository semesterRepository;

    @Autowired
    private ClassSectionRepository classSectionRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private String adminToken;
    private String lecturerToken;
    private String studentToken;

    private User admin;
    private User lecturer;
    private User student;

    @BeforeEach
    void setUp() {
        // Clear child mappings first, then parent tables
        jdbcTemplate.execute("DELETE FROM timetable_slots WHERE 1=1");
        classSectionRepository.deleteAll();
        courseRepository.deleteAll();
        semesterRepository.deleteAll();
        roomWifiAccessPointRepository.deleteAll();
        roomRepository.deleteAll();
        wifiAccessPointRepository.deleteAll();

        admin = userRepository.findByUsername("admin_facility_test").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("ADM-FAC-01")
                        .username("admin_facility_test")
                        .email("admin.facility@unicheck.edu.vn")
                        .password(passwordEncoder.encode("admin123"))
                        .fullName("Quản trị viên Cơ sở vật chất")
                        .role(Role.ADMIN)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );
        adminToken = jwtUtil.generateAccessToken(admin);

        lecturer = userRepository.findByUsername("lecturer_facility_test").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("GV-FAC-01")
                        .username("lecturer_facility_test")
                        .email("lecturer.facility@unicheck.edu.vn")
                        .password(passwordEncoder.encode("lecturer123"))
                        .fullName("TS. Giảng Viên Test")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );
        lecturerToken = jwtUtil.generateAccessToken(lecturer);

        student = userRepository.findByUsername("student_facility_test").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("SV-FAC-01")
                        .username("student_facility_test")
                        .email("student.facility@unicheck.edu.vn")
                        .password(passwordEncoder.encode("student123"))
                        .fullName("Sinh Viên Facility Test")
                        .role(Role.STUDENT)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );
        studentToken = jwtUtil.generateAccessToken(student);
    }

    // =========================================================================
    // 1. Classrooms (Rooms) Tests
    // =========================================================================

    @Test
    @DisplayName("1.1. Tạo phòng học thành công - ADMIN 201 Created")
    void testCreateRoom_Success() throws Exception {
        RoomCreateRequest request = RoomCreateRequest.builder()
                .code("C3-102")
                .name("Hội trường C3-102")
                .capacity(150)
                .building("Tòa C")
                .floor(1)
                .type(RoomType.AUDITORIUM)
                .status(RoomStatus.AVAILABLE)
                .description("Hội trường lớn âm thanh vòm")
                .build();

        mockMvc.perform(post("/api/v1/facilities/rooms")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.code").value("C3-102"))
                .andExpect(jsonPath("$.data.name").value("Hội trường C3-102"))
                .andExpect(jsonPath("$.data.capacity").value(150))
                .andExpect(jsonPath("$.data.type").value("AUDITORIUM"))
                .andExpect(jsonPath("$.data.status").value("AVAILABLE"));
    }

    @Test
    @DisplayName("1.2. Tạo phòng học thất bại khi trùng mã phòng - 409 Conflict")
    void testCreateRoom_DuplicateCode() throws Exception {
        roomRepository.save(Room.builder()
                .code("A2-304")
                .name("Phòng A2-304")
                .capacity(70)
                .type(RoomType.THEORY)
                .status(RoomStatus.AVAILABLE)
                .build());

        RoomCreateRequest duplicate = RoomCreateRequest.builder()
                .code("A2-304")
                .name("Phòng A2-304 Trùng")
                .capacity(80)
                .type(RoomType.THEORY)
                .build();

        mockMvc.perform(post("/api/v1/facilities/rooms")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(duplicate)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_5002"));
    }

    @Test
    @DisplayName("1.3. Lấy danh sách phòng học có phân trang & lọc - 200 OK")
    void testGetRooms_PaginationAndFilters() throws Exception {
        roomRepository.save(Room.builder()
                .code("A1-101").name("Phòng A1-101").capacity(60).building("Tòa A")
                .type(RoomType.THEORY).status(RoomStatus.AVAILABLE).build());
        roomRepository.save(Room.builder()
                .code("B2-201").name("Phòng Lab B2-201").capacity(45).building("Tòa B")
                .type(RoomType.LAB).status(RoomStatus.OCCUPIED).build());
        roomRepository.save(Room.builder()
                .code("C1-301").name("Hội trường C1-301").capacity(200).building("Tòa C")
                .type(RoomType.AUDITORIUM).status(RoomStatus.AVAILABLE).build());

        // Lọc theo building = Tòa B
        mockMvc.perform(get("/api/v1/facilities/rooms")
                        .header("Authorization", "Bearer " + lecturerToken)
                        .param("building", "Tòa B"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content", hasSize(1)))
                .andExpect(jsonPath("$.data.content[0].code").value("B2-201"));

        // Lọc theo search
        mockMvc.perform(get("/api/v1/facilities/rooms")
                        .header("Authorization", "Bearer " + studentToken)
                        .param("search", "Hội trường"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content", hasSize(1)))
                .andExpect(jsonPath("$.data.content[0].code").value("C1-301"));
    }

    @Test
    @DisplayName("1.4. Cập nhật phòng học thành công - 200 OK")
    void testUpdateRoom_Success() throws Exception {
        Room room = roomRepository.save(Room.builder()
                .code("B1-205").name("Phòng B1-205").capacity(50)
                .type(RoomType.THEORY).status(RoomStatus.AVAILABLE).build());

        RoomUpdateRequest updateRequest = RoomUpdateRequest.builder()
                .name("Phòng Lab B1-205 Mới")
                .capacity(55)
                .building("Tòa B")
                .type(RoomType.LAB)
                .status(RoomStatus.MAINTENANCE)
                .build();

        mockMvc.perform(put("/api/v1/facilities/rooms/" + room.getId())
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.name").value("Phòng Lab B1-205 Mới"))
                .andExpect(jsonPath("$.data.capacity").value(55))
                .andExpect(jsonPath("$.data.type").value("LAB"))
                .andExpect(jsonPath("$.data.status").value("MAINTENANCE"));
    }

    @Test
    @DisplayName("1.5. Xóa phòng học thành công khi không có lịch học - 200 OK")
    void testDeleteRoom_Success() throws Exception {
        Room room = roomRepository.save(Room.builder()
                .code("D1-101").name("Phòng D1-101").capacity(40)
                .type(RoomType.THEORY).status(RoomStatus.AVAILABLE).build());

        mockMvc.perform(delete("/api/v1/facilities/rooms/" + room.getId())
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        mockMvc.perform(get("/api/v1/facilities/rooms/" + room.getId())
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("ERR_5001"));
    }

    @Test
    @DisplayName("1.6. Chặn xóa phòng học khi đang được xếp lịch trong thời khóa biểu - 400 Bad Request")
    void testDeleteRoom_BlockedWhenInUse() throws Exception {
        Room room = roomRepository.save(Room.builder()
                .code("C2-202").name("Phòng C2-202").capacity(70)
                .type(RoomType.THEORY).status(RoomStatus.AVAILABLE).build());

        Course course = courseRepository.save(Course.builder()
                .code("CS999").name("Môn học Test").credits(3).numberOfSlots(45).status(CourseStatus.ACTIVE).build());

        Semester semester = semesterRepository.save(Semester.builder()
                .code("HKTEST").name("Học kỳ Test").startDate(LocalDate.now()).endDate(LocalDate.now().plusMonths(4)).status(SemesterStatus.ACTIVE).build());

        ClassSection classSection = classSectionRepository.save(ClassSection.builder()
                .className("CS999.01").course(course).semester(semester).lecturer(lecturer).numberOfSlots(45).maxStudents(50).currentEnrollment(0).status(ClassSectionStatus.OPEN).build());

        // Chèn 1 ca học vào timetable_slots liên kết với room.getId() và classSection
        jdbcTemplate.update(
                "INSERT INTO timetable_slots (class_name, room_id, date, day_of_week, slot_number, status) " +
                        "VALUES (?, ?, CURRENT_DATE, 2, 1, 'SCHEDULED')",
                classSection.getClassName(),
                room.getId()
        );

        mockMvc.perform(delete("/api/v1/facilities/rooms/" + room.getId())
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_5007"));
    }

    // =========================================================================
    // 2. Wi-Fi Access Points Tests
    // =========================================================================

    @Test
    @DisplayName("2.1. Thêm mới Wi-Fi AP thành công - Chuẩn hóa BSSID uppercase 201 Created")
    void testCreateWifiAp_Success() throws Exception {
        WifiAccessPointCreateRequest request = WifiAccessPointCreateRequest.builder()
                .ssid("UniCheck_C3_Front")
                .bssid("00-1a-2b-3c-4d-5e") // Gửi dạng gạch ngang, chữ thường
                .name("AP C3 Phía Trước")
                .location("Bục giảng Giảng đường C")
                .status(WifiApStatus.ACTIVE)
                .build();

        mockMvc.perform(post("/api/v1/facilities/wifi-ap")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.ssid").value("UniCheck_C3_Front"))
                .andExpect(jsonPath("$.data.bssid").value("00:1A:2B:3C:4D:5E")) // Đã chuẩn hóa
                .andExpect(jsonPath("$.data.status").value("ACTIVE"));
    }

    @Test
    @DisplayName("2.2. Thêm mới Wi-Fi AP thất bại khi định dạng BSSID sai - 400 Bad Request")
    void testCreateWifiAp_InvalidBssid() throws Exception {
        WifiAccessPointCreateRequest request = WifiAccessPointCreateRequest.builder()
                .ssid("UniCheck_Invalid")
                .bssid("INVALID_MAC_ADDRESS")
                .name("AP Lỗi BSSID")
                .build();

        mockMvc.perform(post("/api/v1/facilities/wifi-ap")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @DisplayName("2.3. Bắt lỗi khi trùng BSSID - 409 Conflict")
    void testCreateWifiAp_DuplicateBssid() throws Exception {
        wifiAccessPointRepository.save(WifiAccessPoint.builder()
                .ssid("UniCheck_AP1")
                .bssid("AA:BB:CC:DD:EE:FF")
                .status(WifiApStatus.ACTIVE)
                .build());

        WifiAccessPointCreateRequest duplicate = WifiAccessPointCreateRequest.builder()
                .ssid("UniCheck_AP2")
                .bssid("aa:bb:cc:dd:ee:ff")
                .name("Trùng MAC")
                .build();

        mockMvc.perform(post("/api/v1/facilities/wifi-ap")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(duplicate)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_5004"));
    }

    // =========================================================================
    // 3. Room - Wi-Fi AP Association Tests
    // =========================================================================

    @Test
    @DisplayName("3.1. Gán Wi-Fi AP vào phòng học thành công - 201 Created")
    void testAssignWifiApToRoom_Success() throws Exception {
        Room room = roomRepository.save(Room.builder()
                .code("A2-301").name("Phòng A2-301").capacity(70)
                .type(RoomType.THEORY).status(RoomStatus.AVAILABLE).build());

        WifiAccessPoint ap = wifiAccessPointRepository.save(WifiAccessPoint.builder()
                .ssid("UniCheck_A2_301")
                .bssid("11:22:33:44:55:66")
                .status(WifiApStatus.ACTIVE)
                .build());

        AssignWifiApRequest assignRequest = AssignWifiApRequest.builder()
                .wifiAccessPointId(ap.getId())
                .signalStrength(-58)
                .isPrimary(true)
                .positionNote("Gắn trần nhà giữa phòng")
                .build();

        mockMvc.perform(post("/api/v1/facilities/rooms/" + room.getId() + "/wifi-ap")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(assignRequest)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.roomId").value(room.getId()))
                .andExpect(jsonPath("$.data.roomCode").value("A2-301"))
                .andExpect(jsonPath("$.data.bssid").value("11:22:33:44:55:66"))
                .andExpect(jsonPath("$.data.signalStrength").value(-58))
                .andExpect(jsonPath("$.data.isPrimary").value(true));
    }

    @Test
    @DisplayName("3.2. Chặn gán trùng lặp Wi-Fi AP vào cùng một phòng - 409 Conflict")
    void testAssignWifiApToRoom_DuplicateGuard() throws Exception {
        Room room = roomRepository.save(Room.builder()
                .code("A2-302").name("Phòng A2-302").capacity(70)
                .type(RoomType.THEORY).status(RoomStatus.AVAILABLE).build());

        WifiAccessPoint ap = wifiAccessPointRepository.save(WifiAccessPoint.builder()
                .ssid("UniCheck_A2_302")
                .bssid("22:33:44:55:66:77")
                .status(WifiApStatus.ACTIVE)
                .build());

        AssignWifiApRequest assignRequest = AssignWifiApRequest.builder()
                .wifiAccessPointId(ap.getId())
                .signalStrength(-60)
                .build();

        // Gán lần 1 -> 201
        mockMvc.perform(post("/api/v1/facilities/rooms/" + room.getId() + "/wifi-ap")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(assignRequest)))
                .andExpect(status().isCreated());

        // Gán lần 2 trùng lặp -> 409 ROOM_WIFI_ALREADY_LINKED
        mockMvc.perform(post("/api/v1/facilities/rooms/" + room.getId() + "/wifi-ap")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(assignRequest)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_5005"));
    }

    @Test
    @DisplayName("3.3. Hủy gán Wi-Fi AP khỏi phòng học thành công - 200 OK")
    void testUnassignWifiApFromRoom_Success() throws Exception {
        Room room = roomRepository.save(Room.builder()
                .code("A2-303").name("Phòng A2-303").capacity(70)
                .type(RoomType.THEORY).status(RoomStatus.AVAILABLE).build());

        WifiAccessPoint ap = wifiAccessPointRepository.save(WifiAccessPoint.builder()
                .ssid("UniCheck_A2_303")
                .bssid("33:44:55:66:77:88")
                .status(WifiApStatus.ACTIVE)
                .build());

        // Gán vào phòng
        AssignWifiApRequest assignRequest = AssignWifiApRequest.builder()
                .wifiAccessPointId(ap.getId())
                .build();
        mockMvc.perform(post("/api/v1/facilities/rooms/" + room.getId() + "/wifi-ap")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(assignRequest)))
                .andExpect(status().isCreated());

        // Hủy gán
        mockMvc.perform(delete("/api/v1/facilities/rooms/" + room.getId() + "/wifi-ap/" + ap.getId())
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        // Kiểm tra danh sách AP phòng rỗng
        mockMvc.perform(get("/api/v1/facilities/rooms/" + room.getId() + "/wifi-ap")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(0)));
    }

    // =========================================================================
    // 4. RBAC & Security Tests
    // =========================================================================

    @Test
    @DisplayName("4.1. Không truyền Token truy cập API phòng học - 401 Unauthorized")
    void testUnauthenticated_Forbidden() throws Exception {
        mockMvc.perform(get("/api/v1/facilities/rooms"))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(post("/api/v1/facilities/rooms")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("4.2. Giảng viên và Sinh viên không có quyền ghi dữ liệu phòng học - 403 Forbidden")
    void testNonAdmin_WriteForbidden() throws Exception {
        RoomCreateRequest request = RoomCreateRequest.builder()
                .code("X1-101").name("Phòng Hack").capacity(50).type(RoomType.THEORY).build();

        // Giảng viên thử POST
        mockMvc.perform(post("/api/v1/facilities/rooms")
                        .header("Authorization", "Bearer " + lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.errorCode").value("ERR_2001"));

        // Sinh viên thử POST
        mockMvc.perform(post("/api/v1/facilities/rooms")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.errorCode").value("ERR_2001"));
    }

    @Test
    @DisplayName("4.3. KPI Stats Endpoint trả về đầy đủ các chỉ số thống kê - 200 OK")
    void testFacilityStats_Success() throws Exception {
        roomRepository.save(Room.builder().code("R1").name("P1").capacity(100).status(RoomStatus.AVAILABLE).type(RoomType.THEORY).build());
        roomRepository.save(Room.builder().code("R2").name("P2").capacity(50).status(RoomStatus.OCCUPIED).type(RoomType.LAB).build());
        wifiAccessPointRepository.save(WifiAccessPoint.builder().ssid("W1").bssid("11:11:11:11:11:11").status(WifiApStatus.ACTIVE).build());

        mockMvc.perform(get("/api/v1/facilities/rooms/stats")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.totalRooms").value(2))
                .andExpect(jsonPath("$.data.availableRooms").value(1))
                .andExpect(jsonPath("$.data.occupiedRooms").value(1))
                .andExpect(jsonPath("$.data.totalCapacity").value(150))
                .andExpect(jsonPath("$.data.activeWifiAps").value(1));
    }
}
