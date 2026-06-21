package com.shukri.mybahaya.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.stereotype.Service;

@Service
public class FcmService {

    // Called after every status change to push a notification to the citizen's phone.
    // fcmToken is the unique device address saved by the Flutter app on login.
    public void sendStatusUpdate(String fcmToken, String category, String newStatus) {
        String title = "MyBahaya — Report Update";
        String body = switch (newStatus) {
            case "IN_PROGRESS" -> "Responders are on the way for your " + category + " report.";
            case "RESOLVED"    -> "Your " + category + " report has been resolved. Thank you!";
            default            -> "Your " + category + " report status: " + newStatus + ".";
        };

        Message message = Message.builder()
            .setToken(fcmToken)
            .setNotification(Notification.builder()
                .setTitle(title)
                .setBody(body)
                .build())
            // Data payload lets Flutter read values even in background
            .putData("status", newStatus)
            .putData("category", category)
            .build();

        try {
            String messageId = FirebaseMessaging.getInstance().send(message);
            System.out.println("[FCM] Sent to " + fcmToken.substring(0, 10) + "… → " + messageId);
        } catch (FirebaseMessagingException e) {
            System.err.println("[FCM] Failed: " + e.getMessage());
        }
    }
}
