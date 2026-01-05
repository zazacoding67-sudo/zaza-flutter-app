import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ========== CONFIGURATION ==========
  // SET THIS TO FALSE for real API testing
  static const bool useDummyData = false; // ⚠️ CHANGE TO FALSE

  // ⚠️ VERIFY THIS IP IS CORRECT - Use your computer's IP
  // Run 'ipconfig' in CMD to find IPv4 Address
  static const String baseUrl = 'http://192.168.100.121/zaza_api';

  // Alternative URLs if above doesn't work:
  // For web testing: 'http://localhost/zaza_api'
  // For emulator: 'http://10.0.2.2/zaza_api'
  // For physical device: 'http://YOUR_COMPUTER_IP/zaza_api'

  // ========== ASSETS API ==========
  static Future<List<dynamic>> getAssets({String? status}) async {
    print('📱 getAssets() called | useDummyData: $useDummyData');

    if (useDummyData) {
      print('📦 Returning DUMMY assets data');
      return _getDummyAssets();
    }

    try {
      print('🌐 Attempting to connect to: $baseUrl/assets/read.php');

      String url = '$baseUrl/assets/read.php';
      if (status != null) {
        url += '?status=$status';
      }

      print('🔗 Full URL: $url');

      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      print('📡 HTTP Status Code: ${response.statusCode}');
      print(
        '📡 Response Body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) + '...' : response.body}',
      );

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          final records = data['records'] ?? [];
          print('✅ SUCCESS! Loaded ${records.length} assets from API');
          return records;
        } catch (e) {
          print('❌ JSON Parse Error: $e');
          print('❌ Raw response: ${response.body}');
          throw Exception('Invalid JSON format from server');
        }
      } else {
        print('❌ Server Error ${response.statusCode}: ${response.body}');
        throw Exception('Server error ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Network/Connection Error: $e');
      print('❌ Type of error: ${e.runtimeType}');
      return _getDummyAssets(); // Fallback to dummy data on error
    }
  }

  // ========== BORROWINGS API ==========
  static Future<List<dynamic>> getBorrowings({String? status}) async {
    print('📱 getBorrowings() called | useDummyData: $useDummyData');

    if (useDummyData) {
      print('📦 Returning DUMMY borrowings data');
      return _getDummyBorrowings();
    }

    try {
      print('🌐 Attempting to connect to: $baseUrl/borrowings/read.php');

      String url = '$baseUrl/borrowings/read.php';
      if (status != null) {
        url += '?status=$status';
      }

      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      print('📡 HTTP Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final records = data['records'] ?? [];
        print('✅ SUCCESS! Loaded ${records.length} borrowings from API');
        return records;
      } else {
        print('❌ Server Error ${response.statusCode}');
        throw Exception('Server error ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Network/Connection Error: $e');
      return _getDummyBorrowings(); // Fallback to dummy data on error
    }
  }

  // ========== DUMMY DATA (FALLBACK) ==========
  static Future<List<Map<String, dynamic>>> _getDummyAssets() async {
    print('🔄 Loading dummy assets (fallback)...');
    await Future.delayed(const Duration(seconds: 1));

    return [
      {
        'asset_id': '1',
        'asset_name': 'MacBook Pro',
        'brand': 'Apple',
        'model': 'M2 Pro 14"',
        'category': 'Computer',
        'location': 'Office Floor 3',
        'status': 'Borrowed',
        'purchase_date': '2024-01-15',
        'serial_number': 'MBP14M2-2024-001',
        'notes': 'For development team',
      },
      {
        'asset_id': '2',
        'asset_name': 'Dell Laptop',
        'brand': 'Dell',
        'model': 'Latitude 5420',
        'category': 'Computer',
        'location': 'Office Floor 2',
        'status': 'Available',
        'purchase_date': '2024-02-20',
        'serial_number': 'DL5420-2024-002',
        'notes': 'General use',
      },
      // ... add more dummy assets as needed
    ];
  }

  static Future<List<Map<String, dynamic>>> _getDummyBorrowings() async {
    print('🔄 Loading dummy borrowings (fallback)...');
    await Future.delayed(const Duration(seconds: 1));

    return [
      {
        'borrowing_id': '1',
        'asset_name': 'MacBook Pro',
        'user_name': 'Ahmad Ali',
        'staff_id': 'STAFF001',
        'borrow_date': '2024-12-10',
        'expected_return_date': '2024-12-20',
        'actual_return_date': null,
        'status': 'Active',
        'purpose': 'Project Development',
      },
      // ... add more dummy borrowings as needed
    ];
  }

  // ========== CREATE METHODS ==========
  static Future<bool> createBorrowing(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/borrowings/create.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Error creating borrowing: $e');
    }
  }

  static Future<bool> createAsset(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/assets/create.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Error creating asset: $e');
    }
  }
}
