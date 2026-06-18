import 'dart:convert';
import 'package:http/http.dart' as http;

/// Reverse geocoding via OpenStreetMap Nominatim (free, no API key needed).
/// Results are cached in memory so the same coordinate is never fetched twice.
class GeocodingService {
  // Cache keyed by "lat,lng" rounded to 4 decimal places (~11m accuracy)
  static final Map<String, _GeoResult> _cache = {};

  static String _key(double lat, double lng) =>
      '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';

  /// Returns both place name and state for a coordinate.
  /// Uses cache — safe to call repeatedly.
  static Future<_GeoResult> reverse(double lat, double lng) async {
    final k = _key(lat, lng);
    if (_cache.containsKey(k)) return _cache[k]!;

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lng&format=json&addressdetails=1',
      );
      final response = await http
          .get(uri, headers: {'User-Agent': 'MyBahaya/1.0 (mybahaya.app)'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>? ?? {};

        // Pick the most specific place name available
        final place = (address['amenity'] ??
                address['shop'] ??
                address['building'] ??
                address['road'] ??
                address['suburb'] ??
                address['village'] ??
                address['town'] ??
                address['city_district'] ??
                address['city'] ??
                'Unknown Location')
            as String;

        // Malaysian state (negeri)
        final state = (address['state'] ?? 'Malaysia') as String;

        final result = _GeoResult(place: place, state: state);
        _cache[k] = result;
        return result;
      }
    } catch (_) {}

    final fallback = _GeoResult(place: 'Unknown Location', state: 'Malaysia');
    _cache[k] = fallback;
    return fallback;
  }

  static Future<String> getPlaceName(double lat, double lng) async =>
      (await reverse(lat, lng)).place;

  static Future<String> getState(double lat, double lng) async =>
      (await reverse(lat, lng)).state;
}

class _GeoResult {
  final String place;
  final String state;
  const _GeoResult({required this.place, required this.state});
}
