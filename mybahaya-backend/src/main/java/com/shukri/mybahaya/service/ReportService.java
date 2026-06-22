package com.shukri.mybahaya.service;

import com.google.cloud.firestore.FieldValue;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class ReportService {

    // State machine: each key is the ONLY valid next state from that current state.
    private static final Map<String, String> VALID_NEXT_STATUS = Map.of(
        "NEW",         "RECEIVED",
        "RECEIVED",    "IN_PROGRESS",
        "IN_PROGRESS", "RESOLVED"
    );

    @Autowired private RoutingService routingService;
    @Autowired private AiEnrichmentService aiEnrichmentService;
    @Autowired private FcmService fcmService;

    /* ── Create a new report ─────────────────────────────────── */

    public Map<String, Object> saveReport(String uid, String category, String details,
                                          double latitude, double longitude, List<String> imageUrls) throws Exception {
        Firestore db = FirestoreClient.getFirestore();
        String reportId = UUID.randomUUID().toString();

        // First image is the "primary" — kept in imageUrl for backward compatibility
        // (web modal, mobile cards, AI all read imageUrl). Full set goes in imageUrls.
        String imageUrl = (imageUrls != null && !imageUrls.isEmpty()) ? imageUrls.get(0) : "";

        Map<String, Object> reportData = new HashMap<>();
        reportData.put("reportId", reportId);
        reportData.put("userId", uid);
        reportData.put("category", category);
        reportData.put("details", details != null ? details : "");
        reportData.put("imageUrl", imageUrl);
        reportData.put("imageUrls", imageUrls != null ? imageUrls : List.of());
        reportData.put("status", "NEW");
        reportData.put("createdAt", FieldValue.serverTimestamp());

        Map<String, Double> location = new HashMap<>();
        location.put("latitude", latitude);
        location.put("longitude", longitude);
        reportData.put("location", location);

        // Routing: find nearest matching organisation
        RoutingService.DispatchResult dispatch = null;
        try {
            dispatch = routingService.findNearestOrg(category, latitude, longitude);
        } catch (Exception e) {
            System.err.println("[Routing] Failed: " + e.getMessage());
        }

        if (dispatch != null) {
            reportData.put("status",          "RECEIVED");
            reportData.put("assignedOrgId",   dispatch.orgId());
            reportData.put("assignedOrgName", dispatch.orgName());
            reportData.put("assignedOrgType", dispatch.orgType());
            reportData.put("etaMinutes",      dispatch.etaMinutes());
        }

        db.collection("reports").document(reportId).set(reportData).get();
        System.out.println("[ReportService] Report saved: " + reportId + " — now calling enrichReport, imageUrl=" + imageUrl);

        // Sanitized public copy for the community feed/map (no reporter identity,
        // no assignment, no status). Readable by all authenticated users.
        Map<String, Object> publicData = new HashMap<>();
        publicData.put("reportId",  reportId);
        publicData.put("category",  category);
        publicData.put("details",   details != null ? details : "");
        publicData.put("imageUrl",  imageUrl);
        publicData.put("location",  location);
        publicData.put("createdAt", FieldValue.serverTimestamp());
        db.collection("public_incidents").document(reportId).set(publicData).get();

        // Async AI enrichment — fires and forgets, does not block the response
        aiEnrichmentService.enrichReport(reportId, imageUrl, category, details);
        System.out.println("[ReportService] enrichReport call returned (async dispatched) for " + reportId);

        Map<String, Object> result = new HashMap<>();
        result.put("reportId", reportId);
        result.put("imageUrl", imageUrl);
        if (dispatch != null) {
            result.put("assignedOrgId",   dispatch.orgId());
            result.put("assignedOrgName", dispatch.orgName());
            result.put("etaMinutes",      dispatch.etaMinutes());
        }
        return result;
    }

    /* ── Attach a video uploaded after the report was created ── */
    // Called by the background video upload endpoint. Video is kept on the
    // private report (for responders), not copied to the public feed.

    public void attachVideo(String reportId, String videoUrl) throws Exception {
        Firestore db = FirestoreClient.getFirestore();
        var snap = db.collection("reports").document(reportId).get().get();
        if (!snap.exists()) throw new Exception("Report not found: " + reportId);
        db.collection("reports").document(reportId).update(
            "videoUrl", videoUrl,
            "videoUpdatedAt", FieldValue.serverTimestamp()
        ).get();
    }

    /* ── Update status (state machine) ──────────────────────── */

    public void updateStatus(String reportId, String newStatus) throws Exception {
        Firestore db = FirestoreClient.getFirestore();

        // Read current report
        var snap = db.collection("reports").document(reportId).get().get();
        if (!snap.exists()) throw new Exception("Report not found: " + reportId);

        String current = snap.getString("status");

        // Validate transition — throws if illegal
        String allowed = VALID_NEXT_STATUS.get(current != null ? current : "NEW");
        if (!newStatus.equals(allowed)) {
            throw new Exception("Invalid status transition: " + current + " → " + newStatus);
        }

        // Write new status
        db.collection("reports").document(reportId).update(
            "status", newStatus,
            "statusUpdatedAt", FieldValue.serverTimestamp()
        ).get();

        // Send FCM push to the citizen who filed the report
        String userId = snap.getString("userId");
        String category = snap.getString("category");
        if (userId != null) {
            var userSnap = db.collection("users").document(userId).get().get();
            String fcmToken = (String) userSnap.get("fcmToken");
            if (fcmToken != null && !fcmToken.isBlank()) {
                fcmService.sendStatusUpdate(fcmToken, category != null ? category : "incident", newStatus);
            }
        }
    }
}
