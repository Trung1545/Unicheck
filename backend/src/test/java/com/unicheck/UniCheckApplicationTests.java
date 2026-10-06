package com.unicheck;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest
@ActiveProfiles("test")
@DisplayName("Integration Test: Context Load & Flyway Schema Migration")
class UniCheckApplicationTests {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    @DisplayName("Spring Application Context should load cleanly and Flyway V1 should execute successfully")
    void contextLoadsAndFlywayExecutes() {
        assertNotNull(jdbcTemplate, "JdbcTemplate should be injected");

        // Verify key tables exist from Flyway V1 migration
        Integer usersCount = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM users", Integer.class);
        Integer sessionsCount = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM attendance_sessions", Integer.class);
        Integer faceCount = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM face_encodings", Integer.class);

        assertNotNull(usersCount);
        assertNotNull(sessionsCount);
        assertNotNull(faceCount);
        assertTrue(usersCount >= 0);
    }
}
