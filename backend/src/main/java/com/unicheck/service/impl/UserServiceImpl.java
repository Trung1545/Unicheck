package com.unicheck.service.impl;

import com.unicheck.common.dto.PageResponse;
import com.unicheck.exception.AppException;
import com.unicheck.exception.ErrorCode;
import com.unicheck.model.dto.UserCreateRequest;
import com.unicheck.model.dto.UserResponse;
import com.unicheck.model.entity.LecturerProfile;
import com.unicheck.model.entity.StudentProfile;
import com.unicheck.model.entity.User;
import com.unicheck.model.entity.UserPermission;
import com.unicheck.model.enums.FaceDataStatus;
import com.unicheck.model.enums.Role;
import com.unicheck.model.enums.UserStatus;
import com.unicheck.repository.LecturerProfileRepository;
import com.unicheck.repository.StudentProfileRepository;
import com.unicheck.repository.UserRepository;
import com.unicheck.service.SystemLogService;
import com.unicheck.service.UserService;
import jakarta.persistence.criteria.Predicate;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.ArrayList;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final StudentProfileRepository studentProfileRepository;
    private final LecturerProfileRepository lecturerProfileRepository;
    private final SystemLogService systemLogService;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public UserResponse createUser(UserCreateRequest request, HttpServletRequest httpRequest) {
        // 1. Kiểm tra tính duy nhất của username
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new AppException(ErrorCode.USER_ALREADY_EXISTS, "Tên đăng nhập '" + request.getUsername() + "' đã tồn tại");
        }

        // 2. Kiểm tra tính duy nhất của email
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new AppException(ErrorCode.USER_ALREADY_EXISTS, "Email '" + request.getEmail() + "' đã tồn tại");
        }

        // 3. Kiểm tra tính duy nhất của mã định danh (nếu có)
        if (StringUtils.hasText(request.getCode()) && userRepository.existsByCode(request.getCode())) {
            throw new AppException(ErrorCode.USER_ALREADY_EXISTS, "Mã định danh '" + request.getCode() + "' đã tồn tại");
        }

        // 4. Khởi tạo đối tượng User (mặc định INACTIVE theo sequence diagram Figure 17)
        User user = User.builder()
                .code(request.getCode())
                .username(request.getUsername())
                .fullName(request.getFullName())
                .email(request.getEmail())
                .phone(request.getPhone())
                .dob(request.getDob())
                .sex(StringUtils.hasText(request.getSex()) ? request.getSex() : "OTHER")
                .role(request.getRole() != null ? request.getRole() : Role.STUDENT)
                .status(request.getStatus() != null ? request.getStatus() : UserStatus.INACTIVE)
                .faceDataStatus(FaceDataStatus.NOT_REGISTERED)
                .avatar(request.getAvatar())
                .isPasswordChanged(false)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        if (StringUtils.hasText(request.getPassword())) {
            user.setPassword(passwordEncoder.encode(request.getPassword()));
            user.setIsPasswordChanged(true);
        }

        User savedUser = userRepository.save(user);

        // 5. Khởi tạo Profile theo vai trò
        if (savedUser.getRole() == Role.STUDENT) {
            StudentProfile studentProfile = StudentProfile.builder()
                    .user(savedUser)
                    .course(request.getStudentCourse())
                    .majorId(request.getMajorId())
                    .specializationId(request.getSpecializationId())
                    .subSpecializationId(request.getSubSpecializationId())
                    .build();
            studentProfileRepository.save(studentProfile);
            savedUser.setStudentProfile(studentProfile);
        } else if (savedUser.getRole() == Role.LECTURER) {
            LecturerProfile lecturerProfile = LecturerProfile.builder()
                    .user(savedUser)
                    .department(request.getDepartment())
                    .expertise(request.getExpertise())
                    .bio(request.getBio())
                    .build();
            lecturerProfileRepository.save(lecturerProfile);
            savedUser.setLecturerProfile(lecturerProfile);
        }

        // 6. Ghi Audit Log (ai, lúc nào, làm gì)
        User performer = getCurrentAuthenticatedUser();
        String description = String.format("Tạo tài khoản người dùng: %s (Họ tên: %s, Mã: %s, Vai trò: %s, Trạng thái: %s)",
                savedUser.getUsername(),
                savedUser.getFullName(),
                savedUser.getCode() != null ? savedUser.getCode() : "N/A",
                savedUser.getRole(),
                savedUser.getStatus());

        systemLogService.logAudit(
                "USER_CREATE",
                description,
                performer,
                null,
                "User ID: " + savedUser.getId() + ", Username: " + savedUser.getUsername(),
                httpRequest
        );

        return mapToUserResponse(savedUser);
    }

    @Override
    @Transactional(readOnly = true)
    public UserResponse getUser(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND, "Không tìm thấy người dùng với ID: " + id));
        return mapToUserResponse(user);
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<UserResponse> getAllUsers(String search, Role role, UserStatus status, Pageable pageable) {
        Specification<User> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (StringUtils.hasText(search)) {
                String pattern = "%" + search.trim().toLowerCase() + "%";
                Predicate usernameMatch = cb.like(cb.lower(root.get("username")), pattern);
                Predicate fullNameMatch = cb.like(cb.lower(root.get("fullName")), pattern);
                Predicate emailMatch = cb.like(cb.lower(root.get("email")), pattern);
                Predicate codeMatch = cb.like(cb.lower(root.get("code")), pattern);
                predicates.add(cb.or(usernameMatch, fullNameMatch, emailMatch, codeMatch));
            }

            if (role != null) {
                predicates.add(cb.equal(root.get("role"), role));
            }

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<User> page = userRepository.findAll(spec, pageable);
        Page<UserResponse> mappedPage = page.map(this::mapToUserResponse);
        return PageResponse.of(mappedPage);
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<UserResponse> getActiveUsers(String search, Pageable pageable) {
        return getAllUsers(search, null, UserStatus.ACTIVE, pageable);
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<UserResponse> getInactiveUsers(String search, Pageable pageable) {
        return getAllUsers(search, null, UserStatus.INACTIVE, pageable);
    }

    private User getCurrentAuthenticatedUser() {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            if (authentication != null && authentication.isAuthenticated() && !"anonymousUser".equals(authentication.getPrincipal())) {
                return userRepository.findByUsername(authentication.getName()).orElse(null);
            }
        } catch (Exception ignored) {}
        return null;
    }

    private UserResponse mapToUserResponse(User user) {
        UserResponse.UserResponseBuilder builder = UserResponse.builder()
                .id(user.getId())
                .code(user.getCode())
                .username(user.getUsername())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .dob(user.getDob())
                .sex(user.getSex())
                .role(user.getRole())
                .status(user.getStatus())
                .faceDataStatus(user.getFaceDataStatus())
                .avatar(user.getAvatar())
                .isPasswordChanged(user.getIsPasswordChanged())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt());

        studentProfileRepository.findByUserId(user.getId()).ifPresent(sp -> {
            builder.studentCourse(sp.getCourse())
                    .gpa(sp.getGpa())
                    .majorId(sp.getMajorId())
                    .specializationId(sp.getSpecializationId())
                    .subSpecializationId(sp.getSubSpecializationId());
        });

        lecturerProfileRepository.findByUserId(user.getId()).ifPresent(lp -> {
            builder.department(lp.getDepartment())
                    .expertise(lp.getExpertise())
                    .bio(lp.getBio());
        });

        if (user.getPermissions() != null) {
            List<String> perms = user.getPermissions().stream()
                    .map(UserPermission::getPermission)
                    .collect(Collectors.toList());
            builder.permissions(perms);
        }

        return builder.build();
    }
}
