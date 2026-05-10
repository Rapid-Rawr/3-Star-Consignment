import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'utils/theme_notifier.dart';
import 'utils/supabase_service.dart';
import 'widgets/login_drawer.dart';
import 'views/tabbar/beranda_page.dart';
import 'views/tabbar/pembayaran_page.dart';
import 'views/tabbar/barang_page.dart';
import 'views/tabbar/pengguna_page.dart';
import 'widgets/custom_bottom_nav.dart';
import 'package:provider/provider.dart';
import '../service/auth_provider.dart' as local;
import '../service/roles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint(
      'Warning: .env file not found or failed to load. Supabase features may be unavailable.',
    );
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final supabaseUrl = dotenv.env['PROJECT_URL'];
  final supabaseAnonKey = dotenv.env['ANON_KEY'];

  if (supabaseUrl != null &&
      supabaseAnonKey != null &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty) {
    try {
      await SupabaseService.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Warning: Failed to initialize Supabase: $e');
    }
  } else {
    debugPrint(
      'Warning: Supabase keys are missing, skipping Supabase intialization.',
    );
  }

  final authProvider = local.AuthProvider();
  await authProvider.init();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => authProvider)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: 'Star Consignment',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1D1B20),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Poppins',
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1D1B20),
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1D1B20),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Poppins',
          scaffoldBackgroundColor: const Color(0xFF1D1B20),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1D1B20),
            foregroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthController _auth = AuthController.instance;

  User? _currentUser;
  StreamSubscription<User?>? _authSubscription;
  bool _isSigningIn = false;
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
    _auth.init();
    _authSubscription = _auth.authStateChanges.listen((user) {
      if (mounted) setState(() => _currentUser = user);
      if (user != null) _auth.syncPhotoUrl(user);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _showLoginRequiredDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Login Required',
      barrierColor: Colors.black.withOpacity(0.2),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 40,
                        color: Colors.orange,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Login Diperlukan',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Anda harus login terlebih dahulu untuk mengakses fitur ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);

                          Future.delayed(const Duration(milliseconds: 200), () {
                            _scaffoldKey.currentState?.openEndDrawer();
                          });
                        },
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Login Sekarang'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
    );
  }

  void _updateTabController(int newLength) {
    if (_tabController.length != newLength) {
      _tabController.dispose();

      _currentTabIndex = 0; // reset biar aman

      _tabController = TabController(length: newLength, vsync: this);

      _tabController.addListener(() {
        if (!_tabController.indexIsChanging && mounted) {
          setState(() => _currentTabIndex = _tabController.index);
        }
      });
    }
  }

  List<Widget> getPages(bool isAdmin) {
    return isAdmin
        ? const [HomePage(), PaymentPage(), ItemPage(), UserPage()]
        : const [HomePage(), PaymentPage(), ItemPage()];
  }

  List<String> getTitles(bool isAdmin) {
    return isAdmin
        ? ['Beranda', 'Transaksi', 'Barang', 'Pengguna']
        : ['Beranda', 'Transaksi', 'Barang'];
  }

  List<CustomBottomNavItem> getNavItems(bool isAdmin) {
    return [
      const CustomBottomNavItem(
        iconSvg: 'assets/icons/Home Outlined.svg',
        activeIconSvg: 'assets/icons/Home Filled.svg',
        activeIconSize: 30,
      ),
      const CustomBottomNavItem(
        iconSvg: 'assets/icons/Payment Outline.svg',
        activeIconSvg: 'assets/icons/Payment Filled.svg',
        activeIconSize: 30,
      ),
      const CustomBottomNavItem(
        iconSvg: 'assets/icons/Shelves Outlined.svg',
        activeIconSvg: 'assets/icons/Shelves Filled.svg',
        iconSize: 24,
        activeIconSize: 26,
      ),
      if (isAdmin)
        const CustomBottomNavItem(
          icon: Icons.group_outlined,
          activeIcon: Icons.group_rounded,
          activeIconSize: 30,
        ),
    ];
  }

  Future<void> _handleSignIn() async {
    setState(() => _isSigningIn = true);
    await _auth.signInWithGoogle(context);
    if (mounted) {
      setState(() => _isSigningIn = false);
      if (FirebaseAuth.instance.currentUser != null) {
        _scaffoldKey.currentState?.closeEndDrawer();
        final name =
            FirebaseAuth.instance.currentUser?.displayName ?? 'Pengguna';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anda berhasil masuk sebagai $name'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    await _auth.signOut(context);
    if (mounted) {
      setState(() {
        _currentTabIndex = 0;
      });

      _tabController.animateTo(0);

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _showLoginRequiredDialog();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<local.AuthProvider>().role;
    final isAdmin = role == Roles.admin;

    final pages = getPages(isAdmin);
    final titles = getTitles(isAdmin);
    final navItems = getNavItems(isAdmin);

    if (_currentTabIndex >= pages.length) {
      _currentTabIndex = 0;
    }

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
    _updateTabController(pages.length);

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      appBar: AppBar(
        title: Text(titles[_currentTabIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: LoginDrawer(
        currentUser: _currentUser,
        isSigningIn: _isSigningIn,
        onSignIn: _handleSignIn,
        onSignOut: _handleSignOut,
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentTabIndex,
        onTap: (i) {
          final user = FirebaseAuth.instance.currentUser;

          // Beranda boleh diakses tanpa login
          if (i != 0 && user == null) {
            _showLoginRequiredDialog();
            return;
          }

          setState(() => _currentTabIndex = i);
          _tabController.animateTo(i);
        },
        items: navItems,
      ),
      body: TabBarView(controller: _tabController, children: pages),
    );
  }
}
