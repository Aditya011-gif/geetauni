import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Collection names
  static const String _usersCollection = 'users';
  static const String _profilesCollection = 'profiles';
  static const String _sessionsCollection = 'sessions';
  static const String _cropsCollection = 'crops';
  static const String _ordersCollection = 'orders';
  static const String _transactionsCollection = 'transactions';
  static const String _loanRequestsCollection = 'loan_requests';
  static const String _loanOffersCollection = 'loan_offers';

  /// Create user in Firebase Auth and Firestore
  Future<Map<String, dynamic>> createFirebaseUser({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create Firebase user');
      }

      // Prepare user data for Firestore (exclude sensitive data)
      final firestoreUserData = {
        'id': userData['id'],
        'firebaseUid': firebaseUser.uid,
        'firstName': userData['firstName'],
        'lastName': userData['lastName'],
        'email': userData['email'],
        'phone': userData['phone'],
        'userType': userData['userType'],
        'isEmailVerified': userData['isEmailVerified'],
        'isPhoneVerified': userData['isPhoneVerified'],
        'isKycVerified': userData['isKycVerified'],
        'isActive': userData['isActive'],
        'createdAt': userData['createdAt'],
        'updatedAt': userData['updatedAt'],
      };

      // Store user data in Firestore
      debugPrint(
        '📝 Attempting to write to Firestore collection: $_usersCollection',
      );
      debugPrint('📝 Document ID: ${userData['id']}');
      debugPrint('📝 Data to write: ${firestoreUserData.toString()}');

      await _firestore
          .collection(_usersCollection)
          .doc(userData['id'])
          .set(firestoreUserData);

      debugPrint('✅ Successfully wrote user data to Firestore');

      // Ensure user stays signed in
      debugPrint('🔐 User is now signed in with UID: ${firebaseUser.uid}');

      return {
        'success': true,
        'firebaseUid': firebaseUser.uid,
        'message': 'User created successfully in Firebase',
      };
    } catch (e) {
      debugPrint('Firebase user creation error: $e');
      return {
        'success': false,
        'message': 'Failed to create user in Firebase: $e',
      };
    }
  }

  /// Sync user data to Firestore
  Future<bool> syncUserData(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      // Prepare user data for Firestore (exclude sensitive data)
      final firestoreUserData = {
        'id': userData['id'],
        'firstName': userData['firstName'],
        'lastName': userData['lastName'],
        'email': userData['email'],
        'phone': userData['phone'],
        'userType': userData['userType'],
        'isEmailVerified': userData['isEmailVerified'],
        'isPhoneVerified': userData['isPhoneVerified'],
        'isKycVerified': userData['isKycVerified'],
        'isActive': userData['isActive'],
        'createdAt': userData['createdAt'],
        'updatedAt': userData['updatedAt'],
        'lastSyncedAt': DateTime.now().toIso8601String(),
      };

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .set(firestoreUserData, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('Firebase user sync error: $e');
      return false;
    }
  }

  /// Sign in user with email and password
  Future<bool> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('🔐 User signed in successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase sign in error: $e');
      return false;
    }
  }

  /// Create profile data in Firestore
  Future<bool> createProfileData({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      // Check if user is authenticated
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No authenticated user found for profile creation');
        return false;
      }

      debugPrint('🔐 Authenticated user: ${currentUser.uid}');

      final firestoreProfileData = {
        'userId': userId,
        'firebaseUid': currentUser.uid,
        'profileData': profileData,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      debugPrint(
        '📝 Attempting to write profile to Firestore collection: $_profilesCollection',
      );
      debugPrint('📝 Profile document ID: $userId');
      debugPrint(
        '📝 Profile data to write: ${firestoreProfileData.toString()}',
      );

      await _firestore
          .collection(_profilesCollection)
          .doc(userId)
          .set(firestoreProfileData);

      debugPrint('✅ Successfully wrote profile data to Firestore');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase profile creation error: $e');
      return false;
    }
  }

  /// Update profile data in Firestore
  Future<bool> updateProfileData({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      await _firestore.collection(_profilesCollection).doc(userId).update({
        'profileData': profileData,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Firebase profile update error: $e');
      return false;
    }
  }

  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Firebase get user error: $e');
      return null;
    }
  }

  /// Get profile data from Firestore
  Future<Map<String, dynamic>?> getProfileData(String userId) async {
    try {
      final doc = await _firestore
          .collection(_profilesCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Firebase get profile error: $e');
      return null;
    }
  }

  /// Sign in user with Firebase Auth
  Future<Map<String, dynamic>> signInWithFirebase({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to sign in with Firebase');
      }

      return {
        'success': true,
        'firebaseUid': firebaseUser.uid,
        'email': firebaseUser.email,
        'message': 'Signed in successfully',
      };
    } catch (e) {
      debugPrint('Firebase sign in error: $e');
      return {'success': false, 'message': 'Failed to sign in: $e'};
    }
  }

  /// Sign out from Firebase Auth
  Future<bool> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return true;
    } catch (e) {
      debugPrint('Firebase sign out error: $e');
      return false;
    }
  }

  /// Get current Firebase user
  User? getCurrentFirebaseUser() {
    return _firebaseAuth.currentUser;
  }

  /// Check if user is signed in to Firebase
  bool isSignedIn() {
    return _firebaseAuth.currentUser != null;
  }

  /// Listen to authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Delete user data from Firestore
  Future<bool> deleteUserData(String userId) async {
    try {
      // Delete user document
      await _firestore.collection(_usersCollection).doc(userId).delete();

      // Delete profile document
      await _firestore.collection(_profilesCollection).doc(userId).delete();

      return true;
    } catch (e) {
      debugPrint('Firebase delete user error: $e');
      return false;
    }
  }

  /// Batch sync multiple users (for data migration)
  Future<bool> batchSyncUsers(List<Map<String, dynamic>> users) async {
    try {
      final batch = _firestore.batch();

      for (final userData in users) {
        final userRef = _firestore
            .collection(_usersCollection)
            .doc(userData['id']);

        // Prepare user data for Firestore (exclude sensitive data)
        final firestoreUserData = {
          'id': userData['id'],
          'firstName': userData['firstName'],
          'lastName': userData['lastName'],
          'email': userData['email'],
          'phone': userData['phone'],
          'userType': userData['userType'],
          'isEmailVerified': userData['isEmailVerified'],
          'isPhoneVerified': userData['isPhoneVerified'],
          'isKycVerified': userData['isKycVerified'],
          'isActive': userData['isActive'],
          'createdAt': userData['createdAt'],
          'updatedAt': userData['updatedAt'],
          'lastSyncedAt': DateTime.now().toIso8601String(),
        };

        batch.set(userRef, firestoreUserData, SetOptions(merge: true));
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Firebase batch sync error: $e');
      return false;
    }
  }

  // ==================== MARKETPLACE METHODS ====================

  /// Create crop listing in Firestore
  Future<bool> createCropListing({
    required String cropId,
    required Map<String, dynamic> cropData,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No authenticated user for crop listing');
        return false;
      }

      final firestoreCropData = {
        ...cropData,
        'firebaseUid': currentUser.uid,
        'isAvailable': true,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_cropsCollection)
          .doc(cropId)
          .set(firestoreCropData);

      debugPrint('✅ Crop listing created in Firebase: $cropId');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase crop creation error: $e');
      return false;
    }
  }

  /// Get all available crops from Firestore
  Future<List<Map<String, dynamic>>> getAllCrops() async {
    try {
      final querySnapshot = await _firestore
          .collection(_cropsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final crops = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Sort by createdAt in memory to avoid composite index requirement
      crops.sort((a, b) {
        final aCreatedAt = a['createdAt'];
        final bCreatedAt = b['createdAt'];

        if (aCreatedAt == null && bCreatedAt == null) return 0;
        if (aCreatedAt == null) return 1;
        if (bCreatedAt == null) return -1;

        DateTime aDate, bDate;
        if (aCreatedAt is Timestamp) {
          aDate = aCreatedAt.toDate();
        } else if (aCreatedAt is String) {
          aDate = DateTime.parse(aCreatedAt);
        } else {
          return 0;
        }

        if (bCreatedAt is Timestamp) {
          bDate = bCreatedAt.toDate();
        } else if (bCreatedAt is String) {
          bDate = DateTime.parse(bCreatedAt);
        } else {
          return 0;
        }

        return bDate.compareTo(aDate); // Descending order
      });

      return crops;
    } catch (e) {
      debugPrint('❌ Firebase get crops error: $e');
      return [];
    }
  }

  /// Get crops by farmer
  Future<List<Map<String, dynamic>>> getCropsByFarmer(String farmerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_cropsCollection)
          .where('farmerId', isEqualTo: farmerId)
          .get();

      final crops = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Sort by createdAt in memory to avoid composite index requirement
      crops.sort((a, b) {
        final aCreatedAt = a['createdAt'];
        final bCreatedAt = b['createdAt'];

        if (aCreatedAt == null && bCreatedAt == null) return 0;
        if (aCreatedAt == null) return 1;
        if (bCreatedAt == null) return -1;

        DateTime aDate, bDate;
        if (aCreatedAt is Timestamp) {
          aDate = aCreatedAt.toDate();
        } else if (aCreatedAt is String) {
          aDate = DateTime.parse(aCreatedAt);
        } else {
          return 0;
        }

        if (bCreatedAt is Timestamp) {
          bDate = bCreatedAt.toDate();
        } else if (bCreatedAt is String) {
          bDate = DateTime.parse(bCreatedAt);
        } else {
          return 0;
        }

        return bDate.compareTo(aDate); // Descending order
      });

      return crops;
    } catch (e) {
      debugPrint('❌ Firebase get farmer crops error: $e');
      return [];
    }
  }

  /// Update crop availability
  Future<bool> updateCropAvailability(String cropId, bool isAvailable) async {
    try {
      await _firestore.collection(_cropsCollection).doc(cropId).update({
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('❌ Firebase crop update error: $e');
      return false;
    }
  }

  /// Create order in Firestore
  Future<bool> createOrder({
    required String orderId,
    required Map<String, dynamic> orderData,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No authenticated user for order creation');
        return false;
      }

      final firestoreOrderData = {
        ...orderData,
        'buyerFirebaseUid': currentUser.uid,
        'sellerFirebaseUid': orderData['sellerFirebaseUid'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .set(firestoreOrderData);

      debugPrint('✅ Order created in Firebase: $orderId');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase order creation error: $e');
      return false;
    }
  }

  /// Get orders by user
  Future<List<Map<String, dynamic>>> getOrdersByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_ordersCollection)
          .where('buyerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('❌ Firebase get user orders error: $e');
      return [];
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('❌ Firebase order status update error: $e');
      return false;
    }
  }

  /// Search crops by name or category
  Future<List<Map<String, dynamic>>> searchCrops(String searchQuery) async {
    try {
      final querySnapshot = await _firestore
          .collection(_cropsCollection)
          .where('isAvailable', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      // Filter results locally for better search functionality
      final results = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((crop) {
            final name = (crop['name'] as String? ?? '').toLowerCase();
            final category = (crop['category'] as String? ?? '').toLowerCase();
            final farmer = (crop['farmerName'] as String? ?? '').toLowerCase();
            final query = searchQuery.toLowerCase();

            return name.contains(query) ||
                category.contains(query) ||
                farmer.contains(query);
          })
          .toList();

      return results;
    } catch (e) {
      debugPrint('❌ Firebase search crops error: $e');
      return [];
    }
  }

  /// Get real-time crops stream
  Stream<List<Map<String, dynamic>>> getCropsStream() {
    return _firestore
        .collection(_cropsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  /// Get real-time orders stream for a user
  Stream<List<Map<String, dynamic>>> getOrdersStream(String userId) {
    return _firestore
        .collection(_ordersCollection)
        .where('buyerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  // ==================== LOAN METHODS ====================

  /// Create a loan request
  Future<bool> createLoanRequest({
    required String requestId,
    required Map<String, dynamic> loanData,
  }) async {
    try {
      await _firestore.collection(_loanRequestsCollection).doc(requestId).set({
        ...loanData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      debugPrint('✅ Loan request created in Firebase: $requestId');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase loan request creation error: $e');
      return false;
    }
  }

  /// Get all active loan requests
  Future<List<Map<String, dynamic>>> getAllLoanRequests() async {
    try {
      final querySnapshot = await _firestore
          .collection(_loanRequestsCollection)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('❌ Firebase get loan requests error: $e');
      return [];
    }
  }

  /// Get loan requests for a specific farmer
  Future<List<Map<String, dynamic>>> getFarmerLoanRequests(
    String farmerId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_loanRequestsCollection)
          .where('farmerId', isEqualTo: farmerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('❌ Firebase get farmer loan requests error: $e');
      return [];
    }
  }

  /// Create a loan offer
  Future<bool> createLoanOffer({
    required String offerId,
    required Map<String, dynamic> offerData,
  }) async {
    try {
      await _firestore.collection(_loanOffersCollection).doc(offerId).set({
        ...offerData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      debugPrint('✅ Loan offer created in Firebase: $offerId');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase loan offer creation error: $e');
      return false;
    }
  }

  /// Get loan offers for a specific farmer
  Future<List<Map<String, dynamic>>> getFarmerLoanOffers(
    String farmerId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_loanOffersCollection)
          .where('farmerId', isEqualTo: farmerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('❌ Firebase get farmer loan offers error: $e');
      return [];
    }
  }

  /// Get loan offers made by a specific buyer
  Future<List<Map<String, dynamic>>> getBuyerLoanOffers(String buyerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_loanOffersCollection)
          .where('buyerId', isEqualTo: buyerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('❌ Firebase get buyer loan offers error: $e');
      return [];
    }
  }

  /// Update loan offer status
  Future<bool> updateLoanOfferStatus(String offerId, String status) async {
    try {
      await _firestore.collection(_loanOffersCollection).doc(offerId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Loan offer status updated: $offerId -> $status');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase loan offer status update error: $e');
      return false;
    }
  }

  /// Get real-time loan requests stream for a farmer
  Stream<List<Map<String, dynamic>>> getLoanRequestsStream(String farmerId) {
    return _firestore
        .collection(_loanRequestsCollection)
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  /// Get real-time loan offers stream for a farmer
  Stream<List<Map<String, dynamic>>> getLoanOffersStream(String farmerId) {
    return _firestore
        .collection(_loanOffersCollection)
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  /// Get real-time active loan requests stream (for buyers)
  Stream<List<Map<String, dynamic>>> getActiveLoanRequestsStream() {
    return _firestore
        .collection(_loanRequestsCollection)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  // ==================== TRANSACTION METHODS ====================

  /// Create a transaction record
  Future<bool> createTransaction({
    required String transactionId,
    required Map<String, dynamic> transactionData,
  }) async {
    try {
      await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .set({
            ...transactionData,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      debugPrint('✅ Transaction created: $transactionId');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase create transaction error: $e');
      return false;
    }
  }

  /// Get user transactions
  Future<List<Map<String, dynamic>>> getUserTransactions(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_transactionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('❌ Firebase get user transactions error: $e');
      return [];
    }
  }

  /// Get transaction by ID
  Future<Map<String, dynamic>?> getTransaction(String transactionId) async {
    try {
      final doc = await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .get();

      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      debugPrint('❌ Firebase get transaction error: $e');
      return null;
    }
  }

  /// Update transaction status
  Future<bool> updateTransactionStatus(
    String transactionId,
    String status,
  ) async {
    try {
      await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      debugPrint('✅ Transaction status updated: $transactionId -> $status');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase transaction status update error: $e');
      return false;
    }
  }

  /// Get real-time transactions stream for a user
  Stream<List<Map<String, dynamic>>> getTransactionsStream(String userId) {
    return _firestore
        .collection(_transactionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  /// Get transactions by type (purchase, sale, loan, etc.)
  Future<List<Map<String, dynamic>>> getTransactionsByType(
    String userId,
    String type,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_transactionsCollection)
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('❌ Firebase get transactions by type error: $e');
      return [];
    }
  }

  /// Get transaction analytics for a user
  Future<Map<String, dynamic>> getTransactionAnalytics(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_transactionsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final transactions = querySnapshot.docs.map((doc) => doc.data()).toList();

      double totalSpent = 0;
      double totalEarned = 0;
      int totalTransactions = transactions.length;
      Map<String, int> typeBreakdown = {};

      for (final transaction in transactions) {
        final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
        final type = transaction['type'] as String? ?? 'unknown';

        if (transaction['isDebit'] == true) {
          totalSpent += amount;
        } else {
          totalEarned += amount;
        }

        typeBreakdown[type] = (typeBreakdown[type] ?? 0) + 1;
      }

      return {
        'totalTransactions': totalTransactions,
        'totalSpent': totalSpent,
        'totalEarned': totalEarned,
        'netAmount': totalEarned - totalSpent,
        'typeBreakdown': typeBreakdown,
      };
    } catch (e) {
      debugPrint('❌ Firebase get transaction analytics error: $e');
      return {
        'totalTransactions': 0,
        'totalSpent': 0.0,
        'totalEarned': 0.0,
        'netAmount': 0.0,
        'typeBreakdown': <String, int>{},
      };
    }
  }

  /// Update user wallet balance
  Future<bool> updateWalletBalance(String userId, double newBalance) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'walletBalance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Wallet balance updated for user: $userId -> ₹$newBalance');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase wallet balance update error: $e');
      return false;
    }
  }

  /// Get user wallet balance
  Future<double> getWalletBalance(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return (data['walletBalance'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      debugPrint('❌ Firebase get wallet balance error: $e');
      return 0.0;
    }
  }

  // ==================== GENERIC DOCUMENT METHODS ====================

  /// Create a document in any collection
  Future<bool> createDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      final documentData = {
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(collection).doc(documentId).set(documentData);

      debugPrint('✅ Document created in $collection: $documentId');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase document creation error in $collection: $e');
      return false;
    }
  }

  /// Update a document in any collection
  Future<bool> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final updateData = {
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(collection)
          .doc(documentId)
          .update(updateData);

      debugPrint('✅ Document updated in $collection: $documentId');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase document update error in $collection: $e');
      return false;
    }
  }

  /// Get a document from any collection
  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String documentId,
  ) async {
    try {
      final doc = await _firestore.collection(collection).doc(documentId).get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Firebase get document error in $collection: $e');
      return null;
    }
  }

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getCollection(
    String collection, {
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ Firebase get collection error for $collection: $e');
      return [];
    }
  }
}
