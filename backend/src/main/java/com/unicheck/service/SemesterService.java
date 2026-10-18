package com.unicheck.service;

import com.unicheck.model.dto.SemesterCreateRequest;
import com.unicheck.model.dto.SemesterResponse;
import com.unicheck.model.dto.SemesterUpdateRequest;
import com.unicheck.model.enums.SemesterStatus;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface SemesterService {

    Page<SemesterResponse> getSemesters(String search, SemesterStatus status, Pageable pageable);

    SemesterResponse getSemesterById(Long id);

    SemesterResponse getActiveSemester();

    SemesterResponse createSemester(SemesterCreateRequest request, HttpServletRequest httpRequest);

    SemesterResponse updateSemester(Long id, SemesterUpdateRequest request, HttpServletRequest httpRequest);

    void deleteSemester(Long id, HttpServletRequest httpRequest);

    SemesterResponse lockSemester(Long id, HttpServletRequest httpRequest);

    boolean existsByCode(String code);
}
