package com.unicheck.common;

import com.unicheck.common.dto.ApiResponse;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Unit Test: ApiResponse DTO Structure")
class ApiResponseTest {

    @Test
    @DisplayName("Should create successful response with default message and null errorCode")
    void testSuccessResponse() {
        String payload = "Sample Data";
        ApiResponse<String> response = ApiResponse.ok(payload);

        assertTrue(response.isSuccess());
        assertEquals("Sample Data", response.getData());
        assertEquals("Success", response.getMessage());
        assertNull(response.getErrorCode());
    }

    @Test
    @DisplayName("Should create successful response with custom message")
    void testSuccessResponseWithCustomMessage() {
        ApiResponse<Integer> response = ApiResponse.ok(100, "Xử lý thành công");

        assertTrue(response.isSuccess());
        assertEquals(100, response.getData());
        assertEquals("Xử lý thành công", response.getMessage());
        assertNull(response.getErrorCode());
    }

    @Test
    @DisplayName("Should create error response with false success, null data and errorCode")
    void testErrorResponse() {
        ApiResponse<Void> response = ApiResponse.error("Xác thực thất bại", "ERR_2002");

        assertFalse(response.isSuccess());
        assertNull(response.getData());
        assertEquals("Xác thực thất bại", response.getMessage());
        assertEquals("ERR_2002", response.getErrorCode());
    }
}
