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

        String imageUrl = (imageUrls != null && !imageUrls.isEmpty()) ? imageUrls.get(0) : "";

        Map<String, Object> reportData = new HashMap<>();
        reportData.put("reportId",           reportId);
        reportData.put("userId",             uid);
        reportData.put("category",           category);
        reportData.put("details",            details != null ? details : "");
        reportData.put("imageUrl",           imageUrl);
        reportData.put("imageUrls",          imageUrls != null ? imageUrls : List.of());
        reportData.put("status",             "NEW");
        reportData.put("verificationStatus", "PENDING");
        reportData.put("createdAt",          FieldValue.serverTimestamp());

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

        // Sanitized public copy — includes verificationStatus so the Flutter
        // community feed can show "False Alarm" badges on rejected reports.
        Map<String, Object> publicData = new HashMap<>();
        publicData.put("reportId",           reportId);
        publicData.put("category",           category);
        publicData.put("details",            details != null ? details : "");
        publicData.put("imageUrl",           imageUrl);
        publicData.put("imageUrls",          imageUrls != null ? imageUrls : List.of());
        publicData.put("location",           location);
        publicData.put("createdAt",          FieldValue.serverTimestamp());
        publicData.put("verificationStatus", "PENDING");
        db.collection("public_incidents").document(reportId).set(publicData).get();

        // Phase 1 — notify nearby citizens asynchronously
        final RoutingService.DispatchResult finalDispatch = dispatch;
        new Thread(() -> {
            notifyNearbyUsers(category, latitude, longitude, uid);
            // Phase 3 — notify assigned org's browser
            if (finalDispatch != null) {
                notifyOrg(finalDispatch.orgId(), finalDispatch.orgName(), category, reportId);
            }
        }).start();

        // Async AI enrichment — does not block the response
        aiEnrichmentService.enrichReport(reportId, imageUrl, category, details);

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

    /* ── Phase 1: notify citizens within their chosen radius ── */

    private void notifyNearbyUsers(String category, double reportLat, double reportLng, String reporterUid) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            var users = db.collection("users").get().get().getDocuments();
            System.out.println("[Nearby FCM] === Checking " + users.size() + " users for a " + category
                + " report at (" + reportLat + ", " + reportLng + ") ===");

            int sent = 0;
            for (var userDoc : users) {
                String uid = userDoc.getId();

                if (uid.equals(reporterUid)) {
                    System.out.println("[Nearby FCM] " + uid + " → SKIP (is the reporter)");
                    continue;
                }

                String token   = userDoc.getString("fcmToken");
                Double userLat  = userDoc.getDouble("latitude");
                Double userLng  = userDoc.getDouble("longitude");
                Double radius   = userDoc.getDouble("alertRadiusKm");

                if (token == null || token.isBlank()) {
                    System.out.println("[Nearby FCM] " + uid + " → SKIP (no fcmToken)");
                    continue;
                }
                if (userLat == null || userLng == null) {
                    System.out.println("[Nearby FCM] " + uid + " → SKIP (no latitude/longitude saved — open the app's Home screen)");
                    continue;
                }
                if (radius == null) {
                    System.out.println("[Nearby FCM] " + uid + " → SKIP (no alertRadiusKm)");
                    continue;
                }

                double dist = haversineKm(reportLat, reportLng, userLat, userLng);
                if (dist <= radius) {
                    System.out.println("[Nearby FCM] " + uid + " → SEND (" + String.format("%.2f", dist)
                        + "km away, radius " + radius + "km)");
                    fcmService.sendNearbyAlert(token, category, dist);
                    sent++;
                } else {
                    System.out.println("[Nearby FCM] " + uid + " → SKIP (" + String.format("%.2f", dist)
                        + "km away, outside " + radius + "km radius)");
                }
            }
            System.out.println("[Nearby FCM] === Done. Notifications sent: " + sent + " ===");
        } catch (Exception e) {
            System.err.println("[Nearby FCM] Failed: " + e.getMessage());
            e.printStackTrace();
        }
    }

    /* ── Phase 3: notify the assigned org's browser ── */

    private void notifyOrg(String orgId, String orgName, String category, String reportId) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            var orgSnap = db.collection("organizations").document(orgId).get().get();
            if (!orgSnap.exists()) return;
            String browserToken = orgSnap.getString("browserFcmToken");
            if (browserToken == null || browserToken.isBlank()) return;
            fcmService.sendNewAssignment(browserToken, orgName, category, reportId);
        } catch (Exception e) {
            System.err.println("[Org FCM] Failed: " + e.getMessage());
        }
    }

    private static double haversineKm(double lat1, double lng1, double lat2, double lng2) {
        final double R = 6371.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                 + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                   * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    /* ── Attach a video uploaded after the report was created ── */

    public void attachVideo(String reportId, String videoUrl) throws Exception {
        Firestore db = FirestoreClient.getFirestore();
        var snap = db.collection("reports").document(reportId).get().get();
        if (!snap.exists()) throw new Exception("Report not found: " + reportId);
        db.collection("reports").document(reportId).update(
            "videoUrl", videoUrl,
            "videoUpdatedAt", FieldValue.serverTimestamp()
        ).get();

        // Mirror the video to the public feed so the mobile community view
        // (which reads public_incidents) can show it to everyone too.
        try {
            db.collection("public_incidents").document(reportId).update(
                "videoUrl", videoUrl
            ).get();
        } catch (Exception ignored) {}
    }

    /* ── Phase 2: verify or reject a report ─────────────────── */

    public void verifyReport(String reportId, String action) throws Exception {
        if (!action.equals("VERIFIED") && !action.equals("REJECTED")) {
            throw new Exception("Invalid action: " + action + ". Must be VERIFIED or REJECTED.");
        }
        Firestore db = FirestoreClient.getFirestore();
        var snap = db.collection("reports").document(reportId).get().get();
        if (!snap.exists()) throw new Exception("Report not found: " + reportId);

        db.collection("reports").document(reportId).update(
            "verificationStatus", action,
            "verifiedAt", FieldValue.serverTimestamp()
        ).get();

        // Mirror to public_incidents so Flutter community feed shows the badge
        try {
            db.collection("public_incidents").document(reportId).update(
                "verificationStatus", action
            ).get();
        } catch (Exception ignored) {}
    }

    /* ── Update status (state machine) ──────────────────────── */

    public void updateStatus(String reportId, String newStatus) throws Exception {
        Firestore db = FirestoreClient.getFirestore();

        var snap = db.collection("reports").document(reportId).get().get();
        if (!snap.exists()) throw new Exception("Report not found: " + reportId);

        String current = snap.getString("status");

        String allowed = VALID_NEXT_STATUS.get(current != null ? current : "NEW");
        if (!newStatus.equals(allowed)) {
            throw new Exception("Invalid status transition: " + current + " → " + newStatus);
        }

        db.collection("reports").document(reportId).update(
            "status", newStatus,
            "statusUpdatedAt", FieldValue.serverTimestamp()
        ).get();

        String userId   = snap.getString("userId");
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
