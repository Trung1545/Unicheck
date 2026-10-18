package com.unicheck.service.impl;

import com.unicheck.model.entity.SystemLog;
import com.unicheck.model.entity.User;
import com.unicheck.repository.SystemLogRepository;
import com.unicheck.service.SystemLogService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class SystemLogServiceImpl implements SystemLogService {

    private final SystemLogRepository systemLogRepository;

    @Override
    @Transactional
    public SystemLog logAudit(String action, String description, User performer, String oldValue, String newValue, HttpServletRequest request) {
        String ip = extractClientIp(request);
        String userAgent = request != null ? request.getHeader("User-Agent") : null;
        return logAudit(action, description, performer, oldValue, newValue, ip, userAgent);
    }

    @Override
    @Transactional
    public SystemLog logAudit(String action, String description, User performer, String oldValue, String newValue, String ipAddress, String userAgent) {
        SystemLog auditLog = SystemLog.builder()
                .action(action)
                .description(description)
                .type("AUDIT")
                .source("WEB")
                .ipAddress(ipAddress != null && ipAddress.length() > 45 ? ipAddress.substring(0, 45) : ipAddress)
                .userAgent(userAgent != null && userAgent.length() > 1000 ? userAgent.substring(0, 1000) : userAgent)
                .oldValue(oldValue)
                .newValue(newValue)
                .performer(performer)
                .createdAt(LocalDateTime.now())
                .build();

        log.info("AUDIT LOG [Action: {}, Performer: {}, IP: {}] - {}",
                action,
                performer != null ? performer.getUsername() : "SYSTEM",
                ipAddress,
                description);

        return systemLogRepository.save(auditLog);
    }

    private String extractClientIp(HttpServletRequest request) {
        if (request == null) {
            return "127.0.0.1";
        }
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (StringUtils.hasText(xForwardedFor)) {
            return xForwardedFor.split(",")[0].trim();
        }
        String remoteAddr = request.getRemoteAddr();
        return StringUtils.hasText(remoteAddr) ? remoteAddr : "127.0.0.1";
    }
}
