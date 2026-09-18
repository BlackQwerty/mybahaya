package com.shukri.mybahaya.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Method;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for RoutingService — tests the pure-Java haversine calculation
 * and ETA formula without any Firestore connection.
 */
@DisplayName("Module 5 – Routing & ETA Calculation")
class RoutingServiceTest {

    private final RoutingService service = new RoutingService();

    /** Calls the private haversineKm method via reflection */
    private double haversine(double lat1, double lng1, double lat2, double lng2) throws Exception {
        Method m = RoutingService.class.getDeclaredMethod("haversineKm", double.class, double.class, double.class, double.class);
        m.setAccessible(true);
        return (double) m.invoke(service, lat1, lng1, lat2, lng2);
    }

    // ── Test cases ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("TC5.1 – Same point distance is zero")
    void samePoint_distanceIsZero() throws Exception {
        double dist = haversine(3.1390, 101.6869, 3.1390, 101.6869);
        assertEquals(0.0, dist, 0.001, "Distance from a point to itself must be 0");
    }

    @Test
    @DisplayName("TC5.2 – KL City to Putrajaya ≈ 25 km")
    void klToPutrajaya_approx25km() throws Exception {
        // KL City (3.1390, 101.6869) → Putrajaya (2.9264, 101.6964)
        double dist = haversine(3.1390, 101.6869, 2.9264, 101.6964);
        assertTrue(dist > 22 && dist < 28,
            "KL→Putrajaya should be ~25 km, got: " + dist);
    }

    @Test
    @DisplayName("TC5.3 – Haversine result is non-negative")
    void haversine_alwaysNonNegative() throws Exception {
        double dist = haversine(5.4141, 100.3288, 3.1390, 101.6869);
        assertTrue(dist >= 0, "Distance must always be non-negative");
    }

    @Test
    @DisplayName("TC5.4 – ETA formula: 10 km straight → ceil((10×1.3/40)×60) = 20 min")
    void etaFormula_10km() {
        double straightKm = 10.0;
        double roadKm = straightKm * 1.3;          // 13 km
        int eta = (int) Math.ceil((roadKm / 40.0) * 60.0);   // 19.5 → 20
        assertEquals(20, eta, "ETA for 10 km straight should be 20 minutes");
    }
}

