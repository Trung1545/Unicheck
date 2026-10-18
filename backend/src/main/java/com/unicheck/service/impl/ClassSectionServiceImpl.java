package com.unicheck.service.impl;

import com.unicheck.exception.AppException;
import com.unicheck.exception.ErrorCode;
import com.unicheck.model.dto.*;
import com.unicheck.model.entity.*;
import com.unicheck.model.enums.ClassSectionStatus;
import com.unicheck.model.enums.Role;
import com.unicheck.repository.*;
import com.unicheck.service.ClassSectionService;
import com.unicheck.service.SystemLogService;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Root;
import jakarta.persistence.criteria.Subquery;
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
public class ClassSectionServiceImpl implements ClassSectionService {

    private final ClassSectionRepository classSectionRepository;
    private final CourseRepository courseRepository;
    private final SemesterRepository semesterRepository;
    private final UserRepository userRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final TeachingAssignmentRepository teachingAssignmentRepository;
    private final SystemLogService systemLogService;

    @Override
    @Transactional(readOnly = true)
    public Page<ClassSectionResponse> getClassSections(
            String search,
            Long semesterId,
            Long courseId,
            Long lecturerId,
            ClassSectionStatus status,
            Pageable pageable) {

        User currentUser = getCurrentAuthenticatedUser();

        Specification<ClassSection> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            // 1. Text Search (Class name, course code, course name, lecturer name)
            if (StringUtils.hasText(search)) {
                String likePattern = "%" + search.trim().toLowerCase() + "%";
                predicates.add(cb.or(
                        cb.like(cb.lower(root.get("className")), likePattern),
                        cb.like(cb.lower(root.get("course").get("code")), likePattern),
                        cb.like(cb.lower(root.get("course").get("name")), likePattern),
                        cb.like(cb.lower(root.get("lecturer").get("fullName")), likePattern)
                ));
            }

            // 2. Filters
            if (semesterId != null) {
                predicates.add(cb.equal(root.get("semester").get("id"), semesterId));
            }

            if (courseId != null) {
                predicates.add(cb.equal(root.get("course").get("id"), courseId));
            }

            if (lecturerId != null) {
                predicates.add(cb.equal(root.get("lecturer").get("id"), lecturerId));
            }

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            // 3. Role-based scoping
            if (currentUser != null) {
                if (currentUser.getRole() == Role.LECTURER) {
                    predicates.add(cb.equal(root.get("lecturer").get("id"), currentUser.getId()));
                } else if (currentUser.getRole() == Role.STUDENT) {
                    Subquery<Long> subquery = query.subquery(Long.class);
                    Root<Enrollment> enrollRoot = subquery.from(Enrollment.class);
                    subquery.select(cb.literal(1L))
                            .where(
                                    cb.equal(enrollRoot.get("classSection").get("className"), root.get("className")),
                                    cb.equal(enrollRoot.get("student").get("id"), currentUser.getId())
                            );
                    predicates.add(cb.exists(subquery));
                }
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        return classSectionRepository.findAll(spec, pageable).map(this::mapToClassSectionResponse);
    }

    @Override
    @Transactional(readOnly = true)
    public ClassSectionResponse getClassSectionByClassName(String className) {
        ClassSection classSection = classSectionRepository.findByClassName(className)
                .orElseThrow(() -> new AppException(ErrorCode.CLASS_NOT_FOUND, "Không tìm thấy lớp học phần: " + className));

        User currentUser = getCurrentAuthenticatedUser();
        if (currentUser != null) {
            if (currentUser.getRole() == Role.LECTURER) {
                if (classSection.getLecturer() == null || !classSection.getLecturer().getId().equals(currentUser.getId())) {
                    throw new AppException(ErrorCode.FORBIDDEN, "Bạn không có quyền truy cập lớp học phần này");
                }
            } else if (currentUser.getRole() == Role.STUDENT) {
                boolean enrolled = enrollmentRepository.existsByClassSection_ClassNameAndStudent_Id(className, currentUser.getId());
                if (!enrolled) {
                    throw new AppException(ErrorCode.FORBIDDEN, "Bạn chưa ghi danh vào lớp học phần này");
                }
            }
        }

        return mapToClassSectionResponse(classSection);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean existsByClassName(String className) {
        return classSectionRepository.existsByClassName(className.trim().toUpperCase());
    }

    @Override
    @Transactional
    public ClassSectionResponse createClassSection(ClassSectionCreateRequest request, HttpServletRequest httpRequest) {
        String cleanClassName = request.getClassName().trim().toUpperCase();

        if (classSectionRepository.existsByClassName(cleanClassName)) {
            throw new AppException(ErrorCode.CLASS_ALREADY_EXISTS, "Mã lớp học phần đã tồn tại: " + cleanClassName);
        }

        Course course = courseRepository.findById(request.getCourseId())
                .orElseThrow(() -> new AppException(ErrorCode.COURSE_NOT_FOUND, "Không tìm thấy học phần với ID: " + request.getCourseId()));

        Semester semester = semesterRepository.findById(request.getSemesterId())
                .orElseThrow(() -> new AppException(ErrorCode.SEMESTER_NOT_FOUND, "Không tìm thấy học kỳ với ID: " + request.getSemesterId()));

        User lecturer = null;
        if (request.getLecturerId() != null) {
            lecturer = userRepository.findById(request.getLecturerId())
                    .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND, "Không tìm thấy giảng viên với ID: " + request.getLecturerId()));
            if (lecturer.getRole() != Role.LECTURER) {
                throw new AppException(ErrorCode.INVALID_LECTURER_ROLE, "Người dùng được chọn không có vai trò Giảng viên (LECTURER)");
            }

            // Sync teaching assignment
            if (!teachingAssignmentRepository.existsByLecturer_IdAndCourse_IdAndSemester_Id(lecturer.getId(), course.getId(), semester.getId())) {
                teachingAssignmentRepository.save(TeachingAssignment.builder()
                        .lecturer(lecturer)
                        .course(course)
                        .semester(semester)
                        .build());
            }
        }

        int slots = request.getNumberOfSlots() != null && request.getNumberOfSlots() > 0
                ? request.getNumberOfSlots()
                : (course.getNumberOfSlots() != null ? course.getNumberOfSlots() : 45);

        ClassSection classSection = ClassSection.builder()
                .className(cleanClassName)
                .course(course)
                .semester(semester)
                .lecturer(lecturer)
                .numberOfSlots(slots)
                .maxStudents(request.getMaxStudents())
                .currentEnrollment(0)
                .status(request.getStatus() != null ? request.getStatus() : ClassSectionStatus.OPEN)
                .gradesSubmitted(false)
                .gradesPublished(false)
                .resitGradesPublished(false)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        ClassSection saved = classSectionRepository.save(classSection);

        User performer = getCurrentAuthenticatedUser();
        systemLogService.logAudit(
                "CLASS_CREATE",
                String.format("Tạo mới lớp học phần: %s cho môn %s (%s)", saved.getClassName(), course.getName(), course.getCode()),
                performer,
                null,
                String.format("className=%s, maxStudents=%d", saved.getClassName(), saved.getMaxStudents()),
                httpRequest
        );

        return mapToClassSectionResponse(saved);
    }

