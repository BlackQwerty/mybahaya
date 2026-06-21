package com.shukri.mybahaya.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.cloud.firestore.FieldValue;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class AiEnrichmentService {

    @Value("${gemini.api.key}")
    private String geminiApiKey;

    // NOTE: gemini-2.0-flash had its free-tier quota set to 0 by Google.
    // Free quota now lives on gemini-2.5-flash, which also supports vision.
    private static final String GEMINI_URL =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=";

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Async
    public void enrichReport(String reportId, String imageUrl, String category, String details) {
        System.out.println("[AI] Starting enrichment for report " + reportId + " imageUrl=" + imageUrl);
        try {
            HttpURLConnection conn = (HttpURLConnection) URI.create(imageUrl).toURL().openConnection();
            conn.setConnectTimeout(10_000);
            conn.setReadTimeout(30_000);
            InputStream is = conn.getInputStream();
            byte[] imageBytes = is.readAllBytes();
            is.close();
            System.out.println("[AI] Downloaded image: " + imageBytes.length + " bytes");
            String base64Image = Base64.getEncoder().encodeToString(imageBytes);
            String mimeType = imageUrl.toLowerCase().endsWith(".png") ? "image/png" : "image/jpeg";

            String prompt = String.format(
                "You are an emergency incident analyzer for Malaysia. Analyze this incident image and return ONLY a JSON object with these exact fields:\n" +
                "- severity: integer 1-5 (1=minor, 5=life-threatening)\n" +
                "- summary: string (1-2 sentence description of what you observe)\n" +
                "- hazards: array of strings listing detected hazards\n" +
                "- suggestedCategory: string, one of: Fire, Medical, Theft, Assault, Other\n" +
                "- looksFake: boolean, true if the image appears staged or irrelevant to an emergency\n\n" +
                "Reported category: %s\nAdditional details: %s\n\n" +
                "Return ONLY valid JSON, no markdown code fences.",
                category, details != null && !details.isBlank() ? details : "none"
            );

            Map<String, Object> textPart = Map.of("text", prompt);
            Map<String, Object> imagePart = Map.of(
                "inline_data", Map.of("mime_type", mimeType, "data", base64Image)
            );
            Map<String, Object> requestBody = Map.of(
                "contents", List.of(Map.of("parts", List.of(textPart, imagePart)))
            );

            @SuppressWarnings("unchecked")
            Map<String, Object> response = restTemplate.postForObject(
                GEMINI_URL + geminiApiKey, requestBody, Map.class
            );

            if (response == null) return;

            String rawText = extractText(response);
            if (rawText == null || rawText.isBlank()) return;

            // Strip markdown fences if model returns them anyway
            String jsonText = rawText.strip()
                .replaceAll("(?s)^```json\\s*", "")
                .replaceAll("(?s)```\\s*$", "")
                .strip();

            @SuppressWarnings("unchecked")
            Map<String, Object> aiResult = objectMapper.readValue(jsonText, Map.class);

            Map<String, Object> updates = new HashMap<>();
            updates.put("ai.severity",          aiResult.getOrDefault("severity", 3));
            updates.put("ai.summary",           aiResult.getOrDefault("summary", ""));
            updates.put("ai.hazards",           aiResult.getOrDefault("hazards", List.of()));
            updates.put("ai.suggestedCategory", aiResult.getOrDefault("suggestedCategory", category));
            updates.put("ai.looksFake",         aiResult.getOrDefault("looksFake", false));
            updates.put("ai.processedAt",       FieldValue.serverTimestamp());

            Firestore db = FirestoreClient.getFirestore();
            db.collection("reports").document(reportId).update(updates).get();

            System.out.println("[AI] Enriched report " + reportId + " — severity=" + aiResult.get("severity"));

        } catch (Exception e) {
            System.err.println("[AI] Enrichment failed for report " + reportId + ": " + e.getMessage());
        }
    }

    @SuppressWarnings("unchecked")
    private String extractText(Map<String, Object> response) {
        try {
            var candidates = (List<Map<String, Object>>) response.get("candidates");
            if (candidates == null || candidates.isEmpty()) return null;
            var content = (Map<String, Object>) candidates.get(0).get("content");
            if (content == null) return null;
            var parts = (List<Map<String, Object>>) content.get("parts");
            if (parts == null || parts.isEmpty()) return null;
            return (String) parts.get(0).get("text");
        } catch (Exception e) {
            return null;
        }
    }
}
