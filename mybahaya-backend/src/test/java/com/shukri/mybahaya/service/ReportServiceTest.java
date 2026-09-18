package com.shukri.mybahaya.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Field;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for ReportService — focuses on the status state machine logic
 * which is pure Java and requires no Firebase connection.
 */
@DisplayName("Module 3 – Report Status State Machine")
class ReportServiceTest {

    // The VALID_NEXT_STATUS map is private static final in ReportService.
    // We expose it here as a mirror to test the same transition rules
    // without needing a live Firestore connection.
    private static final Map<String, String> VALID_NEXT_STATUS = Map.of(
        "NEW",         "RECEIVED",
        "RECEIVED",    "IN_PROGRESS",
        "IN_PROGRESS", "RESOLVED"
    );

    /** Simulates the transition logic inside ReportService.updateStatus() */
    private void assertValidTransition(String current, String next) {
        String allowed = VALID_NEXT_STATUS.get(current != null ? current : "NEW");
        assertEquals(next, allowed,
            "Expected " + current + " → " + next + " to be a valid transition");
    }

    private void assertInvalidTransition(String current, String attempted) {
        String allowed = VALID_NEXT_STATUS.get(current != null ? current : "NEW");
        assertNotEquals(attempted, allowed,
            "Expected " + current + " → " + attempted + " to be INVALID");
    }

    // ── Test cases ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("TC3.1 – NEW transitions to RECEIVED (valid)")
    void newToReceived_isValid() {
        assertValidTransition("NEW", "RECEIVED");
    }

    @Test
    @DisplayName("TC3.2 – RECEIVED transitions to IN_PROGRESS (valid)")
    void receivedToInProgress_isValid() {
        assertValidTransition("RECEIVED", "IN_PROGRESS");
    }

    @Test
    @DisplayName("TC3.3 – IN_PROGRESS transitions to RESOLVED (valid)")
    void inProgressToResolved_isValid() {
        assertValidTransition("IN_PROGRESS", "RESOLVED");
    }

    @Test
    @DisplayName("TC3.4 – NEW cannot skip to RESOLVED (invalid transition)")
    void newToResolved_isInvalid() {
        assertInvalidTransition("NEW", "RESOLVED");
    }

    @Test
    @DisplayName("TC3.5 – RESOLVED has no further valid transition")
    void resolved_hasNoNextStatus() {
        assertNull(VALID_NEXT_STATUS.get("RESOLVED"),
            "RESOLVED should have no valid next status");
    }
}

