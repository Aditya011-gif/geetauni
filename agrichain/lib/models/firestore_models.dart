import 'dart:math' as Math;
import 'package:cloud_firestore/cloud_firestore.dart';

// Enums
enum CropCategory { grains, vegetables, fruits, pulses, spices, oilseeds }

enum CropType {
  wheat,
  rice,
  potato,
  tomato,
  onion,
  maize,
  mango,
  apple,
  banana,
  cotton,
  sugarcane,
  soybean,
}

enum CertificationType { organic, fssai, agmark, iso, gmp, haccp }

enum QualityGrade { premium, grade1, grade2, standard }

enum UserType { farmer, buyer, lender, admin }

enum RatingType { quality, delivery, communication, overall, buyer, seller }

enum LoanStatus { pending, active, completed, defaulted, overdue }

enum LoanRequestStatus { open, closed, funded }

enum LoanOfferStatus { pending, accepted, rejected, expired }

enum OrderStatus { pending, confirmed, shipped, delivered, cancelled }

enum BiddingType { fixedPrice, auction }

enum AuctionStatus { active, ended, cancelled }

// Firestore-compatible User model
class FirestoreUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserType userType;
  final String? location;
  final String? walletAddress;
  final double walletBalance;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final Map<String, dynamic> metadata;
  final String? signatureUrl;

  FirestoreUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.userType,
    this.location,
    this.walletAddress,
    this.walletBalance = 0.0,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.metadata = const {},
    this.signatureUrl,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType.name,
      'location': location,
      'walletAddress': walletAddress,
      'walletBalance': walletBalance,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'metadata': metadata,
      'signatureUrl': signatureUrl,
    };
  }

  factory FirestoreUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirestoreUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      userType: UserType.values.firstWhere(
        (e) => e.name == data['userType'],
        orElse: () => UserType.farmer,
      ),
      location: data['location'],
      walletAddress: data['walletAddress'],
      walletBalance: (data['walletBalance'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      signatureUrl: data['signatureUrl'],
    );
  }

  FirestoreUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserType? userType,
    String? location,
    String? walletAddress,
    double? walletBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
    String? signatureUrl,
  }) {
    return FirestoreUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      location: location ?? this.location,
      walletAddress: walletAddress ?? this.walletAddress,
      walletBalance: walletBalance ?? this.walletBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      signatureUrl: signatureUrl ?? this.signatureUrl,
    );
  }
}

// Firestore-compatible Crop model
class FirestoreCrop {
  final String id;
  final String name;
  final String farmerId;
  final String farmerName;
  final String location;
  final double price;
  final String quantity;
  final DateTime harvestDate;
  final String imageUrl;
  final String description;
  final bool isNFT;
  final String? nftTokenId;
  final BiddingType biddingType;
  final String? auctionId;
  final DateTime? auctionEndTime;
  final double? startingBid;
  final double? reservePrice;
  final CropType? cropType;
  final CropCategory? category;
  final List<Map<String, dynamic>> certifications;
  final QualityGrade qualityGrade;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  FirestoreCrop({
    required this.id,
    required this.name,
    required this.farmerId,
    required this.farmerName,
    required this.location,
    required this.price,
    required this.quantity,
    required this.harvestDate,
    required this.imageUrl,
    required this.description,
    this.isNFT = false,
    this.nftTokenId,
    this.biddingType = BiddingType.fixedPrice,
    this.auctionId,
    this.auctionEndTime,
    this.startingBid,
    this.reservePrice,
    this.cropType,
    this.category,
    this.certifications = const [],
    this.qualityGrade = QualityGrade.standard,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'location': location,
      'price': price,
      'quantity': quantity,
      'harvestDate': Timestamp.fromDate(harvestDate),
      'imageUrl': imageUrl,
      'description': description,
      'isNFT': isNFT,
      'nftTokenId': nftTokenId,
      'biddingType': biddingType.name,
      'auctionId': auctionId,
      'auctionEndTime': auctionEndTime != null
          ? Timestamp.fromDate(auctionEndTime!)
          : null,
      'startingBid': startingBid,
      'reservePrice': reservePrice,
      'cropType': cropType?.name,
      'category': category?.name,
      'certifications': certifications,
      'qualityGrade': qualityGrade.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
    };
  }

