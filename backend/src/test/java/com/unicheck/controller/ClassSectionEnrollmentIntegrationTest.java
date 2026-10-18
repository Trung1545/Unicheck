package com.unicheck.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.model.dto.*;
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
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class ClassSectionEnrollmentIntegrationTest {

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
    private ClassSectionRepository classSectionRepository;

    @Autowired
    private EnrollmentRepository enrollmentRepository;

    @Autowired
    private TeachingAssignmentRepository teachingAssignmentRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    private String adminToken;
    private String lecturerToken;
    private String otherLecturerToken;
    private String studentToken;

    private User admin;
    private User lecturer;
    private User otherLecturer;
    private User student;
    private Course course;
    private Semester semester;

    @BeforeEach
    void setUp() {
        enrollmentRepository.deleteAll();
        teachingAssignmentRepository.deleteAll();
        classSectionRepository.deleteAll();
        courseRepository.deleteAll();
        semesterRepository.deleteAll();

        // 1. Users
        admin = userRepository.findByUsername("admin_class_test").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("ADM-CLS-01")
                        .username("admin_class_test")
                        .email("admin.cls@unicheck.edu.vn")
                        .password(passwordEncoder.encode("admin123"))
                        .fullName("Quản trị viên Lớp HP")
                        .role(Role.ADMIN)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );
        adminToken = jwtUtil.generateAccessToken(admin);

        lecturer = userRepository.findByUsername("lecturer_class_test").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("GV-CLS-01")
                        .username("lecturer_class_test")
                        .email("lecturer.cls@unicheck.edu.vn")
                        .password(passwordEncoder.encode("lecturer123"))
                        .fullName("TS. Lê Hoàng Nam")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );
        lecturerToken = jwtUtil.generateAccessToken(lecturer);

        otherLecturer = userRepository.findByUsername("other_lecturer_class_test").orElseGet(() ->
                userRepository.save(User.builder()
                        .code("GV-CLS-02")
                        .username("other_lecturer_class_test")
                        .email("other.lecturer.cls@unicheck.edu.vn")
                        .password(passwordEncoder.encode("lecturer123"))
                        .fullName("ThS. Đặng Thị Anh Thư")
                        .role(Role.LECTURER)
                        .status(UserStatus.ACTIVE)
                        .isPasswordChanged(true)
                        .build())
        );
        otherLecturerToken = jwtUtil.generateAccessToken(otherLecturer);

        student = userRepository.findByUsername("student_class_test").orElseGet(() -> {
            User s = userRepository.save(User.builder()
                    .code("2251120011")
                    .username("student_class_test")
                    .email("student.cls@unicheck.edu.vn")
                    .password(passwordEncoder.encode("student123"))
                    .fullName("Nguyễn Trần Khánh Linh")
                    .role(Role.STUDENT)
                    .status(UserStatus.ACTIVE)
                    .isPasswordChanged(true)
                    .build());
            s.setStudentProfile(StudentProfile.builder()
                    .user(s)
                    .course("22DTH01")
                    .gpa(3.5)
                    .build());
            return userRepository.save(s);
        });
        studentToken = jwtUtil.generateAccessToken(student);

        // 2. Base Course & Semester
        course = courseRepository.save(Course.builder()
                .code("IT301")
                .name("Lập trình Web Nâng cao")
                .credits(3)
                .numberOfSlots(45)
                .status(CourseStatus.ACTIVE)
                .build());

        semester = semesterRepository.save(Semester.builder()
                .code("HK1_2024_2025")
                .name("Học kỳ I (2024 - 2025)")
                .startDate(LocalDate.of(2024, 9, 2))
                .endDate(LocalDate.of(2025, 1, 18))
                .status(SemesterStatus.ACTIVE)
                .build());
    }

    @Test
    @DisplayName("1. ADMIN lấy danh sách lớp học phần có phân trang thành công")
    void testGetClasses_Admin_Success() throws Exception {
        classSectionRepository.save(ClassSection.builder()
                .className("IT301.01")
                .course(course)
                .semester(semester)
                .lecturer(lecturer)
                .maxStudents(70)
                .numberOfSlots(45)
                .status(ClassSectionStatus.OPEN)
                .build());

        mockMvc.perform(get("/api/v1/classes")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content", hasSize(1)))
                .andExpect(jsonPath("$.data.content[0].className").value("IT301.01"))
                .andExpect(jsonPath("$.data.content[0].courseCode").value("IT301"))
                .andExpect(jsonPath("$.data.content[0].lecturerName").value("TS. Lê Hoàng Nam"));
    }

    @Test
    @DisplayName("2. ADMIN tạo lớp học phần hợp lệ thành công")
    void testCreateClass_Admin_Success() throws Exception {
        ClassSectionCreateRequest request = ClassSectionCreateRequest.builder()
                .className("IT301.01")
                .courseId(course.getId())
                .semesterId(semester.getId())
                .lecturerId(lecturer.getId())
                .maxStudents(70)
                .numberOfSlots(45)
                .status(ClassSectionStatus.OPEN)
                .build();

        mockMvc.perform(post("/api/v1/classes")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.className").value("IT301.01"))
                .andExpect(jsonPath("$.data.currentEnrollment").value(0))
                .andExpect(jsonPath("$.data.maxStudents").value(70));

        // Verify teaching assignment was created
        assertTrue(teachingAssignmentRepository.existsByLecturer_IdAndCourse_IdAndSemester_Id(
                lecturer.getId(), course.getId(), semester.getId()));
    }

    @Test
    @DisplayName("3. Từ chối tạo lớp khi mã className bị trùng")
    void testCreateClass_DuplicateClassName_Conflict() throws Exception {
        classSectionRepository.save(ClassSection.builder()
                .className("IT301.01")
                .course(course)
                .semester(semester)
                .lecturer(lecturer)
                .maxStudents(70)
                .numberOfSlots(45)
                .build());

        ClassSectionCreateRequest request = ClassSectionCreateRequest.builder()
                .className("IT301.01")
                .courseId(course.getId())
                .semesterId(semester.getId())
                .maxStudents(70)
                .build();

        mockMvc.perform(post("/api/v1/classes")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_4013"));
    }

    @Test
    @DisplayName("4. Từ chối tạo lớp khi Course không tồn tại")
    void testCreateClass_CourseNotFound_NotFound() throws Exception {
        ClassSectionCreateRequest request = ClassSectionCreateRequest.builder()
                .className("CS999.01")
                .courseId(999999L)
                .semesterId(semester.getId())
                .maxStudents(50)
                .build();

        mockMvc.perform(post("/api/v1/classes")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_4003"));
    }

    @Test
    @DisplayName("5. Từ chối tạo lớp khi Semester không tồn tại")
    void testCreateClass_SemesterNotFound_NotFound() throws Exception {
        ClassSectionCreateRequest request = ClassSectionCreateRequest.builder()
                .className("IT301.01")
                .courseId(course.getId())
                .semesterId(999999L)
                .maxStudents(50)
                .build();

        mockMvc.perform(post("/api/v1/classes")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_4004"));
    }

    @Test
    @DisplayName("6. Từ chối gán giảng viên có role không phải LECTURER")
    void testCreateClass_InvalidLecturerRole_BadRequest() throws Exception {
        ClassSectionCreateRequest request = ClassSectionCreateRequest.builder()
                .className("IT301.01")
                .courseId(course.getId())
                .semesterId(semester.getId())
                .lecturerId(student.getId()) // student instead of lecturer
                .maxStudents(50)
                .build();

        mockMvc.perform(post("/api/v1/classes")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_4012"));
    }

    @Test
    @DisplayName("7. Cập nhật thông tin lớp học phần hợp lệ")
    void testUpdateClass_Success() throws Exception {
        classSectionRepository.save(ClassSection.builder()
                .className("IT301.01")
                .course(course)
                .semester(semester)
                .lecturer(lecturer)
                .maxStudents(70)
                .numberOfSlots(45)
                .status(ClassSectionStatus.OPEN)
                .build());

        ClassSectionUpdateRequest request = ClassSectionUpdateRequest.builder()
                .lecturerId(otherLecturer.getId())
                .maxStudents(80)
                .numberOfSlots(45)
                .status(ClassSectionStatus.ACTIVE)
                .build();

        mockMvc.perform(put("/api/v1/classes/IT301.01")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.maxStudents").value(80))
                .andExpect(jsonPath("$.data.status").value("ACTIVE"))
                .andExpect(jsonPath("$.data.lecturerName").value("ThS. Đặng Thị Anh Thư"));
    }

    @Test
    @DisplayName("8. Không cho phép giảm maxStudents nhỏ hơn số lượng sinh viên đã ghi danh")
    void testUpdateClass_MaxStudentsLessThanCurrentEnrollment_BadRequest() throws Exception {
        classSectionRepository.save(ClassSection.builder()
                .className("IT301.01")
                .course(course)
                .semester(semester)
                .maxStudents(70)
                .numberOfSlots(45)
                .currentEnrollment(10)
                .status(ClassSectionStatus.OPEN)
                .build());

        ClassSectionUpdateRequest request = ClassSectionUpdateRequest.builder()
                .maxStudents(5) // less than 10
                .status(ClassSectionStatus.OPEN)
                .build();

        mockMvc.perform(put("/api/v1/classes/IT301.01")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_1001"));
    }

    @Test
    @DisplayName("9. Chặn xóa lớp học phần khi đã có sinh viên ghi danh")
    void testDeleteClass_HasEnrollments_BadRequest() throws Exception {
        ClassSection cs = classSectionRepository.save(ClassSection.builder()
                .className("IT301.01")
                .course(course)
                .semester(semester)
                .maxStudents(70)
                .numberOfSlots(45)
                .currentEnrollment(1)
                .status(ClassSectionStatus.OPEN)
                .build());

        enrollmentRepository.save(Enrollment.builder()
                .classSection(cs)
                .student(student)
                .studentCode("2251120011")
                .status(EnrollmentStatus.ENROLLED)
                .build());

        mockMvc.perform(delete("/api/v1/classes/IT301.01")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_4005"));
    }

    @Test
    @DisplayName("10. Ghi danh sinh viên hợp lệ vào lớp học phần")
    void testCreateEnrollment_Success() throws Exception {
        classSectionRepository.save(ClassSection.builder()
                .className("IT301.01")
                .course(course)
                .semester(semester)
                .lecturer(lecturer)
                .maxStudents(70)
                .numberOfSlots(45)
                .currentEnrollment(0)
                .status(ClassSectionStatus.OPEN)
                .build());

        EnrollmentCreateRequest request = EnrollmentCreateRequest.builder()
                .className("IT301.01")
                .studentId(student.getId())
                .build();

        mockMvc.perform(post("/api/v1/enrollments")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.className").value("IT301.01"))
                .andExpect(jsonPath("$.data.studentName").value("Nguyễn Trần Khánh Linh"))
                .andExpect(jsonPath("$.data.studentCode").value("2251120011"));

        // Verify currentEnrollment in ClassSection incremented
        ClassSection updated = classSectionRepository.findByClassName("IT301.01").orElseThrow();
        assertEquals(1, updated.getCurrentEnrollment());
    }

    @Test
    @DisplayName("11. Từ chối ghi danh nếu người dùng không phải là STUDENT")
    void testCreateEnrollment_InvalidRole_BadRequest() throws Exception {
        classSectionRepository.save(ClassSection.builder()
                .className("IT301.01")
                .course(course)
                .semester(semester)
                .maxStudents(70)
                .numberOfSlots(45)
                .status(ClassSectionStatus.OPEN)
                .build());

        EnrollmentCreateRequest request = EnrollmentCreateRequest.builder()
                .className("IT301.01")
                .studentId(lecturer.getId()) // lecturer instead of student
                .build();

        mockMvc.perform(post("/api/v1/enrollments")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_4010"));
    }

    @Test
    @DisplayName("12. Từ chối ghi danh trùng lặp cùng sinh viên vào cùng một lớp")
    void testCreateEnrollment_Duplicate_Conflict() throws Exception {
        ClassSection cs = classSectionRepository.save(ClassSection.builder()
                .className("IT301.01")
                .course(course)
                .semester(semester)
                .maxStudents(70)
                .numberOfSlots(45)
                .currentEnrollment(1)
                .status(ClassSectionStatus.OPEN)
                .build());

        enrollmentRepository.save(Enrollment.builder()
                .classSection(cs)
                .student(student)
                .studentCode("2251120011")
                .status(EnrollmentStatus.ENROLLED)
                .build());

        EnrollmentCreateRequest request = EnrollmentCreateRequest.builder()
                .className("IT301.01")
                .studentId(student.getId())
                .build();

        mockMvc.perform(post("/api/v1/enrollments")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_4011"));
    }

    @Test
    @DisplayName("13. Từ chối ghi danh khi lớp học đã đầy sĩ số (CLASS_FULL)")
    void testCreateEnrollment_ClassFull_BadRequest() throws Exception {
        classSectionRepository.save(ClassSection.builder()
                .className("IT301.01")
                .course(course)
                .semester(semester)
                .maxStudents(1)
                .numberOfSlots(45)
                .currentEnrollment(1)
                .status(ClassSectionStatus.OPEN)
                .build());

        EnrollmentCreateRequest request = EnrollmentCreateRequest.builder()
                .className("IT301.01")
                .studentId(student.getId())
                .build();

        mockMvc.perform(post("/api/v1/enrollments")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ERR_4002"));
    }

    @Test
    @DisplayName("14. Hủy ghi danh hợp lệ và tự động giảm sĩ số lớp")
    void testDeleteEnrollment_Success() throws Exception {
        ClassSection cs = classSectionRepository.save(ClassSection.builder()
                .className("IT301.01")
                .course(course)
                .semester(semester)
                .maxStudents(70)
                .numberOfSlots(45)
                .currentEnrollment(1)
                .status(ClassSectionStatus.OPEN)
                .build());

        Enrollment e = enrollmentRepository.save(Enrollment.builder()
                .classSection(cs)
                .student(student)
                .studentCode("2251120011")
                .status(EnrollmentStatus.ENROLLED)
                .build());

        mockMvc.perform(delete("/api/v1/enrollments/" + e.getId())
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        // Verify enrollment deleted and class count decremented
        assertFalse(enrollmentRepository.existsById(e.getId()));
        ClassSection updated = classSectionRepository.findByClassName("IT301.01").orElseThrow();
        assertEquals(0, updated.getCurrentEnrollment());
    }

    @Test
    @DisplayName("15. STUDENT không có quyền tạo lớp học phần (403 Forbidden)")
    void testCreateClass_StudentForbidden() throws Exception {
        ClassSectionCreateRequest request = ClassSectionCreateRequest.builder()
                .className("IT301.02")
                .courseId(course.getId())
                .semesterId(semester.getId())
                .maxStudents(50)
                .numberOfSlots(45)
                .build();

        mockMvc.perform(post("/api/v1/classes")
                        .header("Authorization", "Bearer " + studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("16. LECTURER không có quyền tạo ghi danh (403 Forbidden)")
    void testCreateEnrollment_LecturerForbidden() throws Exception {
        EnrollmentCreateRequest request = EnrollmentCreateRequest.builder()
                .className("IT301.01")
                .studentId(student.getId())
                .build();

        mockMvc.perform(post("/api/v1/enrollments")
                        .header("Authorization", "Bearer " + lecturerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("17. LECTURER chỉ xem được lớp được phân công giảng dạy")
    void testGetClasses_LecturerScoped() throws Exception {
        classSectionRepository.save(ClassSection.builder()
                .className("IT301.01")
                .course(course)
                .semester(semester)
                .lecturer(lecturer)
                .maxStudents(70)
                .numberOfSlots(45)
                .status(ClassSectionStatus.OPEN)
                .build());

        classSectionRepository.save(ClassSection.builder()
                .className("IT301.02")
                .course(course)
                .semester(semester)
                .lecturer(otherLecturer)
                .maxStudents(70)
                .numberOfSlots(45)
                .status(ClassSectionStatus.OPEN)
                .build());

        mockMvc.perform(get("/api/v1/classes")
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content", hasSize(1)))
                .andExpect(jsonPath("$.data.content[0].className").value("IT301.01"));
    }

    @Test
    @DisplayName("18. Lấy danh sách sinh viên qua route lồng nhau /api/v1/classes/{className}/students")
    void testGetClassStudents_NestedRoute_Success() throws Exception {
        ClassSection cs = classSectionRepository.save(ClassSection.builder()
                .className("IT301.01")
                .course(course)
                .semester(semester)
                .lecturer(lecturer)
                .maxStudents(70)
                .numberOfSlots(45)
                .currentEnrollment(1)
                .status(ClassSectionStatus.OPEN)
                .build());

        enrollmentRepository.save(Enrollment.builder()
                .classSection(cs)
                .student(student)
                .studentCode("2251120011")
                .status(EnrollmentStatus.ENROLLED)
                .build());

        mockMvc.perform(get("/api/v1/classes/IT301.01/students")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].studentCode").value("2251120011"))
                .andExpect(jsonPath("$.data[0].studentName").value("Nguyễn Trần Khánh Linh"));
    }
}
