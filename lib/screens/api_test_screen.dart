// lib/screens/api_test_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String testResult = 'Click test buttons...';
  bool isLoading = false;

  Future<void> testAssetsApi() async {
    setState(() {
      isLoading = true;
      testResult = 'Testing assets API...';
    });

    try {
      final assets = await ApiService.getAssets();
      setState(() {
        testResult =
            '✅ SUCCESS!\nLoaded ${assets.length} assets\n\nFirst asset: ${assets.isNotEmpty ? assets[0]['asset_name'] : 'None'}';
      });
    } catch (e) {
      setState(() {
        testResult = '❌ FAILED!\nError: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> testBorrowingsApi() async {
    setState(() {
      isLoading = true;
      testResult = 'Testing borrowings API...';
    });

    try {
      final borrowings = await ApiService.getBorrowings();
      setState(() {
        testResult =
            '✅ SUCCESS!\nLoaded ${borrowings.length} borrowings\n\nFirst record: ${borrowings.isNotEmpty ? borrowings[0]['asset_name'] : 'None'}';
      });
    } catch (e) {
      setState(() {
        testResult = '❌ FAILED!\nError: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Test')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'API Configuration',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text('Base URL: ${ApiService.baseUrl}'),
                    Text('Using Dummy Data: ${ApiService.useDummyData}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : testAssetsApi,
                    child: const Text('Test Assets API'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : testBorrowingsApi,
                    child: const Text('Test Borrowings API'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    testResult,
                    style: TextStyle(
                      color: testResult.contains('✅')
                          ? Colors.green
                          : testResult.contains('❌')
                          ? Colors.red
                          : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
