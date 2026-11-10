package com.unicheck.service;

import com.unicheck.exception.AppException;
import com.unicheck.exception.ErrorCode;
import com.unicheck.model.dto.QrValidationRequest;
import com.unicheck.model.entity.User;
import com.unicheck.model.enums.Role;
import com.unicheck.repository.AttendanceSessionRepository;
import com.unicheck.security.UserPrincipal;
import com.unicheck.service.impl.StaticTestQrServiceImpl;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.core.env.Environment;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

public class StaticTestQrServiceUnitTest {

    @Test
    @DisplayName("Production Profile Test: Static Test QR is strictly disabled in production")
    void testProductionProfileBlocksStaticQr() {
        AttendanceSessionRepository sessionRepo = Mockito.mock(AttendanceSessionRepository.class);
        Environment env = Mockito.mock(Environment.class);

        // Giả lập môi trường Production
        when(env.getActiveProfiles()).thenReturn(new String[]{"prod"});

        StaticTestQrServiceImpl service = new StaticTestQrServiceImpl(sessionRepo, null, env);
        // Ngay cả khi ai đó cố tình set staticQrEnabled = true
        ReflectionTestUtils.setField(service, "staticQrEnabled", true);
        ReflectionTestUtils.setField(service, "allowedClassName", "UNICHECK-E2E-01");

        assertFalse(service.isStaticQrEnabledInEnvironment(), "Production environment must return false");

        User admin = User.builder().id(1L).username("admin").role(Role.ADMIN).build();
        UserPrincipal principal = new UserPrincipal(admin);

        // Cố gắng phát hành QR Test trên Production -> Bị chặn
        AppException ex1 = assertThrows(AppException.class, () ->
                service.generateOrGetStaticQrToken(principal, 100L));
        assertEquals(ErrorCode.STATIC_QR_NOT_ALLOWED, ex1.getErrorCode());

        // Cố gắng xác thực QR Test trên Production -> Bị chặn
        QrValidationRequest valReq = QrValidationRequest.builder()
                .sessionId(100L)
                .qrToken("STQR:100:abcdef1234567890abcdef1234567890")
                .build();
        AppException ex2 = assertThrows(AppException.class, () ->
                service.validateStaticQrToken(valReq));
        assertEquals(ErrorCode.STATIC_QR_NOT_ALLOWED, ex2.getErrorCode());
    }

    @Test
    @DisplayName("Default Config Test: When static-qr.enabled is false, static QR is disabled")
    void testStaticQrDisabledByDefault() {
        AttendanceSessionRepository sessionRepo = Mockito.mock(AttendanceSessionRepository.class);
        Environment env = Mockito.mock(Environment.class);

        when(env.getActiveProfiles()).thenReturn(new String[]{"test"});

        StaticTestQrServiceImpl service = new StaticTestQrServiceImpl(sessionRepo, null, env);
        // Default: staticQrEnabled = false
        ReflectionTestUtils.setField(service, "staticQrEnabled", false);

        assertFalse(service.isStaticQrEnabledInEnvironment(), "Must be disabled by default");
    }
}
