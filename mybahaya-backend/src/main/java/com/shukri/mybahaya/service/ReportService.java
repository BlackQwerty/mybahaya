package com.shukri.mybahaya.service;

import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.FieldValue;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class ReportService {

    public String saveReport(String uid, String category, String details, double latitude, double longitude, String imageUrl) throws Exception {
        Firestore db = FirestoreClient.getFirestore();
        String reportId = UUID.randomUUID().toString();

        Map<String, Object> reportData = new HashMap<>();
        reportData.put("reportId", reportId);
        reportData.put("userId", uid);
        reportData.put("category", category);
        reportData.put("details", details != null ? details : "");
        reportData.put("imageUrl", imageUrl);
        
        Map<String, Double> location = new HashMap<>();
        location.put("latitude", latitude);
        location.put("longitude", longitude);
        reportData.put("location", location);
        
        // FieldValue.serverTimestamp() stores a proper Firestore Timestamp
        // (not a plain Java Date) so ordering and querying works correctly
        reportData.put("createdAt", FieldValue.serverTimestamp());

        // Save to Firestore 'reports' collection
        db.collection("reports").document(reportId).set(reportData).get();

        return reportId;
    }
}
