package com.shukri.mybahaya.controller;

import com.shukri.mybahaya.service.MinioService;
import com.shukri.mybahaya.service.ReportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/reports")
public class ReportController {

    @Autowired private MinioService minioService;
    @Autowired private ReportService reportService;

    /* ── POST /api/reports — citizen submits a new report ───── */

    @PostMapping
    public ResponseEntity<Map<String, Object>> createReport(
            @RequestParam("images") List<MultipartFile> images,
            @RequestParam("category") String category,
            @RequestParam(value = "details", required = false) String details,
            @RequestParam("latitude") double latitude,
            @RequestParam("longitude") double longitude) {

        try {
            String uid = (String) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
            if (uid == null || uid.isEmpty()) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            }
            if (images == null || images.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("status", "error", "message", "At least one image is required"));
            }

            // Upload each photo (1–3) to MinIO, collect their URLs.
            List<String> imageUrls = new ArrayList<>();
            for (MultipartFile img : images) {
                if (img != null && !img.isEmpty()) {
                    imageUrls.add(minioService.uploadReportImage(img));
                }
            }

            Map<String, Object> result = reportService.saveReport(uid, category, details, latitude, longitude, imageUrls);
            result.put("status", "success");

            return ResponseEntity.status(HttpStatus.CREATED).body(result);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("status", "error", "message", e.getMessage() != null ? e.getMessage() : "Unknown error"));
        }
    }

    /* ── POST /api/reports/{reportId}/video — background video upload ── */
    // Mobile submits the report first (fast), then uploads the optional video
    // here in the background. The video is attached to the existing report.

    @PostMapping("/{reportId}/video")
    public ResponseEntity<Map<String, Object>> uploadVideo(
            @PathVariable String reportId,
            @RequestParam("video") MultipartFile video) {

        try {
            String uid = (String) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
            if (uid == null || uid.isEmpty()) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            }
            if (video == null || video.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("ok", false, "message", "No video file provided"));
            }

            String videoUrl = minioService.uploadReportVideo(video);
            reportService.attachVideo(reportId, videoUrl);

            return ResponseEntity.ok(Map.of("ok", true, "videoUrl", videoUrl));

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("ok", false, "message", e.getMessage() != null ? e.getMessage() : "Video upload failed"));
        }
    }

    /* ── PATCH /api/reports/{reportId}/verify — org/admin verifies or rejects ── */

    @PatchMapping("/{reportId}/verify")
    public ResponseEntity<Map<String, Object>> verifyReport(
            @PathVariable String reportId,
            @RequestBody Map<String, String> body) {
        try {
            String uid = (String) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
            if (uid == null || uid.isEmpty()) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            }
            String action = body.get("action");
            if (action == null || action.isBlank()) {
                return ResponseEntity.badRequest().body(Map.of("ok", false, "message", "action field required"));
            }
            reportService.verifyReport(reportId, action.toUpperCase());
            return ResponseEntity.ok(Map.of("ok", true, "verificationStatus", action.toUpperCase()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("ok", false, "message", e.getMessage() != null ? e.getMessage() : "Verify failed"));
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
