// lib/screens/admin/reports/type_helpers.dart
import 'package:flutter/foundation.dart';

class TypeHelpers {
  /// Converts any List to List<Map<String, dynamic>>
  static List<Map<String, dynamic>> convertToListOfMaps(List<dynamic> list) {
    try {
      if (list.isEmpty) return [];

      return list
          .map((item) {
            if (item == null) return <String, dynamic>{};

            // If already Map<String, dynamic>
            if (item is Map<String, dynamic>) {
              return item;
            }

            // If Map (untyped)
            if (item is Map) {
              try {
                return item.cast<String, dynamic>();
              } catch (e) {
                // Convert each key to String
                final Map<String, dynamic> converted = {};
                item.forEach((key, value) {
                  converted[key.toString()] = value;
                });
                return converted;
              }
            }

            // If item has toJson() or toMap() method
            try {
              if (item is dynamic &&
                  (item.toJson is Function || item.toMap is Function)) {
                if (item.toJson is Function) {
                  return Map<String, dynamic>.from(item.toJson());
                } else if (item.toMap is Function) {
                  return Map<String, dynamic>.from(item.toMap());
                }
              }
            } catch (_) {}

            // Return empty map for unsupported types
            debugPrint(
              'Cannot convert item of type ${item.runtimeType} to Map',
            );
            return <String, dynamic>{};
          })
          .where((map) => map.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error in convertToListOfMaps: $e');
      return [];
    }
  }

  /// Safely extracts list from map and converts it
  static List<Map<String, dynamic>> extractListFromMap(
    Map<String, dynamic> data,
    String key,
  ) {
    try {
      final value = data[key];
      if (value is List) {
        return convertToListOfMaps(value);
      }
      return [];
    } catch (e) {
      debugPrint('Error extracting list from map: $e');
      return [];
    }
  }
}
