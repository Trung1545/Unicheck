package com.unicheck.service.impl;

import com.unicheck.service.EmailService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class EmailServiceImpl implements EmailService {

    @Async
    @Override
    public void sendOtpEmail(String toEmail, String otp) {
        // In development & production logging, sending email asynchronously with masked OTP and masked recipient
        log.info("[EmailService] Sending OTP verification code [******] to email [{}]", maskEmail(toEmail));
    }

    private String maskEmail(String email) {
        if (email == null || !email.contains("@")) return "***";
        int atIdx = email.indexOf('@');
        String name = email.substring(0, atIdx);
        String domain = email.substring(atIdx);
        String maskedName = name.length() <= 2 ? name.charAt(0) + "***" : name.substring(0, 2) + "***";
        return maskedName + domain;
    }
}
