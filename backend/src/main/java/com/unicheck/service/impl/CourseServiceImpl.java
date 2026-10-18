package com.unicheck.service.impl;

import com.unicheck.exception.AppException;
import com.unicheck.exception.ErrorCode;
import com.unicheck.model.dto.CourseCreateRequest;
import com.unicheck.model.dto.CourseResponse;
import com.unicheck.model.dto.CourseSummaryDto;
import com.unicheck.model.dto.CourseUpdateRequest;
import com.unicheck.model.entity.Course;
import com.unicheck.model.entity.User;
import com.unicheck.model.enums.CourseStatus;
import com.unicheck.repository.CourseRepository;
import com.unicheck.repository.UserRepository;
import com.unicheck.service.CourseService;
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
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class CourseServiceImpl implements CourseService {

    private final CourseRepository courseRepository;
    private final UserRepository userRepository;
    private final SystemLogService systemLogService;

    @Override
    @Transactional(readOnly = true)
    public Page<CourseResponse> getCourses(String search, Integer credits, CourseStatus status, Pageable pageable) {
        Specification<Course> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (StringUtils.hasText(search)) {
                String likePattern = "%" + search.trim().toLowerCase() + "%";
                predicates.add(cb.or(
                        cb.like(cb.lower(root.get("code")), likePattern),
                        cb.like(cb.lower(root.get("name")), likePattern)
                ));
            }

            if (credits != null) {
                predicates.add(cb.equal(root.get("credits"), credits));
            }

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        return courseRepository.findAll(spec, pageable).map(this::mapToCourseResponse);
    }

    @Override
    @Transactional(readOnly = true)
    public CourseResponse getCourseById(Long id) {
        Course course = courseRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.COURSE_NOT_FOUND, "Không tìm thấy học phần với ID: " + id));
        return mapToCourseResponse(course);
    }

    @Override
    @Transactional
    public CourseResponse createCourse(CourseCreateRequest request, HttpServletRequest httpRequest) {
        String cleanCode = request.getCode().trim().toUpperCase();
        if (courseRepository.existsByCode(cleanCode)) {
            throw new AppException(ErrorCode.DUPLICATE_RESOURCE, "Mã học phần '" + cleanCode + "' đã tồn tại trong hệ thống");
        }

        Set<Course> prerequisites = new HashSet<>();
        if (request.getPrerequisiteIds() != null && !request.getPrerequisiteIds().isEmpty()) {
            for (Long prereqId : request.getPrerequisiteIds()) {
                Course prereq = courseRepository.findById(prereqId)
                        .orElseThrow(() -> new AppException(ErrorCode.COURSE_NOT_FOUND, "Không tìm thấy học phần tiên quyết với ID: " + prereqId));
                prerequisites.add(prereq);
            }
        }

        Course course = Course.builder()
                .code(cleanCode)
                .name(request.getName().trim())
                .description(request.getDescription())
                .credits(request.getCredits())
                .numberOfSlots(request.getNumberOfSlots())
                .status(request.getStatus() != null ? request.getStatus() : CourseStatus.ACTIVE)
                .isCalculatedInGpa(request.getIsCalculatedInGpa() != null ? request.getIsCalculatedInGpa() : true)
                .prerequisites(prerequisites)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        Course saved = courseRepository.save(course);

        User performer = getCurrentAuthenticatedUser();
        systemLogService.logAudit(
                "COURSE_CREATE",
                String.format("Tạo mới học phần: %s (%s) - %d tín chỉ", saved.getName(), saved.getCode(), saved.getCredits()),
                performer,
                null,
                String.format("code=%s, name=%s, credits=%d", saved.getCode(), saved.getName(), saved.getCredits()),
                httpRequest
        );

        return mapToCourseResponse(saved);
    }

    @Override
    @Transactional
    public CourseResponse updateCourse(Long id, CourseUpdateRequest request, HttpServletRequest httpRequest) {
        Course course = courseRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.COURSE_NOT_FOUND, "Không tìm thấy học phần với ID: " + id));

        String oldValue = String.format("name=%s, credits=%d, slots=%d, status=%s",
                course.getName(), course.getCredits(), course.getNumberOfSlots(), course.getStatus());

        course.setName(request.getName().trim());
        course.setDescription(request.getDescription());
        course.setCredits(request.getCredits());
        course.setNumberOfSlots(request.getNumberOfSlots());

        if (request.getStatus() != null) {
            course.setStatus(request.getStatus());
        }
        if (request.getIsCalculatedInGpa() != null) {
            course.setIsCalculatedInGpa(request.getIsCalculatedInGpa());
        }

        // Cập nhật môn tiên quyết
        if (request.getPrerequisiteIds() != null) {
            if (request.getPrerequisiteIds().contains(id)) {
                throw new AppException(ErrorCode.CIRCULAR_PREREQUISITE, "Học phần không thể đặt chính nó làm môn tiên quyết");
            }

            Set<Course> updatedPrereqs = new HashSet<>();
            for (Long prereqId : request.getPrerequisiteIds()) {
                Course prereq = courseRepository.findById(prereqId)
                        .orElseThrow(() -> new AppException(ErrorCode.COURSE_NOT_FOUND, "Không tìm thấy môn tiên quyết với ID: " + prereqId));
                
                // Kiểm tra chu trình lặp: nếu môn tiên quyết này đã có course hiện tại làm môn tiên quyết của nó
                if (prereq.getPrerequisites().stream().anyMatch(p -> p.getId().equals(id))) {
                    throw new AppException(ErrorCode.CIRCULAR_PREREQUISITE,
                            String.format("Phát hiện chu trình phụ thuộc vòng giữa học phần '%s' và '%s'", course.getCode(), prereq.getCode()));
                }
                updatedPrereqs.add(prereq);
            }
            course.setPrerequisites(updatedPrereqs);
        }

        course.setUpdatedAt(LocalDateTime.now());
        Course updated = courseRepository.save(course);

        String newValue = String.format("name=%s, credits=%d, slots=%d, status=%s",
                updated.getName(), updated.getCredits(), updated.getNumberOfSlots(), updated.getStatus());

        User performer = getCurrentAuthenticatedUser();
        systemLogService.logAudit(
                "COURSE_UPDATE",
                String.format("Cập nhật học phần: %s (%s)", updated.getName(), updated.getCode()),
                performer,
                oldValue,
                newValue,
                httpRequest
        );

        return mapToCourseResponse(updated);
    }

    @Override
    @Transactional
    public void deleteCourse(Long id, HttpServletRequest httpRequest) {
        Course course = courseRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.COURSE_NOT_FOUND, "Không tìm thấy học phần với ID: " + id));

        // Kiểm tra toàn vẹn quan hệ: nếu học phần này đang là tiên quyết của môn khác
        if (courseRepository.isPrerequisiteForOthers(id)) {
            throw new AppException(ErrorCode.CANNOT_DELETE_REFERENCED_RESOURCE,
                    "Không thể xóa học phần '" + course.getCode() + "' vì đang là môn tiên quyết của học phần khác trong hệ thống");
        }

        courseRepository.delete(course);

        User performer = getCurrentAuthenticatedUser();
        systemLogService.logAudit(
                "COURSE_DELETE",
                String.format("Xóa học phần: %s (%s)", course.getName(), course.getCode()),
                performer,
                String.format("id=%d, code=%s", course.getId(), course.getCode()),
                null,
                httpRequest
        );
    }

    @Override
    @Transactional(readOnly = true)
    public boolean existsByCode(String code) {
        if (!StringUtils.hasText(code)) return false;
        return courseRepository.existsByCode(code.trim().toUpperCase());
    }

    @Override
    @Transactional(readOnly = true)
    public List<CourseSummaryDto> getAllCourseSummaries() {
        return courseRepository.findAll().stream()
                .map(c -> CourseSummaryDto.builder()
                        .id(c.getId())
                        .code(c.getCode())
                        .name(c.getName())
                        .credits(c.getCredits())
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

    private CourseResponse mapToCourseResponse(Course course) {
        List<CourseSummaryDto> prereqDtos = Collections.emptyList();
        if (course.getPrerequisites() != null && !course.getPrerequisites().isEmpty()) {
            prereqDtos = course.getPrerequisites().stream()
                    .map(p -> CourseSummaryDto.builder()
                            .id(p.getId())
                            .code(p.getCode())
                            .name(p.getName())
                            .credits(p.getCredits())
                            .build())
                    .sorted(Comparator.comparing(CourseSummaryDto::getCode))
                    .collect(Collectors.toList());
        }

        return CourseResponse.builder()
                .id(course.getId())
                .code(course.getCode())
                .name(course.getName())
                .description(course.getDescription())
                .credits(course.getCredits())
                .numberOfSlots(course.getNumberOfSlots())
                .status(course.getStatus())
                .isCalculatedInGpa(course.getIsCalculatedInGpa())
                .prerequisites(prereqDtos)
                .createdAt(course.getCreatedAt())
                .updatedAt(course.getUpdatedAt())
                .build();
    }
}
