package com.unicheck.service;

import com.unicheck.model.entity.AttendanceRecheckRequest;
import com.unicheck.model.entity.AttendanceVerificationAttempt;
import com.unicheck.model.entity.User;
import com.unicheck.repository.AttendanceVerificationAttemptRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AttendanceVerificationAttemptService {

    private final AttendanceVerificationAttemptRepository attemptRepository;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void recordAttempt(
            AttendanceRecheckRequest req,
            User student,
            boolean qr,
            boolean wifi,
            boolean face,
            boolean liveness,
            String status,
            String errCode,
            String reason
    ) {
        if (req == null || student == null) return;
        try {
            AttendanceVerificationAttempt attempt = AttendanceVerificationAttempt.builder()
                    .recheckRequest(req)
                    .student(student)
                    .qrResult(qr ? "PASSED" : "FAILED")
                    .wifiResult(wifi ? "PASSED" : "FAILED")
                    .faceMatchResult(face ? "PASSED" : "FAILED")
                    .livenessResult(liveness ? "PASSED" : "FAILED")
                    .verificationStatus(status)
                    .failureCode(errCode)
                    .failureReason(reason)
                    .build();
            attemptRepository.saveAndFlush(attempt);
        } catch (Exception ex) {
            log.error("Không thể lưu lịch sử xác thực điểm danh lại (Attempt): {}", ex.getMessage());
        }
    }
}
