# AgriChain - Technical Design Document

## Architecture Overview

AgriChain follows a hybrid architecture combining traditional mobile app development with blockchain technology, creating a decentralized agricultural marketplace with DeFi capabilities.

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Client Applications                          │
├─────────────────┬─────────────────┬─────────────────────────────┤
│   Flutter App   │   Web App       │   Admin Dashboard           │
│   (iOS/Android) │   (PWA)         │   (Web)                     │
└─────────────────┴─────────────────┴─────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    API Gateway Layer                           │
├─────────────────────────────────────────────────────────────────┤
│  • Authentication & Authorization                              │
│  • Rate Limiting & Throttling                                  │
│  • Request/Response Transformation                             │
│  • API Versioning                                              │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Backend Services                             │
├─────────────────┬─────────────────┬─────────────────────────────┤
│  Firebase Core  │  Custom APIs    │  Blockchain Services        │
│  • Auth         │  • Marketplace  │  • Smart Contracts          │
│  • Firestore    │  • Loan Engine  │  • NFT Management           │
│  • Storage      │  • Analytics    │  • Wallet Integration       │
│  • Functions    │  • Notifications│  • IPFS Storage             │
└─────────────────┴─────────────────┴─────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                 External Integrations                          │
├─────────────────┬─────────────────┬─────────────────────────────┤
│  Payment        │  Identity       │  Blockchain                 │
│  • Razorpay     │  • DigiLocker   │  • Polygon Network          │
│  • Crypto       │  • Aadhaar API  │  • Infura RPC               │
│  • Escrow       │  • PAN API      │  • IPFS Network             │
└─────────────────┴─────────────────┴─────────────────────────────┘
```

## System Components

### 1. Frontend Architecture

#### 1.1 Flutter Application Structure

```
lib/
├── main.dart                    # Application entry point
├── config/                      # Configuration management
│   ├── app_config.dart         # Environment-specific configs
│   ├── app_initializer.dart    # App initialization logic
│   └── environment_config.dart # Environment variables
├── models/                      # Data models
│   ├── firestore_models.dart   # Firestore entity models
│   ├── crop_nft.dart          # NFT-specific models
│   └── land_nft.dart          # Land NFT models
├── services/                    # Business logic services
│   ├── auth_service.dart       # Authentication service
│   ├── blockchain_service.dart # Blockchain interactions
│   ├── database_service.dart   # Database operations
│   ├── contract_pdf_service.dart # Document generation
│   └── payment_service.dart    # Payment processing
├── providers/                   # State management
│   └── app_state.dart          # Global application state
├── screens/                     # UI screens
│   ├── auth/                   # Authentication screens
│   ├── marketplace/            # Marketplace screens
│   ├── loans/                  # Loan management screens
│   └── profile/                # User profile screens
├── widgets/                     # Reusable UI components
│   ├── crop_card.dart          # Crop display component
│   ├── rating_widgets.dart     # Rating components
│   └── payment_widgets.dart    # Payment UI components
└── theme/                       # UI theming
    └── app_theme.dart          # Application theme
```

#### 1.2 State Management Architecture

**Provider Pattern Implementation:**
- **AppState**: Global application state management
- **AuthState**: User authentication and session management
- **MarketplaceState**: Crop listings and marketplace data
- **LoanState**: Loan requests and offers management
- **WalletState**: Wallet balance and transaction history

### 2. Backend Architecture

#### 2.1 Firebase Services Integration

**Firebase Authentication:**
- Email/password authentication
- Phone number verification
- Custom token generation for blockchain wallet integration
- Session management with refresh tokens

**Cloud Firestore Database Structure:**
```
/users/{userId}
  - profile data
  - verification status
  - wallet information
  
/crops/{cropId}
  - crop details
  - farmer information
  - pricing and availability
  
/nfts/{nftId}
  - NFT metadata
  - ownership history
  - collateral status
  
/loans/{loanId}
  - loan terms
  - repayment schedule
  - collateral details
  
/orders/{orderId}
  - transaction details
  - delivery information
  - payment status
  
/auctions/{auctionId}
  - auction parameters
  - bid history
  - winner information
