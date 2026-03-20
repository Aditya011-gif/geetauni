import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/land_nft.dart';
import '../services/nft_service.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class MintLandNFTScreen extends StatefulWidget {
  const MintLandNFTScreen({super.key});

  @override
  State<MintLandNFTScreen> createState() => _MintLandNFTScreenState();
}

class _MintLandNFTScreenState extends State<MintLandNFTScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isMinting = false;

  // Land Details Controllers
  final _addressController = TextEditingController();
  final _surveyNumberController = TextEditingController();
  final _subDivisionController = TextEditingController();
  final _villageController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _areaController = TextEditingController();
  final _soilTypeController = TextEditingController();
  final _waterSourceController = TextEditingController();
  final _landUseController = TextEditingController();
  final _accessRoadController = TextEditingController();
  final _boundariesController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  // Legal Documents Controllers
  final _registrationNumberController = TextEditingController();
  final _registrarOfficeController = TextEditingController();
  final _previousOwnersController = TextEditingController();

  // Valuation Controllers
  final _currentValueController = TextEditingController();
  final _marketRateController = TextEditingController();
  final _guidanceValueController = TextEditingController();
  final _valuedByController = TextEditingController();

  // Dropdown values
  String _selectedLandType = 'Agricultural';
  String _selectedOwnershipType = 'Freehold';
  String _selectedValuationMethod = 'Market';
  bool _hasIrrigation = false;
  bool _hasLegalDisputes = false;
  bool _isEncumbered = false;
  DateTime _registrationDate = DateTime.now();
  DateTime _valuationDate = DateTime.now();

  // Document images
  final List<String> _documentImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _landTypes = [
    'Agricultural',
    'Residential',
    'Commercial',
    'Industrial',
  ];
  final List<String> _ownershipTypes = ['Freehold', 'Leasehold', 'Joint'];
  final List<String> _valuationMethods = ['Market', 'Income', 'Cost'];

  @override
  void dispose() {
    _addressController.dispose();
    _surveyNumberController.dispose();
    _subDivisionController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _areaController.dispose();
    _soilTypeController.dispose();
    _waterSourceController.dispose();
    _landUseController.dispose();
    _accessRoadController.dispose();
    _boundariesController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _registrationNumberController.dispose();
    _registrarOfficeController.dispose();
    _previousOwnersController.dispose();
    _currentValueController.dispose();
    _marketRateController.dispose();
    _guidanceValueController.dispose();
    _valuedByController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mint Land NFT'),
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
                _buildLandDetailsStep(),
                _buildLegalDocumentsStep(),
                _buildValuationStep(),
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

  Widget _buildLandDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Land Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _addressController,
              label: 'Property Address',
              hint: 'Enter complete property address',
              validator: (value) =>
                  value?.isEmpty == true ? 'Address is required' : null,
            ),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _surveyNumberController,
                    label: 'Survey Number',
                    hint: 'Survey No.',
                    validator: (value) => value?.isEmpty == true
                        ? 'Survey number is required'
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _subDivisionController,
                    label: 'Sub Division',
                    hint: 'Sub Division',
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _villageController,
                    label: 'Village',
                    hint: 'Village name',
                    validator: (value) =>
                        value?.isEmpty == true ? 'Village is required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _districtController,
                    label: 'District',
                    hint: 'District name',
                    validator: (value) =>
                        value?.isEmpty == true ? 'District is required' : null,
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _stateController,
                    label: 'State',
                    hint: 'State name',
                    validator: (value) =>
                        value?.isEmpty == true ? 'State is required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _pincodeController,
                    label: 'Pincode',
                    hint: 'PIN Code',
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Pincode is required' : null,
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _areaController,
                    label: 'Area (Acres)',
                    hint: 'Land area in acres',
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Area is required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Land Type',
                    value: _selectedLandType,
                    items: _landTypes,
                    onChanged: (value) =>
                        setState(() => _selectedLandType = value!),
                  ),
                ),
              ],
            ),

            _buildTextField(
              controller: _soilTypeController,
              label: 'Soil Type',
              hint: 'Type of soil (e.g., Clay, Sandy, Loamy)',
            ),

            _buildTextField(
              controller: _waterSourceController,
              label: 'Water Source',
              hint: 'Primary water source (e.g., Borewell, Canal, River)',
            ),

            _buildTextField(
              controller: _landUseController,
              label: 'Current Land Use',
              hint: 'How the land is currently being used',
            ),

            _buildTextField(
              controller: _accessRoadController,
              label: 'Access Road',
              hint: 'Type of road access (e.g., Paved, Gravel, Dirt)',
            ),

            _buildTextField(
              controller: _boundariesController,
              label: 'Boundaries',
              hint: 'Describe property boundaries (comma separated)',
              maxLines: 3,
            ),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _latitudeController,
                    label: 'Latitude',
                    hint: 'GPS Latitude',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _longitudeController,
                    label: 'Longitude',
                    hint: 'GPS Longitude',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            SwitchListTile(
              title: const Text('Has Irrigation'),
              subtitle: const Text('Does the land have irrigation facilities?'),
              value: _hasIrrigation,
              onChanged: (value) => setState(() => _hasIrrigation = value),
              activeThumbColor: AppTheme.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalDocumentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legal Documents',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _registrationNumberController,
            label: 'Registration Number',
            hint: 'Property registration number',
            validator: (value) => value?.isEmpty == true
                ? 'Registration number is required'
                : null,
          ),

          _buildDateField(
            label: 'Registration Date',
            selectedDate: _registrationDate,
            onDateSelected: (date) => setState(() => _registrationDate = date),
          ),

          _buildTextField(
            controller: _registrarOfficeController,
            label: 'Registrar Office',
            hint: 'Name of registrar office',
            validator: (value) =>
                value?.isEmpty == true ? 'Registrar office is required' : null,
          ),

          _buildDropdown(
            label: 'Ownership Type',
            value: _selectedOwnershipType,
            items: _ownershipTypes,
            onChanged: (value) =>
                setState(() => _selectedOwnershipType = value!),
          ),

          _buildTextField(
            controller: _previousOwnersController,
            label: 'Previous Owners',
            hint: 'List of previous owners (comma separated)',
            maxLines: 3,
          ),

          SwitchListTile(
            title: const Text('Has Legal Disputes'),
            subtitle: const Text('Are there any ongoing legal disputes?'),
            value: _hasLegalDisputes,
            onChanged: (value) => setState(() => _hasLegalDisputes = value),
            activeThumbColor: AppTheme.primaryGreen,
          ),

          SwitchListTile(
            title: const Text('Is Encumbered'),
            subtitle: const Text('Is the property under any encumbrance?'),
            value: _isEncumbered,
            onChanged: (value) => setState(() => _isEncumbered = value),
            activeThumbColor: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildValuationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Property Valuation',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _currentValueController,
            label: 'Current Market Value (₹)',
            hint: 'Current market value in rupees',
            keyboardType: TextInputType.number,
            validator: (value) =>
                value?.isEmpty == true ? 'Current value is required' : null,
          ),

          _buildDateField(
            label: 'Valuation Date',
            selectedDate: _valuationDate,
            onDateSelected: (date) => setState(() => _valuationDate = date),
          ),

          _buildDropdown(
            label: 'Valuation Method',
            value: _selectedValuationMethod,
            items: _valuationMethods,
            onChanged: (value) =>
                setState(() => _selectedValuationMethod = value!),
          ),

          _buildTextField(
            controller: _valuedByController,
            label: 'Valued By',
            hint: 'Who conducted the valuation',
            validator: (value) => value?.isEmpty == true
                ? 'Valuator information is required'
                : null,
          ),

          _buildTextField(
            controller: _marketRateController,
            label: 'Market Rate per Acre (₹)',
            hint: 'Current market rate per acre',
            keyboardType: TextInputType.number,
          ),

          _buildTextField(
            controller: _guidanceValueController,
            label: 'Government Guidance Value (₹)',
            hint: 'Official government guidance value',
            keyboardType: TextInputType.number,
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

          const Text(
            'Please upload the following documents:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          const Text(
            '• Title Deed\n• Survey Settlement\n• Encumbrance Certificate\n• Property Photos\n• Valuation Certificate',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _pickDocumentImages,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Add Documents'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),

          const SizedBox(height: 16),

          if (_documentImages.isNotEmpty) ...[
            const Text(
              'Selected Documents:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _documentImages.length,
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
                                _documentImages[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Image.file(
                                File(_documentImages[index]),
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
                        onTap: () => _removeDocumentImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
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

          _buildReviewSection('Land Details', [
            'Address: ${_addressController.text}',
            'Survey Number: ${_surveyNumberController.text}',
            'Area: ${_areaController.text} acres',
            'Land Type: $_selectedLandType',
            'Village: ${_villageController.text}',
            'District: ${_districtController.text}',
            'State: ${_stateController.text}',
          ]),

          _buildReviewSection('Legal Information', [
            'Registration Number: ${_registrationNumberController.text}',
            'Registration Date: ${_registrationDate.toLocal().toString().split(' ')[0]}',
            'Ownership Type: $_selectedOwnershipType',
            'Registrar Office: ${_registrarOfficeController.text}',
          ]),

          _buildReviewSection('Valuation', [
            'Current Value: ₹${_currentValueController.text}',
            'Valuation Method: $_selectedValuationMethod',
            'Valued By: ${_valuedByController.text}',
            'Market Rate: ₹${_marketRateController.text}/acre',
          ]),

          _buildReviewSection('Documents', [
            'Total Documents: ${_documentImages.length}',
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
                Icon(Icons.security, color: AppTheme.primaryGreen, size: 32),
                SizedBox(height: 8),
                Text(
                  'NFT Minting',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your land will be tokenized as an NFT on the blockchain, providing immutable proof of ownership and enabling it to be used as collateral for loans.',
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
          ...items.map(
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
            firstDate: DateTime(1900),
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
              onPressed: _currentStep == 4 ? _mintLandNFT : _nextStep,
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
        return _registrationNumberController.text.isNotEmpty &&
            _registrarOfficeController.text.isNotEmpty;
      case 2:
        return _currentValueController.text.isNotEmpty &&
            _valuedByController.text.isNotEmpty;
      case 3:
        if (_documentImages.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please upload at least one document'),
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

  Future<void> _pickDocumentImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _documentImages.addAll(images.map((image) => image.path));
      });
    }
  }

  void _removeDocumentImage(int index) {
    setState(() {
      _documentImages.removeAt(index);
    });
  }

  Future<void> _mintLandNFT() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isMinting = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final user = appState.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create land details
      final landDetails = LandDetails(
        address: _addressController.text,
        surveyNumber: _surveyNumberController.text,
        subDivision: _subDivisionController.text,
        village: _villageController.text,
        district: _districtController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
        areaInAcres: double.parse(_areaController.text),
        landType: _selectedLandType,
        soilType: _soilTypeController.text,
        waterSource: _waterSourceController.text,
        boundaries: _boundariesController.text
            .split(',')
            .map((e) => e.trim())
            .toList(),
        coordinates: GeoLocation(
          latitude: double.tryParse(_latitudeController.text) ?? 0.0,
          longitude: double.tryParse(_longitudeController.text) ?? 0.0,
        ),
        landUse: _landUseController.text,
        hasIrrigation: _hasIrrigation,
        accessRoad: _accessRoadController.text,
      );

      // Create legal documents
      final legalDocuments = LegalDocuments(
        registrationNumber: _registrationNumberController.text,
        registrationDate: _registrationDate,
        registrarOffice: _registrarOfficeController.text,
        ownershipType: _selectedOwnershipType,
        previousOwners: _previousOwnersController.text
            .split(',')
            .map((e) => e.trim())
            .toList(),
        titleDeedHash: '', // Will be set by NFT service
        surveySettlementHash: '', // Will be set by NFT service
        encumbranceCertificateHash: '', // Will be set by NFT service
        hasLegalDisputes: _hasLegalDisputes,
        mortgageDetails: [],
        isEncumbered: _isEncumbered,
      );

      // Create valuation details
      final valuation = ValuationDetails(
        currentValue: double.parse(_currentValueController.text),
        valuationDate: _valuationDate,
        valuationMethod: _selectedValuationMethod,
        valuedBy: _valuedByController.text,
        valuationCertificateHash: '', // Will be set by NFT service
        marketRate: double.tryParse(_marketRateController.text) ?? 0.0,
        guidanceValue: double.tryParse(_guidanceValueController.text) ?? 0.0,
        history: [],
        comparableProperties: {},
      );

      // Mint the NFT
      final result = await NFTService.mintLandNFT(
        ownerFirebaseUid: user.id,
        ownerName: user.name,
        ownerAddress:
            user.walletAddress ?? '0x${user.name.hashCode.toRadixString(16)}',
        landDetails: landDetails,
        legalDocuments: legalDocuments,
        valuation: valuation,
        documentImages: _documentImages,
      );

      if (result['success']) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Land NFT minted successfully! Token ID: ${result['tokenId']}',
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
