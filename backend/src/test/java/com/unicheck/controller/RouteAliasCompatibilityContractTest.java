package com.unicheck.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.model.dto.LoginRequest;
import com.unicheck.model.dto.RefreshTokenRequest;
import com.unicheck.model.entity.User;
import com.unicheck.model.enums.Role;
import com.unicheck.model.enums.UserStatus;
import com.unicheck.repository.UserRepository;
import com.unicheck.security.JwtUtil;
import com.unicheck.security.TokenRedisService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DisplayName("P03 Contract: Route Alias Compatibility Tests (/api/ vs /api/v1/)")
public class RouteAliasCompatibilityContractTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private TokenRedisService tokenRedisService;

    private User studentUser;
    private User adminUser;

    @BeforeEach
    void setUp() {
        long ts = System.currentTimeMillis();

        studentUser = User.builder()
                .code("SV_ALIAS_" + ts)
                .username("student_alias_" + ts)
                .email("student_alias_" + ts + "@unicheck.edu.vn")
                .password(passwordEncoder.encode("Student@123"))
                .fullName("Nguyễn Alias Sinh Viên")
                .role(Role.STUDENT)
                .status(UserStatus.ACTIVE)
                .sex("NAM")
                .isPasswordChanged(true)
                .build();
        studentUser = userRepository.save(studentUser);

        adminUser = User.builder()
                .code("AD_ALIAS_" + ts)
                .username("admin_alias_" + ts)
                .email("admin_alias_" + ts + "@unicheck.edu.vn")
                .password(passwordEncoder.encode("Admin@123"))
                .fullName("Trần Alias Quản Trị")
                .role(Role.ADMIN)
                .status(UserStatus.ACTIVE)
                .sex("NAM")
                .isPasswordChanged(true)
                .build();
        adminUser = userRepository.save(adminUser);

        tokenRedisService.resetFailedLogins(studentUser.getUsername(), "127.0.0.1");
        tokenRedisService.resetFailedLogins(adminUser.getUsername(), "127.0.0.1");
    }

    @Test
    @DisplayName("P03-1: Verify /api/v1/auth/login and /api/auth/login return identical flat JSON contract")
    void testLoginCanonicalAndAliasReturnIdenticalFlatContract() throws Exception {
        LoginRequest loginRequest = LoginRequest.builder()
                .username(studentUser.getUsername())
                .password("Student@123")
                .build();

        // 1. Call Canonical Route (/api/v1/auth/login)
        MvcResult canonicalResult = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.message", is("Đăng nhập thành công")))
                .andExpect(jsonPath("$.errorCode").doesNotExist())
                .andExpect(jsonPath("$.data.token", notNullValue()))
                .andExpect(jsonPath("$.data.refreshToken", notNullValue()))
                .andExpect(jsonPath("$.data.tokenType", is("Bearer")))
                .andExpect(jsonPath("$.data.expiresIn", is((int) (jwtUtil.getAccessTokenExpirationMs() / 1000))))
                .andExpect(jsonPath("$.data.userId", is(studentUser.getId().intValue())))
                .andExpect(jsonPath("$.data.code", is(studentUser.getCode())))
                .andExpect(jsonPath("$.data.username", is(studentUser.getUsername())))
                .andExpect(jsonPath("$.data.fullName", is(studentUser.getFullName())))
                .andExpect(jsonPath("$.data.email", is(studentUser.getEmail())))
                .andExpect(jsonPath("$.data.role", is("STUDENT")))
                .andExpect(jsonPath("$.data.isPasswordChanged", is(true)))
                // Crucial contract assertion: user object must NOT be nested
                .andExpect(jsonPath("$.data.user").doesNotExist())
                .andReturn();

        // 2. Call Legacy Alias Route (/api/auth/login)
        MvcResult aliasResult = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.message", is("Đăng nhập thành công")))
                .andExpect(jsonPath("$.errorCode").doesNotExist())
                .andExpect(jsonPath("$.data.token", notNullValue()))
                .andExpect(jsonPath("$.data.refreshToken", notNullValue()))
                .andExpect(jsonPath("$.data.tokenType", is("Bearer")))
                .andExpect(jsonPath("$.data.expiresIn", is((int) (jwtUtil.getAccessTokenExpirationMs() / 1000))))
                .andExpect(jsonPath("$.data.userId", is(studentUser.getId().intValue())))
                .andExpect(jsonPath("$.data.code", is(studentUser.getCode())))
                .andExpect(jsonPath("$.data.username", is(studentUser.getUsername())))
                .andExpect(jsonPath("$.data.fullName", is(studentUser.getFullName())))
                .andExpect(jsonPath("$.data.email", is(studentUser.getEmail())))
                .andExpect(jsonPath("$.data.role", is("STUDENT")))
                .andExpect(jsonPath("$.data.isPasswordChanged", is(true)))
                .andExpect(jsonPath("$.data.user").doesNotExist())
                .andReturn();

        assertNotNull(canonicalResult.getResponse().getContentAsString());
        assertNotNull(aliasResult.getResponse().getContentAsString());
    }

    @Test
    @DisplayName("P03-2: Verify /api/v1/auth/me and /api/auth/me return identical profile data")
    void testGetProfileCanonicalAndAliasReturnIdenticalData() throws Exception {
        String token = jwtUtil.generateAccessToken(studentUser);

        // 1. Canonical /api/v1/auth/me
        mockMvc.perform(get("/api/v1/auth/me")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.id", is(studentUser.getId().intValue())))
                .andExpect(jsonPath("$.data.username", is(studentUser.getUsername())))
                .andExpect(jsonPath("$.data.role", is("STUDENT")))
                .andExpect(jsonPath("$.data.status", is("ACTIVE")));

        // 2. Legacy Alias /api/auth/me
        mockMvc.perform(get("/api/auth/me")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.id", is(studentUser.getId().intValue())))
                .andExpect(jsonPath("$.data.username", is(studentUser.getUsername())))
                .andExpect(jsonPath("$.data.role", is("STUDENT")))
                .andExpect(jsonPath("$.data.status", is("ACTIVE")));

        // 3. Alternative path /profile on both
        mockMvc.perform(get("/api/v1/auth/profile")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.username", is(studentUser.getUsername())));

        mockMvc.perform(get("/api/auth/profile")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.username", is(studentUser.getUsername())));
    }

    @Test
    @DisplayName("P03-3: Verify Refresh Token flow works identically across /api/v1/ and /api/")
    void testRefreshTokenCanonicalAndAliasParity() throws Exception {
        LoginRequest loginRequest = LoginRequest.builder()
                .username(studentUser.getUsername())
                .password("Student@123")
                .build();

        // Login on canonical to get refresh token
        MvcResult res1 = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();
        String json1 = res1.getResponse().getContentAsString();
        String rt1 = objectMapper.readTree(json1).path("data").path("refreshToken").asText();

        // Refresh on canonical endpoint
        RefreshTokenRequest refreshReq1 = RefreshTokenRequest.builder().refreshToken(rt1).build();
        mockMvc.perform(post("/api/v1/auth/refresh-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(refreshReq1)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.token", notNullValue()))
                .andExpect(jsonPath("$.data.refreshToken", notNullValue()))
                .andExpect(jsonPath("$.data.tokenType", is("Bearer")));

        // Login on alias to get another refresh token
        MvcResult res2 = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();
        String json2 = res2.getResponse().getContentAsString();
        String rt2 = objectMapper.readTree(json2).path("data").path("refreshToken").asText();

        // Refresh on alias endpoint
        RefreshTokenRequest refreshReq2 = RefreshTokenRequest.builder().refreshToken(rt2).build();
        mockMvc.perform(post("/api/auth/refresh-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(refreshReq2)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.token", notNullValue()))
                .andExpect(jsonPath("$.data.refreshToken", notNullValue()))
                .andExpect(jsonPath("$.data.tokenType", is("Bearer")));
    }

    @Test
    @DisplayName("P03-4: Verify Logout flow works identically across /api/v1/ and /api/")
    void testLogoutCanonicalAndAliasParity() throws Exception {
        String token1 = jwtUtil.generateAccessToken(studentUser);
        mockMvc.perform(post("/api/v1/auth/logout")
                        .header("Authorization", "Bearer " + token1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.message", is("Đăng xuất thành công")));

        String token2 = jwtUtil.generateAccessToken(studentUser);
        mockMvc.perform(post("/api/auth/logout")
                        .header("Authorization", "Bearer " + token2))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.message", is("Đăng xuất thành công")));
    }

    @Test
    @DisplayName("P03-5: Verify Error Contract parity (400 validation, 401 bad credentials, 401 unauthorized)")
    void testErrorHandlingCanonicalAndAliasParity() throws Exception {
        // Bad credentials error parity (ERR_2002)
        LoginRequest badCreds = LoginRequest.builder()
                .username(studentUser.getUsername())
                .password("WrongPassword123")
                .build();

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(badCreds)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_2002")));

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(badCreds)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_2002")));

        // Validation error parity (ERR_1001)
        LoginRequest emptyReq = LoginRequest.builder().username("").password("").build();

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(emptyReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_1001")));

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(emptyReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_1001")));

        // Unauthorized access without token parity (ERR_2000)
        mockMvc.perform(get("/api/v1/auth/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_2000")));

        mockMvc.perform(get("/api/auth/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_2000")));
    }

    @Test
    @DisplayName("P03-6: Verify User Management canonical and alias route parity")
    void testUserManagementCanonicalAndAliasParity() throws Exception {
        String adminToken = jwtUtil.generateAccessToken(adminUser);
        String studentToken = jwtUtil.generateAccessToken(studentUser);

        // 1. Admin access to canonical /api/v1/users
        mockMvc.perform(get("/api/v1/users")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.content", notNullValue()))
                .andExpect(jsonPath("$.data.totalElements", greaterThanOrEqualTo(2)));

        // 2. Admin access to alias /api/users
        mockMvc.perform(get("/api/users")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.content", notNullValue()))
                .andExpect(jsonPath("$.data.totalElements", greaterThanOrEqualTo(2)));

        // 3. User details by ID on both
        mockMvc.perform(get("/api/v1/users/" + studentUser.getId())
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id", is(studentUser.getId().intValue())))
                .andExpect(jsonPath("$.data.username", is(studentUser.getUsername())));

        mockMvc.perform(get("/api/users/" + studentUser.getId())
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id", is(studentUser.getId().intValue())))
                .andExpect(jsonPath("$.data.username", is(studentUser.getUsername())));

        // 4. Forbidden check: Student cannot access users endpoint (ERR_2001)
        mockMvc.perform(get("/api/v1/users")
                        .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_2001")));

        mockMvc.perform(get("/api/users")
                        .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_2001")));
    }
}
