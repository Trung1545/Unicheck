package com.unicheck.security;

import com.unicheck.service.impl.EmailServiceImpl;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Security Sanitization and Sensitive Data Leakage Prevention Tests")
class SecuritySanitizationTest {

    @Test
    @DisplayName("Should mask email in TokenRedisService sanitizeKeyForLog for OTP keys")
    void testSanitizeOtpKeyWithEmail() {
        String key = "otp:forgot_password:student01@unicheck.edu.vn";
        String sanitized = TokenRedisService.sanitizeKeyForLog(key);

        assertNotNull(sanitized);
        assertFalse(sanitized.contains("student01@unicheck.edu.vn"), "Full raw email must not be exposed");
        assertTrue(sanitized.startsWith("otp:forgot_password:st***@unicheck.edu.vn"), "Email prefix should be masked");
    }

    @Test
    @DisplayName("Should truncate long token hash in sanitizeKeyForLog")
    void testSanitizeTokenHashKey() {
        String rawToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c";
        String hashedKey = "jwt_blacklist:sha256_" + JwtUtil.hashToken(rawToken);
        String sanitized = TokenRedisService.sanitizeKeyForLog(hashedKey);

        assertNotNull(sanitized);
        assertFalse(sanitized.contains(rawToken), "Raw token must not appear in key");
        assertTrue(sanitized.contains("..."), "Long key should be truncated for log safety");
    }

    @Test
    @DisplayName("Should mask username in failed login key")
    void testSanitizeFailedLoginUserKey() {
        String key = "failed_login:user:admin_supersecret";
        String sanitized = TokenRedisService.sanitizeKeyForLog(key);

        assertNotNull(sanitized);
        assertFalse(sanitized.contains("admin_supersecret"), "Raw username should be masked");
        assertTrue(sanitized.contains("ad***"), "Username must have masked suffix");
    }

    @Test
    @DisplayName("Should mask email correctly")
    void testMaskEmail() {
        assertEquals("ad***@unicheck.edu.vn", TokenRedisService.maskEmail("admin@unicheck.edu.vn"));
        assertEquals("a***@unicheck.edu.vn", TokenRedisService.maskEmail("ab@unicheck.edu.vn"));
        assertEquals("***", TokenRedisService.maskEmail("invalid-email"));
        assertEquals("***", TokenRedisService.maskEmail(null));
    }

    @Test
    @DisplayName("Should execute EmailServiceImpl without leaking OTP")
    void testEmailServiceExecution() {
        EmailServiceImpl emailService = new EmailServiceImpl();
        assertDoesNotThrow(() -> emailService.sendOtpEmail("test@unicheck.edu.vn", "123456"));
    }
}
