import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_state.dart';
import '../models/firestore_models.dart';
import '../widgets/shimmer_loading.dart';
import '../services/download_service.dart';
import '../services/contract_pdf_service.dart';
import '../services/database_service.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DownloadService _downloadService = DownloadService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final isFarmer = appState.currentUser?.userType == UserType.farmer;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: const Text(
              'Loan Services',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  text: isFarmer ? 'My Loan Requests' : 'Browse Requests',
                  icon: Icon(isFarmer ? Icons.request_page : Icons.search),
                ),
                Tab(
                  text: isFarmer ? 'Loan Offers' : 'My Offers',
                  icon: Icon(isFarmer ? Icons.local_offer : Icons.handshake),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              isFarmer
                  ? _buildMyLoanRequestsTab()
                  : _buildBrowseLoanRequestsTab(),
              isFarmer ? _buildLoanOffersTab() : _buildMyOffersTab(),
            ],
          ),
          floatingActionButton: isFarmer
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddLoanRequestDialog(context, appState),
                  backgroundColor: const Color(0xFF2E7D32),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add Loan Request',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildMyLoanRequestsTab() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('loan_requests')
              .where('farmerId', isEqualTo: appState.currentUser?.id)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingGrid();
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(
                'No Loan Requests',
                'You haven\'t created any loan requests yet.',
                Icons.request_page,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildLoanRequestCard(data, isOwner: true);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBrowseLoanRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('loan_requests')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingGrid();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            'No Loan Requests',
            'No active loan requests available at the moment.',
            Icons.search_off,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildLoanRequestCard(data, isOwner: false);
          },
        );
      },
    );
  }

  Widget _buildLoanOffersTab() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('loan_offers')
              .where('farmerId', isEqualTo: appState.currentUser?.id)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingGrid();
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(
                'No Loan Offers',
                'You haven\'t received any loan offers yet.',
                Icons.local_offer,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildLoanOfferCard(data, isReceiver: true);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMyOffersTab() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('loan_offers')
              .where('buyerId', isEqualTo: appState.currentUser?.id)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingGrid();
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(
                'No Offers Made',
                'You haven\'t made any loan offers yet.',
                Icons.handshake,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildLoanOfferCard(data, isReceiver: false);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLoanRequestCard(
    Map<String, dynamic> data, {
    required bool isOwner,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(data['status'] ?? 'active'),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (data['status'] ?? 'active').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (data['urgency'] == 'high')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'URGENT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data['farmerName'] ?? 'Unknown Farmer',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  data['location'] ?? 'Unknown Location',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Loan Amount',
                    '₹${data['loanAmount']?.toString() ?? '0'}',
                    Icons.currency_rupee,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Purpose',
                    data['purpose'] ?? 'General',
                    Icons.agriculture,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Expected ROI',
                    data['expectedROI'] ?? 'N/A',
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Repayment',
                    data['repaymentPeriod'] ?? 'N/A',
                    Icons.schedule,
                  ),
                ),
              ],
            ),
            if (data['description'] != null) ...[
              const SizedBox(height: 12),
              Text(
                data['description'],
                style: const TextStyle(color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            // Download Loan Contract action (available to both roles)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _downloadLoanContract(data),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Loan Contract'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (!isOwner)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showMakeLoanOfferDialog(data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.handshake),
                  label: const Text('Make Offer'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanOfferCard(
    Map<String, dynamic> data, {
    required bool isReceiver,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(data['status'] ?? 'pending'),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (data['status'] ?? 'pending').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  isReceiver
                      ? 'From: ${data['buyerName']}'
                      : 'To: ${data['farmerName']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Offered Amount',
                    '₹${data['offeredAmount']?.toString() ?? '0'}',
                    Icons.currency_rupee,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Interest Rate',
                    data['interestRate'] ?? 'N/A',
                    Icons.percent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              'Repayment Period',
              data['repaymentPeriod'] ?? 'N/A',
              Icons.schedule,
            ),
            if (data['terms'] != null) ...[
              const SizedBox(height: 12),
              Text(
                'Terms: ${data['terms']}',
                style: const TextStyle(color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            if (isReceiver && data['status'] == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _updateOfferStatus(data['id'], 'accepted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _updateOfferStatus(data['id'], 'rejected'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            // Download Loan Contract action (always visible)
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _downloadLoanContract(data),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Loan Contract'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadLoanContract(Map<String, dynamic> data) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Preparing loan contract...'),
            ],
          ),
        ),
      );

      // Fetch borrower and lender details
      String? borrowerSignatureUrl;
      String? lenderSignatureUrl;

      // Borrower (Farmer)
      if (data['farmerId'] != null) {
        try {
          final farmerDoc = await DatabaseService().getUserById(
            data['farmerId'],
          );
          if (farmerDoc != null) {
            borrowerSignatureUrl = farmerDoc['signatureUrl'];
          }
        } catch (e) {
          debugPrint('Error fetching borrower signature: $e');
        }
      }

      // Lender (Buyer)
      if (data['buyerId'] != null) {
        try {
          final buyerDoc = await DatabaseService().getUserById(data['buyerId']);
          if (buyerDoc != null) {
            lenderSignatureUrl = buyerDoc['signatureUrl'];
          }
        } catch (e) {
          debugPrint('Error fetching lender signature: $e');
        }
      }

      // Generate loan agreement bytes
      final bytes = await ContractPdfService.generateLoanAgreement(
        agreementId:
            (data['id'] ?? 'AGL-${DateTime.now().millisecondsSinceEpoch}')
                .toString(),
        borrowerName: (data['farmerName'] ?? data['borrowerName'] ?? 'Borrower')
            .toString(),
        lenderName: (data['buyerName'] ?? data['lenderName'] ?? 'Lender')
            .toString(),
        loanAmount:
            (num.tryParse(
                      (data['loanAmount'] ?? data['offeredAmount'] ?? '0')
                          .toString(),
                    ) ??
                    0)
                .toDouble(),
        interestRate: (data['interestRate'] ?? data['expectedROI'] ?? 'N/A')
            .toString(),
        repaymentPeriod: (data['repaymentPeriod'] ?? 'N/A').toString(),
        purpose: (data['purpose'] ?? 'Agriculture input financing').toString(),
        collateralNFT: (data['collateral'] ?? data['collateralNFT'])
            ?.toString(),
        borrowerSignatureUrl: borrowerSignatureUrl,
        lenderSignatureUrl: lenderSignatureUrl,
      );

      final doc = DocumentInfo(
        id: 'loan_agreement',
        title: 'Loan Agreement',
        description: 'Agrichain loan agreement contract',
        fileName: 'AgriChain_Loan_Agreement.pdf',
        filePath: '',
        icon: Icons.account_balance,
        color: const Color(0xFF2E7D32),
        estimatedSize: '1.8 MB',
        contentBytes: bytes,
      );

      double progress = 0.0;
      final result = await _downloadService.downloadDocument(
        doc,
        onProgress: (p) => progress = p,
      );

      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Loan contract saved to ${result.filePath}'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Failed to download contract'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildLoadingGrid() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ShimmerLoading(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'approved':
        return Colors.green;
      case 'rejected':
      case 'declined':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showAddLoanRequestDialog(BuildContext context, AppState appState) {
    final formKey = GlobalKey<FormState>();
    final controllers = {
      'amount': TextEditingController(),
      'purpose': TextEditingController(),
      'cropType': TextEditingController(),
      'farmSize': TextEditingController(),
      'expectedROI': TextEditingController(),
      'repaymentPeriod': TextEditingController(),
      'collateral': TextEditingController(),
      'description': TextEditingController(),
    };

    String urgency = 'medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Loan Request'),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: controllers['amount'],
                      decoration: const InputDecoration(
                        labelText: 'Loan Amount (₹)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllers['purpose'],
                      decoration: const InputDecoration(
                        labelText: 'Purpose',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllers['cropType'],
                      decoration: const InputDecoration(
                        labelText: 'Crop Type',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllers['expectedROI'],
                      decoration: const InputDecoration(
                        labelText: 'Expected ROI (%)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllers['repaymentPeriod'],
                      decoration: const InputDecoration(
                        labelText: 'Repayment Period',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: urgency,
                      decoration: const InputDecoration(
                        labelText: 'Urgency',
                        border: OutlineInputBorder(),
                      ),
                      items: ['low', 'medium', 'high'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          urgency = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllers['description'],
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _submitLoanRequest(controllers, urgency, appState);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMakeLoanOfferDialog(Map<String, dynamic> loanRequest) {
    final formKey = GlobalKey<FormState>();
    final controllers = {
      'amount': TextEditingController(
        text: loanRequest['loanAmount']?.toString(),
      ),
      'interestRate': TextEditingController(),
      'terms': TextEditingController(),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make Loan Offer'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controllers['amount'],
                decoration: const InputDecoration(
                  labelText: 'Offered Amount (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controllers['interestRate'],
                decoration: const InputDecoration(
                  labelText: 'Interest Rate (%)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controllers['terms'],
                decoration: const InputDecoration(
                  labelText: 'Terms & Conditions',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _submitLoanOffer(controllers, loanRequest);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Offer'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitLoanRequest(
    Map<String, TextEditingController> controllers,
    String urgency,
    AppState appState,
  ) async {
    try {
      final loanRequestId = 'loan_${DateTime.now().millisecondsSinceEpoch}';

      await _firestore.collection('loan_requests').doc(loanRequestId).set({
        'id': loanRequestId,
        'farmerId': appState.currentUser!.id,
        'farmerName': appState.currentUser!.name,
        'location': appState.currentUser!.location ?? 'Unknown',
        'loanAmount': double.tryParse(controllers['amount']!.text) ?? 0,
        'purpose': controllers['purpose']!.text,
        'cropType': controllers['cropType']!.text,
        'farmSize': controllers['farmSize']!.text,
        'expectedROI': controllers['expectedROI']!.text,
        'repaymentPeriod': controllers['repaymentPeriod']!.text,
        'collateral': controllers['collateral']!.text,
        'description': controllers['description']!.text,
        'urgency': urgency,
        'status': 'active',
        'createdDate': DateTime.now(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan request submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting loan request: $e')),
      );
    }
  }

  Future<void> _submitLoanOffer(
    Map<String, TextEditingController> controllers,
    Map<String, dynamic> loanRequest,
  ) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final offerId = 'offer_${DateTime.now().millisecondsSinceEpoch}';

      await _firestore.collection('loan_offers').doc(offerId).set({
        'id': offerId,
        'loanRequestId': loanRequest['id'],
        'farmerId': loanRequest['farmerId'],
        'farmerName': loanRequest['farmerName'],
        'buyerId': appState.currentUser!.id,
        'buyerName': appState.currentUser!.name,
        'offeredAmount': double.tryParse(controllers['amount']!.text) ?? 0,
        'interestRate': '${controllers['interestRate']!.text}%',
        'repaymentPeriod': loanRequest['repaymentPeriod'],
        'terms': controllers['terms']!.text,
        'status': 'pending',
        'validUntil': DateTime.now().add(const Duration(days: 30)),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan offer submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting loan offer: $e')),
      );
    }
  }

  Future<void> _updateOfferStatus(String offerId, String status) async {
    try {
      await _firestore.collection('loan_offers').doc(offerId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Offer $status successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating offer: $e')));
    }
  }
}
