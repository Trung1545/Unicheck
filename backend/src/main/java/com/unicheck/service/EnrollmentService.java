package com.unicheck.service;

import com.unicheck.model.dto.EnrollmentCreateRequest;
import com.unicheck.model.dto.EnrollmentResponse;
import com.unicheck.model.enums.EnrollmentStatus;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface EnrollmentService {

    Page<EnrollmentResponse> getEnrollments(String className, Long studentId, EnrollmentStatus status, String search, Pageable pageable);

    List<EnrollmentResponse> getStudentsByClass(String className);

    EnrollmentResponse getEnrollmentById(Long id);

    EnrollmentResponse createEnrollment(EnrollmentCreateRequest request, HttpServletRequest httpRequest);

    void deleteEnrollment(Long id, HttpServletRequest httpRequest);
}
