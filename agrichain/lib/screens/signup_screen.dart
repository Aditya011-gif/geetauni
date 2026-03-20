import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../services/security_service.dart';
import '../models/firestore_models.dart';
import 'profile_setup_screen.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Form Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();

  // State Variables
  UserType _selectedUserType = UserType.farmer;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _agreeToPrivacy = false;
  int _currentStep = 0;

  // KYC State
  bool _isKycVerified = false;
  bool _isKycInProgress = false;
  String? _kycStatus;

  // Signature State
  XFile? _signatureImage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms || !_agreeToPrivacy) {
      _showErrorSnackBar('Please accept the terms and privacy policy');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🚀 Starting user registration...');

      // Create Firebase user account
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (userCredential.user != null) {
        debugPrint('✅ Firebase Auth user created: ${userCredential.user!.uid}');

        // Update Firebase user display name
        await userCredential.user!.updateDisplayName(
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        );
        debugPrint('✅ Display name updated');

        // Create user document in Firestore immediately
        final userData = {
          'id': userCredential.user!.uid,
          'firebaseUid': userCredential.user!.uid,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'name':
              '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'userType': _selectedUserType.name,
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'walletAddress': '', // Will be generated later
          'walletBalance': 0.0,
          'signatureUrl': null, // Will be updated later
          'metadata': <String, dynamic>{},
        };

        debugPrint('📝 Creating user document in Firestore...');
        final created = await DatabaseService().createUser(userData);
        if (created) {
          debugPrint('✅ User document created successfully in Firestore');
        } else {
          debugPrint('❌ Failed to create user document in Firestore');
          throw Exception('Failed to create user document');
        }

        // Create KYC data if provided
        if (_aadhaarController.text.isNotEmpty ||
            _panController.text.isNotEmpty) {
          final kycData = {
            'id':
                'kyc_${userCredential.user!.uid}_${DateTime.now().millisecondsSinceEpoch}',
            'userId': userCredential.user!.uid,
            'aadhaarNumber': _aadhaarController.text.trim(),
            'panNumber': _panController.text.trim(),
            'kycStatus': _isKycVerified ? 'pending' : 'incomplete',
            'kycData': '',
            'aadhaarVerified': 0,
            'panVerified': 0,
            'digiLockerVerified': 0,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          };
          await DatabaseService().createKycData(kycData);
        }

        // Upload Signature if present (in background/non-blocking for account creation)
        if (_signatureImage != null) {
          debugPrint('📤 Uploading signature...');
          try {
            final ref = FirebaseStorage.instance
                .ref()
                .child('signatures')
                .child('${userCredential.user!.uid}.jpg');

            if (kIsWeb) {
              await ref.putData(await _signatureImage!.readAsBytes());
            } else {
              await ref.putFile(File(_signatureImage!.path));
            }

            final signatureUrl = await ref.getDownloadURL();
            debugPrint('✅ Signature uploaded: $signatureUrl');

            // Update user document with signature URL
            await DatabaseService().updateUser(userCredential.user!.uid, {
              'signatureUrl': signatureUrl,
              'updatedAt': DateTime.now().toIso8601String(),
            });
            debugPrint('✅ User document updated with signature URL');
          } catch (e) {
            debugPrint('❌ Signature upload failed: $e');
            // Continue with signup even if signature upload fails
            _showErrorSnackBar(
              'Signature upload failed, but account created. You can update it later in profile.',
            );
          }
        }

        // Log successful registration
        final securityService = SecurityService();
        await securityService.logSecurityEvent(
          userId: userCredential.user!.uid,
          event: 'user_registered',
          details: {
            'email': _emailController.text.trim(),
            'user_type': _selectedUserType.name,
            'kyc_provided':
                (_aadhaarController.text.isNotEmpty ||
                        _panController.text.isNotEmpty)
                    .toString(),
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        // Navigate to profile setup
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileSetupScreen(
                userId: userCredential.user!.uid,
                userType: _selectedUserType,
                userName:
                    '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
                userEmail: _emailController.text.trim(),
                userPassword: _passwordController.text,
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists for this email.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address format.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        default:
          errorMessage = 'Registration failed. Please try again.';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('An error occurred during sign up');
      debugPrint('Signup error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initiateKycVerification() async {
    if (_aadhaarController.text.length != 12) {
      _showErrorSnackBar('Please enter a valid 12-digit Aadhaar number');
      return;
    }

    // For now, just validate the format and mark as ready for KYC
    // Actual KYC verification will happen after user creation
    setState(() {
      _isKycInProgress = true;
    });

    // Simulate validation delay
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Basic format validation
      if (_aadhaarController.text.length == 12 &&
          _panController.text.length == 10) {
        setState(() {
          _isKycVerified = true;
          _kycStatus = 'Ready for Verification';
        });
        _showSuccessSnackBar(
          'Documents validated. KYC will be completed after account creation.',
        );
      } else {
        setState(() {
          _kycStatus = 'Invalid Format';
        });
        _showErrorSnackBar('Please check your Aadhaar and PAN number format');
      }
    } catch (e) {
      setState(() {
        _kycStatus = 'Failed';
      });
      _showErrorSnackBar('Document validation error occurred');
    } finally {
      setState(() {
        _isKycInProgress = false;
      });
    }
  }

  Future<void> _pickSignatureImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1024,
      );

      if (image != null) {
        setState(() {
          _signatureImage = image;
        });
      }
    } catch (e) {
      debugPrint('Error picking signature: $e');
      _showErrorSnackBar('Failed to pick instance image');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Progress Indicator
              _buildProgressIndicator(),

              // Form Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildBasicInfoStep(),
                        _buildKycStep(),
                        _buildAccountStep(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Join AgriChain Community',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: index <= _currentStep
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGreen,
            ),
          ),
          const SizedBox(height: 20),

          // User Type Selection
          const Text(
            'I am a',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkGreen,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildUserTypeCard(
                  userType: UserType.farmer,
                  title: 'Farmer/Seller',
                  subtitle: 'Sell crops & get loans',
                  icon: Icons.agriculture,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUserTypeCard(
                  userType: UserType.buyer,
                  title: 'Buyer/Lender',
                  subtitle: 'Buy crops & provide loans',
                  icon: Icons.shopping_cart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Name Fields
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: _buildInputDecoration('First Name', Icons.person),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'First name is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: _buildInputDecoration(
                    'Last Name',
                    Icons.person_outline,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Last name is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _buildInputDecoration('Email Address', Icons.email),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Phone Field
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _buildInputDecoration('Phone Number', Icons.phone),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone number is required';
              }
              if (value.length != 10) {
                return 'Please enter a valid 10-digit phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Next Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_validateBasicInfo()) {
                  _nextStep();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue to KYC',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKycStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KYC Verification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Verify your identity using Digi Locker for secure transactions',
            style: TextStyle(fontSize: 14, color: AppTheme.grey),
          ),
          const SizedBox(height: 24),

          // Aadhaar Number
          TextFormField(
            controller: _aadhaarController,
            keyboardType: TextInputType.number,
            decoration: _buildInputDecoration(
              'Aadhaar Number',
              Icons.credit_card,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Aadhaar number is required';
              }
              if (value.length != 12) {
                return 'Please enter a valid 12-digit Aadhaar number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // PAN Number
          TextFormField(
            controller: _panController,
            decoration: _buildInputDecoration(
              'PAN Number',
              Icons.account_balance_wallet,
            ),
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              LengthLimitingTextInputFormatter(10),
              FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'PAN number is required';
              }
              if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value)) {
                return 'Please enter a valid PAN number';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // KYC Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getKycStatusColor().withValues(alpha: 0.1),
              border: Border.all(color: _getKycStatusColor()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  _getKycStatusIcon(),
                  color: _getKycStatusColor(),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  _getKycStatusText(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getKycStatusColor(),
                  ),
                ),
                if (_kycStatus != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _kycStatus!,
                    style: TextStyle(fontSize: 14, color: AppTheme.grey),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // KYC Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isKycInProgress || _isKycVerified
                  ? null
                  : _initiateKycVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isKycVerified
                    ? AppTheme.primaryGreen
                    : AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isKycInProgress
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _isKycVerified
                          ? 'KYC Verified ✓'
                          : 'Verify with Digi Locker',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Signature Upload Section
          const Text(
            'Digital Signature',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                if (_signatureImage != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network(
                            _signatureImage!.path,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.contain,
                          )
                        : Image.file(
                            File(_signatureImage!.path),
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickSignatureImage,
                    icon: const Icon(Icons.edit, color: AppTheme.primaryGreen),
                    label: const Text('Change Signature'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: const BorderSide(color: AppTheme.primaryGreen),
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.draw, size: 48, color: AppTheme.grey),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload your signature for contracts',
                    style: TextStyle(color: AppTheme.grey),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickSignatureImage,
                    icon: const Icon(
                      Icons.upload,
                      color: AppTheme.primaryGreen,
                    ),
                    label: const Text('Upload Signature'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: const BorderSide(color: AppTheme.primaryGreen),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Navigation Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isKycVerified ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Security',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a secure password for your account',
            style: TextStyle(fontSize: 14, color: AppTheme.grey),
          ),
          const SizedBox(height: 24),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: _buildInputDecoration('Password', Icons.lock).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                return 'Password must contain uppercase, lowercase, and number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration:
                _buildInputDecoration(
                  'Confirm Password',
                  Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Terms and Privacy Checkboxes
          CheckboxListTile(
            value: _agreeToTerms,
            onChanged: (value) {
              setState(() {
                _agreeToTerms = value ?? false;
              });
            },
            title: const Text(
              'I agree to the Terms of Service',
              style: TextStyle(fontSize: 14),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppTheme.primaryGreen,
          ),
          CheckboxListTile(
            value: _agreeToPrivacy,
            onChanged: (value) {
              setState(() {
                _agreeToPrivacy = value ?? false;
              });
            },
            title: const Text(
              'I agree to the Privacy Policy',
              style: TextStyle(fontSize: 14),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 24),

          // Create Account Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Back Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Back',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Login Link
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text(
                'Already have an account? Login here',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeCard({
    required UserType userType,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedUserType == userType;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUserType = userType;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withValues(alpha: 0.1)
              : Colors.grey[50],
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppTheme.primaryGreen : AppTheme.grey,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.darkGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

  bool _validateBasicInfo() {
    return _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        RegExp(
          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
        ).hasMatch(_emailController.text) &&
        _phoneController.text.length == 10;
  }

  Color _getKycStatusColor() {
    if (_isKycVerified) return AppTheme.primaryGreen;
    if (_kycStatus == 'Failed') return Colors.red;
    return AppTheme.grey;
  }

  IconData _getKycStatusIcon() {
    if (_isKycVerified) return Icons.verified_user;
    if (_kycStatus == 'Failed') return Icons.error;
    return Icons.security;
  }

  String _getKycStatusText() {
    if (_isKycVerified) return 'Documents Validated';
    if (_kycStatus == 'Failed' || _kycStatus == 'Invalid Format')
      return 'Invalid Documents';
    return 'KYC Pending';
  }
}