```

**Firebase Cloud Functions:**
- Payment processing webhooks
- Blockchain event listeners
- Automated loan calculations
- Notification triggers
- Data validation and sanitization

#### 2.2 Blockchain Integration Architecture

**Smart Contract Structure:**
```
contracts/
├── NFT/
│   ├── CropNFT.sol             # Crop tokenization contract
│   ├── LandNFT.sol             # Land tokenization contract
│   └── NFTMarketplace.sol      # NFT trading contract
├── DeFi/
│   ├── LoanContract.sol        # Loan management contract
│   ├── CollateralManager.sol   # Collateral handling contract
│   └── InterestCalculator.sol  # Interest calculation logic
├── Marketplace/
│   ├── CropMarketplace.sol     # Crop trading contract
│   ├── AuctionContract.sol     # Auction mechanism contract
│   └── EscrowContract.sol      # Payment escrow contract
└── Governance/
    ├── VotingContract.sol      # Platform governance
    └── ProposalContract.sol    # Feature proposals
```

**Blockchain Service Layer:**
- Web3 provider management (Infura integration)
- Smart contract interaction abstraction
- Transaction signing and broadcasting
- Event listening and processing
- Gas optimization strategies

### 3. Data Models & Schemas

#### 3.1 Core Entity Models

**User Model:**
```dart
class FirestoreUser {
  final String id;
  final String firebaseUid;
  final String name;
  final String email;
  final String? phone;
  final UserType userType;
  final String? location;
  final String? walletAddress;
  final double walletBalance;
  final KYCStatus kycStatus;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;
}

enum UserType { farmer, buyer, lender, admin }
enum KYCStatus { pending, verified, rejected, expired }
```

**Crop Model:**
```dart
class FirestoreCrop {
  final String id;
  final String farmerId;
  final String name;
  final CropCategory category;
  final double price;
  final String quantity;
  final DateTime harvestDate;
  final String location;
  final QualityGrade qualityGrade;
  final List<Certification> certifications;
  final bool isNFT;
  final String? nftTokenId;
  final BiddingType biddingType;
  final DateTime createdAt;
}

enum CropCategory { grains, vegetables, fruits, pulses, spices, oilseeds }
enum QualityGrade { premium, grade1, grade2, standard }
enum BiddingType { fixedPrice, auction }
```

**NFT Model:**
```dart
class CropNFT {
  final String tokenId;
  final String ownerAddress;
  final CropDetails cropDetails;
  final HarvestData harvestData;
  final QualityAssurance qualityAssurance;
  final String ipfsHash;
  final bool isCollateralized;
  final String? activeLoanId;
  final List<TransferHistory> transferHistory;
}

class LandNFT {
  final String tokenId;
  final String ownerAddress;
  final LandDetails landDetails;
  final LegalDocuments legalDocuments;
  final ValuationDetails valuation;
  final String ipfsHash;
  final bool isCollateralized;
  final String? activeLoanId;
}
```

**Loan Model:**
```dart
class FirestoreLoan {
  final String id;
  final String borrowerId;
  final String lenderId;
  final double principalAmount;
  final double interestRate;
  final int termMonths;
  final LoanStatus status;
  final List<String> collateralNFTs;
  final DateTime startDate;
  final DateTime? endDate;
  final List<Payment> paymentHistory;
}

enum LoanStatus { pending, active, completed, defaulted, overdue }
```

#### 3.2 Database Schema Design

**Firestore Collections Structure:**

```yaml
users:
  - Document ID: userId
  - Fields: profile, kyc, wallet, preferences, metadata
  - Subcollections: transactions, notifications, ratings

crops:
  - Document ID: cropId
  - Fields: details, pricing, availability, farmer, location
  - Subcollections: bids, reviews, images

nfts:
  - Document ID: nftId
  - Fields: metadata, ownership, collateral_status, blockchain_data
  - Subcollections: transfer_history, valuations

loans:
  - Document ID: loanId
  - Fields: terms, parties, collateral, status, payments
  - Subcollections: payment_schedule, modifications, documents

orders:
  - Document ID: orderId
  - Fields: transaction_details, delivery, payment, status
  - Subcollections: tracking, communications, disputes

auctions:
  - Document ID: auctionId
  - Fields: parameters, status, winner, final_price
  - Subcollections: bids, participants
