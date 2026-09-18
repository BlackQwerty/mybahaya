package com.shukri.mybahaya.controller;

import com.shukri.mybahaya.service.MinioService;
import com.shukri.mybahaya.service.ReportService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for ReportController — covers validation paths and HTTP status
 * codes without a live Spring context or Firebase connection.
 */
@DisplayName("Module 2 – Report Submission Validation")
class ReportControllerTest {

    private MinioService minioService;
    private ReportService reportService;
    private ReportController controller;

    @BeforeEach
    void setUp() {
        minioService  = mock(MinioService.class);
        reportService = mock(ReportService.class);
        controller    = new ReportController();
        // Inject mocks into @Autowired fields via ReflectionTestUtils
        ReflectionTestUtils.setField(controller, "minioService",  minioService);
        ReflectionTestUtils.setField(controller, "reportService", reportService);
    }

    private void setAuthenticatedUser(String uid) {
        SecurityContextHolder.getContext().setAuthentication(
            new UsernamePasswordAuthenticationToken(uid, null, Collections.emptyList())
        );
    }

    private void clearAuth() {
        SecurityContextHolder.clearContext();
    }

    // ── Test cases ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("TC2.1 – No authentication returns 401 UNAUTHORIZED")
    void noAuth_returns401() {
        clearAuth();
        // Simulate null UID in security context (unauthenticated request)
        SecurityContextHolder.getContext().setAuthentication(
            new UsernamePasswordAuthenticationToken(null, null, Collections.emptyList())
        );
        MockMultipartFile img = new MockMultipartFile("images", "test.jpg", "image/jpeg", new byte[]{1});
        ResponseEntity<Map<String, Object>> response =
            controller.createReport(List.of(img), "Fire", null, 3.139, 101.687);
        assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
    }

    @Test
    @DisplayName("TC2.2 – Empty image list returns 400 BAD REQUEST")
    void emptyImages_returns400() {
        setAuthenticatedUser("user123");
        ResponseEntity<Map<String, Object>> response =
            controller.createReport(List.of(), "Fire", null, 3.139, 101.687);
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertTrue(response.getBody().toString().contains("image"),
            "Error message should mention image");
    }

    @Test
    @DisplayName("TC2.3 – Valid request with mocked services returns 201 CREATED")
    void validRequest_returns201() throws Exception {
        setAuthenticatedUser("user123");
        MockMultipartFile img = new MockMultipartFile("images", "fire.jpg", "image/jpeg", new byte[]{1, 2, 3});

        when(minioService.uploadReportImage(any())).thenReturn("http://minio/fire.jpg");
        when(reportService.saveReport(eq("user123"), eq("Fire"), eq("Building on fire"),
                eq(3.139), eq(101.687), anyList()))
            .thenReturn(new HashMap<>(Map.of("reportId", "rpt-001", "imageUrl", "http://minio/fire.jpg")));

        ResponseEntity<Map<String, Object>> response =
            controller.createReport(List.of(img), "Fire", "Building on fire", 3.139, 101.687);

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertEquals("success", response.getBody().get("status"));
    }

    @Test
    @DisplayName("TC2.4 – MinIO exception returns 500 INTERNAL_SERVER_ERROR")
    void serviceException_returns500() throws Exception {
        setAuthenticatedUser("user123");
        MockMultipartFile img = new MockMultipartFile("images", "fire.jpg", "image/jpeg", new byte[]{1});
        when(minioService.uploadReportImage(any())).thenThrow(new RuntimeException("MinIO down"));

        ResponseEntity<Map<String, Object>> response =
            controller.createReport(List.of(img), "Fire", null, 3.139, 101.687);

        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
    }
}