    @Override
    @Transactional
    public ClassSectionResponse updateClassSection(String className, ClassSectionUpdateRequest request, HttpServletRequest httpRequest) {
        ClassSection classSection = classSectionRepository.findByClassName(className)
                .orElseThrow(() -> new AppException(ErrorCode.CLASS_NOT_FOUND, "Không tìm thấy lớp học phần: " + className));

        if (request.getMaxStudents() < classSection.getCurrentEnrollment()) {
            throw new AppException(ErrorCode.INVALID_REQUEST,
                    "Sĩ số tối đa (" + request.getMaxStudents() + ") không được nhỏ hơn số sinh viên hiện đã ghi danh (" + classSection.getCurrentEnrollment() + ")");
        }

        String oldValue = String.format("maxStudents=%d, status=%s, lecturer=%s",
                classSection.getMaxStudents(),
                classSection.getStatus(),
                classSection.getLecturer() != null ? classSection.getLecturer().getFullName() : "null");

        if (request.getLecturerId() != null) {
            User lecturer = userRepository.findById(request.getLecturerId())
                    .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND, "Không tìm thấy giảng viên với ID: " + request.getLecturerId()));
            if (lecturer.getRole() != Role.LECTURER) {
                throw new AppException(ErrorCode.INVALID_LECTURER_ROLE, "Người dùng được chọn không có vai trò Giảng viên (LECTURER)");
            }

