import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Service to upload, store, and retrieve contract PDFs from Firebase.
class ContractStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload a contract PDF to Firebase Storage and save metadata to Firestore.
  static Future<String?> uploadContract({
    required Uint8List pdfBytes,
    required String orderId,
    required String contractType,
    required String buyerName,
    required String sellerName,
    required String cropName,
    required double totalAmount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user for contract upload');
        return null;
      }

      final fileName = '${contractType}_$orderId.pdf';
      final storagePath = 'contracts/${user.uid}/$fileName';

      // Upload PDF to Firebase Storage
      final ref = _storage.ref().child(storagePath);
      final metadata = SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'orderId': orderId,
          'contractType': contractType,
          'uploadedBy': user.uid,
        },
      );

      await ref.putData(pdfBytes, metadata);
      final downloadUrl = await ref.getDownloadURL();

      // Save contract metadata to Firestore
      await _firestore.collection('contracts').add({
        'orderId': orderId,
        'contractType': contractType,
        'fileName': fileName,
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'fileSize': pdfBytes.length,
        'buyerName': buyerName,
        'sellerName': sellerName,
        'cropName': cropName,
        'totalAmount': totalAmount,
        'userFirebaseUid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Contract uploaded: $storagePath');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading contract: $e');
      return null;
    }
  }

  /// Get all contracts for the current user.
  static Future<List<ContractDocument>> getUserContracts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('contracts')
          .where('userFirebaseUid', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ContractDocument(
          id: doc.id,
          orderId: data['orderId'] ?? '',
          contractType: data['contractType'] ?? 'purchase',
          fileName: data['fileName'] ?? '',
          storagePath: data['storagePath'] ?? '',
          downloadUrl: data['downloadUrl'] ?? '',
          fileSize: data['fileSize'] ?? 0,
          buyerName: data['buyerName'] ?? '',
          sellerName: data['sellerName'] ?? '',
          cropName: data['cropName'] ?? '',
          totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
          createdAt: data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching contracts: $e');
      return [];
    }
  }

  /// Download contract bytes from Firebase Storage.
  static Future<Uint8List?> downloadContract(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      final data = await ref.getData();
      return data;
    } catch (e) {
      debugPrint('❌ Error downloading contract: $e');
      return null;
    }
  }
}

/// Model for a stored contract document.
class ContractDocument {
  final String id;
  final String orderId;
  final String contractType;
  final String fileName;
  final String storagePath;
  final String downloadUrl;
  final int fileSize;
  final String buyerName;
  final String sellerName;
  final String cropName;
  final double totalAmount;
  final DateTime createdAt;

  ContractDocument({
    required this.id,
    required this.orderId,
    required this.contractType,
    required this.fileName,
    required this.storagePath,
    required this.downloadUrl,
    required this.fileSize,
    required this.buyerName,
    required this.sellerName,
    required this.cropName,
    required this.totalAmount,
    required this.createdAt,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get displayName {
    switch (contractType) {
      case 'purchase':
        return 'Purchase Contract';
      case 'loan':
        return 'Loan Agreement';
      default:
        return 'Contract';
    }
  }
}
