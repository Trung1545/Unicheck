package com.unicheck.service.impl;

import com.unicheck.exception.AppException;
import com.unicheck.exception.ErrorCode;
import com.unicheck.model.dto.EnrollmentCreateRequest;
import com.unicheck.model.dto.EnrollmentResponse;
import com.unicheck.model.entity.ClassSection;
import com.unicheck.model.entity.Enrollment;
import com.unicheck.model.entity.User;
import com.unicheck.model.enums.ClassSectionStatus;
import com.unicheck.model.enums.EnrollmentStatus;
import com.unicheck.model.enums.Role;
import com.unicheck.repository.ClassSectionRepository;
import com.unicheck.repository.EnrollmentRepository;
import com.unicheck.repository.UserRepository;
import com.unicheck.service.EnrollmentService;
import com.unicheck.service.SystemLogService;
import jakarta.persistence.criteria.Predicate;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class EnrollmentServiceImpl implements EnrollmentService {

    private final EnrollmentRepository enrollmentRepository;
    private final ClassSectionRepository classSectionRepository;
    private final UserRepository userRepository;
    private final SystemLogService systemLogService;

    @Override
    @Transactional(readOnly = true)
    public Page<EnrollmentResponse> getEnrollments(
            String className,
            Long studentId,
            EnrollmentStatus status,
            String search,
            Pageable pageable) {

        User currentUser = getCurrentAuthenticatedUser();

        Specification<Enrollment> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (StringUtils.hasText(className)) {
                predicates.add(cb.equal(root.get("classSection").get("className"), className.trim().toUpperCase()));
            }

            if (studentId != null) {
                predicates.add(cb.equal(root.get("student").get("id"), studentId));
            }

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            if (StringUtils.hasText(search)) {
                String likePattern = "%" + search.trim().toLowerCase() + "%";
                predicates.add(cb.or(
                        cb.like(cb.lower(root.get("studentCode")), likePattern),
                        cb.like(cb.lower(root.get("student").get("fullName")), likePattern),
                        cb.like(cb.lower(root.get("student").get("email")), likePattern)
                ));
            }

            // Role-based scoping
            if (currentUser != null) {
                if (currentUser.getRole() == Role.LECTURER) {
                    predicates.add(cb.equal(root.get("classSection").get("lecturer").get("id"), currentUser.getId()));
                } else if (currentUser.getRole() == Role.STUDENT) {
                    predicates.add(cb.equal(root.get("student").get("id"), currentUser.getId()));
                }
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        return enrollmentRepository.findAll(spec, pageable).map(this::mapToEnrollmentResponse);
    }

    @Override
    @Transactional(readOnly = true)
    public List<EnrollmentResponse> getStudentsByClass(String className) {
        ClassSection classSection = classSectionRepository.findByClassName(className)
                .orElseThrow(() -> new AppException(ErrorCode.CLASS_NOT_FOUND, "Không tìm thấy lớp học phần: " + className));

        User currentUser = getCurrentAuthenticatedUser();
        if (currentUser != null) {
            if (currentUser.getRole() == Role.LECTURER) {
                if (classSection.getLecturer() == null || !classSection.getLecturer().getId().equals(currentUser.getId())) {
                    throw new AppException(ErrorCode.FORBIDDEN, "Bạn không có quyền truy cập danh sách sinh viên lớp này");
                }
            } else if (currentUser.getRole() == Role.STUDENT) {
                boolean isEnrolled = enrollmentRepository.existsByClassSection_ClassNameAndStudent_Id(className, currentUser.getId());
                if (!isEnrolled) {
                    throw new AppException(ErrorCode.FORBIDDEN, "Bạn chưa ghi danh vào lớp học phần này");
                }
            }
        }

        return enrollmentRepository.findByClassSection_ClassName(className).stream()
                .map(this::mapToEnrollmentResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public EnrollmentResponse getEnrollmentById(Long id) {
        Enrollment enrollment = enrollmentRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.ENROLLMENT_NOT_FOUND, "Không tìm thấy bản ghi ghi danh với ID: " + id));

        User currentUser = getCurrentAuthenticatedUser();
        if (currentUser != null) {
            if (currentUser.getRole() == Role.LECTURER) {
                if (enrollment.getClassSection().getLecturer() == null ||
                        !enrollment.getClassSection().getLecturer().getId().equals(currentUser.getId())) {
                    throw new AppException(ErrorCode.FORBIDDEN, "Bạn không có quyền truy cập bản ghi ghi danh này");
                }
            } else if (currentUser.getRole() == Role.STUDENT) {
                if (!enrollment.getStudent().getId().equals(currentUser.getId())) {
                    throw new AppException(ErrorCode.FORBIDDEN, "Bạn không có quyền xem thông tin ghi danh của sinh viên khác");
                }
            }
        }

        return mapToEnrollmentResponse(enrollment);
    }

    @Override
    @Transactional
    public EnrollmentResponse createEnrollment(EnrollmentCreateRequest request, HttpServletRequest httpRequest) {
        String cleanClassName = request.getClassName().trim().toUpperCase();

        ClassSection classSection = classSectionRepository.findByClassName(cleanClassName)
                .orElseThrow(() -> new AppException(ErrorCode.CLASS_NOT_FOUND, "Không tìm thấy lớp học phần: " + cleanClassName));

        if (classSection.getStatus() == ClassSectionStatus.CANCELLED || classSection.getStatus() == ClassSectionStatus.CLOSED) {
            throw new AppException(ErrorCode.CLASS_NOT_OPEN,
                    "Không thể ghi danh vào lớp học phần đã đóng hoặc tạm hủy (Trạng thái: " + classSection.getStatus() + ")");
        }

        if (classSection.getCurrentEnrollment() >= classSection.getMaxStudents()) {
            throw new AppException(ErrorCode.CLASS_FULL,
                    "Lớp học phần đã đạt sĩ số tối đa (" + classSection.getMaxStudents() + " SV)");
        }

        User student = userRepository.findById(request.getStudentId())
                .orElseThrow(() -> new AppException(ErrorCode.STUDENT_NOT_FOUND, "Không tìm thấy sinh viên với ID: " + request.getStudentId()));

        if (student.getRole() != Role.STUDENT) {
            throw new AppException(ErrorCode.INVALID_STUDENT_ROLE, "Người dùng được chọn không có vai trò Sinh viên (STUDENT)");
        }

        if (enrollmentRepository.existsByClassSection_ClassNameAndStudent_Id(cleanClassName, student.getId())) {
            throw new AppException(ErrorCode.DUPLICATE_ENROLLMENT,
                    String.format("Sinh viên %s (%s) đã được ghi danh vào lớp học phần %s",
                            student.getFullName(),
                            student.getCode() != null ? student.getCode() : student.getUsername(),
                            cleanClassName));
        }

        String studentCode = student.getCode() != null && !student.getCode().isBlank()
                ? student.getCode()
                : student.getUsername();

        Enrollment enrollment = Enrollment.builder()
                .classSection(classSection)
                .student(student)
                .studentCode(studentCode)
                .status(EnrollmentStatus.ENROLLED)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        Enrollment saved = enrollmentRepository.save(enrollment);

        // Update current enrollment in class section
        classSection.setCurrentEnrollment(classSection.getCurrentEnrollment() + 1);
        classSectionRepository.save(classSection);

        User performer = getCurrentAuthenticatedUser();
        systemLogService.logAudit(
                "ENROLLMENT_CREATE",
                String.format("Ghi danh sinh viên %s (%s) vào lớp %s", student.getFullName(), studentCode, cleanClassName),
                performer,
                null,
                String.format("className=%s, studentId=%d, studentCode=%s", cleanClassName, student.getId(), studentCode),
                httpRequest
        );

        return mapToEnrollmentResponse(saved);
    }

    @Override
    @Transactional
    public void deleteEnrollment(Long id, HttpServletRequest httpRequest) {
        Enrollment enrollment = enrollmentRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.ENROLLMENT_NOT_FOUND, "Không tìm thấy bản ghi ghi danh với ID: " + id));

        long gradeCount = enrollmentRepository.countStudentGradesByEnrollmentId(id);
        if (gradeCount > 0) {
            throw new AppException(ErrorCode.CANNOT_DELETE_REFERENCED_RESOURCE,
                    "Không thể hủy ghi danh sinh viên đã có bản ghi điểm số trong lớp học phần (" + gradeCount + " bản ghi điểm)");
        }

        long attendanceCount = enrollmentRepository.countAttendanceRecords(
                enrollment.getClassSection().getClassName(),
                enrollment.getStudent().getId()
        );
        if (attendanceCount > 0) {
            throw new AppException(ErrorCode.CANNOT_DELETE_REFERENCED_RESOURCE,
                    "Không thể hủy ghi danh sinh viên đã có lịch sử điểm danh (" + attendanceCount + " buổi điểm danh)");
        }

        ClassSection cs = enrollment.getClassSection();
        if (cs.getCurrentEnrollment() != null && cs.getCurrentEnrollment() > 0) {
            cs.setCurrentEnrollment(cs.getCurrentEnrollment() - 1);
            classSectionRepository.save(cs);
        }

        String info = String.format("class=%s, student=%s (%s)",
                cs.getClassName(), enrollment.getStudent().getFullName(), enrollment.getStudentCode());

        enrollmentRepository.delete(enrollment);

        User performer = getCurrentAuthenticatedUser();
        systemLogService.logAudit(
                "ENROLLMENT_DELETE",
                "Hủy ghi danh sinh viên: " + info,
                performer,
                info,
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

    private EnrollmentResponse mapToEnrollmentResponse(Enrollment e) {
        String studentClass = null;
        if (e.getStudent().getStudentProfile() != null && e.getStudent().getStudentProfile().getCourse() != null) {
            studentClass = e.getStudent().getStudentProfile().getCourse();
        }

        return EnrollmentResponse.builder()
                .id(e.getId())
                .className(e.getClassSection().getClassName())
                .courseId(e.getClassSection().getCourse().getId())
                .courseCode(e.getClassSection().getCourse().getCode())
                .courseName(e.getClassSection().getCourse().getName())
                .semesterId(e.getClassSection().getSemester().getId())
                .semesterCode(e.getClassSection().getSemester().getCode())
                .studentId(e.getStudent().getId())
                .studentCode(e.getStudentCode())
                .studentName(e.getStudent().getFullName())
                .studentEmail(e.getStudent().getEmail())
                .studentClass(studentClass)
                .avatar(e.getStudent().getAvatar())
                .faceDataStatus(e.getStudent().getFaceDataStatus())
                .status(e.getStatus())
                .createdAt(e.getCreatedAt())
                .updatedAt(e.getUpdatedAt())
                .build();
    }
}
