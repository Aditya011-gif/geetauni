import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/my_crops_screen.dart';
import 'screens/loans_screen.dart';
import 'screens/marketplace_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/add_crop_screen.dart';
import 'screens/downloads_screen.dart';
import 'providers/app_state.dart';
import 'config/app_initializer.dart';
import 'models/firestore_models.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const AgriChainApp());
}

class AgriChainApp extends StatefulWidget {
  const AgriChainApp({super.key});

  @override
  State<AgriChainApp> createState() => _AgriChainAppState();
}

class _AgriChainAppState extends State<AgriChainApp> {
  bool _isInitialized = false;
  bool _initializationFailed = false;
  String _errorMessage = '';
  bool _isFirstTime = true;
  bool _checkingFirstTime = true;
  final AppInitializer _appInitializer = AppInitializer();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Check if this is the first time opening the app
      await _checkFirstTimeUser();

      final success = await _appInitializer.initialize();
      setState(() {
        _isInitialized = success;
        _initializationFailed = !success;
        _checkingFirstTime = false;
        if (!success) {
          final results = _appInitializer.initializationResults;
          _errorMessage =
              results['error']?.toString() ?? 'Unknown initialization error';
        }
      });
    } catch (e) {
      setState(() {
        _isInitialized = false;
        _initializationFailed = true;
        _checkingFirstTime = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    setState(() {
      _isFirstTime = !hasSeenOnboarding;
    });
  }

  Future<void> _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    setState(() {
      _isFirstTime = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final appState = AppState();
            // Initialize AppState after creation to trigger mock data initialization
            appState.initialize();
            return appState;
          },
        ),
      ],
      child: MaterialApp(
        title: 'AgriChain',
        theme: AppTheme.lightTheme,
        home: _buildHome(),
        debugShowCheckedModeBanner: false,
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/add-crop':
        return MaterialPageRoute(
          builder: (context) => const AddCropScreen(),
          settings: settings,
        );
      default:
        return null;
    }
  }

  Widget _buildHome() {
    if (_initializationFailed) {
      return _buildErrorScreen();
    }

    if (!_isInitialized || _checkingFirstTime) {
      return _buildLoadingScreen();
    }

    // Show onboarding for first-time users
    if (_isFirstTime) {
      return OnboardingScreen(onComplete: _markOnboardingComplete);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is signed in, show main screen
          // Note: AppState._onAuthStateChanged will handle loading user data
          return const MainScreen();
        } else {
          // User is not signed in, show login screen
          return const LoginScreen();
        }
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppTheme.background),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: const Icon(
                  Icons.agriculture,
                  size: 60,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 40),

              // App Name
              Text(
                'AgriChain',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 8),

              // Tagline
              Text(
                'Empowering Agriculture with Blockchain',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 60),

              // Loading Indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),

              // Loading Text
              const Text(
                'Initializing application...',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppTheme.background),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: AppTheme.error,
                  ),
                ),
                const SizedBox(height: 40),

                // Error Title
                Text(
                  'Initialization Failed',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Error Message
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),

                // Retry Button
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isInitialized = false;
                      _initializationFailed = false;
                      _errorMessage = '';
                    });
                    _initializeApp();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Farmer/Seller screens
  final List<Widget> _farmerScreens = [
    const HomeScreen(),
    const MyCropsScreen(),
    const LoansScreen(),
    const MarketplaceScreen(),
    const DownloadsScreen(),
    const ProfileScreen(),
  ];

  // Buyer screens
  final List<Widget> _buyerScreens = [
    const MarketplaceScreen(),
    const WalletScreen(),
    const ProfileScreen(),
    const LoansScreen(),
    const DownloadsScreen(),
    const AnalyticsScreen(),
  ];

  // Farmer/Seller navigation items
  final List<BottomNavigationBarItem> _farmerNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.agriculture_outlined),
      activeIcon: Icon(Icons.agriculture),
      label: 'My Crops',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.account_balance_outlined),
      activeIcon: Icon(Icons.account_balance),
      label: 'Loans',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.shopping_cart_outlined),
      activeIcon: Icon(Icons.shopping_cart),
      label: 'Marketplace',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.description_outlined),
      activeIcon: Icon(Icons.description),
      label: 'Contracts',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  // Buyer navigation items
  final List<BottomNavigationBarItem> _buyerNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.store_outlined),
      activeIcon: Icon(Icons.store),
      label: 'Market',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.account_balance_wallet_outlined),
      activeIcon: Icon(Icons.account_balance_wallet),
      label: 'Wallet',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.account_balance_outlined),
      activeIcon: Icon(Icons.account_balance),
      label: 'Loans',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.description_outlined),
      activeIcon: Icon(Icons.description),
      label: 'Contracts',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.analytics_outlined),
      activeIcon: Icon(Icons.analytics),
      label: 'Analytics',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final user = appState.currentUser;
        final firebaseUser = FirebaseAuth.instance.currentUser;

        // Show loading while user data is being loaded
        if (appState.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            ),
          );
        }

        // If no user data but Firebase user exists, try loading user data
        if (user == null && firebaseUser != null) {
          // Trigger user data loading if not already loading
          if (!appState.isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              appState.loadUserData(firebaseUser.uid);
            });
          }
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryGreen),
                  SizedBox(height: 16),
                  Text(
                    'Loading your profile...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // If no Firebase user, show login message
        if (firebaseUser == null) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 64, color: AppTheme.primaryGreen),
                  SizedBox(height: 16),
                  Text(
                    'Please log in to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // If user data failed to load, show error and redirect to login
        if (user == null && appState.error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(appState.error!),
                backgroundColor: AppTheme.error,
                duration: const Duration(seconds: 3),
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            ),
          );
        }

        final isBuyer = user?.userType == UserType.buyer;
        final screens = isBuyer ? _buyerScreens : _farmerScreens;
        final navItems = isBuyer ? _buyerNavItems : _farmerNavItems;

        // Ensure current index is within bounds
        if (_currentIndex >= screens.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          extendBody: true, // Allow body to scroll behind nav bar
          appBar: AppBar(
            backgroundColor: AppTheme.background,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
            centerTitle: true,
            title: Text(
              _getScreenTitle(isBuyer),
              style: GoogleFonts.outfit(
                // Using Outfit if available, or just TextStyle
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                color: AppTheme.textSecondary,
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  appState.clearUser();
                },
                tooltip: 'Logout',
              ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: screens[_currentIndex],
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(32),
              boxShadow: AppTheme.floatingShadow,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: _onTabTapped,
                    items: navItems,
                    type: BottomNavigationBarType.fixed,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    selectedItemColor: AppTheme.primaryColor,
                    unselectedItemColor: AppTheme.textSecondary,
                    showSelectedLabels: true,
                    showUnselectedLabels: false, // Cleaner look for 6 items
                    selectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      height: 1.5,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 10,
                    ),
                    iconSize: 22,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getScreenTitle(bool isBuyer) {
    if (isBuyer) {
      switch (_currentIndex) {
        case 0:
          return 'Marketplace';
        case 1:
          return 'Wallet';
        case 2:
          return 'Profile';
        case 3:
          return 'Loans';
        case 4:
          return 'Analytics';
        default:
          return 'AgriChain';
      }
    } else {
      switch (_currentIndex) {
        case 0:
          return 'Home';
        case 1:
          return 'My Crops';
        case 2:
          return 'Loans';
        case 3:
          return 'Marketplace';
        case 4:
          return 'Profile';
        default:
          return 'AgriChain';
      }
    }
  }
}
