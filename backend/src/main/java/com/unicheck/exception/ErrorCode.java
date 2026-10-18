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
    FACE_ALREADY_REGISTERED("ERR_3009", "Sinh viên đã hoàn tất đăng ký Face-ID", HttpStatus.CONFLICT),
    FACE_REGISTRATION_BLOCKED("ERR_3010", "Tài khoản bị tạm khóa đăng ký Face-ID do vượt quá số lần thử", HttpStatus.FORBIDDEN),
    AI_SERVICE_UNAVAILABLE("ERR_3011", "Dịch vụ AI nhận diện khuôn mặt hiện không khả dụng", HttpStatus.SERVICE_UNAVAILABLE),
    ATTENDANCE_SESSION_NOT_FOUND("ERR_3012", "Không tìm thấy phiên điểm danh yêu cầu", HttpStatus.NOT_FOUND),
    ATTENDANCE_SESSION_ALREADY_OPEN("ERR_3013", "Phiên điểm danh hiện đang mở", HttpStatus.CONFLICT),
    ATTENDANCE_SESSION_ALREADY_CLOSED("ERR_3014", "Phiên điểm danh đã kết thúc, không thể mở lại hoặc đóng lại", HttpStatus.BAD_REQUEST),
    ATTENDANCE_SESSION_INVALID_STATE("ERR_3015", "Trạng thái phiên điểm danh không hợp lệ cho thao tác này", HttpStatus.BAD_REQUEST),
    SESSION_CREATION_NOT_ALLOWED("ERR_3016", "Không thể tạo phiên điểm danh ngoài thời gian hoặc khi chưa đủ điều kiện", HttpStatus.BAD_REQUEST),
    LECTURER_NOT_ASSIGNED_TO_CLASS("ERR_3017", "Giảng viên không phụ trách lớp học phần này", HttpStatus.FORBIDDEN),
    ATTENDANCE_CONFIG_NOT_FOUND("ERR_3018", "Không tìm thấy cấu hình điểm danh", HttpStatus.NOT_FOUND),
    DUPLICATE_SESSION_FOR_SLOT("ERR_3019", "Đã tồn tại phiên điểm danh cho buổi học này", HttpStatus.CONFLICT),

    // Academic & Management Errors (4000 - 4099)
    DUPLICATE_RESOURCE("ERR_4001", "Dữ liệu đã tồn tại trong hệ thống", HttpStatus.CONFLICT),
    CLASS_FULL("ERR_4002", "Lớp học đã đạt số lượng tối đa", HttpStatus.BAD_REQUEST),
    COURSE_NOT_FOUND("ERR_4003", "Không tìm thấy học phần yêu cầu", HttpStatus.NOT_FOUND),
    SEMESTER_NOT_FOUND("ERR_4004", "Không tìm thấy học kỳ yêu cầu", HttpStatus.NOT_FOUND),
    CANNOT_DELETE_REFERENCED_RESOURCE("ERR_4005", "Không thể xóa dữ liệu đang được liên kết hoặc tham chiếu", HttpStatus.BAD_REQUEST),
    CIRCULAR_PREREQUISITE("ERR_4006", "Học phần không thể đặt chính nó hoặc tạo chu trình tiên quyết vòng lặp", HttpStatus.BAD_REQUEST),
    CLASS_NOT_FOUND("ERR_4007", "Không tìm thấy lớp học phần yêu cầu", HttpStatus.NOT_FOUND),
    ENROLLMENT_NOT_FOUND("ERR_4008", "Không tìm thấy bản ghi ghi danh", HttpStatus.NOT_FOUND),
    STUDENT_NOT_FOUND("ERR_4009", "Không tìm thấy sinh viên yêu cầu", HttpStatus.NOT_FOUND),
    INVALID_STUDENT_ROLE("ERR_4010", "Người dùng không phải là sinh viên", HttpStatus.BAD_REQUEST),
    DUPLICATE_ENROLLMENT("ERR_4011", "Sinh viên đã được ghi danh vào lớp học phần này", HttpStatus.CONFLICT),
    INVALID_LECTURER_ROLE("ERR_4012", "Người dùng không phải là giảng viên", HttpStatus.BAD_REQUEST),
    CLASS_ALREADY_EXISTS("ERR_4013", "Mã lớp học phần đã tồn tại trong hệ thống", HttpStatus.CONFLICT),
    CLASS_NOT_OPEN("ERR_4014", "Lớp học phần hiện không mở cho ghi danh", HttpStatus.BAD_REQUEST),
    CANNOT_MODIFY_CLASS_NAME("ERR_4015", "Không được phép thay đổi mã lớp học phần", HttpStatus.BAD_REQUEST),

    // Facility & Wi-Fi Management Errors (5000 - 5099)
    ROOM_NOT_FOUND("ERR_5001", "Không tìm thấy phòng học yêu cầu", HttpStatus.NOT_FOUND),
    ROOM_ALREADY_EXISTS("ERR_5002", "Mã phòng học đã tồn tại trong hệ thống", HttpStatus.CONFLICT),
    WIFI_AP_NOT_FOUND("ERR_5003", "Không tìm thấy Wi-Fi Access Point yêu cầu", HttpStatus.NOT_FOUND),
    WIFI_AP_ALREADY_EXISTS("ERR_5004", "BSSID hoặc thiết bị Wi-Fi đã tồn tại trong hệ thống", HttpStatus.CONFLICT),
    ROOM_WIFI_ALREADY_LINKED("ERR_5005", "Wi-Fi Access Point này đã được gán vào phòng học", HttpStatus.CONFLICT),
    ROOM_WIFI_NOT_FOUND("ERR_5006", "Không tìm thấy liên kết giữa phòng học và Wi-Fi Access Point", HttpStatus.NOT_FOUND),
    ROOM_IN_USE("ERR_5007", "Phòng học đang được xếp lịch thời khóa biểu hoặc phiên điểm danh, không thể xóa", HttpStatus.BAD_REQUEST),
    INVALID_BSSID_FORMAT("ERR_5008", "Định dạng địa chỉ BSSID/MAC không hợp lệ (chuẩn XX:XX:XX:XX:XX:XX)", HttpStatus.BAD_REQUEST),

    // Timetable & Scheduling Errors (6000 - 6099)
    TIMETABLE_SLOT_NOT_FOUND("ERR_6001", "Không tìm thấy lịch học yêu cầu", HttpStatus.NOT_FOUND),
    SLOT_TYPE_NOT_FOUND("ERR_6002", "Không tìm thấy loại tiết/ca học yêu cầu", HttpStatus.NOT_FOUND),
    ROOM_SCHEDULE_CONFLICT("ERR_6003", "Xung đột phòng học: Phòng này đã được xếp lịch cho lớp khác trong cùng thời gian", HttpStatus.CONFLICT),
    LECTURER_SCHEDULE_CONFLICT("ERR_6004", "Xung đột giảng viên: Giảng viên đã có lịch giảng dạy lớp khác trong cùng thời gian", HttpStatus.CONFLICT),
    CLASS_SCHEDULE_CONFLICT("ERR_6005", "Xung đột lớp học: Lớp học phần đã có lịch học trong cùng thời gian", HttpStatus.CONFLICT),
    DATE_OUTSIDE_SEMESTER("ERR_6006", "Ngày học không nằm trong khoảng thời gian của học kỳ", HttpStatus.BAD_REQUEST),
    DATE_ON_HOLIDAY("ERR_6007", "Ngày học trùng với ngày nghỉ lễ quy định của học kỳ", HttpStatus.BAD_REQUEST),
    ROOM_CAPACITY_INSUFFICIENT("ERR_6008", "Sức chứa phòng học không đủ cho sĩ số của lớp học phần", HttpStatus.BAD_REQUEST),
    ROOM_NOT_AVAILABLE("ERR_6009", "Phòng học hiện đang ở trạng thái không khả dụng (bảo trì hoặc ngưng hoạt động)", HttpStatus.BAD_REQUEST),
    TIMETABLE_SLOT_HAS_ATTENDANCE("ERR_6010", "Lịch học đã có dữ liệu phiên điểm danh phát sinh, không thể sửa/xóa làm mất dữ liệu lịch sử", HttpStatus.BAD_REQUEST),
    INVALID_PERIOD_RANGE("ERR_6011", "Tiết bắt đầu và tiết kết thúc không hợp lệ", HttpStatus.BAD_REQUEST);

    private final String code;
    private final String message;
    private final HttpStatus httpStatus;

    ErrorCode(String code, String message, HttpStatus httpStatus) {
        this.code = code;
        this.message = message;
        this.httpStatus = httpStatus;
    }
}
