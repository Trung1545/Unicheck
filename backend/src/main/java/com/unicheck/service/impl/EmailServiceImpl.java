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
        // In development & production logging, sending email asynchronously
        log.info("[EmailService] Sending OTP verification code [{}] to email [{}]", otp, toEmail);
    }
}
