package com.unicheck.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public enum ErrorCode {
    // System & General Errors (1000 - 1099)
    INTERNAL_SERVER_ERROR("ERR_1000", "Lỗi hệ thống máy chủ nội bộ", HttpStatus.INTERNAL_SERVER_ERROR),
    INVALID_REQUEST("ERR_1001", "Dữ liệu yêu cầu không hợp lệ", HttpStatus.BAD_REQUEST),
    RESOURCE_NOT_FOUND("ERR_1002", "Không tìm thấy tài nguyên yêu cầu", HttpStatus.NOT_FOUND),
    METHOD_NOT_ALLOWED("ERR_1003", "Phương thức HTTP không được hỗ trợ", HttpStatus.METHOD_NOT_ALLOWED),

    // Authentication & Security Errors (2000 - 2099)
    UNAUTHORIZED("ERR_2000", "Yêu cầu đăng nhập hoặc phiên làm việc đã hết hạn", HttpStatus.UNAUTHORIZED),
    FORBIDDEN("ERR_2001", "Bạn không có quyền truy cập chức năng này", HttpStatus.FORBIDDEN),
    INVALID_CREDENTIALS("ERR_2002", "Tên đăng nhập hoặc mật khẩu không chính xác", HttpStatus.UNAUTHORIZED),
    ACCOUNT_LOCKED("ERR_2003", "Tài khoản hiện đang bị khóa", HttpStatus.FORBIDDEN),
    ACCOUNT_INACTIVE("ERR_2004", "Tài khoản chưa được kích hoạt", HttpStatus.FORBIDDEN),
    TOKEN_EXPIRED("ERR_2005", "Mã xác thực JWT đã hết hạn", HttpStatus.UNAUTHORIZED),
    TOKEN_INVALID("ERR_2006", "Mã xác thực JWT không hợp lệ", HttpStatus.UNAUTHORIZED),
    RATE_LIMIT_EXCEEDED("ERR_2007", "Quá nhiều lần thử đăng nhập thất bại. Vui lòng thử lại sau 15 phút", HttpStatus.TOO_MANY_REQUESTS),
    INVALID_OTP("ERR_2008", "Mã xác thực không chính xác hoặc đã hết hạn", HttpStatus.BAD_REQUEST),
    PASSWORD_MISMATCH("ERR_2009", "Mật khẩu hiện tại không chính xác", HttpStatus.BAD_REQUEST),
    TOKEN_REVOKED("ERR_2010", "Phiên đăng nhập đã bị thu hồi", HttpStatus.UNAUTHORIZED),
    USER_ALREADY_EXISTS("ERR_2011", "Tên đăng nhập, email hoặc mã định danh đã tồn tại trong hệ thống", HttpStatus.BAD_REQUEST),

    // Face Recognition & Attendance Errors (3000 - 3099)
    FACE_NOT_DETECTED("ERR_3001", "Không phát hiện khuôn mặt trong ảnh", HttpStatus.BAD_REQUEST),
    MULTIPLE_FACES_DETECTED("ERR_3002", "Phát hiện nhiều hơn một khuôn mặt", HttpStatus.BAD_REQUEST),
    FACE_LIVENESS_FAILED("ERR_3003", "Kiểm tra thực thể (liveness) thất bại", HttpStatus.BAD_REQUEST),
    FACE_NOT_MATCHED("ERR_3004", "Khuôn mặt không khớp với hồ sơ đã đăng ký", HttpStatus.BAD_REQUEST),
    FACE_NOT_REGISTERED("ERR_3005", "Sinh viên chưa đăng ký dữ liệu khuôn mặt", HttpStatus.BAD_REQUEST),
    ATTENDANCE_SESSION_CLOSED("ERR_3006", "Ca điểm danh đã kết thúc hoặc chưa mở", HttpStatus.BAD_REQUEST),
    ALREADY_CHECKED_IN("ERR_3007", "Bạn đã điểm danh thành công cho ca học này", HttpStatus.CONFLICT),
    WIFI_NOT_MATCHED("ERR_3008", "Vị trí Wi-Fi không khớp với phòng học quy định", HttpStatus.BAD_REQUEST),

    // Academic & Management Errors (4000 - 4099)
    DUPLICATE_RESOURCE("ERR_4001", "Dữ liệu đã tồn tại trong hệ thống", HttpStatus.CONFLICT),
    CLASS_FULL("ERR_4002", "Lớp học đã đạt số lượng tối đa", HttpStatus.BAD_REQUEST);

    private final String code;
    private final String message;
    private final HttpStatus httpStatus;

    ErrorCode(String code, String message, HttpStatus httpStatus) {
        this.code = code;
        this.message = message;
        this.httpStatus = httpStatus;
    }
}
