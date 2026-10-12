package com.unicheck.service.impl;

import com.unicheck.common.dto.PageResponse;
import com.unicheck.exception.AppException;
import com.unicheck.exception.ErrorCode;
import com.unicheck.model.dto.UserCreateRequest;
import com.unicheck.model.dto.UserResponse;
import com.unicheck.model.dto.UserUpdateRequest;
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

    @Override
    @Transactional
    public UserResponse updateUser(Long id, UserUpdateRequest request, HttpServletRequest httpRequest) {
        // 1. Tìm kiếm User theo ID
        User user = userRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND, "Không tìm thấy người dùng với ID: " + id));

        // 2. Kiểm tra tính duy nhất của email (nếu thay đổi)
        if (StringUtils.hasText(request.getEmail()) && !request.getEmail().equalsIgnoreCase(user.getEmail())) {
            if (userRepository.existsByEmail(request.getEmail())) {
                throw new AppException(ErrorCode.USER_ALREADY_EXISTS, "Email '" + request.getEmail() + "' đã được sử dụng");
            }
        }

        // 3. Kiểm tra tính duy nhất của mã định danh (nếu thay đổi)
        if (StringUtils.hasText(request.getCode()) && !request.getCode().equalsIgnoreCase(user.getCode())) {
            if (userRepository.existsByCode(request.getCode())) {
                throw new AppException(ErrorCode.USER_ALREADY_EXISTS, "Mã định danh '" + request.getCode() + "' đã được sử dụng");
            }
        }

        // 4. Ghi nhận snapshot cũ trước khi thay đổi (Old Value)
        String oldValue = String.format("fullName='%s', email='%s', phone='%s', code='%s', role='%s', sex='%s'",
                user.getFullName(), user.getEmail(), user.getPhone(), user.getCode(), user.getRole(), user.getSex());
        Role oldRole = user.getRole();

        // 5. Cập nhật các trường thông tin cơ bản
        if (StringUtils.hasText(request.getFullName())) {
            user.setFullName(request.getFullName());
        }
        if (StringUtils.hasText(request.getEmail())) {
            user.setEmail(request.getEmail());
        }
        if (request.getCode() != null) {
            user.setCode(request.getCode());
        }
        if (request.getPhone() != null) {
            user.setPhone(request.getPhone());
        }
        if (request.getDob() != null) {
            user.setDob(request.getDob());
        }
        if (StringUtils.hasText(request.getSex())) {
            user.setSex(request.getSex());
        }
        if (StringUtils.hasText(request.getAvatar())) {
            user.setAvatar(request.getAvatar());
        }
        if (request.getRole() != null) {
            user.setRole(request.getRole());
        }
        user.setUpdatedAt(LocalDateTime.now());

        // 6. Cập nhật Profile theo vai trò
        if (user.getRole() == Role.STUDENT) {
            StudentProfile studentProfile = studentProfileRepository.findByUserId(user.getId())
                    .orElseGet(() -> StudentProfile.builder().user(user).build());

            if (request.getStudentCourse() != null) studentProfile.setCourse(request.getStudentCourse());
            if (request.getMajorId() != null) studentProfile.setMajorId(request.getMajorId());
            if (request.getSpecializationId() != null) studentProfile.setSpecializationId(request.getSpecializationId());
            if (request.getSubSpecializationId() != null) studentProfile.setSubSpecializationId(request.getSubSpecializationId());
            studentProfileRepository.save(studentProfile);
            user.setStudentProfile(studentProfile);
        } else if (user.getRole() == Role.LECTURER) {
            LecturerProfile lecturerProfile = lecturerProfileRepository.findByUserId(user.getId())
                    .orElseGet(() -> LecturerProfile.builder().user(user).build());

            if (request.getDepartment() != null) lecturerProfile.setDepartment(request.getDepartment());
            if (request.getExpertise() != null) lecturerProfile.setExpertise(request.getExpertise());
            if (request.getBio() != null) lecturerProfile.setBio(request.getBio());
            lecturerProfileRepository.save(lecturerProfile);
            user.setLecturerProfile(lecturerProfile);
        }

        User updatedUser = userRepository.save(user);

        // 7. Ghi nhận snapshot mới sau khi thay đổi (New Value)
        String newValue = String.format("fullName='%s', email='%s', phone='%s', code='%s', role='%s', sex='%s'",
                updatedUser.getFullName(), updatedUser.getEmail(), updatedUser.getPhone(), updatedUser.getCode(), updatedUser.getRole(), updatedUser.getSex());

        // 8. Ghi Audit Log (ai, lúc nào, làm gì)
        User performer = getCurrentAuthenticatedUser();
        String action = (oldRole != updatedUser.getRole()) ? "USER_ROLE_CHANGED" : "USER_UPDATE";
        String description = String.format("Cập nhật tài khoản người dùng: %s (ID: %d)%s",
                updatedUser.getUsername(),
                updatedUser.getId(),
                (oldRole != updatedUser.getRole()) ? " [Đổi vai trò: " + oldRole + " -> " + updatedUser.getRole() + "]" : "");

        systemLogService.logAudit(
                action,
                description,
                performer,
                oldValue,
                newValue,
                httpRequest
        );

        return mapToUserResponse(updatedUser);
    }

    @Override
    @Transactional
    public void deleteUser(Long id, HttpServletRequest httpRequest) {
        // 1. Kiểm tra tồn tại
        User user = userRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND, "Không tìm thấy người dùng với ID: " + id));

        // 2. Không cho phép tự xóa tài khoản của chính mình
        User performer = getCurrentAuthenticatedUser();
        if (performer != null && performer.getId().equals(id)) {
            throw new AppException(ErrorCode.INVALID_REQUEST, "Bạn không thể tự xóa tài khoản của chính mình");
        }

        // 3. Snapshot thông tin cũ để ghi Audit log
        String oldValue = String.format("id=%d, username='%s', email='%s', fullName='%s', code='%s', role='%s', status='%s'",
                user.getId(), user.getUsername(), user.getEmail(), user.getFullName(),
                user.getCode() != null ? user.getCode() : "N/A", user.getRole(), user.getStatus());

        // 4. Thực hiện xóa đối tượng
        userRepository.delete(user);

        // 5. Ghi Audit Log (ai, lúc nào, làm gì)
        String description = String.format("Xóa tài khoản người dùng: %s (ID: %d, Vai trò: %s)",
                user.getUsername(), id, user.getRole());

        systemLogService.logAudit(
                "USER_DELETE",
                description,
                performer,
                oldValue,
                null,
                httpRequest
        );
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
