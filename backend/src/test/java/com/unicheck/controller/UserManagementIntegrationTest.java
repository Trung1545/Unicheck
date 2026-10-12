package com.unicheck.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.model.dto.UserCreateRequest;
import com.unicheck.model.dto.UserUpdateRequest;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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

    // =========================================================================
    // CHỨC NĂNG 3: CẬP NHẬT TÀI KHOẢN NGƯỜI DÙNG & GHI AUDIT LOG
    // =========================================================================

    @Test
    @DisplayName("Chức năng 3: Admin cập nhật thông tin người dùng thành công và ghi nhận Audit Log (oldValue -> newValue)")
    void testUpdateUser_Success_AndAuditLogged() throws Exception {
        UserUpdateRequest updateReq = UserUpdateRequest.builder()
                .fullName("Nguyễn Văn A (Cập Nhật)")
                .phone("0912345678")
                .dob(LocalDate.of(2003, 10, 15))
                .sex("MALE")
                .studentCourse("K20")
                .build();

        mockMvc.perform(put("/api/users/" + studentUser.getId())
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.fullName", is("Nguyễn Văn A (Cập Nhật)")))
                .andExpect(jsonPath("$.data.phone", is("0912345678")))
                .andExpect(jsonPath("$.data.studentCourse", is("K20")));

        // 1. Kiểm tra cập nhật DB
        User updatedDb = userRepository.findById(studentUser.getId()).orElse(null);
        assertNotNull(updatedDb);
        assertEquals("Nguyễn Văn A (Cập Nhật)", updatedDb.getFullName());
        assertEquals("0912345678", updatedDb.getPhone());

        StudentProfile sp = studentProfileRepository.findByUserId(studentUser.getId()).orElse(null);
        assertNotNull(sp);
        assertEquals("K20", sp.getCourse());

        // 2. Kiểm tra Audit Log có lưu oldValue và newValue
        List<SystemLog> logs = systemLogRepository.findByPerformerIdOrderByCreatedAtDesc(adminUser.getId());
        assertFalse(logs.isEmpty());
        SystemLog updateLog = logs.get(0);
        assertEquals("USER_UPDATE", updateLog.getAction());
        assertNotNull(updateLog.getOldValue());
        assertNotNull(updateLog.getNewValue());
        assertTrue(updateLog.getNewValue().contains("Nguyễn Văn A (Cập Nhật)"));
    }

    @Test
    @DisplayName("Chức năng 3: Admin đổi vai trò người dùng (STUDENT -> LECTURER) ghi nhận Audit Log USER_ROLE_CHANGED")
    void testUpdateUser_RoleChanged_AndAuditLogged() throws Exception {
        UserUpdateRequest updateReq = UserUpdateRequest.builder()
                .role(Role.LECTURER)
                .department("Khoa Công nghệ Thông tin")
                .expertise("Trí tuệ nhân tạo")
                .build();

        mockMvc.perform(put("/api/users/" + studentUser.getId())
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.role", is("LECTURER")))
                .andExpect(jsonPath("$.data.department", is("Khoa Công nghệ Thông tin")));

        List<SystemLog> logs = systemLogRepository.findByPerformerIdOrderByCreatedAtDesc(adminUser.getId());
        assertFalse(logs.isEmpty());
        SystemLog roleLog = logs.get(0);
        assertEquals("USER_ROLE_CHANGED", roleLog.getAction());
        assertTrue(roleLog.getDescription().contains("Đổi vai trò"));
    }

    @Test
    @DisplayName("Chức năng 3: Cập nhật email trùng với tài khoản khác trả về 400 Bad Request")
    void testUpdateUser_DuplicateEmail_ThrowsBadRequest() throws Exception {
        UserUpdateRequest updateReq = UserUpdateRequest.builder()
                .email(adminUser.getEmail()) // email của adminUser
                .build();

        mockMvc.perform(put("/api/users/" + studentUser.getId())
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode", is("ERR_2011")));
    }

    @Test
    @DisplayName("Chức năng 3: Quyền STUDENT không được cập nhật tài khoản quản trị (403 Forbidden)")
    void testUpdateUser_ForbiddenForStudent() throws Exception {
        UserUpdateRequest updateReq = UserUpdateRequest.builder()
                .fullName("Hack Full Name")
                .build();

        mockMvc.perform(put("/api/users/" + adminUser.getId())
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.errorCode", is("ERR_2001")));
    }

    // =========================================================================
    // CHỨC NĂNG 4: XÓA TÀI KHOẢN NGƯỜI DÙNG & GHI AUDIT LOG
    // =========================================================================

    @Test
    @DisplayName("Chức năng 4: Admin xóa tài khoản người dùng thành công và ghi nhận Audit Log")
    void testDeleteUser_Success_AndAuditLogged() throws Exception {
        long ts = System.currentTimeMillis();
        User userToDelete = User.builder()
                .code("DEL_" + ts)
                .username("todelete_" + ts)
                .fullName("Người Dùng Sắp Xóa")
                .email("todelete_" + ts + "@unicheck.edu.vn")
                .role(Role.STUDENT)
                .status(UserStatus.INACTIVE)
                .build();
        userRepository.save(userToDelete);
        Long deleteId = userToDelete.getId();

        mockMvc.perform(delete("/api/users/" + deleteId)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.message", containsString("Xóa tài khoản người dùng thành công")));

        // 1. Kiểm tra đối tượng đã bị xóa khỏi DB
        assertFalse(userRepository.findById(deleteId).isPresent());

        // 2. Kiểm tra Audit Log được ghi lại
        List<SystemLog> logs = systemLogRepository.findByPerformerIdOrderByCreatedAtDesc(adminUser.getId());
        assertFalse(logs.isEmpty());
        SystemLog deleteLog = logs.get(0);
        assertEquals("USER_DELETE", deleteLog.getAction());
        assertNotNull(deleteLog.getOldValue());
        assertTrue(deleteLog.getDescription().contains("todelete_" + ts));
    }

    @Test
    @DisplayName("Chức năng 4: Xóa người dùng không tồn tại trả về 404 Not Found")
    void testDeleteUser_NotFound_Throws404() throws Exception {
        mockMvc.perform(delete("/api/users/888888")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode", is("ERR_1002")));
    }

    @Test
    @DisplayName("Chức năng 4: Admin không thể tự xóa tài khoản của chính mình (400 Bad Request)")
    void testDeleteUser_SelfDeletion_ThrowsBadRequest() throws Exception {
        mockMvc.perform(delete("/api/users/" + adminUser.getId())
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode", is("ERR_1001")))
                .andExpect(jsonPath("$.message", containsString("không thể tự xóa")));
    }

    @Test
    @DisplayName("Chức năng 4: Quyền STUDENT không được xóa tài khoản (403 Forbidden)")
    void testDeleteUser_ForbiddenForStudent() throws Exception {
        mockMvc.perform(delete("/api/users/" + studentUser.getId())
                        .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.errorCode", is("ERR_2001")));
    }
}
