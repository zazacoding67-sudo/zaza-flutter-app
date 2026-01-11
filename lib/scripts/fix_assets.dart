import 'package:cloud_firestore/cloud_firestore.dart';

class DataFixer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fixAssetAvailability() async {
    print('Starting to fix asset availability...');

    try {
      final snapshot = await _firestore.collection('assets').get();
      int fixedCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString() ?? 'Available';
        final shouldBeAvailable = status.toLowerCase() == 'available';
        final currentIsAvailable = data['isAvailable'] ?? true;

        if (currentIsAvailable != shouldBeAvailable) {
          await doc.reference.update({
            'isAvailable': shouldBeAvailable,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          fixedCount++;
          print('Fixed asset: ${doc.id} - ${data['name']}');
        }
      }

      print('Fixed $fixedCount assets');
    } catch (e) {
      print('Error fixing assets: $e');
    }
  }
}
