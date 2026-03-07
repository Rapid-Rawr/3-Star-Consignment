import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'utils/theme_notifier.dart';
import 'widgets/login_drawer.dart';
import 'views/beranda_page.dart';
import 'views/pembayaran_page.dart';
import 'views/barang_page.dart';
import 'widgets/custom_bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
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
  late final TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
    _auth.init();
    _authSubscription = _auth.authStateChanges.listen((user) {
      if (mounted) setState(() => _currentUser = user);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _authSubscription?.cancel();
    super.dispose();
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
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      appBar: AppBar(
        title: Text(['Beranda', 'Transaksi', 'Barang'][_currentTabIndex]),
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
          setState(() => _currentTabIndex = i);
          _tabController.animateTo(i);
        },
        items: const [
          CustomBottomNavItem(
            icon: Icons.home_rounded,
            activeIcon: Icons.home_rounded,
          ),
          CustomBottomNavItem(
            icon: Icons.payment_rounded,
            activeIcon: Icons.payment_rounded,
          ),
          CustomBottomNavItem(
            icon: Icons.inventory_2_rounded,
            iconSize: 24,
            activeIcon: Icons.inventory_2_rounded,
            activeIconSize: 24,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [BerandaPage(), PesananPage(), LaporanPage()],
      ),
    );
  }
}
