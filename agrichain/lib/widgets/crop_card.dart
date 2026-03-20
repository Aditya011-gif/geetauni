import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/crop.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import '../services/contract_pdf_service.dart';
import '../services/contract_storage_service.dart';
import '../services/database_service.dart';
import 'payment_method_selector.dart';
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';

class CropCard extends StatefulWidget {
  final FirestoreCrop crop;
  final bool showPlaceOrder;
  final VoidCallback? onTap;

  const CropCard({
    super.key,
    required this.crop,
    this.showPlaceOrder = true,
    this.onTap,
  });

  @override
  State<CropCard> createState() => _CropCardState();
}

class _CropCardState extends State<CropCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap ?? () => _showCropDetails(context),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Image Area with Floating Badges
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image Placeholder / Gradient
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: _buildCropImage(),
                    ),

                    // Floating Glass Badges
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Row(
                        children: [
                          if (widget.crop.isNFT)
                            _buildGlassBadge(
                              context,
                              'NFT',
                              Icons.verified,
                              AppTheme.secondaryColor,
                            ),
                          if (widget.crop.isNFT && widget.crop.isAuction)
                            const SizedBox(width: 8),
                          if (widget.crop.isAuction)
                            _buildAuctionBadge(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Content Area
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.crop.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  widget.crop.location,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Pricing & Certs
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPricingSection(context),
                          const SizedBox(height: 8),
                          if (widget.crop.certifications.isNotEmpty)
                            _buildCertificationDots(context)
                          else
                            Text(
                              _getTimeAgo(widget.crop.harvestDate),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppTheme.textDisabled),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBadge(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: Colors.white.withOpacity(0.2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuctionBadge(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final auction = appState.getAuctionByCropId(widget.crop.id);
        if (auction == null) return const SizedBox.shrink();

        final isActive =
            auction.endTime.difference(DateTime.now()).inSeconds > 0;
        return _buildGlassBadge(
          context,
          isActive ? 'LIVE' : 'ENDED',
          Icons.gavel,
          isActive ? AppTheme.success : AppTheme.error,
        );
      },
    );
  }

  Widget _buildCropImage() {
    final colors = _getCropColors(widget.crop.name);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          _getCropIcon(widget.crop.name),
          size: 48,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  List<Color> _getCropColors(String cropName) {
    if (cropName.toLowerCase().contains('wheat')) {
      return [const Color(0xFFE6D690), const Color(0xFFC7A008)];
    } else if (cropName.toLowerCase().contains('rice')) {
      return [const Color(0xFFC8E6C9), const Color(0xFF81C784)];
    } else if (cropName.toLowerCase().contains('corn')) {
      return [const Color(0xFFFFECB3), const Color(0xFFFFCA28)];
    } else if (cropName.toLowerCase().contains('tomato')) {
      return [const Color(0xFFFFCCBC), const Color(0xFFFF7043)];
    } else {
      return [const Color(0xFFA5D6A7), const Color(0xFF66BB6A)];
    }
  }

  IconData _getCropIcon(String cropName) {
    if (cropName.toLowerCase().contains('wheat')) return Icons.grass;
    if (cropName.toLowerCase().contains('rice')) return Icons.rice_bowl;
    if (cropName.toLowerCase().contains('corn')) return Icons.agriculture;
    if (cropName.toLowerCase().contains('tomato')) return Icons.local_florist;
    return Icons.eco;
  }

  Widget _buildPricingSection(BuildContext context) {
    final theme = Theme.of(context);

    // Auction Pricing
    if (widget.crop.isAuction) {
      return Consumer<AppState>(
        builder: (context, appState, child) {
          final auction = appState.getAuctionByCropId(widget.crop.id);
          if (auction == null) return _buildDirectPricing(context);

          final bids = appState.getBidsForAuction(auction.id);
          final currentBid = bids.isNotEmpty
              ? (bids.last['amount'] as num).toDouble()
              : auction.startingPrice;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Bid', style: theme.textTheme.labelSmall),
              Text(
                '₹${currentBid.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      );
    }

    // Direct Pricing
    return _buildDirectPricing(context);
  }

  Widget _buildDirectPricing(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '₹${widget.crop.price.toStringAsFixed(0)}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '/${widget.crop.quantity}',
            style: theme.textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCertificationDots(BuildContext context) {
    return Row(
      children: widget.crop.certifications.take(3).map((cert) {
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Tooltip(
            message: cert['type'] ?? 'Certified',
            child: CircleAvatar(
              radius: 4,
              backgroundColor: AppTheme.secondaryColor,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Now';
  }

  void _showCropDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CropDetailsSheet(
        crop: widget.crop,
        showPlaceOrder: widget.showPlaceOrder,
      ),
    );
  }
}

// Redesigned Detail Sheet
class _CropDetailsSheet extends StatelessWidget {
  final FirestoreCrop crop;
  final bool showPlaceOrder;

  const _CropDetailsSheet({required this.crop, this.showPlaceOrder = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textDisabled.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          crop.name,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              crop.location,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const Spacer(),
                            if (crop.isNFT)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryColor.withOpacity(
                                    0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.secondaryColor,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.verified,
                                      size: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'NFT Verified',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Price & Stats
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStat(context, 'Price', '₹${crop.price}'),
                              _buildStat(context, 'Quantity', crop.quantity),
                              _buildStat(
                                context,
                                'Harvest',
                                DateFormat('MMM d').format(crop.harvestDate),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Description
                        Text(
                          'About this crop',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          crop.description,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                                height: 1.6,
                              ),
                        ),
                        const SizedBox(height: 24),

                        // Farmer Info
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primaryColor.withOpacity(
                              0.1,
                            ),
                            child: Text(
                              crop.farmerName[0],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          title: Text(crop.farmerName),
                          subtitle: const Text('Verified Farmer'),
                          trailing: IconButton(
                            icon: const Icon(Icons.chat_bubble_outline),
                            onPressed: () {}, // Todo: Implement chat
                          ),
                        ),

                        const SizedBox(
                          height: 100,
                        ), // Spacing for sticky button
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (showPlaceOrder)
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => _showOrderDialog(context),
                        child: const Text('Place Order'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showOrderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Confirm Order',
                      style: Theme.of(dialogContext).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
              ),

              // Order details
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: Theme.of(dialogContext).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    _buildOrderDetailRow(dialogContext, 'Crop', crop.name),
                    _buildOrderDetailRow(
                      dialogContext,
                      'Quantity',
                      crop.quantity,
                    ),
                    _buildOrderDetailRow(
                      dialogContext,
                      'Price',
                      '₹${crop.price.toStringAsFixed(0)}',
                    ),
                    _buildOrderDetailRow(
                      dialogContext,
                      'Location',
                      crop.location,
                    ),
                    _buildOrderDetailRow(
                      dialogContext,
                      'Farmer',
                      crop.farmerName,
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: Theme.of(dialogContext).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${crop.price.toStringAsFixed(0)}',
                          style: Theme.of(dialogContext).textTheme.titleLarge
                              ?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Payment section
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: PaymentMethodSelector(
                    amount: crop.price,
                    description: 'Purchase ${crop.name} - ${crop.quantity}',
                    metadata: {
                      'cropId': crop.id,
                      'cropName': crop.name,
                      'farmerId': crop.farmerId,
                      'quantity': crop.quantity,
                    },
                    onPaymentSuccess: (paymentData) {
                      _processOrder(dialogContext, context, paymentData);
                    },
                    onPaymentFailure: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payment failed: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _processOrder(
    BuildContext dialogContext,
    BuildContext parentContext,
    Map<String, dynamic> paymentData,
  ) async {
    try {
      // Show loading
      showDialog(
        context: dialogContext,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing order...'),
                ],
              ),
            ),
          ),
        ),
      );

      final appState = Provider.of<AppState>(parentContext, listen: false);
      final currentUser = appState.currentUser;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Create order ID
      final orderId = const Uuid().v4();
      final orderData = {
        'id': orderId,
        'cropId': crop.id,
        'cropName': crop.name,
        'quantity': crop.quantity,
        'price': crop.price,
        'totalAmount': crop.price,
        'buyerId': currentUser.id,
        'buyerName': currentUser.name,
        'sellerId': crop.farmerId,
        'sellerName': crop.farmerName,
        'status': 'pending',
        'paymentMethod': paymentData['payment_method'] ?? 'unknown',
        'transactionId': paymentData['transaction_id'] ?? '',
        'deliveryLocation': crop.location,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Create order in Firebase
      final firebaseService = FirebaseService();
      await firebaseService.createOrder(orderId: orderId, orderData: orderData);

      // Fetch farmer details for signature
      String? farmerSignatureUrl;
      try {
        final farmerDoc = await DatabaseService().getUserById(crop.farmerId);
        if (farmerDoc != null) {
          farmerSignatureUrl = farmerDoc['signatureUrl'];
        }
      } catch (e) {
        debugPrint('Error fetching farmer signature: $e');
      }

      // Generate contract PDF
      final contractPdf = await ContractPdfService.generatePurchaseContract(
        contractId: orderId,
        farmerName: crop.farmerName,
        buyerName: currentUser.name,
        cropName: crop.name,
        quantity: double.parse(crop.quantity.split(' ')[0]),
        price: crop.price,
        deliveryDate: DateFormat('dd MMMM yyyy').format(crop.harvestDate),
        deliveryLocation: crop.location,
        paymentTerms: 'Paid via ${paymentData['payment_method']}',
        farmerSignatureUrl: farmerSignatureUrl,
        buyerSignatureUrl: currentUser.signatureUrl,
      );

      // Upload contract to Firebase Storage
      await ContractStorageService.uploadContract(
        pdfBytes: contractPdf,
        orderId: orderId,
        contractType: 'purchase',
        buyerName: currentUser.name,
        sellerName: crop.farmerName,
        cropName: crop.name,
        totalAmount: crop.price,
      );

      // Close loading dialog
      Navigator.pop(dialogContext);
      // Close payment dialog
      Navigator.pop(dialogContext);
      // Close crop details
      Navigator.pop(parentContext);

      // Show success and offer to download contract
      showDialog(
        context: parentContext,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.success, size: 32),
              const SizedBox(width: 12),
              const Text('Order Placed!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your order has been placed successfully.'),
              const SizedBox(height: 12),
              Text(
                'Order ID: $orderId',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'A contract has been generated. Would you like to download it?',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Printing.layoutPdf(onLayout: (format) => contractPdf);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.download),
              label: const Text('Download Contract'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close any open dialogs
      Navigator.pop(dialogContext); // Close loading

      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Text('Order failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