```

### 4. API Design

#### 4.1 RESTful API Endpoints

**Authentication Endpoints:**
```
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/logout
POST /api/v1/auth/refresh
POST /api/v1/auth/verify-email
POST /api/v1/auth/reset-password
```

**User Management Endpoints:**
```
GET    /api/v1/users/profile
PUT    /api/v1/users/profile
POST   /api/v1/users/kyc/submit
GET    /api/v1/users/kyc/status
POST   /api/v1/users/wallet/connect
GET    /api/v1/users/wallet/balance
```

**Marketplace Endpoints:**
```
GET    /api/v1/crops?category={category}&location={location}
POST   /api/v1/crops
PUT    /api/v1/crops/{cropId}
DELETE /api/v1/crops/{cropId}
POST   /api/v1/crops/{cropId}/order
GET    /api/v1/orders
GET    /api/v1/orders/{orderId}
```

**NFT Endpoints:**
```
POST   /api/v1/nfts/mint/crop
POST   /api/v1/nfts/mint/land
GET    /api/v1/nfts/owned
POST   /api/v1/nfts/{nftId}/transfer
GET    /api/v1/nfts/{nftId}/history
POST   /api/v1/nfts/{nftId}/collateralize
```

**Loan Endpoints:**
```
POST   /api/v1/loans/request
GET    /api/v1/loans/requests
POST   /api/v1/loans/{loanId}/offer
POST   /api/v1/loans/{loanId}/accept
POST   /api/v1/loans/{loanId}/payment
GET    /api/v1/loans/{loanId}/schedule
```

**Auction Endpoints:**
```
POST   /api/v1/auctions/create
GET    /api/v1/auctions/active
POST   /api/v1/auctions/{auctionId}/bid
GET    /api/v1/auctions/{auctionId}/bids
POST   /api/v1/auctions/{auctionId}/close
```

#### 4.2 WebSocket Events

**Real-time Updates:**
```
// Auction bidding
auction:bid_placed
auction:bid_updated
auction:auction_ended

// Order status
order:status_changed
order:payment_received
order:delivery_updated

// Loan updates
loan:offer_received
loan:payment_due
loan:status_changed

// Notifications
notification:new_message
notification:system_alert
```

### 5. Security Architecture

#### 5.1 Authentication & Authorization

**Multi-layered Security:**
1. **Firebase Authentication**: Primary user authentication
2. **JWT Tokens**: API access control with refresh mechanism
3. **Blockchain Signatures**: Wallet-based transaction signing
4. **2FA Integration**: SMS/Email based two-factor authentication

**Role-Based Access Control (RBAC):**
```dart
enum Permission {
  // Farmer permissions
  CREATE_CROP_LISTING,
  MINT_CROP_NFT,
  REQUEST_LOAN,
  
  // Buyer permissions
  PLACE_ORDER,
  PARTICIPATE_AUCTION,
  RATE_SELLER,
  
  // Lender permissions
  OFFER_LOAN,
  MANAGE_COLLATERAL,
  VIEW_CREDIT_REPORTS,
  
  // Admin permissions
  MANAGE_USERS,
  MODERATE_CONTENT,
  ACCESS_ANALYTICS,
  SYSTEM_CONFIGURATION
}
```

#### 5.2 Data Protection

**Encryption Strategy:**
- **At Rest**: AES-256 encryption for sensitive data in Firestore
- **In Transit**: TLS 1.3 for all API communications
- **Client-side**: Local storage encryption for sensitive app data
- **Blockchain**: Private key management with hardware security modules

**Privacy Controls:**
- GDPR compliance with data portability and deletion rights
- Selective data sharing with granular permissions
- Anonymization of analytics data
- Audit logging for all data access

### 6. Blockchain Integration Design

#### 6.1 Smart Contract Architecture

**NFT Contracts:**
```solidity
// CropNFT.sol
contract CropNFT is ERC721, Ownable {
    struct CropMetadata {
        string cropType;
        uint256 quantity;
        uint256 harvestDate;
        string location;
        string qualityGrade;
        string ipfsHash;
    }
    
    mapping(uint256 => CropMetadata) public cropData;
    mapping(uint256 => bool) public isCollateralized;
    
    function mintCropNFT(address to, CropMetadata memory metadata) external;
    function collateralize(uint256 tokenId, address loanContract) external;
    function releaseCollateral(uint256 tokenId) external;
}
```

**Loan Management Contract:**
```solidity
// LoanContract.sol
contract LoanContract is Ownable {
    struct Loan {
        address borrower;
        address lender;
        uint256 principal;
        uint256 interestRate;
        uint256 termMonths;
        uint256[] collateralTokens;
        LoanStatus status;
        uint256 startTime;
    }
    
    enum LoanStatus { Pending, Active, Completed, Defaulted }
    
    mapping(uint256 => Loan) public loans;
    
    function createLoan(LoanParams memory params) external returns (uint256);
    function acceptLoan(uint256 loanId) external payable;
    function makePayment(uint256 loanId) external payable;
    function liquidateCollateral(uint256 loanId) external;
}
```

#### 6.2 IPFS Integration

**Decentralized Storage Strategy:**
```dart
class IPFSService {
  // Upload crop images and metadata
  Future<String> uploadCropData(CropData data) async {
    final metadata = {
      'name': data.name,
      'description': data.description,
      'image': await uploadImage(data.imagePath),
      'attributes': data.attributes,
      'harvest_date': data.harvestDate.toIso8601String(),
      'quality_certificates': data.certificates,
    };
    
    return await uploadJSON(metadata);
  }
  