            if (!teachingAssignmentRepository.existsByLecturer_IdAndCourse_IdAndSemester_Id(lecturer.getId(), classSection.getCourse().getId(), classSection.getSemester().getId())) {
                teachingAssignmentRepository.save(TeachingAssignment.builder()
                        .lecturer(lecturer)
                        .course(classSection.getCourse())
                        .semester(classSection.getSemester())
                        .build());
            }
            classSection.setLecturer(lecturer);
        } else {
            classSection.setLecturer(null);
        }

        classSection.setMaxStudents(request.getMaxStudents());
        if (request.getNumberOfSlots() != null && request.getNumberOfSlots() > 0) {
            classSection.setNumberOfSlots(request.getNumberOfSlots());
        }
        if (request.getStatus() != null) {
            classSection.setStatus(request.getStatus());
        }

        ClassSection saved = classSectionRepository.save(classSection);

        User performer = getCurrentAuthenticatedUser();
        systemLogService.logAudit(
                "CLASS_UPDATE",
                String.format("Cập nhật lớp học phần: %s", saved.getClassName()),
                performer,
                oldValue,
                String.format("maxStudents=%d, status=%s, lecturer=%s",
                        saved.getMaxStudents(),
                        saved.getStatus(),
                        saved.getLecturer() != null ? saved.getLecturer().getFullName() : "null"),
                httpRequest
        );

        return mapToClassSectionResponse(saved);
    }

    @Override
    @Transactional
    public void deleteClassSection(String className, HttpServletRequest httpRequest) {
        ClassSection classSection = classSectionRepository.findByClassName(className)
                .orElseThrow(() -> new AppException(ErrorCode.CLASS_NOT_FOUND, "Không tìm thấy lớp học phần: " + className));

        long enrollmentCount = enrollmentRepository.countByClassSection_ClassName(className);
        if (enrollmentCount > 0) {
            throw new AppException(ErrorCode.CANNOT_DELETE_REFERENCED_RESOURCE,
                    "Không thể xóa lớp học phần đang có " + enrollmentCount + " sinh viên ghi danh. Vui lòng hủy ghi danh trước khi xóa hoặc chuyển trạng thái sang CANCELLED.");
        }

        long timetableCount = classSectionRepository.countTimetableSlots(className);
        if (timetableCount > 0) {
            throw new AppException(ErrorCode.CANNOT_DELETE_REFERENCED_RESOURCE,
                    "Không thể xóa lớp học phần đang có " + timetableCount + " ca lịch học đã xếp.");
        }

        long assignmentCount = classSectionRepository.countAssignments(className);
        if (assignmentCount > 0) {
            throw new AppException(ErrorCode.CANNOT_DELETE_REFERENCED_RESOURCE,
                    "Không thể xóa lớp học phần đang có bài tập được gán.");
        }

        classSectionRepository.delete(classSection);

        User performer = getCurrentAuthenticatedUser();
        systemLogService.logAudit(
                "CLASS_DELETE",
                "Xóa lớp học phần: " + className,
                performer,
                className,
                null,
                httpRequest
        );
    }

    @Override
    @Transactional(readOnly = true)
    public ClassSectionStatsResponse getStats(Long semesterId) {
        List<ClassSection> sections;
        if (semesterId != null) {
            sections = classSectionRepository.findAll((root, query, cb) ->
                    cb.equal(root.get("semester").get("id"), semesterId));
        } else {
            sections = classSectionRepository.findAll();
        }

        long total = sections.size();
        long active = sections.stream().filter(s -> s.getStatus() == ClassSectionStatus.OPEN || s.getStatus() == ClassSectionStatus.ACTIVE).count();
        long fullCapacity = sections.stream().filter(s -> s.getMaxStudents() > 0 && ((double) s.getCurrentEnrollment() / s.getMaxStudents()) >= 0.8).count();
        long underCapacity = sections.stream().filter(s -> s.getCurrentEnrollment() < 15).count();

        return ClassSectionStatsResponse.builder()
                .totalClasses(total)
                .activeClasses(active)
                .fullCapacityClasses(fullCapacity)
                .underCapacityClasses(underCapacity)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public List<ClassSectionSummaryDto> getClassSummaries(Long semesterId) {
        Specification<ClassSection> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            if (semesterId != null) {
                predicates.add(cb.equal(root.get("semester").get("id"), semesterId));
            }
            return cb.and(predicates.toArray(new Predicate[0]));
        };

        return classSectionRepository.findAll(spec).stream()
                .map(cs -> ClassSectionSummaryDto.builder()
                        .className(cs.getClassName())
                        .courseId(cs.getCourse().getId())
                        .courseCode(cs.getCourse().getCode())
                        .courseName(cs.getCourse().getName())
                        .semesterId(cs.getSemester().getId())
                        .semesterCode(cs.getSemester().getCode())
                        .semesterName(cs.getSemester().getName())
                        .lecturerId(cs.getLecturer() != null ? cs.getLecturer().getId() : null)
                        .lecturerName(cs.getLecturer() != null ? cs.getLecturer().getFullName() : null)
                        .currentEnrollment(cs.getCurrentEnrollment())
                        .maxStudents(cs.getMaxStudents())
                        .status(cs.getStatus())
                        .build())
                .collect(Collectors.toList());
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

    private ClassSectionResponse mapToClassSectionResponse(ClassSection cs) {
        return ClassSectionResponse.builder()
                .className(cs.getClassName())
                .courseId(cs.getCourse().getId())
                .courseCode(cs.getCourse().getCode())
                .courseName(cs.getCourse().getName())
                .credits(cs.getCourse().getCredits())
                .semesterId(cs.getSemester().getId())
                .semesterCode(cs.getSemester().getCode())
                .semesterName(cs.getSemester().getName())
                .lecturerId(cs.getLecturer() != null ? cs.getLecturer().getId() : null)
                .lecturerCode(cs.getLecturer() != null ? cs.getLecturer().getCode() : null)
                .lecturerName(cs.getLecturer() != null ? cs.getLecturer().getFullName() : null)
                .lecturerEmail(cs.getLecturer() != null ? cs.getLecturer().getEmail() : null)
                .numberOfSlots(cs.getNumberOfSlots())
                .maxStudents(cs.getMaxStudents())
                .currentEnrollment(cs.getCurrentEnrollment())
                .status(cs.getStatus())
                .gradesSubmitted(cs.getGradesSubmitted())
                .gradesSubmittedAt(cs.getGradesSubmittedAt())
                .gradesPublished(cs.getGradesPublished())
                .gradesPublishedAt(cs.getGradesPublishedAt())
                .resitGradesPublished(cs.getResitGradesPublished())
                .resitGradesPublishedAt(cs.getResitGradesPublishedAt())
                .createdAt(cs.getCreatedAt())
                .updatedAt(cs.getUpdatedAt())
                .build();
    }
}
