package com.unicheck.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.model.dto.*;
import com.unicheck.model.entity.User;
import com.unicheck.model.enums.CourseStatus;
import com.unicheck.model.enums.Role;
import com.unicheck.model.enums.SemesterStatus;
import com.unicheck.model.enums.UserStatus;
import com.unicheck.repository.CourseRepository;
import com.unicheck.repository.SemesterConfigRepository;
import com.unicheck.repository.SemesterRepository;
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
import java.util.Set;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class AcademicCatalogIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private CourseRepository courseRepository;

    @Autowired
    private SemesterRepository semesterRepository;

    @Autowired
    private SemesterConfigRepository semesterConfigRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    private String adminToken;
    private String studentToken;

    @BeforeEach
    void setUp() {
        semesterConfigRepository.deleteAll();
        semesterRepository.deleteAll();
        courseRepository.deleteAll();

        // 1. Setup Admin user
        User admin = userRepository.findByUsername("admin_academic_test").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("ADM-ACAD-01")
                        .username("admin_academic_test")
                        .email("admin.acad@unicheck.edu.vn")
                        .password(passwordEncoder.encode("admin123"))
                        .fullName("Quản trị viên Đào tạo")
                        .role(Role.ADMIN)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );
        adminToken = jwtUtil.generateAccessToken(admin);

        // 2. Setup Student user
        User student = userRepository.findByUsername("student_academic_test").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("STU-ACAD-01")
                        .username("student_academic_test")
                        .email("student.acad@unicheck.edu.vn")
                        .password(passwordEncoder.encode("student123"))
                        .fullName("Sinh viên Test")
                        .role(Role.STUDENT)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );
        studentToken = jwtUtil.generateAccessToken(student);
    }

    @Test
    @DisplayName("Admin tạo học phần mới thành công và truy vấn chi tiết")
    void shouldAllowAdminToCreateCourseAndRetrieveIt() throws Exception {
        CourseCreateRequest request = CourseCreateRequest.builder()
                .code("CS1010")
                .name("Nhập môn Lập trình C++")
                .description("Học phần cơ sở ngành về tư duy thuật toán và ngôn ngữ C++")
                .credits(3)
                .numberOfSlots(45)
                .status(CourseStatus.ACTIVE)
                .isCalculatedInGpa(true)
                .build();

        String responseJson = mockMvc.perform(post("/api/v1/courses")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.code", is("CS1010")))
                .andExpect(jsonPath("$.data.name", is("Nhập môn Lập trình C++")))
                .andExpect(jsonPath("$.data.credits", is(3)))
                .andReturn().getResponse().getContentAsString();

        Long courseId = objectMapper.readTree(responseJson).get("data").get("id").asLong();

        // Truy vấn lại học phần
        mockMvc.perform(get("/api/v1/courses/" + courseId)
                        .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.code", is("CS1010")))
                .andExpect(jsonPath("$.data.credits", is(3)));
    }

    @Test
    @DisplayName("Tạo học phần có môn tiên quyết và chặn chu trình lặp tiên quyết")
    void shouldHandlePrerequisitesAndCircularDependency() throws Exception {
        // Tạo môn 1: CS1010
        CourseCreateRequest req1 = CourseCreateRequest.builder()
                .code("CS1010")
                .name("Nhập môn Lập trình")
                .credits(3)
                .numberOfSlots(45)
                .build();

        String res1 = mockMvc.perform(post("/api/v1/courses")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req1)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        Long cs1010Id = objectMapper.readTree(res1).get("data").get("id").asLong();

        // Tạo môn 2: CS2050 có CS1010 là tiên quyết
        CourseCreateRequest req2 = CourseCreateRequest.builder()
                .code("CS2050")
                .name("Cấu trúc Dữ liệu & Giải thuật")
                .credits(4)
                .numberOfSlots(60)
                .prerequisiteIds(Set.of(cs1010Id))
                .build();

        String res2 = mockMvc.perform(post("/api/v1/courses")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req2)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.prerequisites", hasSize(1)))
                .andExpect(jsonPath("$.data.prerequisites[0].code", is("CS1010")))
                .andReturn().getResponse().getContentAsString();

        Long cs2050Id = objectMapper.readTree(res2).get("data").get("id").asLong();

        // Chặn chu trình lặp: sửa CS1010 để đặt CS2050 làm tiên quyết
        CourseUpdateRequest updateReq = CourseUpdateRequest.builder()
                .name("Nhập môn Lập trình")
                .credits(3)
                .numberOfSlots(45)
                .prerequisiteIds(Set.of(cs2050Id))
                .build();

        mockMvc.perform(put("/api/v1/courses/" + cs1010Id)
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode", is("ERR_4006")));

        // Chặn xóa môn CS1010 khi đang là tiên quyết của CS2050
        mockMvc.perform(delete("/api/v1/courses/" + cs1010Id)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode", is("ERR_4005")));
    }

    @Test
    @DisplayName("Chặn người dùng không có quyền ADMIN thao tác ghi học phần")
    void shouldDenyCourseCreationForNonAdmin() throws Exception {
        CourseCreateRequest request = CourseCreateRequest.builder()
                .code("SE3020")
                .name("Thiết kế Phần mềm")
                .credits(3)
                .numberOfSlots(45)
                .build();

        mockMvc.perform(post("/api/v1/courses")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Admin tạo học kỳ mới kèm cấu hình và truy vấn học kỳ hiện hành")
    void shouldAllowAdminToCreateSemesterWithConfig() throws Exception {
        LocalDate start = LocalDate.now().plusDays(10);
        LocalDate end = start.plusWeeks(18);

        SemesterCreateRequest request = SemesterCreateRequest.builder()
                .code("HK241")
                .name("Học kỳ I 2024 - 2025")
                .startDate(start)
                .endDate(end)
                .status(SemesterStatus.ACTIVE)
                .description("Học kỳ chính khóa thu đông")
                .maxSlotPerDay(6)
                .slotPerSubjectPerWeek(2)
                .slotDuration(50)
                .isPublished(true)
                .build();

        mockMvc.perform(post("/api/v1/semesters")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.code", is("HK241")))
                .andExpect(jsonPath("$.data.config.maxSlotPerDay", is(6)))
                .andExpect(jsonPath("$.data.totalWeeks", is(19)));

        // Truy vấn học kỳ hiện hành (Active)
        mockMvc.perform(get("/api/v1/semesters/active")
                        .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.code", is("HK241")))
                .andExpect(jsonPath("$.data.status", is("ACTIVE")));
    }

    @Test
    @DisplayName("Chặn tạo học kỳ khi ngày kết thúc trước ngày bắt đầu")
    void shouldRejectInvalidSemesterDates() throws Exception {
        LocalDate start = LocalDate.now().plusDays(20);
        LocalDate end = start.minusDays(5); // Kết thúc trước bắt đầu

        SemesterCreateRequest request = SemesterCreateRequest.builder()
                .code("HK_INVALID")
                .name("Học kỳ Lỗi Ngày")
                .startDate(start)
                .endDate(end)
                .build();

        mockMvc.perform(post("/api/v1/semesters")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode", is("ERR_1001")));
    }

    @Test
    @DisplayName("Admin thực hiện khóa sổ học kỳ (Lock Semester)")
    void shouldLockSemesterSuccessfully() throws Exception {
        LocalDate start = LocalDate.now().minusWeeks(18);
        LocalDate end = LocalDate.now().minusWeeks(1);

        SemesterCreateRequest request = SemesterCreateRequest.builder()
                .code("HK232")
                .name("Học kỳ II 2023 - 2024")
                .startDate(start)
                .endDate(end)
                .status(SemesterStatus.ACTIVE)
                .build();

        String res = mockMvc.perform(post("/api/v1/semesters")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        Long semesterId = objectMapper.readTree(res).get("data").get("id").asLong();

        // Khóa sổ học kỳ
        mockMvc.perform(patch("/api/v1/semesters/" + semesterId + "/lock")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status", is("CLOSED")));
    }

    @Test
    @DisplayName("Truy vấn danh sách học kỳ với các trạng thái hợp lệ (ACTIVE, CLOSED, UPCOMING)")
    void shouldQuerySemestersWithAllValidStatusesSuccessfully() throws Exception {
        LocalDate now = LocalDate.now();

        // 1. Semester CLOSED (trước đây từng bị nhầm thành COMPLETED gây lỗi 500 BUG-01)
        semesterRepository.save(com.unicheck.model.entity.Semester.builder()
                .code("SPRING2026")
                .name("Spring 2026")
                .startDate(now.minusMonths(8))
                .endDate(now.minusMonths(4))
                .status(SemesterStatus.CLOSED)
                .build());

        // 2. Semester ACTIVE
        semesterRepository.save(com.unicheck.model.entity.Semester.builder()
                .code("FALL2026")
                .name("Fall 2026")
                .startDate(now.minusMonths(1))
                .endDate(now.plusMonths(3))
                .status(SemesterStatus.ACTIVE)
                .build());

        // 3. Semester UPCOMING
        semesterRepository.save(com.unicheck.model.entity.Semester.builder()
                .code("SPRING2027")
                .name("Spring 2027")
                .startDate(now.plusMonths(4))
                .endDate(now.plusMonths(8))
                .status(SemesterStatus.UPCOMING)
                .build());

        // Gọi API GET /api/v1/semesters không bị lỗi 500 do enum mismatch
        mockMvc.perform(get("/api/v1/semesters")
                        .header("Authorization", "Bearer " + studentToken)
                        .param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.content", hasSize(3)))
                .andExpect(jsonPath("$.data.content[?(@.status == 'CLOSED')].code", contains("SPRING2026")))
                .andExpect(jsonPath("$.data.content[?(@.status == 'ACTIVE')].code", contains("FALL2026")))
                .andExpect(jsonPath("$.data.content[?(@.status == 'UPCOMING')].code", contains("SPRING2027")));

        // Lọc theo status=CLOSED
        mockMvc.perform(get("/api/v1/semesters")
                        .header("Authorization", "Bearer " + studentToken)
                        .param("status", "CLOSED"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.content", hasSize(1)))
                .andExpect(jsonPath("$.data.content[0].code", is("SPRING2026")))
                .andExpect(jsonPath("$.data.content[0].status", is("CLOSED")));
    }
}