  // Upload legal documents for land NFTs
  Future<String> uploadLandDocuments(LandDocuments docs) async {
    final documentHashes = <String>[];
    
    for (final doc in docs.documents) {
      final hash = await uploadDocument(doc);
      documentHashes.add(hash);
    }
    
    final metadata = {
      'land_details': docs.landDetails,
      'legal_documents': documentHashes,
      'valuation': docs.valuation,
      'survey_data': docs.surveyData,
    };
    
    return await uploadJSON(metadata);
  }
}
```

### 7. Payment System Design

#### 7.1 Multi-Currency Support

**Payment Flow Architecture:**
```dart
abstract class PaymentProcessor {
  Future<PaymentResult> processPayment(PaymentRequest request);
  Future<RefundResult> processRefund(RefundRequest request);
  Future<PaymentStatus> getPaymentStatus(String paymentId);
}

class RazorpayProcessor implements PaymentProcessor {
  // Fiat currency payments (INR, USD)
}

class CryptoProcessor implements PaymentProcessor {
  // Cryptocurrency payments (ETH, MATIC, USDC)
}

class EscrowService {
  Future<String> createEscrow(EscrowParams params);
  Future<void> releaseEscrow(String escrowId);
  Future<void> refundEscrow(String escrowId);
}
```

#### 7.2 Transaction Management

**Payment State Machine:**
```
Initiated → Processing → Confirmed → Completed
     ↓           ↓           ↓
   Failed    Cancelled   Refunded
```

### 8. Analytics & Monitoring

#### 8.1 Business Intelligence

**Key Metrics Tracking:**
```dart
class AnalyticsService {
  // User engagement metrics
  void trackUserAction(String action, Map<String, dynamic> properties);
  
  // Transaction metrics
  void trackTransaction(TransactionData transaction);
  
  // Performance metrics
  void trackPerformance(String operation, Duration duration);
  
  // Error tracking
  void trackError(String error, Map<String, dynamic> context);
}
```

**Dashboard Metrics:**
- Daily/Monthly Active Users (DAU/MAU)
- Transaction Volume and Value
- User Acquisition and Retention
- Feature Adoption Rates
- Revenue and Commission Tracking
- Geographic Distribution
- Crop Category Performance
- Loan Default Rates

#### 8.2 System Monitoring

**Health Check Endpoints:**
```
GET /health/status          # Overall system health
GET /health/database        # Database connectivity
GET /health/blockchain      # Blockchain node status
GET /health/external-apis   # Third-party service status
```

**Alerting System:**
- High error rates (>1% in 5 minutes)
- Slow response times (>3 seconds average)
- Database connection issues
- Blockchain network problems
- Payment gateway failures
- Security incidents

### 9. Testing Strategy

#### 9.1 Property-Based Testing Framework

**Core Properties to Test:**

**User Registration Properties:**
```dart
// Property: Valid user data should always result in successful registration
Property userRegistrationProperty = Property.forAll(
  validUserDataGenerator,
  (userData) => registrationService.register(userData).isSuccess
);

