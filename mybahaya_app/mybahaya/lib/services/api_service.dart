import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for iOS Simulator
  static final String baseUrl = Platform.isAndroid 
      ? 'http://10.0.2.2:8080/api'
      : 'http://127.0.0.1:8080/api';

  /// Uploads a report using multipart/form-data to the Spring Boot backend.
  /// Returns the newly created report ID on success.
  static Future<String> submitReport({
    required File imageFile,
    required String category,
    required double latitude,
    required double longitude,
    String? details,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    // Get the Firebase ID token to authenticate with Spring Boot
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Failed to get authentication token');
    }

    final uri = Uri.parse('$baseUrl/reports');
    final request = http.MultipartRequest('POST', uri);

    // Set auth header
    request.headers['Authorization'] = 'Bearer $token';

    // Add fields
    request.fields['category'] = category;
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
    if (details != null && details.isNotEmpty) {
      request.fields['details'] = details;
    }

    // Add image file
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    // Send request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      // Success
      return 'success';
    } else {
      throw Exception('Failed to submit report: ${response.statusCode} - ${response.body}');
    }
  }
}