  factory FirestoreCrop.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirestoreCrop(
      id: doc.id,
      name: data['name'] ?? '',
      farmerId: data['farmerId'] ?? '',
      farmerName: data['farmerName'] ?? '',
      location: data['location'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      quantity: data['quantity'] ?? '',
      harvestDate: (data['harvestDate'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      isNFT: data['isNFT'] ?? false,
      nftTokenId: data['nftTokenId'],
      biddingType: BiddingType.values.firstWhere(
        (e) => e.name == data['biddingType'],
        orElse: () => BiddingType.fixedPrice,
      ),
      auctionId: data['auctionId'],
      auctionEndTime: data['auctionEndTime'] != null
          ? (data['auctionEndTime'] as Timestamp).toDate()
          : null,
      startingBid: data['startingBid']?.toDouble(),
      reservePrice: data['reservePrice']?.toDouble(),
      cropType: data['cropType'] != null
          ? CropType.values.firstWhere(
              (e) => e.name == data['cropType'],
              orElse: () => CropType.wheat,
            )
          : null,
      category: data['category'] != null
          ? CropCategory.values.firstWhere(
              (e) => e.name == data['category'],
              orElse: () => CropCategory.grains,
            )
          : null,
      certifications: List<Map<String, dynamic>>.from(
        data['certifications'] ?? [],
      ),
      qualityGrade: QualityGrade.values.firstWhere(
        (e) => e.name == data['qualityGrade'],
        orElse: () => QualityGrade.standard,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
    );
  }

  bool get isAuction => biddingType == BiddingType.auction;

  bool get isAuctionActive {
    if (!isAuction || auctionEndTime == null) return false;
    return DateTime.now().isBefore(auctionEndTime!);
  }
}

// Firestore-compatible Loan model
class FirestoreLoan {
  final String id;
  final String borrowerId;
  final String borrowerName;
  final double amount;
  final String collateralNFT;
  final double interestRate;
  final int duration;
  final LoanStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  FirestoreLoan({
    required this.id,
    required this.borrowerId,
    required this.borrowerName,
    required this.amount,
    required this.collateralNFT,
    required this.interestRate,
    required this.duration,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'borrowerId': borrowerId,
      'borrowerName': borrowerName,
      'amount': amount,
      'collateralNFT': collateralNFT,
      'interestRate': interestRate,
      'duration': duration,
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'metadata': metadata,
    };
  }

  factory FirestoreLoan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirestoreLoan(
      id: doc.id,
      borrowerId: data['borrowerId'] ?? '',
      borrowerName: data['borrowerName'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      collateralNFT: data['collateralNFT'] ?? '',
      interestRate: (data['interestRate'] ?? 0.0).toDouble(),
      duration: data['duration'] ?? 0,
      status: LoanStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => LoanStatus.pending,
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  double calculateMonthlyPayment() {
    final monthlyRate = interestRate / 100 / 12;
    final numPayments = duration;
    return amount *
        (monthlyRate * Math.pow(1 + monthlyRate, numPayments)) /
        (Math.pow(1 + monthlyRate, numPayments) - 1);
  }
}

// Firestore-compatible Order model
class FirestoreOrder {
  final String id;
  final String cropId;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final String quantity;
  final double totalAmount;
  final OrderStatus status;
  final DateTime orderDate;
  final DateTime? expectedDelivery;
  final DateTime? actualDelivery;
  final bool buyerRated;
  final bool sellerRated;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  FirestoreOrder({
    required this.id,
    required this.cropId,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.quantity,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    this.expectedDelivery,
    this.actualDelivery,
    this.buyerRated = false,
    this.sellerRated = false,
    required this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'cropId': cropId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'quantity': quantity,
      'totalAmount': totalAmount,
      'status': status.name,
      'orderDate': Timestamp.fromDate(orderDate),
      'expectedDelivery': expectedDelivery != null
          ? Timestamp.fromDate(expectedDelivery!)
          : null,
      'actualDelivery': actualDelivery != null
          ? Timestamp.fromDate(actualDelivery!)
          : null,
      'buyerRated': buyerRated,
      'sellerRated': sellerRated,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'metadata': metadata,
    };
  }

  factory FirestoreOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirestoreOrder(
      id: doc.id,
      cropId: data['cropId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      quantity: data['quantity'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      orderDate: (data['orderDate'] as Timestamp).toDate(),
      expectedDelivery: data['expectedDelivery'] != null
          ? (data['expectedDelivery'] as Timestamp).toDate()
          : null,
      actualDelivery: data['actualDelivery'] != null
          ? (data['actualDelivery'] as Timestamp).toDate()
          : null,
      buyerRated: data['buyerRated'] ?? false,
      sellerRated: data['sellerRated'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
}

// Firestore-compatible Auction model
class FirestoreAuction {
  final String id;
  final String cropId;
  final String sellerId;
  final String sellerName;
  final double startingPrice;
  final double? reservePrice;
  final DateTime startTime;
  final DateTime endTime;
  final AuctionStatus status;
  final List<Map<String, dynamic>> bids;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  FirestoreAuction({
    required this.id,
    required this.cropId,
    required this.sellerId,
    required this.sellerName,
    required this.startingPrice,
    this.reservePrice,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.bids = const [],
    required this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'cropId': cropId,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'startingPrice': startingPrice,
      'reservePrice': reservePrice,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status.name,
      'bids': bids,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'metadata': metadata,
    };
  }

  factory FirestoreAuction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirestoreAuction(
      id: doc.id,
      cropId: data['cropId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      startingPrice: (data['startingPrice'] ?? 0.0).toDouble(),
      reservePrice: data['reservePrice']?.toDouble(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      status: AuctionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AuctionStatus.active,
      ),
      bids: List<Map<String, dynamic>>.from(data['bids'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  double get currentHighestBid {
    if (bids.isEmpty) return startingPrice;
    return bids
        .map((bid) => (bid['amount'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
  }

  bool get isActive =>
      status == AuctionStatus.active && DateTime.now().isBefore(endTime);
}

// Security Log model for Firestore
class FirestoreSecurityLog {
  final String id;
  final String userId;
  final String event;
  final String ipAddress;
  final String userAgent;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  FirestoreSecurityLog({
    required this.id,
    required this.userId,
    required this.event,
    required this.ipAddress,
    required this.userAgent,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'event': event,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  factory FirestoreSecurityLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirestoreSecurityLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      event: data['event'] ?? '',
      ipAddress: data['ipAddress'] ?? '',
      userAgent: data['userAgent'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
}

// Session model for Firestore
class FirestoreSession {
  final String id;
  final String userId;
  final String token;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;
  final String? deviceInfo;
  final String? ipAddress;

  FirestoreSession({
    required this.id,
    required this.userId,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    this.isActive = true,
    this.deviceInfo,
    this.ipAddress,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'token': token,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isActive': isActive,
      'deviceInfo': deviceInfo,
      'ipAddress': ipAddress,
    };
  }

  factory FirestoreSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirestoreSession(
      id: doc.id,
      userId: data['userId'] ?? '',
      token: data['token'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      deviceInfo: data['deviceInfo'],
      ipAddress: data['ipAddress'],
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

// Firestore-compatible Rating model
class Rating {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final double rating;
  final String? review;
  final RatingType? ratingType;
  final String? orderId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  Rating({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.rating,
    this.review,
    this.ratingType,
    this.orderId,
    required this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'rating': rating,
      'review': review,
      'ratingType': ratingType?.name,
      'orderId': orderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'metadata': metadata,
    };
  }

  factory Rating.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Rating(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? '',
      toUserId: data['toUserId'] ?? '',
      toUserName: data['toUserName'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      review: data['review'],
      ratingType: data['ratingType'] != null
          ? RatingType.values.firstWhere(
              (e) => e.name == data['ratingType'],
              orElse: () => RatingType.overall,
            )
          : null,
      orderId: data['orderId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
}

// User Rating Statistics model
class UserRatingStats {
  final String userId;
  final double averageRating;
  final int totalRatings;
  final Map<RatingType, double> ratingsByType;
  final Map<RatingType, int> countsByType;
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;
  final DateTime lastUpdated;

  UserRatingStats({
    required this.userId,
    required this.averageRating,
    required this.totalRatings,
    required this.ratingsByType,
    required this.countsByType,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
    required this.lastUpdated,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'ratingsByType': ratingsByType.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'countsByType': countsByType.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'fiveStarCount': fiveStarCount,
      'fourStarCount': fourStarCount,
      'threeStarCount': threeStarCount,
      'twoStarCount': twoStarCount,
      'oneStarCount': oneStarCount,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory UserRatingStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserRatingStats(
      userId: doc.id,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      ratingsByType: Map<RatingType, double>.fromEntries(
        (data['ratingsByType'] as Map<String, dynamic>? ?? {}).entries.map(
          (entry) => MapEntry(
            RatingType.values.firstWhere((e) => e.name == entry.key),
            (entry.value as num).toDouble(),
          ),
        ),
      ),
      countsByType: Map<RatingType, int>.fromEntries(
        (data['countsByType'] as Map<String, dynamic>? ?? {}).entries.map(
          (entry) => MapEntry(
            RatingType.values.firstWhere((e) => e.name == entry.key),
            entry.value as int,
          ),
        ),
      ),
      fiveStarCount: data['fiveStarCount'] ?? 0,
      fourStarCount: data['fourStarCount'] ?? 0,
      threeStarCount: data['threeStarCount'] ?? 0,
      twoStarCount: data['twoStarCount'] ?? 0,
      oneStarCount: data['oneStarCount'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  factory UserRatingStats.empty(String userId) {
    return UserRatingStats(
      userId: userId,
      averageRating: 0.0,
      totalRatings: 0,
      ratingsByType: {},
      countsByType: {},
      fiveStarCount: 0,
      fourStarCount: 0,
      threeStarCount: 0,
      twoStarCount: 0,
      oneStarCount: 0,
      lastUpdated: DateTime.now(),
    );
  }
}