// Property: Invalid email formats should always fail registration
Property emailValidationProperty = Property.forAll(
  invalidEmailGenerator,
  (email) => !registrationService.validateEmail(email)
);
```

**Crop Listing Properties:**
```dart
// Property: Crop price should always be positive
Property cropPriceProperty = Property.forAll(
  cropDataGenerator,
  (crop) => crop.price > 0
);

// Property: Harvest date should not be in the future for existing crops
Property harvestDateProperty = Property.forAll(
  existingCropGenerator,
  (crop) => crop.harvestDate.isBefore(DateTime.now())
);
```

**Auction System Properties:**
```dart
// Property: Highest bid should always win the auction
Property auctionWinnerProperty = Property.forAll(
  auctionWithBidsGenerator,
  (auction) => auction.winner.bidAmount == auction.highestBid
);

// Property: Bid amount should always be higher than previous bid
Property bidIncrementProperty = Property.forAll(
  bidSequenceGenerator,
  (bids) => bids.every((i) => i == 0 || bids[i] > bids[i-1])
);
```

**Loan Calculation Properties:**
```dart
// Property: Monthly payment calculation should be consistent
Property loanPaymentProperty = Property.forAll(
  loanParametersGenerator,
  (params) {
    final payment1 = calculateMonthlyPayment(params);
    final payment2 = calculateMonthlyPayment(params);
    return payment1 == payment2;
  }
);

// Property: Total payments should equal principal + interest
Property loanTotalProperty = Property.forAll(
  loanParametersGenerator,
  (params) {
    final monthlyPayment = calculateMonthlyPayment(params);
    final totalPaid = monthlyPayment * params.termMonths;
    final expectedTotal = params.principal * (1 + params.interestRate);
    return (totalPaid - expectedTotal).abs() < 0.01; // Allow for rounding
  }
);
```

**NFT Minting Properties:**
```dart
// Property: NFT metadata should always be valid JSON
Property nftMetadataProperty = Property.forAll(
  cropDataGenerator,
  (cropData) {
    final metadata = generateNFTMetadata(cropData);
    return isValidJSON(metadata);
  }
);

// Property: IPFS hash should be deterministic for same content
Property ipfsHashProperty = Property.forAll(
  cropDataGenerator,
  (cropData) {
    final hash1 = generateIPFSHash(cropData);
    final hash2 = generateIPFSHash(cropData);
    return hash1 == hash2;
  }
);
```

**Payment Processing Properties:**
```dart
// Property: Payment amount should never be negative
Property paymentAmountProperty = Property.forAll(
  paymentRequestGenerator,
  (request) => request.amount >= 0
);

// Property: Successful payment should update wallet balance
Property walletBalanceProperty = Property.forAll(
  paymentScenarioGenerator,
  (scenario) {
    final initialBalance = scenario.wallet.balance;
    processPayment(scenario.payment);
    final finalBalance = scenario.wallet.balance;
    return finalBalance == initialBalance + scenario.payment.amount;
  }
);
```

#### 9.2 Test Data Generators

**User Data Generator:**
```dart
Generator<UserData> validUserDataGenerator = Generator.combine([
  Generator.string(minLength: 2, maxLength: 50), // name
  Generator.email(), // email
  Generator.phoneNumber(), // phone
  Generator.oneOf(UserType.values), // userType
  Generator.string(minLength: 5, maxLength: 100), // location
]);

