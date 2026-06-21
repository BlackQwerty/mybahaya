package com.shukri.mybahaya.service;

import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class RoutingService {

    // Maps Flutter category names to org types in Firestore
    private static final Map<String, String> CATEGORY_TO_ORG_TYPE = Map.of(
        "Fire",     "fire",
        "Medical",  "medical",
        "Theft",    "police",
        "Assault",  "police"
        // "Other" maps to null → picks closest org of any type
    );

    public record DispatchResult(String orgId, String orgName, String orgType, int etaMinutes) {}

    public DispatchResult findNearestOrg(String category, double lat, double lng) throws Exception {
        Firestore db = FirestoreClient.getFirestore();
        String targetType = CATEGORY_TO_ORG_TYPE.get(category);

        ApiFuture<QuerySnapshot> future = db.collection("organizations")
            .whereEqualTo("status", "active")
            .get();

        List<QueryDocumentSnapshot> docs = future.get().getDocuments();

        QueryDocumentSnapshot best = null;
        double bestDist = Double.MAX_VALUE;

        for (QueryDocumentSnapshot doc : docs) {
            // Skip if type doesn't match (unless category is "Other")
            if (targetType != null && !targetType.equals(doc.getString("type"))) continue;

            Double orgLat = doc.getDouble("latitude");
            Double orgLng = doc.getDouble("longitude");
            if (orgLat == null || orgLng == null) continue;

            double dist = haversineKm(lat, lng, orgLat, orgLng);
            if (dist < bestDist) {
                bestDist = dist;
                best = doc;
            }
        }

        if (best == null) return null;

        // ETA: road distance (straight × 1.3) at 40 km/h
        double roadKm = bestDist * 1.3;
        int etaMinutes = (int) Math.ceil((roadKm / 40.0) * 60.0);

        return new DispatchResult(
            best.getId(),
            best.getString("name"),
            best.getString("type"),
            etaMinutes
        );
    }

    private double haversineKm(double lat1, double lng1, double lat2, double lng2) {
        final double R = 6371.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                 + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                 * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
}
