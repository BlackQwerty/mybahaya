package com.shukri.mybahaya.controller;

import com.shukri.mybahaya.service.MinioService;
import com.shukri.mybahaya.service.ReportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/reports")
public class ReportController {

    @Autowired
    private MinioService minioService;

    @Autowired
    private ReportService reportService;

    @PostMapping
    public ResponseEntity<Map<String, String>> createReport(
            @RequestParam("image") MultipartFile image,
            @RequestParam("category") String category,
            @RequestParam(value = "details", required = false) String details,
            @RequestParam("latitude") double latitude,
            @RequestParam("longitude") double longitude) {
        
        try {
            // Get UID from SecurityContext (set by FirebaseTokenFilter)
            String uid = (String) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

            if (uid == null || uid.isEmpty()) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            }

            // 1. Upload Image to MinIO
            String imageUrl = minioService.uploadReportImage(image);

            // 2. Save Report metadata to Firestore
            String reportId = reportService.saveReport(uid, category, details, latitude, longitude, imageUrl);

            // 3. Return success response
            Map<String, String> response = new HashMap<>();
            response.put("status", "success");
            response.put("reportId", reportId);
            response.put("imageUrl", imageUrl);

            return ResponseEntity.status(HttpStatus.CREATED).body(response);

        } catch (Exception e) {
            e.printStackTrace();
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("status", "error");
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
}
