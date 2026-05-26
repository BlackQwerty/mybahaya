package com.shukri.mybahaya.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import org.springframework.context.annotation.Configuration;

@Configuration
public class FirebaseConfig {

    @PostConstruct
    public void initialize() {
        try {
            // Looks for the active 'gcloud auth application-default login' session on your Mac
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.getApplicationDefault())
                    .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
                System.out.println("🚀 Firebase Admin SDK initialized seamlessly using Application Default Credentials!");
            }
        } catch (Exception e) {
            System.err.println("❌ Failed to initialize Firebase via ADC: " + e.getMessage());
            e.printStackTrace();
        }
    }
}