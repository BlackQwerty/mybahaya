package com.shukri.mybahaya.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.stereotype.Service;

@Service
public class FcmService {

    // Called after every status change to push a notification to the citizen's phone.
    public void sendStatusUpdate(String fcmToken, String category, String newStatus) {
        String title = "MyBahaya — Report Update";
        String body = switch (newStatus) {
            case "IN_PROGRESS" -> "Responders are on the way for your " + category + " report.";
            case "RESOLVED"    -> "Your " + category + " report has been resolved. Thank you!";
            default            -> "Your " + category + " report status: " + newStatus + ".";
        };
        send(fcmToken, title, body, "status", newStatus, "category", category);
    }

    // Called when a new report is within a citizen's chosen alert radius.
    public void sendNearbyAlert(String fcmToken, String category, double distanceKm) {
        String dist = distanceKm < 1
            ? Math.round(distanceKm * 1000) + "m"
            : String.format("%.1f", distanceKm) + "km";
        String title = "⚠️ " + category + " incident nearby";
        String body  = "A " + category.toLowerCase() + " incident was reported " + dist + " from your location.";
        send(fcmToken, title, body, "type", "nearby_alert", "category", category);
    }

    // Called when a new report is assigned to an org — targets their browser push token.
    public void sendNewAssignment(String browserToken, String orgName, String category, String reportId) {
        String title = "New incident assigned";
        String body  = category + " report assigned to " + orgName + ". Tap to view.";
        send(browserToken, title, body, "type", "new_assignment", "reportId", reportId);
    }

    // Generic send — shared by all three methods above.
    private void send(String token, String title, String body, String... dataPairs) {
        var builder = Message.builder()
            .setToken(token)
            .setNotification(Notification.builder().setTitle(title).setBody(body).build());
        for (int i = 0; i + 1 < dataPairs.length; i += 2) {
            builder.putData(dataPairs[i], dataPairs[i + 1]);
        }
        try {
            FirebaseMessaging.getInstance().send(builder.build());
        } catch (FirebaseMessagingException e) {
            System.err.println("[FCM] Failed (" + title + "): " + e.getMessage());
        }
    }
}
