package com.unicheck.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.model.dto.UserCreateRequest;
import com.unicheck.model.entity.StudentProfile;
import com.unicheck.model.entity.SystemLog;
import com.unicheck.model.entity.User;
import com.unicheck.model.enums.Role;
import com.unicheck.model.enums.UserStatus;
import com.unicheck.repository.StudentProfileRepository;
import com.unicheck.repository.SystemLogRepository;
import com.unicheck.repository.UserRepository;
import com.unicheck.security.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class UserManagementIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private StudentProfileRepository studentProfileRepository;

    @Autowired
    private SystemLogRepository systemLogRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    private User adminUser;
    private User studentUser;
    private String adminToken;
    private String studentToken;

    @BeforeEach
    void setUp() {
        long timestamp = System.currentTimeMillis();

        adminUser = User.builder()
                .code("ADM_" + timestamp)
                .username("admin_" + timestamp)
                .password(passwordEncoder.encode("Admin@123456"))
                .fullName("Quản trị viên Hệ thống")
                .email("admin_" + timestamp + "@unicheck.edu.vn")
                .role(Role.ADMIN)
                .status(UserStatus.ACTIVE)
                .build();
        userRepository.save(adminUser);
        adminToken = jwtUtil.generateAccessToken(adminUser);

        studentUser = User.builder()
                .code("STU_" + timestamp)
                .username("student_" + timestamp)
                .password(passwordEncoder.encode("Student@123456"))
                .fullName("Nguyễn Văn A")
                .email("student_" + timestamp + "@unicheck.edu.vn")
                .role(Role.STUDENT)
                .status(UserStatus.ACTIVE)
                .build();
        userRepository.save(studentUser);
        studentToken = jwtUtil.generateAccessToken(studentUser);
    }

    @Test
    @DisplayName("Chức năng 1: Admin tạo tài khoản sinh viên thành công và ghi Audit Log")
    void testCreateUser_Success_AndAuditLogged() throws Exception {
        long ts = System.currentTimeMillis();
        UserCreateRequest request = UserCreateRequest.builder()
                .code("SV_" + ts)
                .username("sinhvien_" + ts)
                .fullName("Trần Thị Hoa")
                .email("hoa_" + ts + "@unicheck.edu.vn")
                .phone("0987654321")
                .dob(LocalDate.of(2004, 5, 20))
                .sex("FEMALE")
                .role(Role.STUDENT)
                .studentCourse("K19")
                .build();

        mockMvc.perform(post("/api/users")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.username", is(request.getUsername())))
                .andExpect(jsonPath("$.data.code", is(request.getCode())))
                .andExpect(jsonPath("$.data.status", is("INACTIVE")))
                .andExpect(jsonPath("$.data.studentCourse", is("K19")));

        // 1. Kiểm tra User đã lưu trong Database
        User savedUser = userRepository.findByUsername(request.getUsername()).orElse(null);
        assertNotNull(savedUser);
        assertEquals(UserStatus.INACTIVE, savedUser.getStatus());
        assertEquals("FEMALE", savedUser.getSex());

        // 2. Kiểm tra StudentProfile được lưu
        StudentProfile sp = studentProfileRepository.findByUserId(savedUser.getId()).orElse(null);
        assertNotNull(sp);
        assertEquals("K19", sp.getCourse());

        // 3. Kiểm tra Audit Log được ghi lại đầy đủ (ai, lúc nào, làm gì)
        List<SystemLog> logs = systemLogRepository.findByPerformerIdOrderByCreatedAtDesc(adminUser.getId());
        assertFalse(logs.isEmpty());
        SystemLog latestLog = logs.get(0);
        assertEquals("USER_CREATE", latestLog.getAction());
        assertEquals("AUDIT", latestLog.getType());
        assertTrue(latestLog.getDescription().contains(request.getUsername()));
        assertNotNull(latestLog.getCreatedAt());
    }

    @Test
    @DisplayName("Chức năng 1: Tạo tài khoản trùng lặp (username, email, code) trả về lỗi 400 Bad Request")
    void testCreateUser_Duplicate_ThrowsBadRequest() throws Exception {
        long ts = System.currentTimeMillis();
        // Trùng email với adminUser
        UserCreateRequest reqDuplicateEmail = UserCreateRequest.builder()
                .code("NEW_CODE_" + ts)
                .username("new_user_" + ts)
                .fullName("Lê Văn B")
                .email(adminUser.getEmail())
                .role(Role.STUDENT)
                .build();

        mockMvc.perform(post("/api/users")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(reqDuplicateEmail)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode", is("ERR_2011")))
                .andExpect(jsonPath("$.message", containsString("Email")));
    }

    @Test
    @DisplayName("Chức năng 1: Quyền STUDENT không được tạo tài khoản (403 Forbidden)")
    void testCreateUser_ForbiddenForStudent() throws Exception {
        long ts = System.currentTimeMillis();
        UserCreateRequest request = UserCreateRequest.builder()
                .code("TEST_" + ts)
                .username("test_" + ts)
                .fullName("Test User")
                .email("test_" + ts + "@unicheck.edu.vn")
                .role(Role.STUDENT)
                .build();

        mockMvc.perform(post("/api/users")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.errorCode", is("ERR_2001")));
    }

    // =========================================================================
    // CHỨC NĂNG 2: XEM CHI TIẾT & DANH SÁCH TÀI KHOẢN (PHÂN TRANG, TÌM KIẾM, LỌC)
    // =========================================================================

    @Test
    @DisplayName("Chức năng 2a: Admin xem chi tiết tài khoản theo ID thành công")
    void testGetUserById_Success() throws Exception {
        mockMvc.perform(get("/api/users/" + studentUser.getId())
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.id", is(studentUser.getId().intValue())))
                .andExpect(jsonPath("$.data.username", is(studentUser.getUsername())))
                .andExpect(jsonPath("$.data.email", is(studentUser.getEmail())))
                .andExpect(jsonPath("$.data.role", is("STUDENT")));
    }

    @Test
    @DisplayName("Chức năng 2a: Xem tài khoản không tồn tại trả về 404 Not Found")
    void testGetUserById_NotFound() throws Exception {
        mockMvc.perform(get("/api/users/999999")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode", is("ERR_1002")));
    }

    @Test
    @DisplayName("Chức năng 2b: Admin xem danh sách có phân trang, tìm kiếm từ khóa và lọc vai trò")
    void testGetAllUsers_PaginationAndFilters() throws Exception {
        // Tạo thêm 1 user để test tìm kiếm
        long ts = System.currentTimeMillis();
        User extraUser = User.builder()
                .code("SPE_SEARCH_" + ts)
                .username("uniquesearch_" + ts)
                .password(passwordEncoder.encode("Pass@123"))
                .fullName("Người Dùng Đặc Biệt")
                .email("uniquesearch_" + ts + "@unicheck.edu.vn")
                .role(Role.LECTURER)
                .status(UserStatus.ACTIVE)
                .build();
        userRepository.save(extraUser);

        // 1. Phân trang: size = 2, page = 0
        mockMvc.perform(get("/api/users")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("page", "0")
                        .param("size", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.content", hasSize(lessThanOrEqualTo(2))))
                .andExpect(jsonPath("$.data.pageNumber", is(0)))
                .andExpect(jsonPath("$.data.totalElements", greaterThanOrEqualTo(2)));

        // 2. Tìm kiếm từ khóa: "uniquesearch"
        mockMvc.perform(get("/api/users")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("search", "uniquesearch_" + ts))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content", hasSize(1)))
                .andExpect(jsonPath("$.data.content[0].username", is(extraUser.getUsername())));

        // 3. Lọc theo Role = LECTURER
        mockMvc.perform(get("/api/users")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("role", "LECTURER"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content", hasItem(hasEntry("role", "LECTURER"))));
    }

    @Test
    @DisplayName("Chức năng 2c & 2d: Xem danh sách tài khoản đã kích hoạt (ACTIVE) và chưa kích hoạt (INACTIVE)")
    void testGetActiveAndInactiveUsers() throws Exception {
        long ts = System.currentTimeMillis();
        User inactiveUser = User.builder()
                .code("INACT_" + ts)
                .username("inactive_" + ts)
                .fullName("Chưa Kích Hoạt")
                .email("inactive_" + ts + "@unicheck.edu.vn")
                .role(Role.STUDENT)
                .status(UserStatus.INACTIVE)
                .build();
        userRepository.save(inactiveUser);

        // Danh sách kích hoạt -> phải chứa studentUser (ACTIVE), không chứa inactiveUser
        mockMvc.perform(get("/api/users/active")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content", hasItem(hasEntry("status", "ACTIVE"))));

        // Danh sách chưa kích hoạt -> phải chứa inactiveUser (INACTIVE)
        mockMvc.perform(get("/api/users/inactive")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content", hasItem(hasEntry("status", "INACTIVE"))));
    }

    @Test
    @DisplayName("Chức năng 2: Quyền STUDENT bị chặn khi xem danh sách quản trị (403 Forbidden)")
    void testViewingEndpoints_ForbiddenForStudent() throws Exception {
        mockMvc.perform(get("/api/users")
                        .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.errorCode", is("ERR_2001")));

        mockMvc.perform(get("/api/users/active")
                        .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isForbidden());

        mockMvc.perform(get("/api/users/inactive")
                        .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isForbidden());
    }
}
