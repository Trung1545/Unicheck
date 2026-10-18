package com.unicheck.model.enums;

import lombok.Getter;

@Getter
public enum AttendanceSessionStatus {
    CREATED("Đã tạo phiên"),
    OPEN("Đang mở điểm danh"),
    CLOSED("Đã chốt sổ"),
    CANCELLED("Đã hủy");

    private final String description;

    AttendanceSessionStatus(String description) {
        this.description = description;
    }
}
