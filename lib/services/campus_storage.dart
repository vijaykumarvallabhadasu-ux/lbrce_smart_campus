
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CampusStorage {
  static const String _bookmarksKey = 'campus_bookmarks';
  static const String _coordinatesKey = 'campus_coordinates';

  /// Save bookmarked campus location IDs.
  static Future<void> saveBookmarks(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _bookmarksKey,
      ids.toList(),
    );
  }

  /// Load bookmarked campus location IDs.
  static Future<Set<String>> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();

    return (prefs.getStringList(_bookmarksKey) ?? <String>[])
        .toSet();
  }

  /// Save a custom latitude and longitude for a campus location.
  static Future<void> saveCoordinates(
    String buildingId,
    double latitude,
    double longitude,
  ) async {
    if (buildingId.trim().isEmpty) {
      throw ArgumentError('Building ID cannot be empty.');
    }

    if (!latitude.isFinite ||
        latitude < -90 ||
        latitude > 90) {
      throw ArgumentError('Latitude must be between -90 and 90.');
    }

    if (!longitude.isFinite ||
        longitude < -180 ||
        longitude > 180) {
      throw ArgumentError('Longitude must be between -180 and 180.');
    }

    final prefs = await SharedPreferences.getInstance();
    final coordinates = await loadAllCoordinates();

    coordinates[buildingId] = {
      'latitude': latitude,
      'longitude': longitude,
    };

    await prefs.setString(
      _coordinatesKey,
      jsonEncode(coordinates),
    );
  }

  /// Load all saved coordinate overrides.
  static Future<Map<String, Map<String, double>>>
      loadAllCoordinates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_coordinatesKey);

    if (raw == null || raw.isEmpty) {
      return <String, Map<String, double>>{};
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map<String, dynamic>) {
        return <String, Map<String, double>>{};
      }

      final result = <String, Map<String, double>>{};

      for (final entry in decoded.entries) {
        final value = entry.value;

        if (value is! Map<String, dynamic>) {
          continue;
        }

        final latitudeValue = value['latitude'];
        final longitudeValue = value['longitude'];

        if (latitudeValue is! num ||
            longitudeValue is! num) {
          continue;
        }

        final latitude = latitudeValue.toDouble();
        final longitude = longitudeValue.toDouble();

        if (!latitude.isFinite ||
            latitude < -90 ||
            latitude > 90 ||
            !longitude.isFinite ||
            longitude < -180 ||
            longitude > 180) {
          continue;
        }

        result[entry.key] = {
          'latitude': latitude,
          'longitude': longitude,
        };
      }

      return result;
    } catch (_) {
      // Return an empty map if stored coordinate data is invalid.
      return <String, Map<String, double>>{};
    }
  }

  /// Remove the custom coordinates for one campus location.
  static Future<void> clearCoordinates(String buildingId) async {
    final prefs = await SharedPreferences.getInstance();
    final coordinates = await loadAllCoordinates();

    coordinates.remove(buildingId);

    await prefs.setString(
      _coordinatesKey,
      jsonEncode(coordinates),
    );
  }

  /// Remove all saved bookmarks and coordinate overrides.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_bookmarksKey);
    await prefs.remove(_coordinatesKey);
  }
}
