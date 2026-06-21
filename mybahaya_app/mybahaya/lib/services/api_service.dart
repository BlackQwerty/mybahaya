import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class SubmitReportResult {
  final String reportId;
  final String? assignedOrgName;
  final int? etaMinutes;

  const SubmitReportResult({
    required this.reportId,
    this.assignedOrgName,
    this.etaMinutes,
  });
}

class ApiService {
  static String get baseUrl {
    const configuredBaseUrl = String.fromEnvironment('MYBAHAYA_API_BASE_URL');
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    return 'https://api.mybahaya.com/api'; // was http://178.105.158.80:8080/api
  }

  /// Uploads a report using multipart/form-data to the Spring Boot backend.
  /// Returns dispatch info (reportId, assigned org, ETA) on success.
  static Future<SubmitReportResult> submitReport({
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
      onTimeout:
          () =>
              throw SocketException(
                'Timed out connecting to backend at $baseUrl',
              ),
    );
    final response = await http.Response.fromStream(streamedResponse).timeout(
      const Duration(seconds: 30),
      onTimeout:
          () =>
              throw SocketException(
                'Timed out waiting for backend response from $baseUrl',
              ),
    );

    if (response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return SubmitReportResult(
        reportId: body['reportId'] as String? ?? '',
        assignedOrgName: body['assignedOrgName'] as String?,
        etaMinutes: body['etaMinutes'] as int?,
      );
    }

    final serverMessage = response.body.isNotEmpty ? ' - ${response.body}' : '';
    throw Exception(
      'Backend returned ${response.statusCode}$serverMessage. API: $baseUrl/reports',
    );
  }
}
