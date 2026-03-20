import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/firestore_models.dart';
import '../theme/app_theme.dart';

import '../widgets/crop_card.dart';

import '../services/firebase_service.dart';
import '../services/contract_pdf_service.dart';
import '../services/database_service.dart';
import '../screens/rating_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'Recent';

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
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.background,
            surfaceTintColor: Colors.transparent, // Disable Material 3 tint
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Marketplace',
              style: GoogleFonts.outfit(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 24,
              ),
            ),
            actions: [
              if (!isFarmer) ...[
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  color: AppTheme.textPrimary,
                  onPressed: () => _showCart(context),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          body: Column(
            children: [
              Container(
                color: AppTheme.background,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    if (!isFarmer) _buildSearchBar(),
                    const SizedBox(height: 8),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: AppTheme.textSecondary,
                        labelStyle: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                        ),
                        dividerColor: Colors.transparent,
                        padding: const EdgeInsets.all(4),
                        tabs: isFarmer
                            ? const [
                                Tab(text: 'Price Comparison'),
                                Tab(text: 'My Orders'),
                              ]
                            : const [
                                Tab(text: 'Browse Crops'),
                                Tab(text: 'My Orders'),
                              ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: isFarmer
                      ? [const _PriceComparisonTab(), const _MyOrdersTab()]
                      : [
                          _BrowseCropsTab(
                            searchQuery: _searchQuery,
                            selectedCategory: _selectedCategory,
                            sortBy: _sortBy,
                            onCategorySelected: (category) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          ),
                          const _MyOrdersTab(),
                        ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: AppTheme.inputBorder, width: 1),
        ),
        child: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search crops...',
            hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
            prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.tune_rounded), // Filter icon
                    color: AppTheme.primaryColor,
                    onPressed: () => _showFilterSheet(context),
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        selectedCategory: _selectedCategory,
        sortBy: _sortBy,
        onApply: (category, sort) {
          setState(() {
            _selectedCategory = category;
            _sortBy = sort;
          });
        },
      ),
    );
  }

  void _showCart(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.shopping_cart, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            const Text('Shopping Cart'),
          ],
        ),
        content: const Text(
          'Cart functionality will be implemented with order management.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _BrowseCropsTab extends StatefulWidget {
  final String searchQuery;
  final String selectedCategory;
  final String sortBy;
  final Function(String) onCategorySelected;

  const _BrowseCropsTab({
    required this.searchQuery,
    required this.selectedCategory,
    required this.sortBy,
    required this.onCategorySelected,
  });

  @override
  State<_BrowseCropsTab> createState() => _BrowseCropsTabState();
}

