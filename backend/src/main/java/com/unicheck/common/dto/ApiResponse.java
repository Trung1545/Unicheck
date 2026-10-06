package com.unicheck.common.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.ALWAYS)
public class ApiResponse<T> {

    private boolean success;
    private T data;
    private String message;
    private String errorCode;

    public static <T> ApiResponse<T> ok(T data) {
        return ApiResponse.<T>builder()
                .success(true)
                .data(data)
                .message("Success")
                .errorCode(null)
                .build();
    }

    public static <T> ApiResponse<T> ok(T data, String message) {
        return ApiResponse.<T>builder()
                .success(true)
                .data(data)
                .message(message)
                .errorCode(null)
                .build();
    }

    public static <T> ApiResponse<T> error(String message, String errorCode) {
        return ApiResponse.<T>builder()
                .success(false)
                .data(null)
                .message(message)
                .errorCode(errorCode)
                .build();
    }

    public static <T> ApiResponse<T> error(T data, String message, String errorCode) {
        return ApiResponse.<T>builder()
                .success(false)
                .data(data)
                .message(message)
                .errorCode(errorCode)
                .build();
    }
}
