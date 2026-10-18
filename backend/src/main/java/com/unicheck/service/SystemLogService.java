package com.unicheck.service;

import com.unicheck.model.entity.SystemLog;
import com.unicheck.model.entity.User;
import jakarta.servlet.http.HttpServletRequest;

public interface SystemLogService {

    SystemLog logAudit(String action, String description, User performer, String oldValue, String newValue, HttpServletRequest request);

    SystemLog logAudit(String action, String description, User performer, String oldValue, String newValue, String ipAddress, String userAgent);
}