class _BrowseCropsTabState extends State<_BrowseCropsTab> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _firebaseCrops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCropsFromFirebase();
  }

  Future<void> _loadCropsFromFirebase() async {
    try {
      final crops = await _firebaseService.getAllCrops();
      if (mounted) {
        setState(() {
          _firebaseCrops = crops;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading crops from Firebase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Use crops from AppState (which are already FirestoreCrop objects)
        var allCrops = <FirestoreCrop>[];

        // Add local crops
        allCrops.addAll(appState.crops);

        var filteredCrops = allCrops.where((crop) {
          // Search filter
          if (widget.searchQuery.isNotEmpty) {
            final query = widget.searchQuery.toLowerCase();
            if (!crop.name.toLowerCase().contains(query) &&
                !crop.farmerName.toLowerCase().contains(query) &&
                !crop.location.toLowerCase().contains(query)) {
              return false;
            }
          }

          // Category filter
          if (widget.selectedCategory != 'All') {
            if (widget.selectedCategory == 'NFT' && !crop.isNFT) return false;
            if (widget.selectedCategory == 'Regular' && crop.isNFT)
              return false;
            if (widget.selectedCategory != 'NFT' &&
                widget.selectedCategory != 'Regular' &&
                !crop.name.toLowerCase().contains(
                  widget.selectedCategory.toLowerCase(),
                )) {
              return false;
            }
          }

          return true;
        }).toList();

        // Sort crops
        switch (widget.sortBy) {
          case 'Price Low to High':
            filteredCrops.sort((a, b) => a.price.compareTo(b.price));
            break;
          case 'Price High to Low':
            filteredCrops.sort((a, b) => b.price.compareTo(a.price));
            break;
          case 'Recent':
            filteredCrops.sort(
              (a, b) => b.harvestDate.compareTo(a.harvestDate),
            );
            break;
          case 'Alphabetical':
            filteredCrops.sort((a, b) => a.name.compareTo(b.name));
            break;
        }

        return Column(
          children: [
            _buildCategoryChips(),
            Expanded(
              child: filteredCrops.isEmpty
                  ? _buildEmptyState(context)
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        padding: const EdgeInsets.only(
                          top: 16,
                          bottom: 100,
                        ), // Bottom padding for floating nav
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio:
                                  0.65, // Taller for the new card design
                            ),
                        itemCount: filteredCrops.length,
                        itemBuilder: (context, index) {
                          return CropCard(
                            crop: filteredCrops[index],
                            // onTap is removed to let CropCard handle it with its internal Sheet
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChips() {
    final categories = [
      'All',
      'NFT',
      'Regular',
      'Wheat',
      'Rice',
      'Corn',
      'Vegetables',
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = widget.selectedCategory == category;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                widget.onCategorySelected(category);
              },
              backgroundColor: AppTheme.surface,
              selectedColor: AppTheme.primaryColor,
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : AppTheme.inputBorder,
                  width: 1,
                ),
              ),
              labelStyle: GoogleFonts.inter(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: isSelected ? 4 : 0,
              shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No crops found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PriceComparisonTab extends StatefulWidget {
  const _PriceComparisonTab();

  @override
  State<_PriceComparisonTab> createState() => _PriceComparisonTabState();
}

class _PriceComparisonTabState extends State<_PriceComparisonTab> {
  String _selectedCropType = 'All';
  String _sortBy = 'Price Low to High';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Group crops by type for price comparison
        final cropPriceData = _generatePriceComparisonData(appState.crops);

        return Column(
          children: [
            _buildFilterControls(),
            Expanded(
              child: cropPriceData.isEmpty
                  ? _buildEmptyPriceState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: cropPriceData.length,
                      itemBuilder: (context, index) {
                        return _PriceComparisonCard(
                          priceData: cropPriceData[index],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterControls() {
    final cropTypes = [
      {'value': 'All', 'label': 'All Crops', 'icon': Icons.agriculture},
      {'value': 'Wheat', 'label': 'Wheat', 'icon': Icons.grass},
      {'value': 'Rice', 'label': 'Rice', 'icon': Icons.rice_bowl},
      {'value': 'Corn', 'label': 'Corn', 'icon': Icons.eco},
      {
        'value': 'Vegetables',
        'label': 'Vegetables',
        'icon': Icons.local_florist,
      },
      {'value': 'Fruits', 'label': 'Fruits', 'icon': Icons.apple},
    ];

    final sortOptions = [
      {
        'value': 'Price Low to High',
        'label': 'Lowest Price First',
        'icon': Icons.arrow_upward,
      },
      {
        'value': 'Price High to Low',
        'label': 'Highest Price First',
        'icon': Icons.arrow_downward,
      },
      {'value': 'Alphabetical', 'label': 'A to Z', 'icon': Icons.sort_by_alpha},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter & Sort Prices',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_list, size: 16, color: AppTheme.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Choose Crop Type',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCropType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryGreen,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: AppTheme.primaryGreen.withOpacity(0.05),
                      ),
                      items: cropTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type['value'] as String,
                              child: Row(
                                children: [
                                  Icon(
                                    type['icon'] as IconData,
                                    size: 20,
                                    color: AppTheme.primaryGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(type['label'] as String),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCropType = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sort, size: 16, color: AppTheme.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Sort Prices',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _sortBy,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryGreen,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: AppTheme.primaryGreen.withOpacity(0.05),
                      ),
                      items: sortOptions
                          .map(
                            (option) => DropdownMenuItem(
                              value: option['value'] as String,
                              child: Row(
                                children: [
                                  Icon(
                                    option['icon'] as IconData,
                                    size: 20,
                                    color: AppTheme.primaryGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(option['label'] as String),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPriceState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 80, color: AppTheme.grey),
          const SizedBox(height: 16),
          Text(
            'No price data available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Price comparison data will appear here',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<CropPriceData> _generatePriceComparisonData(List<FirestoreCrop> crops) {
    // Group crops by name/type
    final Map<String, List<FirestoreCrop>> groupedCrops = {};

    for (final crop in crops) {
      final cropName = crop.name.toLowerCase();
      if (!groupedCrops.containsKey(cropName)) {
        groupedCrops[cropName] = [];
      }
      groupedCrops[cropName]!.add(crop);
    }

    // Create price comparison data
    final List<CropPriceData> priceData = [];

    groupedCrops.forEach((cropName, cropList) {
      if (_selectedCropType == 'All' ||
          cropName.contains(_selectedCropType.toLowerCase())) {
        cropList.sort((a, b) => a.price.compareTo(b.price));

        final minPrice = cropList.first.price;
        final maxPrice = cropList.last.price;
        final avgPrice =
            cropList.fold(0.0, (sum, crop) => sum + crop.price) /
            cropList.length;

        priceData.add(
          CropPriceData(
            cropName: cropName,
            minPrice: minPrice,
            maxPrice: maxPrice,
            averagePrice: avgPrice,
            totalListings: cropList.length,
            crops: cropList,
          ),
        );
      }
    });

    // Sort the price data
    switch (_sortBy) {
      case 'Price Low to High':
        priceData.sort((a, b) => a.averagePrice.compareTo(b.averagePrice));
        break;
      case 'Price High to Low':
        priceData.sort((a, b) => b.averagePrice.compareTo(a.averagePrice));
        break;
      case 'Alphabetical':
        priceData.sort((a, b) => a.cropName.compareTo(b.cropName));
        break;
    }

    return priceData;
  }
}

class CropPriceData {
  final String cropName;
  final double minPrice;
  final double maxPrice;
  final double averagePrice;
  final int totalListings;
  final List<FirestoreCrop> crops;

  CropPriceData({
    required this.cropName,
    required this.minPrice,
    required this.maxPrice,
    required this.averagePrice,
    required this.totalListings,
    required this.crops,
  });
}

class _PriceComparisonCard extends StatelessWidget {
  final CropPriceData priceData;

  const _PriceComparisonCard({required this.priceData});

  IconData _getCropIcon(String cropName) {
    switch (cropName.toLowerCase()) {
      case 'wheat':
        return Icons.grass;
      case 'rice':
        return Icons.rice_bowl;
      case 'corn':
        return Icons.eco;
      case 'vegetables':
        return Icons.local_florist;
      case 'fruits':
        return Icons.apple;
      default:
        return Icons.agriculture;
    }
  }

  Color _getPriceColor(double price, double minPrice, double maxPrice) {
    if (price <= minPrice + (maxPrice - minPrice) * 0.3) {
      return Colors.green; // Low price - good for buyers
    } else if (price >= maxPrice - (maxPrice - minPrice) * 0.3) {
      return Colors.orange; // High price - good for sellers
    } else {
      return AppTheme.primaryGreen; // Average price
    }
  }

  @override
  Widget build(BuildContext context) {
    final priceColor = _getPriceColor(
      priceData.averagePrice,
      priceData.minPrice,
      priceData.maxPrice,
    );
    final priceRange = priceData.maxPrice - priceData.minPrice;
    final priceVariation = priceRange > 0
        ? ((priceRange / priceData.averagePrice) * 100)
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppTheme.primaryGreen.withOpacity(0.02)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with crop info
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      _getCropIcon(priceData.cropName),
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          priceData.cropName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGrey,
                          ),
                        ),
                        Text(
                          '${priceData.totalListings} farmers selling',
                          style: TextStyle(color: AppTheme.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Price information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPriceItem(
                          'Lowest Price',
                          '₹${priceData.minPrice.toStringAsFixed(0)}',
                          Colors.green,
                        ),
                        _buildPriceItem(
                          'Average Price',
                          '₹${priceData.averagePrice.toStringAsFixed(0)}',
                          AppTheme.primaryGreen,
                        ),
                        _buildPriceItem(
                          'Highest Price',
                          '₹${priceData.maxPrice.toStringAsFixed(0)}',
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Price difference: ₹${priceRange.toStringAsFixed(0)} per kg',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showDetailedComparison(context),
                  icon: Icon(Icons.analytics, size: 20),
                  label: Text(
                    'View Detailed Analysis',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInfo(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.darkGrey)),
      ],
    );
  }

  void _showDetailedComparison(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetailedComparisonSheet(priceData: priceData),
    );
  }
}

class _DetailedComparisonSheet extends StatelessWidget {
  final CropPriceData priceData;

  const _DetailedComparisonSheet({required this.priceData});

  Color _getPriceColor(double price) {
    if (price <=
        priceData.minPrice + (priceData.maxPrice - priceData.minPrice) * 0.3) {
      return Colors.green;
    } else if (price >=
        priceData.maxPrice - (priceData.maxPrice - priceData.minPrice) * 0.3) {
      return Colors.orange;
    } else {
      return AppTheme.primaryGreen;
    }
  }

  String _getPriceLabel(double price) {
    if (price <=
        priceData.minPrice + (priceData.maxPrice - priceData.minPrice) * 0.3) {
      return 'Low Price';
    } else if (price >=
        priceData.maxPrice - (priceData.maxPrice - priceData.minPrice) * 0.3) {
      return 'High Price';
    } else {
      return 'Fair Price';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort crops by price for better comparison
    final sortedCrops = List<FirestoreCrop>.from(priceData.crops)
      ..sort((a, b) => a.price.compareTo(b.price));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '${priceData.cropName} Prices',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${priceData.totalListings} farmers selling',
                  style: TextStyle(color: AppTheme.grey, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSimplePriceInfo(
                      'Lowest',
                      '₹${priceData.minPrice.toStringAsFixed(0)}',
                      Colors.green,
                    ),
                    _buildSimplePriceInfo(
                      'Average',
                      '₹${priceData.averagePrice.toStringAsFixed(0)}',
                      AppTheme.primaryGreen,
                    ),
                    _buildSimplePriceInfo(
                      'Highest',
                      '₹${priceData.maxPrice.toStringAsFixed(0)}',
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Instructions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Choose the best price for your needs',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Seller list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: sortedCrops.length,
              itemBuilder: (context, index) {
                final crop = sortedCrops[index];
                final priceColor = _getPriceColor(crop.price);
                final priceLabel = _getPriceLabel(crop.price);
                final isLowestPrice = crop.price == priceData.minPrice;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLowestPrice
                          ? Colors.green.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                      width: isLowestPrice ? 2 : 1,
                    ),
                    color: isLowestPrice
                        ? Colors.green.withOpacity(0.05)
                        : Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Farmer avatar
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: priceColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: priceColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            color: priceColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Farmer info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      crop.farmerName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppTheme.darkGrey,
                                      ),
                                    ),
                                  ),
                                  if (isLowestPrice)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'BEST DEAL',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: AppTheme.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    crop.location,
                                    style: TextStyle(
                                      color: AppTheme.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.inventory,
                                    size: 14,
                                    color: AppTheme.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${crop.quantity} available',
                                    style: TextStyle(
                                      color: AppTheme.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Price info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${crop.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: priceColor,
                              ),
                            ),
                            Text(
                              'per kg',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: priceColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                priceLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: priceColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimplePriceInfo(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(title, style: TextStyle(fontSize: 12, color: AppTheme.darkGrey)),
      ],
    );
  }
}

class _MyOrdersTab extends StatelessWidget {
  const _MyOrdersTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final isFarmer = appState.currentUser?.userType == UserType.farmer;

        // Filter orders based on user type
        final myOrders = isFarmer == true
            ? appState.orders
                  .where(
                    (order) => order.sellerName == appState.currentUser?.name,
                  )
                  .toList()
            : appState.orders
                  .where(
                    (order) => order.buyerName == appState.currentUser?.name,
                  )
                  .toList();

        if (myOrders.isEmpty) {
          return _buildEmptyState(context, isFarmer);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myOrders.length,
          itemBuilder: (context, index) {
            return _OrderCard(order: myOrders[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isFarmer) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFarmer ? Icons.agriculture : Icons.shopping_bag_outlined,
            size: 80,
            color: AppTheme.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isFarmer ? 'No orders received yet' : 'No orders yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFarmer
                ? 'Orders from buyers will appear here when they purchase your crops'
                : 'Start shopping to see your orders here',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final FirestoreOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(order.status),
                  color: _getStatusColor(order.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    Text(
                      _getStatusText(order.status),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${order.totalAmount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOrderDetail(
                  'Farmer',
                  order.sellerName,
                  Icons.person,
                ),
              ),
              Expanded(
                child: _buildOrderDetail(
                  'Quantity',
                  '${order.quantity} units',
                  Icons.inventory,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOrderDetail(
                  'Order Date',
                  DateFormat('MMM dd').format(order.orderDate),
                  Icons.calendar_today,
                ),
              ),
              Expanded(
                child: _buildOrderDetail(
                  'Expected Delivery',
                  DateFormat(
                    'MMM dd',
                  ).format(order.expectedDelivery ?? DateTime.now()),
                  Icons.local_shipping,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOrderActions(context, order),
        ],
      ),
    );
  }

  Widget _buildOrderDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppTheme.grey, fontSize: 12)),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGrey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return AppTheme.primaryGreen;
      case OrderStatus.shipped:
        return Colors.blue;
      case OrderStatus.delivered:
        return AppTheme.accentGreen;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  Widget _buildOrderActions(BuildContext context, FirestoreOrder order) {
    final appState = Provider.of<AppState>(context, listen: false);

    List<Widget> actions = [];

    // Contract download action for confirmed orders
    if (order.status == OrderStatus.confirmed ||
        order.status == OrderStatus.shipped ||
        order.status == OrderStatus.delivered) {
      actions.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _downloadOrderContract(context, order),
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Contract'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: BorderSide(color: AppTheme.primaryGreen),
            ),
          ),
        ),
      );
      actions.add(const SizedBox(width: 8));
    }

    // Track order action
    actions.add(
      Expanded(
        child: OutlinedButton(
          onPressed: () => _trackOrder(context, order),
          child: const Text('Track'),
        ),
      ),
    );

    actions.add(const SizedBox(width: 8));

    // Rating action for delivered orders
    if (order.status == OrderStatus.delivered &&
        appState.currentUser != null &&
        ((appState.currentUser!.id == order.buyerId && !order.buyerRated) ||
            (appState.currentUser!.id == order.sellerId &&
                !order.sellerRated))) {
      actions.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _navigateToRating(context, order),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
            ),
            child: const Text('Rate'),
          ),
        ),
      );
    } else {
      actions.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _contactFarmer(context),
            child: const Text('Contact'),
          ),
        ),
      );
    }

    return Row(children: actions);
  }

  void _navigateToRating(BuildContext context, FirestoreOrder order) {
    final appState = Provider.of<AppState>(context, listen: false);
    final currentUserId = appState.currentUser?.id;

    if (currentUserId == null) return;

    String targetUserId;
    String targetUserName;
    RatingType ratingType;

    if (order.buyerId == currentUserId) {
      // Current user is buyer, rating the seller
      targetUserId = order.sellerId;
      targetUserName = order.sellerName;
      ratingType = RatingType.overall;
    } else {
      // Current user is seller, rating the buyer
      targetUserId = order.buyerId;
      targetUserName = order.buyerName;
      ratingType = RatingType.overall;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GiveRatingScreen(
          toUserId: targetUserId,
          toUserName: targetUserName,
          ratingType: ratingType,
          transactionId: order.id,
        ),
      ),
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.confirmed:
        return Icons.check_circle;
      case OrderStatus.shipped:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  void _trackOrder(BuildContext context, FirestoreOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Track Order'),
        content: Text(
          'Real-time tracking will be implemented with GPS integration. Order #${order.id.substring(0, 8)} is currently ${_getStatusText(order.status).toLowerCase()}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadOrderContract(
    BuildContext context,
    FirestoreOrder order,
  ) async {
    try {
      // Store context reference before async operations
      final currentContext = context;

      // Show loading indicator
      showDialog(
        context: currentContext,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating contract PDF...'),
            ],
          ),
        ),
      );

      final appState = Provider.of<AppState>(currentContext, listen: false);

      // Find the crop data with better error handling
      FirestoreCrop? crop;
      try {
        crop = appState.crops.firstWhere((c) => c.id == order.cropId);
      } catch (e) {
        // If crop not found, close dialog and show error
        if (Navigator.canPop(currentContext)) {
          Navigator.pop(currentContext);
        }
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text('Error: Crop data not found'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      final currentUser = appState.currentUser!;
      String buyerName = order.buyerName;
      String sellerName = order.sellerName;
      String? buyerSignatureUrl;
      String? sellerSignatureUrl;

      // Determine roles and fetch missing signatures
      if (currentUser.id == order.buyerId) {
        // Current user is buyer
        buyerName = currentUser.name;
        buyerSignatureUrl = currentUser.signatureUrl;

        // Fetch seller details
        try {
          final sellerDoc = await DatabaseService().getUserById(order.sellerId);
          if (sellerDoc != null) {
            sellerSignatureUrl = sellerDoc['signatureUrl'];
          }
        } catch (e) {
          debugPrint('Error fetching seller signature: $e');
        }
      } else {
        // Current user is seller
        sellerName = currentUser.name;
        sellerSignatureUrl = currentUser.signatureUrl;

        // Fetch buyer details
        try {
          final buyerDoc = await DatabaseService().getUserById(order.buyerId);
          if (buyerDoc != null) {
            buyerSignatureUrl = buyerDoc['signatureUrl'];
          }
        } catch (e) {
          debugPrint('Error fetching buyer signature: $e');
        }
      }

      // Extract contract data from order metadata
      final metadata = order.metadata ?? {};
      final contractData = {
        'contractId': metadata['smart_contract_id'] ?? order.id,
        'transactionHash':
            metadata['contract_tx_hash'] ??
            '0x${order.id.hashCode.toRadixString(16)}',
        'contractAddress': '0xabcdef1234567890abcdef1234567890abcdef12',
        'escrowAddress': '0x1234567890abcdef1234567890abcdef12345678',
        'blockNumber': 5000000 + (order.id.hashCode % 1000000),
        'gasUsed': '0.0045 ETH',
        'contractData': {
          'terms': {
            'deliveryDeadline':
                order.expectedDelivery?.toIso8601String() ??
                DateTime.now().add(const Duration(days: 7)).toIso8601String(),
            'qualityStandards': 'Grade A organic certification required',
            'penaltyRate': 0.05,
            'refundPolicy': 'Full refund if quality standards not met',
          },
        },
      };

      // Generate PDF
      final pdfBytes = await ContractPdfService.generatePurchaseContract(
        contractId: order.id,
        farmerName: sellerName,
        buyerName: buyerName,
        cropName: crop.name,
        quantity: double.tryParse(order.quantity) ?? 0.0,
        price: crop.price,
        deliveryDate:
            order.expectedDelivery?.toIso8601String() ??
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        deliveryLocation: crop.location,
        paymentTerms: 'Payment via AgriChain platform',
        farmerSignatureUrl: sellerSignatureUrl,
        buyerSignatureUrl: buyerSignatureUrl,
        extra: {
          'contractData': contractData,
          'paymentDetails': metadata['payment_response'],
        },
      );

      // Generate filename
      final fileName = ContractPdfService.generateContractFileName(order.id);

      // Close loading dialog
      if (Navigator.canPop(currentContext)) {
        Navigator.pop(currentContext);
      }

      // Save and share PDF
      await ContractPdfService.shareOrPrintPdf(pdfBytes, fileName);

      // Show success message
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Contract PDF generated successfully!'),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Store context reference
      final currentContext = context;

      // Close loading dialog if open
      if (Navigator.canPop(currentContext)) {
        Navigator.pop(currentContext);
      }

      // Show error message
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text('Error generating contract: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _contactFarmer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact ${order.sellerName}'),
        content: const Text(
          'Direct messaging with farmers will be implemented with real-time chat functionality.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final String selectedCategory;
  final String sortBy;
  final Function(String, String) onApply;

  const _FilterSheet({
    required this.selectedCategory,
    required this.sortBy,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _selectedCategory;
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _sortBy = widget.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter & Sort',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildCategorySection(),
                  const SizedBox(height: 24),
                  _buildSortSection(),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = 'All';
                              _sortBy = 'Recent';
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onApply(_selectedCategory, _sortBy);
                            Navigator.pop(context);
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    final categories = [
      'All',
      'NFT',
      'Regular',
      'Wheat',
      'Rice',
      'Corn',
      'Vegetables',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.darkGrey,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected = _selectedCategory == category;
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryGreen,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryGreen : AppTheme.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSortSection() {
    final sortOptions = [
      'Recent',
      'Price Low to High',
      'Price High to Low',
      'Alphabetical',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.darkGrey,
          ),
        ),
        const SizedBox(height: 12),
        ...sortOptions.map((option) {
          return RadioListTile<String>(
            title: Text(option),
            value: option,
            groupValue: _sortBy,
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
              });
            },
            activeColor: AppTheme.primaryGreen,
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }
}
