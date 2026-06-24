import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
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

  /// Submits a report with 1–3 photos (multipart/form-data) to the backend.
  /// Returns dispatch info (reportId, assigned org, ETA) on success.
  /// Video is NOT sent here — it is uploaded separately in the background
  /// via [uploadVideo] so the citizen's report is recorded instantly.
  static Future<SubmitReportResult> submitReport({
    required List<File> imageFiles,
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

    // All photos use the same field name "images" — Spring binds them to a List.
    for (final file in imageFiles) {
      request.files.add(
        await http.MultipartFile.fromPath('images', file.path),
      );
    }

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () =>
          throw SocketException('Timed out connecting to backend at $baseUrl'),
    );
    final response = await http.Response.fromStream(streamedResponse).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw SocketException(
          'Timed out waiting for backend response from $baseUrl'),
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

  /// Uploads a video for an already-created report, in the background.
  /// [onProgress] is called with a value 0.0–1.0 so the UI can show a bar.
  /// Uses Dio because it exposes upload (send) progress; plain http does not.
  static Future<String?> uploadVideo({
    required String reportId,
    required File videoFile,
    void Function(double progress)? onProgress,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User is not authenticated');

    final token = await user.getIdToken();
    if (token == null) throw Exception('Failed to get authentication token');

    // Safety net — the report screen already rejects oversized videos at pick
    // time, but guard here too so we never start a doomed upload.
    final sizeBytes = await videoFile.length();
    const maxBytes = 100 * 1024 * 1024;
    if (sizeBytes > maxBytes) {
      final mb = (sizeBytes / (1024 * 1024)).toStringAsFixed(0);
      throw Exception('Video is too large (${mb}MB). Max 100MB — pick a shorter clip.');
    }

    final dio = Dio();
    final formData = FormData.fromMap({
      'video': await MultipartFile.fromFile(videoFile.path),
    });

    try {
      final response = await dio.post(
        '$baseUrl/reports/$reportId/video',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(minutes: 8),
          receiveTimeout: const Duration(minutes: 2),
        ),
        onSendProgress: (sent, total) {
          if (total > 0 && onProgress != null) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['videoUrl'] != null) {
          return data['videoUrl'] as String;
        }
        return null;
      }
      throw Exception('Server returned ${response.statusCode}');
    } on DioException catch (e) {
      // Surface the real reason instead of a swallowed silent failure.
      final code = e.response?.statusCode;
      if (code == 413) {
        throw Exception('Video rejected by server (too large). Try a shorter clip.');
      }
      if (e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Upload timed out — connection too slow for this video size.');
      }
      throw Exception('Upload failed${code != null ? ' ($code)' : ''}: ${e.message}');
    }
  }
}
