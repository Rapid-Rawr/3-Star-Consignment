import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'utils/theme_notifier.dart';
import 'utils/supabase_service.dart';
// import 'utils/cleanup_test_data.dart';
import 'widgets/gradient_button.dart';
import 'widgets/app_dialog.dart';
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

  // const bool enableCleanup = false;
  // ignore: unused_local_variable
  // if (enableCleanup) await cleanupTestData();

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
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _auth.init();
    _authSubscription = _auth.authStateChanges.listen((user) {
      if (mounted) setState(() => _currentUser = user);
      if (user != null) _auth.syncPhotoUrl(user);
    });
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging && mounted) {
      if (_currentTabIndex != _tabController.index) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    }
  }

  void _updateTabController(int newLength) {
    if (_tabController.length != newLength) {
      _tabController.removeListener(_handleTabSelection);
      _tabController.dispose();
      _tabController = TabController(
        length: newLength,
        vsync: this,
        initialIndex: 0,
      );
      _tabController.addListener(_handleTabSelection);
      _currentTabIndex = 0;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  List<Widget> getPages(String? role) {
    final isAdmin = role == Roles.admin;
    return isAdmin
        ? const [BerandaPage(), PaymentPage(), ItemPage(), UserPage()]
        : const [BerandaPage(), PaymentPage(), ItemPage()];
  }

  List<String> getTitles(String? role) {
    final isAdmin = role == Roles.admin;
    return isAdmin
        ? ['Beranda', 'Transaksi', 'Barang', 'Pengguna']
        : ['Beranda', 'Transaksi', 'Barang'];
  }

  List<CustomBottomNavItem> getNavItems(String? role) {
    final isAdmin = role == Roles.admin;
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

  void _handleSignOut() {
    _scaffoldKey.currentState?.closeEndDrawer();
    if (_tabController.length > 0) {
      _tabController.index = 0;
    }

    setState(() {
      _currentUser = null;
      _currentTabIndex = 0;
    });

    Provider.of<local.AuthProvider>(context, listen: false).clear();
    _auth.signOut(context);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<local.AuthProvider>().role;
    final pages = getPages(role);
    final titles = getTitles(role);
    final navItems = getNavItems(role);

    if (_currentTabIndex >= pages.length) {
      _currentTabIndex = 0;
    }
    _updateTabController(pages.length);

    final safeIndex = _currentTabIndex;

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      appBar: AppBar(
        title: Text(titles[safeIndex]),
        actions: [
          if (_currentUser == null)
            _isSigningIn
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: GradientButton(
                        label: 'Login',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        onPressed: _handleSignIn,
                      ),
                    ),
                  ),
          if (_currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                bool confirm = false;
                await showAppDialog(
                  context: context,
                  title: 'Keluar',
                  titleIcon: const Icon(Icons.warning_amber_rounded),
                  content: 'Apakah anda yakin ingin keluar?',
                  actions: [
                    AppDialogAction(
                      label: 'Batal',
                      onPressed: () => Navigator.pop(context),
                    ),
                    AppDialogAction(
                      label: 'Keluar',
                      type: AppDialogActionType.gradient,
                      onPressed: () {
                        confirm = true;
                        Navigator.pop(context);
                      },
                    ),
                  ],
                );
                if (confirm && mounted) {
                  _handleSignOut();
                }
              },
            ),
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
        currentIndex: safeIndex,
        disabledIndices: role == null
            ? Set<int>.from(
                List.generate(navItems.length, (i) => i).where((i) => i != 0),
              )
            : {},
        onTap: (i) {
          if (role == null) return;
          setState(() => _currentTabIndex = i);
          _tabController.animateTo(i);
        },
        items: navItems,
      ),
      body: TabBarView(
        controller: _tabController,
        physics: role == null ? const NeverScrollableScrollPhysics() : null,
        children: pages,
      ),
    );
  }
}
