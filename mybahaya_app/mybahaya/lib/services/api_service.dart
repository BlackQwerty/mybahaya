import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static String get baseUrl {
    const configuredBaseUrl = String.fromEnvironment('MYBAHAYA_API_BASE_URL');
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    return 'http://178.105.158.80:8080/api';
  }

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

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['category'] = category;
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
    if (details != null && details.isNotEmpty) {
      request.fields['details'] = details;
    }

    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw SocketException(
        'Timed out connecting to backend at $baseUrl',
      ),
    );
    final response = await http.Response.fromStream(streamedResponse).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw SocketException(
        'Timed out waiting for backend response from $baseUrl',
      ),
    );

    if (response.statusCode == 201) {
      return 'success';
    }

    final serverMessage = response.body.isNotEmpty
        ? ' - ${response.body}'
        : '';
    throw Exception(
      'Backend returned ${response.statusCode}$serverMessage. API: $baseUrl/reports',
    );
  }
}
