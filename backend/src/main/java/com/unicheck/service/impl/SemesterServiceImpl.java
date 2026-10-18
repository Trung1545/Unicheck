package com.unicheck.service.impl;

import com.unicheck.exception.AppException;
import com.unicheck.exception.ErrorCode;
import com.unicheck.model.dto.SemesterConfigDto;
import com.unicheck.model.dto.SemesterCreateRequest;
import com.unicheck.model.dto.SemesterResponse;
import com.unicheck.model.dto.SemesterUpdateRequest;
import com.unicheck.model.entity.Semester;
import com.unicheck.model.entity.SemesterConfig;
import com.unicheck.model.entity.User;
import com.unicheck.model.enums.SemesterStatus;
import com.unicheck.repository.SemesterConfigRepository;
import com.unicheck.repository.SemesterRepository;
import com.unicheck.repository.UserRepository;
import com.unicheck.service.SemesterService;
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
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class SemesterServiceImpl implements SemesterService {

    private final SemesterRepository semesterRepository;
    private final SemesterConfigRepository semesterConfigRepository;
    private final UserRepository userRepository;
    private final SystemLogService systemLogService;

    @Override
    @Transactional(readOnly = true)
    public Page<SemesterResponse> getSemesters(String search, SemesterStatus status, Pageable pageable) {
        Specification<Semester> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (StringUtils.hasText(search)) {
                String likePattern = "%" + search.trim().toLowerCase() + "%";
                predicates.add(cb.or(
                        cb.like(cb.lower(root.get("code")), likePattern),
                        cb.like(cb.lower(root.get("name")), likePattern)
                ));
            }

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        return semesterRepository.findAll(spec, pageable).map(this::mapToSemesterResponse);
    }

    @Override
    @Transactional(readOnly = true)
    public SemesterResponse getSemesterById(Long id) {
        Semester semester = semesterRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.SEMESTER_NOT_FOUND, "Không tìm thấy học kỳ với ID: " + id));
        return mapToSemesterResponse(semester);
    }

    @Override
    @Transactional(readOnly = true)
    public SemesterResponse getActiveSemester() {
        Semester active = semesterRepository.findFirstByStatusOrderByStartDateDesc(SemesterStatus.ACTIVE)
                .orElse(null);
        if (active == null) {
            return null;
        }
        return mapToSemesterResponse(active);
    }

    @Override
    @Transactional
    public SemesterResponse createSemester(SemesterCreateRequest request, HttpServletRequest httpRequest) {
        String cleanCode = request.getCode().trim().toUpperCase();
        if (semesterRepository.existsByCode(cleanCode)) {
            throw new AppException(ErrorCode.DUPLICATE_RESOURCE, "Mã học kỳ '" + cleanCode + "' đã tồn tại trong hệ thống");
        }

        if (!request.getEndDate().isAfter(request.getStartDate())) {
            throw new AppException(ErrorCode.INVALID_REQUEST, "Ngày kết thúc học kỳ phải sau ngày bắt đầu");
        }

        SemesterStatus status = request.getStatus() != null ? request.getStatus() : SemesterStatus.ACTIVE;

        // Nếu kích hoạt học kỳ mới, tự động đưa các học kỳ ACTIVE khác về CLOSED
        if (status == SemesterStatus.ACTIVE) {
            List<Semester> currentActives = semesterRepository.findByStatus(SemesterStatus.ACTIVE);
            for (Semester s : currentActives) {
                s.setStatus(SemesterStatus.CLOSED);
                s.setUpdatedAt(LocalDateTime.now());
                semesterRepository.save(s);
            }
        }

        Semester semester = Semester.builder()
                .code(cleanCode)
                .name(request.getName().trim())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .status(status)
                .description(request.getDescription())
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        Semester saved = semesterRepository.save(semester);

        // Tạo cấu hình học kỳ kèm theo
        SemesterConfig config = SemesterConfig.builder()
                .semester(saved)
                .maxSlotPerDay(request.getMaxSlotPerDay() != null ? request.getMaxSlotPerDay() : 6)
                .slotPerSubjectPerWeek(request.getSlotPerSubjectPerWeek() != null ? request.getSlotPerSubjectPerWeek() : 2)
                .slotDuration(request.getSlotDuration() != null ? request.getSlotDuration() : 50)
                .isPublished(request.getIsPublished() != null ? request.getIsPublished() : false)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        semesterConfigRepository.save(config);
        saved.setConfig(config);

        User performer = getCurrentAuthenticatedUser();
        systemLogService.logAudit(
                "SEMESTER_CREATE",
                String.format("Tạo mới học kỳ: %s (%s) từ %s đến %s",
                        saved.getName(), saved.getCode(), saved.getStartDate(), saved.getEndDate()),
                performer,
                null,
                String.format("code=%s, name=%s, status=%s", saved.getCode(), saved.getName(), saved.getStatus()),
                httpRequest
        );

        return mapToSemesterResponse(saved);
    }

    @Override
    @Transactional
    public SemesterResponse updateSemester(Long id, SemesterUpdateRequest request, HttpServletRequest httpRequest) {
        Semester semester = semesterRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.SEMESTER_NOT_FOUND, "Không tìm thấy học kỳ với ID: " + id));

        if (!request.getEndDate().isAfter(request.getStartDate())) {
            throw new AppException(ErrorCode.INVALID_REQUEST, "Ngày kết thúc học kỳ phải sau ngày bắt đầu");
        }

        String oldValue = String.format("name=%s, start=%s, end=%s, status=%s",
                semester.getName(), semester.getStartDate(), semester.getEndDate(), semester.getStatus());

        semester.setName(request.getName().trim());
        semester.setStartDate(request.getStartDate());
        semester.setEndDate(request.getEndDate());
        semester.setDescription(request.getDescription());

        if (request.getStatus() != null) {
            // Nếu đổi sang ACTIVE, chuyển các kỳ ACTIVE khác về CLOSED
            if (request.getStatus() == SemesterStatus.ACTIVE && semester.getStatus() != SemesterStatus.ACTIVE) {
                List<Semester> currentActives = semesterRepository.findByStatus(SemesterStatus.ACTIVE);
                for (Semester s : currentActives) {
                    if (!s.getId().equals(id)) {
                        s.setStatus(SemesterStatus.CLOSED);
                        s.setUpdatedAt(LocalDateTime.now());
                        semesterRepository.save(s);
                    }
                }
            }
            semester.setStatus(request.getStatus());
        }

        // Cập nhật SemesterConfig
        SemesterConfig config = semesterConfigRepository.findBySemesterId(id).orElse(null);
        if (config == null) {
            config = SemesterConfig.builder()
                    .semester(semester)
                    .maxSlotPerDay(request.getMaxSlotPerDay() != null ? request.getMaxSlotPerDay() : 6)
                    .slotPerSubjectPerWeek(request.getSlotPerSubjectPerWeek() != null ? request.getSlotPerSubjectPerWeek() : 2)
                    .slotDuration(request.getSlotDuration() != null ? request.getSlotDuration() : 50)
                    .isPublished(request.getIsPublished() != null ? request.getIsPublished() : false)
                    .createdAt(LocalDateTime.now())
                    .updatedAt(LocalDateTime.now())
                    .build();
        } else {
            if (request.getMaxSlotPerDay() != null) config.setMaxSlotPerDay(request.getMaxSlotPerDay());
            if (request.getSlotPerSubjectPerWeek() != null) config.setSlotPerSubjectPerWeek(request.getSlotPerSubjectPerWeek());
            if (request.getSlotDuration() != null) config.setSlotDuration(request.getSlotDuration());
            if (request.getIsPublished() != null) config.setIsPublished(request.getIsPublished());
            config.setUpdatedAt(LocalDateTime.now());
        }
        semesterConfigRepository.save(config);
        semester.setConfig(config);

        semester.setUpdatedAt(LocalDateTime.now());
        Semester updated = semesterRepository.save(semester);

        String newValue = String.format("name=%s, start=%s, end=%s, status=%s",
                updated.getName(), updated.getStartDate(), updated.getEndDate(), updated.getStatus());

        User performer = getCurrentAuthenticatedUser();
        systemLogService.logAudit(
                "SEMESTER_UPDATE",
                String.format("Cập nhật học kỳ: %s (%s)", updated.getName(), updated.getCode()),
                performer,
                oldValue,
                newValue,
                httpRequest
        );

        return mapToSemesterResponse(updated);
    }

    @Override
    @Transactional
    public void deleteSemester(Long id, HttpServletRequest httpRequest) {
        Semester semester = semesterRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.SEMESTER_NOT_FOUND, "Không tìm thấy học kỳ với ID: " + id));

        semesterRepository.delete(semester);

        User performer = getCurrentAuthenticatedUser();
        systemLogService.logAudit(
                "SEMESTER_DELETE",
                String.format("Xóa học kỳ: %s (%s)", semester.getName(), semester.getCode()),
                performer,
                String.format("id=%d, code=%s", semester.getId(), semester.getCode()),
                null,
                httpRequest
        );
    }

    @Override
    @Transactional
    public SemesterResponse lockSemester(Long id, HttpServletRequest httpRequest) {
        Semester semester = semesterRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.SEMESTER_NOT_FOUND, "Không tìm thấy học kỳ với ID: " + id));

        String oldStatus = semester.getStatus().name();
        semester.setStatus(SemesterStatus.CLOSED);
        semester.setUpdatedAt(LocalDateTime.now());
        Semester locked = semesterRepository.save(semester);

        User performer = getCurrentAuthenticatedUser();
        systemLogService.logAudit(
                "SEMESTER_LOCK",
                String.format("Khóa sổ lưu trữ dữ liệu học kỳ: %s (%s)", locked.getName(), locked.getCode()),
                performer,
                "status=" + oldStatus,
                "status=CLOSED",
                httpRequest
        );

        return mapToSemesterResponse(locked);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean existsByCode(String code) {
        if (!StringUtils.hasText(code)) return false;
        return semesterRepository.existsByCode(code.trim().toUpperCase());
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

    private SemesterResponse mapToSemesterResponse(Semester semester) {
        SemesterConfig config = semester.getConfig();
        if (config == null) {
            config = semesterConfigRepository.findBySemesterId(semester.getId()).orElse(null);
        }

        SemesterConfigDto configDto = null;
        if (config != null) {
            configDto = SemesterConfigDto.builder()
                    .maxSlotPerDay(config.getMaxSlotPerDay())
                    .slotPerSubjectPerWeek(config.getSlotPerSubjectPerWeek())
                    .slotDuration(config.getSlotDuration())
                    .isPublished(config.getIsPublished())
                    .build();
        }

        long totalWeeks = 0;
        if (semester.getStartDate() != null && semester.getEndDate() != null) {
            totalWeeks = Math.max(1, ChronoUnit.WEEKS.between(semester.getStartDate(), semester.getEndDate()) + 1);
        }

        return SemesterResponse.builder()
                .id(semester.getId())
                .code(semester.getCode())
                .name(semester.getName())
                .startDate(semester.getStartDate())
                .endDate(semester.getEndDate())
                .status(semester.getStatus())
                .description(semester.getDescription())
                .config(configDto)
                .totalWeeks(totalWeeks)
                .createdAt(semester.getCreatedAt())
                .updatedAt(semester.getUpdatedAt())
                .build();
    }
}
