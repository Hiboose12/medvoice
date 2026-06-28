/// Utility helpers for safely converting Dio response data
/// in both debug and release APK builds.
///
/// In release mode, Dart's type system erases generic types,
/// so `response.data is Map<String, dynamic>` may return false
/// even when the response is a valid JSON map. Use these helpers instead.
library;

/// Safely converts any map-like response.data to Map<String, dynamic>.
/// Works correctly in both debug and release (AOT-compiled) builds.
Map<String, dynamic> toMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  throw StateError('Expected a Map response but got ${data.runtimeType}');
}

/// Same as [toMap] but returns an empty map instead of throwing on null/non-map.
Map<String, dynamic> toMapOrEmpty(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return {};
}

/// Converts a list of dynamic items to List<Map<String, dynamic>>.
List<Map<String, dynamic>> toMapList(dynamic data) {
  if (data is List) {
    return data.map((e) {
      if (e is Map<String, dynamic>) return e;
      if (e is Map) return Map<String, dynamic>.from(e);
      throw StateError('List item is not a Map: ${e.runtimeType}');
    }).toList();
  }
  return [];
}
