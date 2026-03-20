import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/crop_nft.dart';
import '../services/nft_service.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class MintCropNFTScreen extends StatefulWidget {
  const MintCropNFTScreen({super.key});

  @override
  State<MintCropNFTScreen> createState() => _MintCropNFTScreenState();
}

class _MintCropNFTScreenState extends State<MintCropNFTScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isMinting = false;

  // Crop Details Controllers
  final _cropNameController = TextEditingController();
  final _varietyController = TextEditingController();
  final _quantityController = TextEditingController();
  final _farmLocationController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final _seedSourceController = TextEditingController();
  final _fertilizersController = TextEditingController();
  final _pesticidesController = TextEditingController();
  final _irrigationMethodController = TextEditingController();
  final _soilTypeController = TextEditingController();
  final _weatherConditionsController = TextEditingController();

  // Harvest Data Controllers
  final _harvestQuantityController = TextEditingController();
  final _gradeController = TextEditingController();
  final _moistureContentController = TextEditingController();
  final _storageConditionsController = TextEditingController();
  final _packagingDetailsController = TextEditingController();
  final _expectedShelfLifeController = TextEditingController();

  // Quality Assurance Controllers
  final _certificationBodyController = TextEditingController();
  final _certificateNumberController = TextEditingController();
  final _testingLabController = TextEditingController();
  final _labReportNumberController = TextEditingController();
  final _nutritionalValueController = TextEditingController();
  final _contaminantLevelsController = TextEditingController();

  // Dropdown values
  String _selectedCropCategory = 'Grains';
  String _selectedUnit = 'Kg';
  String _selectedGrowingMethod = 'Conventional';
  String _selectedHarvestMethod = 'Manual';
  String _selectedQualityGrade = 'A';
  String _selectedCertificationType = 'Organic';
  bool _isOrganic = false;
  bool _hasQualityTests = false;
  DateTime _plantingDate = DateTime.now().subtract(const Duration(days: 90));
  DateTime _harvestDate = DateTime.now();
  DateTime _certificationDate = DateTime.now();
  DateTime _testingDate = DateTime.now();

  // Document images
  final List<String> _cropImages = [];
  final List<String> _certificateImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _cropCategories = [
    'Grains',
    'Vegetables',
    'Fruits',
    'Pulses',
    'Spices',
    'Cash Crops',
  ];
  final List<String> _units = ['Kg', 'Quintal', 'Ton', 'Pieces', 'Bundles'];
  final List<String> _growingMethods = [
    'Conventional',
    'Organic',
    'Hydroponic',
    'Greenhouse',
  ];
  final List<String> _harvestMethods = [
    'Manual',
    'Mechanical',
    'Semi-Mechanical',
  ];
  final List<String> _qualityGrades = ['A', 'B', 'C', 'Premium', 'Standard'];
  final List<String> _certificationTypes = [
    'Organic',
    'Fair Trade',
    'GlobalGAP',
    'FSSAI',
    'ISO',
  ];

  @override
  void dispose() {
    _cropNameController.dispose();
    _varietyController.dispose();
    _quantityController.dispose();
    _farmLocationController.dispose();
    _farmSizeController.dispose();
    _seedSourceController.dispose();
    _fertilizersController.dispose();
    _pesticidesController.dispose();
    _irrigationMethodController.dispose();
    _soilTypeController.dispose();
    _weatherConditionsController.dispose();
    _harvestQuantityController.dispose();
    _gradeController.dispose();
    _moistureContentController.dispose();
    _storageConditionsController.dispose();
    _packagingDetailsController.dispose();
    _expectedShelfLifeController.dispose();
    _certificationBodyController.dispose();
    _certificateNumberController.dispose();
    _testingLabController.dispose();
    _labReportNumberController.dispose();
    _nutritionalValueController.dispose();
    _contaminantLevelsController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mint Crop NFT'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildCropDetailsStep(),
                _buildHarvestDataStep(),
                _buildQualityAssuranceStep(),
                _buildDocumentUploadStep(),
                _buildReviewStep(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(5, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 4,
              decoration: BoxDecoration(
                color: index <= _currentStep
                    ? AppTheme.primaryGreen
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCropDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crop Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _cropNameController,
              label: 'Crop Name',
              hint: 'Enter crop name (e.g., Rice, Wheat, Tomato)',
              validator: (value) =>
                  value?.isEmpty == true ? 'Crop name is required' : null,
            ),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _varietyController,
                    label: 'Variety',
                    hint: 'Crop variety',
                    validator: (value) =>
                        value?.isEmpty == true ? 'Variety is required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Category',
                    value: _selectedCropCategory,
                    items: _cropCategories,
                    onChanged: (value) =>
                        setState(() => _selectedCropCategory = value!),
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _quantityController,
                    label: 'Quantity',
                    hint: 'Total quantity',
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Quantity is required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Unit',
                    value: _selectedUnit,
                    items: _units,
                    onChanged: (value) =>
                        setState(() => _selectedUnit = value!),
                  ),
                ),
              ],
            ),

            _buildTextField(
              controller: _farmLocationController,
              label: 'Farm Location',
              hint: 'Complete farm address',
              validator: (value) =>
                  value?.isEmpty == true ? 'Farm location is required' : null,
            ),

            _buildTextField(
              controller: _farmSizeController,
              label: 'Farm Size (Acres)',
              hint: 'Size of farm in acres',
              keyboardType: TextInputType.number,
              validator: (value) =>
                  value?.isEmpty == true ? 'Farm size is required' : null,
            ),

            _buildDateField(
              label: 'Planting Date',
              selectedDate: _plantingDate,
              onDateSelected: (date) => setState(() => _plantingDate = date),
            ),

            _buildDropdown(
              label: 'Growing Method',
              value: _selectedGrowingMethod,
              items: _growingMethods,
              onChanged: (value) =>
                  setState(() => _selectedGrowingMethod = value!),
            ),

            _buildTextField(
              controller: _seedSourceController,
              label: 'Seed Source',
              hint: 'Source of seeds used',
            ),

            _buildTextField(
              controller: _fertilizersController,
              label: 'Fertilizers Used',
              hint: 'List of fertilizers (comma separated)',
              maxLines: 2,
            ),

            _buildTextField(
              controller: _pesticidesController,
              label: 'Pesticides Used',
              hint: 'List of pesticides (comma separated)',
              maxLines: 2,
            ),

            _buildTextField(
              controller: _irrigationMethodController,
              label: 'Irrigation Method',
              hint: 'Method of irrigation used',
            ),

            _buildTextField(
              controller: _soilTypeController,
              label: 'Soil Type',
              hint: 'Type of soil (e.g., Clay, Sandy, Loamy)',
            ),

            _buildTextField(
              controller: _weatherConditionsController,
              label: 'Weather Conditions',
              hint: 'Weather conditions during growing period',
              maxLines: 2,
            ),

            SwitchListTile(
              title: const Text('Organic Crop'),
              subtitle: const Text('Is this an organically grown crop?'),
              value: _isOrganic,
              onChanged: (value) => setState(() => _isOrganic = value),
              activeThumbColor: AppTheme.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHarvestDataStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Harvest Data',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildDateField(
            label: 'Harvest Date',
            selectedDate: _harvestDate,
            onDateSelected: (date) => setState(() => _harvestDate = date),
          ),

          _buildTextField(
            controller: _harvestQuantityController,
            label: 'Harvest Quantity',
            hint: 'Actual harvested quantity',
            keyboardType: TextInputType.number,
            validator: (value) =>
                value?.isEmpty == true ? 'Harvest quantity is required' : null,
          ),

          _buildDropdown(
            label: 'Harvest Method',
            value: _selectedHarvestMethod,
            items: _harvestMethods,
            onChanged: (value) =>
                setState(() => _selectedHarvestMethod = value!),
          ),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _gradeController,
                  label: 'Grade',
                  hint: 'Quality grade',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Quality Grade',
                  value: _selectedQualityGrade,
                  items: _qualityGrades,
                  onChanged: (value) =>
                      setState(() => _selectedQualityGrade = value!),
                ),
              ),
            ],
          ),

          _buildTextField(
            controller: _moistureContentController,
            label: 'Moisture Content (%)',
            hint: 'Moisture content percentage',
            keyboardType: TextInputType.number,
          ),

          _buildTextField(
            controller: _storageConditionsController,
            label: 'Storage Conditions',
            hint: 'Current storage conditions',
            maxLines: 2,
          ),

          _buildTextField(
            controller: _packagingDetailsController,
            label: 'Packaging Details',
            hint: 'Type of packaging used',
          ),

          _buildTextField(
            controller: _expectedShelfLifeController,
            label: 'Expected Shelf Life (Days)',
            hint: 'Expected shelf life in days',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildQualityAssuranceStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quality Assurance',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Has Quality Tests'),
            subtitle: const Text('Have quality tests been conducted?'),
            value: _hasQualityTests,
            onChanged: (value) => setState(() => _hasQualityTests = value),
            activeThumbColor: AppTheme.primaryGreen,
          ),

          if (_hasQualityTests) ...[
            _buildTextField(
              controller: _testingLabController,
              label: 'Testing Laboratory',
              hint: 'Name of testing laboratory',
              validator: (value) => _hasQualityTests && (value?.isEmpty == true)
                  ? 'Testing lab is required'
                  : null,
            ),

            _buildTextField(
              controller: _labReportNumberController,
              label: 'Lab Report Number',
              hint: 'Laboratory report number',
              validator: (value) => _hasQualityTests && (value?.isEmpty == true)
                  ? 'Lab report number is required'
                  : null,
            ),

            _buildDateField(
              label: 'Testing Date',
              selectedDate: _testingDate,
              onDateSelected: (date) => setState(() => _testingDate = date),
            ),

            _buildTextField(
              controller: _nutritionalValueController,
              label: 'Nutritional Value',
              hint: 'Key nutritional components (comma separated)',
              maxLines: 3,
            ),

            _buildTextField(
              controller: _contaminantLevelsController,
              label: 'Contaminant Levels',
              hint: 'Pesticide residue and contaminant levels',
              maxLines: 2,
            ),
          ],

          _buildTextField(
            controller: _certificationBodyController,
            label: 'Certification Body',
            hint: 'Name of certification body',
          ),

          _buildDropdown(
            label: 'Certification Type',
            value: _selectedCertificationType,
            items: _certificationTypes,
            onChanged: (value) =>
                setState(() => _selectedCertificationType = value!),
          ),

          _buildTextField(
            controller: _certificateNumberController,
            label: 'Certificate Number',
            hint: 'Certification number',
          ),

          _buildDateField(
            label: 'Certification Date',
            selectedDate: _certificationDate,
            onDateSelected: (date) => setState(() => _certificationDate = date),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Documents',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Crop Images Section
          const Text(
            'Crop Images',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          ElevatedButton.icon(
            onPressed: () => _pickImages(true),
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Add Crop Photos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),

          const SizedBox(height: 16),

          if (_cropImages.isNotEmpty) ...[
            const Text(
              'Crop Photos:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            _buildImageGrid(_cropImages, true),
            const SizedBox(height: 24),
          ],

          // Certificate Images Section
          const Text(
            'Certificates & Reports',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          const Text(
            'Upload quality certificates, lab reports, and organic certifications:',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          ElevatedButton.icon(
            onPressed: () => _pickImages(false),
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Add Certificates'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),

          const SizedBox(height: 16),

          if (_certificateImages.isNotEmpty) ...[
            const Text(
              'Certificates:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            _buildImageGrid(_certificateImages, false),
          ],
        ],
      ),
    );
  }

  Widget _buildImageGrid(List<String> images, bool isCropImages) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: kIsWeb
                    ? Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Image.file(
                        File(images[index]),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index, isCropImages),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review & Mint NFT',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildReviewSection('Crop Information', [
            'Crop: ${_cropNameController.text}',
            'Variety: ${_varietyController.text}',
            'Category: $_selectedCropCategory',
            'Quantity: ${_quantityController.text} $_selectedUnit',
            'Farm Location: ${_farmLocationController.text}',
            'Growing Method: $_selectedGrowingMethod',
            'Organic: ${_isOrganic ? "Yes" : "No"}',
          ]),

          _buildReviewSection('Harvest Details', [
            'Harvest Date: ${_harvestDate.toLocal().toString().split(' ')[0]}',
            'Harvest Quantity: ${_harvestQuantityController.text}',
            'Harvest Method: $_selectedHarvestMethod',
            'Quality Grade: $_selectedQualityGrade',
            'Moisture Content: ${_moistureContentController.text}%',
          ]),

          _buildReviewSection('Quality Assurance', [
            'Has Quality Tests: ${_hasQualityTests ? "Yes" : "No"}',
            if (_hasQualityTests) 'Testing Lab: ${_testingLabController.text}',
            if (_hasQualityTests)
              'Lab Report: ${_labReportNumberController.text}',
            'Certification Type: $_selectedCertificationType',
            'Certificate Number: ${_certificateNumberController.text}',
          ]),

          _buildReviewSection('Documents', [
            'Crop Photos: ${_cropImages.length}',
            'Certificates: ${_certificateImages.length}',
          ]),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: const Column(
              children: [
                Icon(Icons.agriculture, color: AppTheme.primaryGreen, size: 32),
                SizedBox(height: 8),
                Text(
                  'Crop NFT Minting',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your crop will be tokenized as an NFT on the blockchain, providing immutable proof of quality and enabling it to be used as collateral for microloans.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.darkGreen, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...items
              .where((item) => item.isNotEmpty)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(item, style: const TextStyle(fontSize: 14)),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.primaryGreen),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.primaryGreen),
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime selectedDate,
    required void Function(DateTime) onDateSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            onDateSelected(date);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryGreen),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(selectedDate.toLocal().toString().split(' ')[0]),
              const Icon(Icons.calendar_today),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Previous'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep == 4 ? _mintCropNFT : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isMinting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_currentStep == 4 ? 'Mint NFT' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 4) {
      if (_validateCurrentStep()) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _formKey.currentState?.validate() ?? false;
      case 1:
        return _harvestQuantityController.text.isNotEmpty;
      case 2:
        if (_hasQualityTests) {
          return _testingLabController.text.isNotEmpty &&
              _labReportNumberController.text.isNotEmpty;
        }
        return true;
      case 3:
        if (_cropImages.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please upload at least one crop photo'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _pickImages(bool isCropImages) async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        if (isCropImages) {
          _cropImages.addAll(images.map((image) => image.path));
        } else {
          _certificateImages.addAll(images.map((image) => image.path));
        }
      });
    }
  }

  void _removeImage(int index, bool isCropImages) {
    setState(() {
      if (isCropImages) {
        _cropImages.removeAt(index);
      } else {
        _certificateImages.removeAt(index);
      }
    });
  }

  Future<void> _mintCropNFT() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isMinting = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final user = appState.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create crop details
      final cropDetails = CropDetails(
        cropName: _cropNameController.text,
        variety: _varietyController.text,
        category: _selectedCropCategory,
        farmLocation: _farmLocationController.text,
        farmingMethod: _selectedGrowingMethod,
        plantingDate: _plantingDate,
        seedSource: _seedSourceController.text,
        fertilizersUsed: _fertilizersController.text
            .split(',')
            .map((e) => e.trim())
            .toList(),
        pesticidesUsed: _pesticidesController.text
            .split(',')
            .map((e) => e.trim())
            .toList(),
        irrigationMethod: _irrigationMethodController.text,
        farmAreaUsed: double.parse(_farmSizeController.text),
        soilType: _soilTypeController.text,
        weatherConditions: {'description': _weatherConditionsController.text},
      );

      // Create harvest data
      final harvestData = HarvestData(
        harvestDate: _harvestDate,
        quantity: double.parse(_harvestQuantityController.text),
        unit: _selectedUnit,
        yieldPerAcre: double.tryParse(_farmSizeController.text) != null
            ? double.parse(_harvestQuantityController.text) /
                  double.parse(_farmSizeController.text)
            : 0.0,
        estimatedValue: 0.0, // Will be calculated based on market rates
        storageLocation: _storageConditionsController.text,
        storageMethod: _selectedHarvestMethod,
        expiryDate: DateTime.now().add(
          Duration(days: int.tryParse(_expectedShelfLifeController.text) ?? 30),
        ),
        harvestImages: [],
        nutritionalInfo: {
          'moistureContent':
              double.tryParse(_moistureContentController.text) ?? 0.0,
          'grade': _gradeController.text,
          'qualityGrade': _selectedQualityGrade,
        },
        harvestConditions: _packagingDetailsController.text,
      );

      // Create quality assurance
      final qualityAssurance = QualityAssurance(
        qualityGrade: _selectedQualityGrade,
        isOrganicCertified: _selectedCertificationType == 'Organic',
        organicCertificationBody: _certificationBodyController.text.isNotEmpty
            ? _certificationBodyController.text
            : null,
        organicCertificateNumber: _certificateNumberController.text.isNotEmpty
            ? _certificateNumberController.text
            : null,
        qualityTests: [], // Will be populated by NFT service
        thirdPartyInspection: _hasQualityTests ? 'Yes' : null,
        inspectionDate: _hasQualityTests ? _testingDate : null,
        inspectorName: _hasQualityTests ? _testingLabController.text : null,
        certificationDocuments: [],
        labResults: {},
        pesticideResidueTest: false,
        heavyMetalTest: false,
        microbiologyTest: false,
      );

      // Mint the NFT
      final result = await NFTService.mintCropNFT(
        ownerFirebaseUid: user.id,
        ownerName: user.name,
        ownerAddress:
            user.walletAddress ?? '0x${user.name.hashCode.toRadixString(16)}',
        cropDetails: cropDetails,
        harvestData: harvestData,
        qualityAssurance: qualityAssurance,
        cropImages: [..._cropImages, ..._certificateImages],
      );

      if (result['success']) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Crop NFT minted successfully! Token ID: ${result['tokenId']}',
              ),
              backgroundColor: AppTheme.primaryGreen,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error minting NFT: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMinting = false);
      }
    }
  }
}