Generator<String> invalidEmailGenerator = Generator.oneOf([
  Generator.string(maxLength: 10), // no @ symbol
  Generator.constant("@domain.com"), // missing local part
  Generator.constant("user@"), // missing domain
]);
```

**Crop Data Generator:**
```dart
Generator<CropData> cropDataGenerator = Generator.combine([
  Generator.oneOf(CropType.values),
  Generator.oneOf(CropCategory.values),
  Generator.doubleRange(min: 1.0, max: 10000.0), // price
  Generator.intRange(min: 1, max: 10000), // quantity
  Generator.dateRange(
    start: DateTime.now().subtract(Duration(days: 365)),
    end: DateTime.now()
  ), // harvest date
  Generator.oneOf(QualityGrade.values),
]);
```

#### 9.3 Integration Testing

**API Integration Tests:**
```dart
group('Marketplace API Integration', () {
  testProperty('Crop listing and retrieval', cropDataGenerator, (cropData) async {
    // Create crop listing
    final response = await api.createCrop(cropData);
    expect(response.success, isTrue);
    
    // Retrieve crop listing
    final retrieved = await api.getCrop(response.cropId);
    expect(retrieved.name, equals(cropData.name));
    expect(retrieved.price, equals(cropData.price));
  });
});
```

**Blockchain Integration Tests:**
```dart
group('NFT Minting Integration', () {
  testProperty('Crop NFT minting', cropDataGenerator, (cropData) async {
    // Upload to IPFS
    final ipfsHash = await ipfsService.uploadCropData(cropData);
    expect(ipfsHash, isNotEmpty);
    
    // Mint NFT
    final tokenId = await nftService.mintCropNFT(cropData, ipfsHash);
    expect(tokenId, isNotEmpty);
    
    // Verify NFT ownership
    final owner = await nftService.getOwner(tokenId);
    expect(owner, equals(cropData.farmerId));
  });
});
```

### 10. Deployment Architecture

#### 10.1 Environment Configuration

**Development Environment:**
- Firebase Emulator Suite for local development
- Polygon Mumbai testnet for blockchain testing
- Local IPFS node for file storage testing
- Mock payment services for transaction testing

**Staging Environment:**
- Firebase staging project
- Polygon Mumbai testnet
- IPFS staging cluster
- Razorpay test environment

**Production Environment:**
- Firebase production project with auto-scaling
- Polygon mainnet with Infura production endpoints
- IPFS production cluster with CDN
- Razorpay production environment

#### 10.2 CI/CD Pipeline

**Build Pipeline:**
```yaml
stages:
  - test
  - build
  - deploy

test:
  script:
    - flutter test
    - flutter test integration_test/
    - npm run test:contracts

build:
  script:
    - flutter build apk --release
    - flutter build web --release
    - docker build -t agrichain-api .

deploy:
  script:
    - firebase deploy --only hosting,functions
    - kubectl apply -f k8s/
```

### 11. Performance Optimization

#### 11.1 Frontend Optimization

**Flutter Performance:**
- Lazy loading for large lists
- Image caching and compression
- State management optimization
- Bundle size optimization
- Memory leak prevention

**Web Performance:**
- Progressive Web App (PWA) implementation
- Service worker for offline functionality
- Code splitting and lazy loading
- CDN integration for static assets

#### 11.2 Backend Optimization

**Database Optimization:**
- Firestore query optimization with composite indexes
- Data denormalization for read-heavy operations
- Pagination for large datasets
- Caching layer with Redis

**Blockchain Optimization:**
- Gas optimization in smart contracts
- Batch transactions where possible
- Layer 2 scaling solutions
- Transaction queuing and retry mechanisms

### 12. Correctness Properties

Based on the prework analysis, here are the key correctness properties that must be maintained:

#### 12.1 User Management Properties
- **Registration Consistency**: Valid user data always results in successful registration
- **Email Uniqueness**: No two users can have the same email address
- **KYC State Integrity**: KYC status transitions follow valid state machine rules

#### 12.2 Marketplace Properties
- **Price Validity**: All crop prices must be positive values
- **Inventory Consistency**: Available quantity never exceeds total quantity
- **Order Atomicity**: Order placement either succeeds completely or fails completely

#### 12.3 Auction Properties
- **Bid Ordering**: Each new bid must be higher than the previous highest bid
- **Auction Timing**: Bids cannot be placed after auction end time
- **Winner Determination**: Highest valid bid always wins the auction

#### 12.4 Loan Properties
- **Interest Calculation**: Monthly payment calculations are mathematically correct
- **Collateral Ratio**: Loan amount never exceeds collateral value by more than allowed ratio
- **Payment Tracking**: Sum of payments plus outstanding balance equals total loan amount

#### 12.5 NFT Properties
- **Metadata Integrity**: NFT metadata is always valid and immutable once minted
- **Ownership Tracking**: NFT ownership changes are properly recorded on blockchain
- **Collateral Status**: NFT cannot be transferred while used as active loan collateral

#### 12.6 Payment Properties
- **Balance Consistency**: Wallet balance changes match transaction amounts
- **Transaction Atomicity**: Payment processing either succeeds completely or fails completely
- **Currency Conversion**: Exchange rate calculations are accurate and consistent

---

This design document provides a comprehensive technical foundation for implementing the AgriChain platform with robust testing strategies and correctness guarantees.