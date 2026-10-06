package com.unicheck.repository;

import com.unicheck.model.entity.LecturerProfile;
import com.unicheck.model.entity.StudentProfile;
import com.unicheck.model.entity.User;
import com.unicheck.model.entity.UserPermission;
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
@DisplayName("Integration Test: User, Profiles & Permissions Repositories")
class UserRepositoryTest {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private StudentProfileRepository studentProfileRepository;

    @Autowired
    private LecturerProfileRepository lecturerProfileRepository;

    @Autowired
    private UserPermissionRepository userPermissionRepository;

    @Test
    @DisplayName("Should create student user with StudentProfile and lookup by username and email")
    void testCreateAndLookupStudent() {
        User student = User.builder()
                .username("SV2026001") // Code identifier
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

        // Lookup by username (mã số sinh viên)
        Optional<User> byUsername = userRepository.findByUsername("SV2026001");
        assertTrue(byUsername.isPresent());
        assertEquals("Nguyễn Văn A", byUsername.get().getFullName());
        assertEquals(Role.STUDENT, byUsername.get().getRole());

        // Lookup by email
        Optional<User> byEmail = userRepository.findByEmail("sv2026001@unicheck.edu.vn");
        assertTrue(byEmail.isPresent());
        assertEquals(savedStudent.getId(), byEmail.get().getId());

        // Verify StudentProfile mapping
        Optional<StudentProfile> studentProfile = studentProfileRepository.findByUserId(savedStudent.getId());
        assertTrue(studentProfile.isPresent());
        assertEquals("K20", studentProfile.get().getCourse());
        assertEquals(3.65, studentProfile.get().getGpa());
    }

    @Test
    @DisplayName("Should create lecturer user with LecturerProfile and assign permissions")
    void testCreateLecturerAndPermissions() {
        User lecturer = User.builder()
                .username("GV2026099") // Code identifier
                .fullName("Trần Thị B")
                .email("gv2026099@unicheck.edu.vn")
                .password("$2a$10$hashedpasswordplaceholder")
                .sex("FEMALE")
                .role(Role.LECTURER)
                .status(UserStatus.ACTIVE)
                .build();

        User savedLecturer = userRepository.save(lecturer);
        assertNotNull(savedLecturer.getId());

        // Create LecturerProfile
        LecturerProfile lecturerProfile = LecturerProfile.builder()
                .user(savedLecturer)
                .department("Khoa Công Nghệ Thông Tin")
                .expertise("Trí tuệ Nhân tạo & Thị giác máy tính")
                .bio("Tiến sĩ Khoa học Máy tính")
                .build();
        lecturerProfileRepository.save(lecturerProfile);

        // Assign permission
        UserPermission permission = UserPermission.builder()
                .user(savedLecturer)
                .permission("ATTENDANCE_MANAGE")
                .build();
        userPermissionRepository.save(permission);

        // Verify query
        List<User> lecturers = userRepository.findByRole(Role.LECTURER);
        assertFalse(lecturers.isEmpty());

        List<UserPermission> permissions = userPermissionRepository.findAllByUserId(savedLecturer.getId());
        assertEquals(1, permissions.size());
        assertEquals("ATTENDANCE_MANAGE", permissions.get(0).getPermission());
    }
}
