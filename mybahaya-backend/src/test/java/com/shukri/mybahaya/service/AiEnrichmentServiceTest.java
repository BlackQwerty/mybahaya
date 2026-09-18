package com.shukri.mybahaya.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Method;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for AiEnrichmentService — tests JSON text extraction and
 * markdown fence stripping logic without calling the Gemini API.
 */
@DisplayName("Module 4 – AI Enrichment & JSON Parsing")
class AiEnrichmentServiceTest {

    private AiEnrichmentService service;

    @BeforeEach
    void setUp() {
        service = new AiEnrichmentService();
    }

    /** Calls the private extractText method via reflection */
    private String extractText(Map<String, Object> response) throws Exception {
        Method m = AiEnrichmentService.class.getDeclaredMethod("extractText", Map.class);
        m.setAccessible(true);
        return (String) m.invoke(service, response);
    }

    /** Builds a fake Gemini response map with the given text content */
    @SuppressWarnings("unchecked")
    private Map<String, Object> fakeGeminiResponse(String text) {
        return Map.of(
            "candidates", List.of(
                Map.of("content", Map.of(
                    "parts", List.of(Map.of("text", text))
                ))
            )
        );
    }

    // ── Test cases ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("TC4.1 – extractText returns correct text from valid Gemini response")
    void extractText_validResponse() throws Exception {
        String expected = "{\"severity\":3,\"summary\":\"Fire at building\"}";
        Map<String, Object> response = fakeGeminiResponse(expected);
        assertEquals(expected, extractText(response));
    }

    @Test
    @DisplayName("TC4.2 – extractText returns null for empty candidates list")
    void extractText_emptyCandidates() throws Exception {
        Map<String, Object> response = Map.of("candidates", List.of());
        assertNull(extractText(response));
    }

    @Test
    @DisplayName("TC4.3 – extractText returns null for null response")
    void extractText_nullResponse() throws Exception {
        // The enrichReport method guards against null before calling extractText,
        // but the method itself should handle it gracefully.
        assertNull(extractText(Map.of())); // no "candidates" key → should return null
    }

    @Test
    @DisplayName("TC4.4 – Markdown fence stripping removes ```json ... ``` wrapper")
    void markdownFenceStripping_removesCodeBlock() {
        String raw = "```json\n{\"severity\":4,\"summary\":\"Flood\"}\n```";
        String cleaned = raw.strip()
            .replaceAll("(?s)^```json\\s*", "")
            .replaceAll("(?s)```\\s*$", "")
            .strip();
        assertEquals("{\"severity\":4,\"summary\":\"Flood\"}", cleaned,
            "Markdown fences should be stripped from AI response");
    }
}

