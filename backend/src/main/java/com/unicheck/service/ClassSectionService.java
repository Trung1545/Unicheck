package com.unicheck.service;

import com.unicheck.model.dto.*;
import com.unicheck.model.enums.ClassSectionStatus;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface ClassSectionService {

    Page<ClassSectionResponse> getClassSections(String search, Long semesterId, Long courseId, Long lecturerId, ClassSectionStatus status, Pageable pageable);

    ClassSectionResponse getClassSectionByClassName(String className);

    boolean existsByClassName(String className);

    ClassSectionResponse createClassSection(ClassSectionCreateRequest request, HttpServletRequest httpRequest);

    ClassSectionResponse updateClassSection(String className, ClassSectionUpdateRequest request, HttpServletRequest httpRequest);

    void deleteClassSection(String className, HttpServletRequest httpRequest);

    ClassSectionStatsResponse getStats(Long semesterId);

    List<ClassSectionSummaryDto> getClassSummaries(Long semesterId);
}
