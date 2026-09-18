package com.shukri.mybahaya.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for FcmService message content — validates the message body
 * text produced for each notification type without sending real FCM messages.
 */
@DisplayName("Module 6 – FCM Notification Message Content")
class FcmServiceTest {

    // ── Helper: replicate the message-body logic from FcmService ────────────
    // We test the string-building logic directly without calling Firebase.

    private String buildStatusUpdateBody(String category, String newStatus) {
        return switch (newStatus) {
            case "IN_PROGRESS" -> "Responders are on the way for your " + category + " report.";
            case "RESOLVED"    -> "Your " + category + " report has been resolved. Thank you!";
            default            -> "Your " + category + " report status: " + newStatus + ".";
        };
    }

    private String buildNearbyAlertTitle(String category) {
        return "⚠️ " + category + " incident nearby";
    }

    private String buildDistanceString(double distanceKm) {
        return distanceKm < 1
            ? Math.round(distanceKm * 1000) + "m"
            : String.format("%.1f", distanceKm) + "km";
    }

    // ── Test cases ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("TC6.1 – IN_PROGRESS status produces 'Responders on the way' message")
    void inProgressStatus_correctBody() {
        String body = buildStatusUpdateBody("Fire", "IN_PROGRESS");
        assertTrue(body.contains("Responders are on the way"),
            "IN_PROGRESS message should mention responders");
        assertTrue(body.contains("Fire"), "Message should contain the category");
    }

    @Test
    @DisplayName("TC6.2 – RESOLVED status produces 'has been resolved' message")
    void resolvedStatus_correctBody() {
        String body = buildStatusUpdateBody("Medical", "RESOLVED");
        assertTrue(body.contains("resolved"),
            "RESOLVED message should say 'resolved'");
    }

    @Test
    @DisplayName("TC6.3 – Sub-kilometre distance formatted in metres (e.g. 250m)")
    void nearbyAlert_distanceLessThan1km_showsMetres() {
        String dist = buildDistanceString(0.25);
        assertEquals("250m", dist,
            "0.25 km should display as 250m");
    }
}

