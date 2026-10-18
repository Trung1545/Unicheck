package com.unicheck.repository;

import com.unicheck.model.entity.*;
import com.unicheck.model.enums.Role;
import com.unicheck.model.enums.UserStatus;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import java.time.LocalDate;
import java.util.List;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
@DisplayName("Verification Test: Application startup on clean PostgreSQL with Flyway V2 & Repositories")
class PostgresCleanDatabaseStartupTest {

    @DynamicPropertySource
    static void configurePostgres(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", () -> "jdbc:postgresql://localhost:5432/unicheck_clean_test");
        registry.add("spring.datasource.username", () -> "unicheck_user");
        registry.add("spring.datasource.password", () -> "unicheck_secret_password");
        registry.add("spring.datasource.driver-class-name", () -> "org.postgresql.Driver");
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "validate");
        registry.add("spring.jpa.properties.hibernate.dialect", () -> "org.hibernate.dialect.PostgreSQLDialect");
        registry.add("spring.flyway.enabled", () -> "true");
        registry.add("spring.data.redis.repositories.enabled", () -> "false");
    }

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private StudentProfileRepository studentProfileRepository;

    @Autowired
    private LecturerProfileRepository lecturerProfileRepository;

    @Autowired
    private UserPermissionRepository userPermissionRepository;

    @Autowired
    private LecturerGradeOtpRepository lecturerGradeOtpRepository;

    @Autowired
    private AccessLogRepository accessLogRepository;

    @Test
    @DisplayName("Should successfully migrate clean PostgreSQL, validate schema, and perform user CRUD")
    void testCleanPostgresStartupAndUserOperations() {
        long ts = System.currentTimeMillis();
        // 1. Create a student with code (mã số), email and profile
        String studentCode = "SV" + ts;
        String studentEmail = "sv" + ts + "@unicheck.edu.vn";

        User student = User.builder()
                .code(studentCode)
                .username("sv_" + ts)
                .fullName("Lê Văn Postgres")
                .email(studentEmail)
                .password("$2a$10$hashedCleanPgPass")
                .sex("MALE")
                .dob(LocalDate.of(2003, 10, 10))
                .phone("0987654321")
                .role(Role.STUDENT)
                .status(UserStatus.ACTIVE)
                .build();

        User savedStudent = userRepository.save(student);
        assertNotNull(savedStudent.getId());

        StudentProfile profile = StudentProfile.builder()
                .user(savedStudent)
                .course("K20")
                .gpa(3.80)
                .build();
        studentProfileRepository.save(profile);

        // 2. Lookup by mã số (code)
        Optional<User> byCode = userRepository.findByCode(studentCode);
        assertTrue(byCode.isPresent(), "User should be found by code (mã số)");
        assertEquals("Lê Văn Postgres", byCode.get().getFullName());
        assertEquals(studentCode, byCode.get().getCode());

        // 3. Lookup by email
        Optional<User> byEmail = userRepository.findByEmail(studentEmail);
        assertTrue(byEmail.isPresent(), "User should be found by email");
        assertEquals(savedStudent.getId(), byEmail.get().getId());

        // 4. Create a lecturer with permissions, OTP and access logs
        String lecturerCode = "GV" + ts;
        User lecturer = User.builder()
                .code(lecturerCode)
                .username("gv_" + ts)
                .fullName("Phạm Thị Postgres")
                .email("gv" + ts + "@unicheck.edu.vn")
                .password("$2a$10$hashedCleanPgPass")
                .sex("FEMALE")
                .role(Role.LECTURER)
                .status(UserStatus.ACTIVE)
                .build();
        User savedLecturer = userRepository.save(lecturer);

        LecturerProfile lecturerProfile = LecturerProfile.builder()
                .user(savedLecturer)
                .department("Khoa An toàn Thông tin")
                .expertise("Bảo mật dữ liệu")
                .bio("Giảng viên chính")
                .build();
        lecturerProfileRepository.save(lecturerProfile);

        UserPermission permission = UserPermission.builder()
                .user(savedLecturer)
                .permission("SCORE_INPUT")
                .build();
        userPermissionRepository.save(permission);

        LecturerGradeOtp otp = LecturerGradeOtp.builder()
                .user(savedLecturer)
                .otpHash("$2a$10$otpSecretHash")
                .build();
        lecturerGradeOtpRepository.save(otp);

        AccessLog accessLog = AccessLog.builder()
                .user(savedLecturer)
                .location("Hà Nội, Vietnam")
                .status("SUCCESS")
                .ipAddress("10.0.0.1")
                .userAgent("PostmanRuntime/7.36.0")
                .build();
        accessLogRepository.save(accessLog);

        // Verify lookup
        Optional<User> byLecturerCode = userRepository.findByCode(lecturerCode);
        assertTrue(byLecturerCode.isPresent());

        List<UserPermission> permissions = userPermissionRepository.findAllByUserId(savedLecturer.getId());
        assertEquals(1, permissions.size());
        assertEquals("SCORE_INPUT", permissions.get(0).getPermission());

        Optional<LecturerGradeOtp> foundOtp = lecturerGradeOtpRepository.findByUserId(savedLecturer.getId());
        assertTrue(foundOtp.isPresent());

        List<AccessLog> foundLogs = accessLogRepository.findByUserId(savedLecturer.getId());
        assertEquals(1, foundLogs.size());
    }
}
