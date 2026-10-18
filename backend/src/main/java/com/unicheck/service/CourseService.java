package com.unicheck.service;

import com.unicheck.model.dto.CourseCreateRequest;
import com.unicheck.model.dto.CourseResponse;
import com.unicheck.model.dto.CourseSummaryDto;
import com.unicheck.model.dto.CourseUpdateRequest;
import com.unicheck.model.enums.CourseStatus;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface CourseService {

    Page<CourseResponse> getCourses(String search, Integer credits, CourseStatus status, Pageable pageable);

    CourseResponse getCourseById(Long id);

    CourseResponse createCourse(CourseCreateRequest request, HttpServletRequest httpRequest);

    CourseResponse updateCourse(Long id, CourseUpdateRequest request, HttpServletRequest httpRequest);

    void deleteCourse(Long id, HttpServletRequest httpRequest);

    boolean existsByCode(String code);

    List<CourseSummaryDto> getAllCourseSummaries();
}
