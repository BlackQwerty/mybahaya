package com.shukri.mybahaya.controller;

import com.shukri.mybahaya.service.MinioService;
import com.shukri.mybahaya.service.ReportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RestController
@RequestMapping("/api/reports")
public class ReportController {

    @Autowired private MinioService minioService;
    @Autowired private ReportService reportService;

    /* ── POST /api/reports — citizen submits a new report ───── */

    @PostMapping
    public ResponseEntity<Map<String, Object>> createReport(
            @RequestParam("image") MultipartFile image,
            @RequestParam("category") String category,
            @RequestParam(value = "details", required = false) String details,
            @RequestParam("latitude") double latitude,
            @RequestParam("longitude") double longitude) {

        try {
            String uid = (String) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
            if (uid == null || uid.isEmpty()) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            }

            String imageUrl = minioService.uploadReportImage(image);
            Map<String, Object> result = reportService.saveReport(uid, category, details, latitude, longitude, imageUrl);
            result.put("status", "success");

            return ResponseEntity.status(HttpStatus.CREATED).body(result);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("status", "error", "message", e.getMessage() != null ? e.getMessage() : "Unknown error"));
        }
    }

    /* ── PATCH /api/reports/{reportId}/status — org/admin updates status ── */
    // The state machine in ReportService validates the transition.
    // On success, it also fires an FCM push to the citizen.

    @PatchMapping("/{reportId}/status")
    public ResponseEntity<Map<String, Object>> updateStatus(
            @PathVariable String reportId,
            @RequestBody Map<String, String> body) {

        try {
            String uid = (String) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
            if (uid == null || uid.isEmpty()) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            }

            String newStatus = body.get("status");
            if (newStatus == null || newStatus.isBlank()) {
                return ResponseEntity.badRequest().body(Map.of("error", "status field is required"));
            }

            reportService.updateStatus(reportId, newStatus);
            return ResponseEntity.ok(Map.of("ok", true, "newStatus", newStatus));

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("ok", false, "message", e.getMessage() != null ? e.getMessage() : "Update failed"));
        }
    }
}
