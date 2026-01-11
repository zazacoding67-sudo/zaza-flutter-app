// lib/services/asset_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/asset.dart';

class AssetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create new asset
  Future<String?> createAsset(Asset asset) async {
    try {
      final docRef = await _firestore
          .collection('assets')
          .add(asset.toFirestore());

      // Log activity
      await _logActivity(
        action: 'asset_created',
        performedBy: asset.createdBy,
        details: {'assetId': docRef.id, 'assetName': asset.name},
      );

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating asset: $e');
      return null;
    }
  }

  // Update asset
  Future<bool> updateAsset(
    String assetId,
    Map<String, dynamic> updates,
    String userId,
  ) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('assets').doc(assetId).update(updates);

      // Log activity
      await _logActivity(
        action: 'asset_updated',
        performedBy: userId,
        details: {'assetId': assetId},
      );

      return true;
    } catch (e) {
      debugPrint('Error updating asset: $e');
      return false;
    }
  }

  // Delete asset
  Future<bool> deleteAsset(String assetId, String userId) async {
    try {
      // Check if asset is currently borrowed
      final borrowings = await _firestore
          .collection('borrowings')
          .where('assetId', isEqualTo: assetId)
          .where('status', isEqualTo: 'active')
          .get();

      if (borrowings.docs.isNotEmpty) {
        debugPrint('Cannot delete asset: currently borrowed');
        return false;
      }

      await _firestore.collection('assets').doc(assetId).delete();

      // Log activity
      await _logActivity(
        action: 'asset_deleted',
        performedBy: userId,
        details: {'assetId': assetId},
      );

      return true;
    } catch (e) {
      debugPrint('Error deleting asset: $e');
      return false;
    }
  }

  // Get single asset
  Future<Asset?> getAsset(String assetId) async {
    try {
      final doc = await _firestore.collection('assets').doc(assetId).get();
      if (doc.exists) {
        return Asset.fromFirestore(doc.data()!, documentId: doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting asset: $e');
      return null;
    }
  }

  // Get all assets stream
  Stream<List<Asset>> getAssetsStream() {
    return _firestore
        .collection('assets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Asset.fromFirestore(doc.data(), documentId: doc.id))
              .toList(),
        );
  }

  // Get available assets stream
  Stream<List<Asset>> getAvailableAssetsStream() {
    return _firestore
        .collection('assets')
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Asset.fromFirestore(doc.data(), documentId: doc.id))
              .toList(),
        );
  }

  // Search assets
  Future<List<Asset>> searchAssets(String query) async {
    try {
      final snapshot = await _firestore.collection('assets').get();
      final assets = snapshot.docs
          .map((doc) => Asset.fromFirestore(doc.data(), documentId: doc.id))
          .toList();

      if (query.isEmpty) return assets;

      final lowerQuery = query.toLowerCase();
      return assets
          .where(
            (asset) =>
                asset.name.toLowerCase().contains(lowerQuery) ||
                asset.assetCode.toLowerCase().contains(lowerQuery) ||
                asset.category.toLowerCase().contains(lowerQuery) ||
                asset.description.toLowerCase().contains(lowerQuery),
          )
          .toList();
    } catch (e) {
      debugPrint('Error searching assets: $e');
      return [];
    }
  }

  // Generate unique asset code
  Future<String> generateAssetCode() async {
    try {
      final snapshot = await _firestore
          .collection('assets')
          .orderBy('assetCode', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return 'AST-001';
      }

      final lastCode = snapshot.docs.first.data()['assetCode'] as String?;
      if (lastCode == null || !lastCode.startsWith('AST-')) {
        return 'AST-001';
      }

      final lastNumber = int.tryParse(lastCode.split('-').last) ?? 0;
      final newNumber = lastNumber + 1;
      return 'AST-${newNumber.toString().padLeft(3, '0')}';
    } catch (e) {
      debugPrint('Error generating asset code: $e');
      return 'AST-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
  }

  // Log activity
  Future<void> _logActivity({
    required String action,
    required String performedBy,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _firestore.collection('activity_logs').add({
        'action': action,
        'performedBy': performedBy,
        'performedByName': 'System', // You can fetch actual name
        'details': details ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error logging activity: $e');
    }
  }
}
