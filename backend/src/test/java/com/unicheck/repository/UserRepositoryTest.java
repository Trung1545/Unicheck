package com.unicheck.repository;

import com.unicheck.model.entity.*;
import com.unicheck.model.enums.Role;
import com.unicheck.model.enums.UserStatus;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
@DisplayName("Integration Test: User, Profiles, Permissions & Security Repositories")
class UserRepositoryTest {

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
    @DisplayName("Should create student user with code, StudentProfile and lookup by code and email")
    void testCreateAndLookupStudent() {
        User student = User.builder()
                .code("SV2026001") // Mã số sinh viên
                .username("nguyen_van_a")
                .fullName("Nguyễn Văn A")
                .email("sv2026001@unicheck.edu.vn")
                .password("$2a$10$hashedpasswordplaceholder")
                .sex("MALE")
                .dob(LocalDate.of(2003, 5, 20))
                .phone("0901234567")
                .role(Role.STUDENT)
                .status(UserStatus.ACTIVE)
                .build();

        User savedStudent = userRepository.save(student);
        assertNotNull(savedStudent.getId());

        // Create StudentProfile
        StudentProfile profile = StudentProfile.builder()
                .user(savedStudent)
                .course("K20")
                .gpa(3.65)
                .build();
        studentProfileRepository.save(profile);

        // 1. Lookup by mã số (code)
        Optional<User> byCode = userRepository.findByCode("SV2026001");
        assertTrue(byCode.isPresent());
        assertEquals("Nguyễn Văn A", byCode.get().getFullName());
        assertEquals("SV2026001", byCode.get().getCode());
        assertEquals(Role.STUDENT, byCode.get().getRole());
        assertTrue(userRepository.existsByCode("SV2026001"));

        // 2. Lookup by email
        Optional<User> byEmail = userRepository.findByEmail("sv2026001@unicheck.edu.vn");
        assertTrue(byEmail.isPresent());
        assertEquals(savedStudent.getId(), byEmail.get().getId());
        assertTrue(userRepository.existsByEmail("sv2026001@unicheck.edu.vn"));

        // 3. Lookup by username
        Optional<User> byUsername = userRepository.findByUsername("nguyen_van_a");
        assertTrue(byUsername.isPresent());

        // 4. Verify StudentProfile mapping
        Optional<StudentProfile> studentProfile = studentProfileRepository.findByUserId(savedStudent.getId());
        assertTrue(studentProfile.isPresent());
        assertEquals("K20", studentProfile.get().getCourse());
        assertEquals(3.65, studentProfile.get().getGpa());
    }

    @Test
    @DisplayName("Should create lecturer user with LecturerProfile, OTP, AccessLog and assign permissions")
    void testCreateLecturerAndPermissions() {
        User lecturer = User.builder()
                .code("GV2026099") // Mã số giảng viên
                .username("tran_thi_b")
                .fullName("Trần Thị B")
                .email("gv2026099@unicheck.edu.vn")
                .password("$2a$10$hashedpasswordplaceholder")
                .sex("FEMALE")
                .role(Role.LECTURER)
                .status(UserStatus.ACTIVE)
                .build();

        User savedLecturer = userRepository.save(lecturer);
        assertNotNull(savedLecturer.getId());

        // 1. Create LecturerProfile
        LecturerProfile lecturerProfile = LecturerProfile.builder()
                .user(savedLecturer)
                .department("Khoa Công Nghệ Thông Tin")
                .expertise("Trí tuệ Nhân tạo & Thị giác máy tính")
                .bio("Tiến sĩ Khoa học Máy tính")
                .build();
        lecturerProfileRepository.save(lecturerProfile);

        // 2. Assign permission
        UserPermission permission = UserPermission.builder()
                .user(savedLecturer)
                .permission("ATTENDANCE_MANAGE")
                .build();
        userPermissionRepository.save(permission);

        // 3. Lecturer Grade OTP
        LecturerGradeOtp otp = LecturerGradeOtp.builder()
                .user(savedLecturer)
                .otpHash("$2a$10$otphashsecret")
                .build();
        lecturerGradeOtpRepository.save(otp);

        // 4. Access Log
        AccessLog accessLog = AccessLog.builder()
                .user(savedLecturer)
                .location("Da Nang, Vietnam")
                .status("SUCCESS")
                .ipAddress("192.168.1.100")
                .userAgent("Mozilla/5.0 Chrome/124.0")
                .build();
        accessLogRepository.save(accessLog);

        // Assertions
        Optional<User> byLecturerCode = userRepository.findByCode("GV2026099");
        assertTrue(byLecturerCode.isPresent());

        List<User> lecturers = userRepository.findByRole(Role.LECTURER);
        assertFalse(lecturers.isEmpty());

        List<UserPermission> permissions = userPermissionRepository.findAllByUserId(savedLecturer.getId());
        assertEquals(1, permissions.size());
        assertEquals("ATTENDANCE_MANAGE", permissions.get(0).getPermission());

        Optional<LecturerGradeOtp> savedOtp = lecturerGradeOtpRepository.findByUserId(savedLecturer.getId());
        assertTrue(savedOtp.isPresent());
        assertEquals("$2a$10$otphashsecret", savedOtp.get().getOtpHash());

        List<AccessLog> logs = accessLogRepository.findByUserId(savedLecturer.getId());
        assertEquals(1, logs.size());
        assertEquals("Da Nang, Vietnam", logs.get(0).getLocation());
    }
}
