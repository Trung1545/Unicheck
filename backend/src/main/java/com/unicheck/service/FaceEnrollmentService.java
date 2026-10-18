package com.unicheck.service;

import com.unicheck.model.dto.FaceEnrollmentResponse;
import com.unicheck.model.dto.FaceRegistrationRequest;
import com.unicheck.model.dto.FaceStatusResponse;

public interface FaceEnrollmentService {

    /**
     * Đăng ký hoặc thu thập lại dữ liệu sinh trắc học khuôn mặt cho sinh viên.
     */
    FaceEnrollmentResponse registerFace(FaceRegistrationRequest request, String currentUsername);

    /**
     * Xem trạng thái đăng ký Face-ID của tài khoản hiện tại.
     */
    FaceStatusResponse getFaceStatus(String currentUsername);

    /**
     * Xóa dữ liệu Face-ID để đăng ký lại.
     */
    void resetFaceData(String currentUsername);

    /**
     * Dành cho quản trị viên xem trạng thái sinh trắc học của sinh viên bất kỳ.
     */
    FaceStatusResponse getFaceStatusByUserId(Long userId);
}
