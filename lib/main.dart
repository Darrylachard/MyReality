import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:projects/Avatar/avatar_creation_page.dart';
import 'package:projects/Avatar/premium_avatar.dart';

import 'Avatar/avatar_model.dart';
import 'Avatar/avatar_widget.dart';
import 'account_progress.dart';
import 'prototype/prototype_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<dynamic>('account');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyReality',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff286755)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff4f5f0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xfff4f5f0),
          foregroundColor: Color(0xff183b33),
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xff183b33),
            letterSpacing: -.7,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xffe2e7df)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xfff0f3ed),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const PrototypePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.now = DateTime.now});

  final DateTime Function() now;

  @override
  HomePageState createState() => HomePageState();
}

enum Place { home, office, shop }

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  AvatarModel? avatar;
  int _selectedIndex = 0;

  // ✅ MOVE currentPlace INSIDE THE STATE (not global)
  Place currentPlace = Place.home;
  Place lastMainPlace = Place.home;

  String get backgroundAsset {
    switch (currentPlace) {
      case Place.shop:
        return 'assets/bg/shop.png';
      case Place.office:
        return 'assets/bg/office.png';
      case Place.home:
        return 'assets/bg/home.png';
    }
  }

  // Player stats
  double food = 100;
  double energy = 100;
  double lifeBalance = 100;

  late final Box<dynamic> _accountBox;
  late AccountProgress _account;
  bool _saving = false;
  Timer? _dayTimer;

  List<String> get completedDays => _account.completedDays;
  double get money => _account.balanceCents / 100;

  @override
  void initState() {
    super.initState();
    _accountBox = Hive.box<dynamic>('account');
    final saved = _accountBox.get('progress');
    _account = saved == null
        ? AccountProgress()
        : AccountProgress.fromMap(saved as Map);
    WidgetsBinding.instance.addObserver(this);
    _scheduleDayRefresh();
  }

  void _scheduleDayRefresh() {
    _dayTimer?.cancel();
    final now = widget.now().toLocal();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _dayTimer = Timer(tomorrow.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleDayRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _scheduleDayRefresh();
    }
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  final formatter = NumberFormat('#,##0.00');

  Widget heartRow({
    required double value,
    required String fullImg,
    required String halfImg,
  }) {
    double remaining = value;

    return Row(
      children: List.generate(5, (i) {
        if (remaining >= 20) {
          remaining -= 20;
          return Image.asset(fullImg, width: 24);
        } else if (remaining >= 10) {
          remaining -= 20;
          return Image.asset(halfImg, width: 24);
        } else {
          remaining -= 20;
          return Image.asset("assets/image/Low_Heart.png", width: 24);
        }
      }),
    );
  }

  Widget statIconDisplay({
    required String iconPath,
    required double value,
    required String fullImg,
    required String halfImg,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 28, height: 28),
          const SizedBox(width: 6),
          heartRow(value: value, fullImg: fullImg, halfImg: halfImg),
        ],
      ),
    );
  }

  Future<bool> _saveProgress(AccountProgress next) async {
    if (_saving) return false;
    setState(() => _saving = true);
    try {
      await _accountBox.put('progress', next.toMap());
      if (!mounted) return false;
      setState(() => _account = next);
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Please try again.')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> markTodayDone() async {
    if (_saving) return;
    final next = _account.checkIn(widget.now());
    if (identical(next, _account)) return;
    if (!await _saveProgress(next) || !mounted) return;
    setState(() {
      currentPlace = Place.office;
      lastMainPlace = Place.office;
    });
    if (next.daysInPeriod == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '14 days completed! Your statement is ready in Account.',
          ),
        ),
      );
    }
  }

  Future<void> handlePurchase(String title, double price) async {
    if (_saving) return;
    final next = _account.purchase((price * 100).round());
    if (identical(next, _account)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Not enough money")));
      return;
    }
    if (await _saveProgress(next) && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Purchased $title!")));
    }
  }

  // ✅ HOME PAGE (with background)
  Widget buildHomePage() {
    return SizedBox.expand(
      child: Stack(
        children: [
          // BACKGROUND MAP (fills screen)
          Positioned.fill(
            child: Image.asset(backgroundAsset, fit: BoxFit.cover),
          ),

          // optional dim overlay
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.12)),
          ),
          // ✅ Shadow to "ground" the avatar
          if (avatar != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 78, // slightly above avatar bottom
              child: Center(
                child: Container(
                  width: 165,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),

          // ✅ AVATAR anchored to the "ground"
          if (avatar != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 88, // 👈 tweak this to match the floor (try 70–120)
              child: Center(
                child: PremiumAvatarMotion(
                  child: AvatarWidget(
                    avatar: avatar!,
                    size: 315,
                  ), // slightly smaller feels natural
                ),
              ),
            ),

          // FOREGROUND (fills screen)
          SafeArea(
            child: Column(
              children: [
                // Top-right stats
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10, top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        statIconDisplay(
                          iconPath: "assets/image/Food_Icon.png",
                          value: food,
                          fullImg: "assets/image/Heart.png",
                          halfImg: "assets/image/Half_Heart.png",
                        ),
                        statIconDisplay(
                          iconPath: "assets/image/Energy_bar.png",
                          value: energy,
                          fullImg: "assets/image/Energy.png",
                          halfImg: "assets/image/Half_Blue.png",
                        ),
                        statIconDisplay(
                          iconPath: "assets/image/Balance.png",
                          value: lifeBalance,
                          fullImg: "assets/image/Life_Balance.png",
                          halfImg: "assets/image/Half_green.png",
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(), // pushes controls down
                // Create Avatar only if null
                if (avatar == null) ...[
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push<AvatarModel>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AvatarCreatorPage(),
                        ),
                      );
                      if (result != null) setState(() => avatar = result);
                    },
                    child: const Text("Create Avatar"),
                  ),
                  const SizedBox(height: 10),
                ],

                ElevatedButton(
                  onPressed: _saving || _account.hasCompleted(widget.now())
                      ? null
                      : markTodayDone,
                  child: Text(
                    _account.hasCompleted(widget.now())
                        ? 'Already showed up today'
                        : 'I showed up!',
                  ),
                ),

                const SizedBox(height: 12),
                if (avatar != null) ...[const SizedBox(height: 12)],

                // completed days list (scrollable area at bottom)
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    itemCount: completedDays.length,
                    itemBuilder: (context, index) => ListTile(
                      leading: const Icon(Icons.check, color: Colors.green),
                      title: Text(
                        completedDays[index],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ SHOP PAGE (reconstructed + uses shop bg)
  Widget buildShopPage() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/bg/shop.png', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.12)),
        ),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Money header card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Shop",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "\$${formatter.format(money)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Example items (edit prices/titles)
              shopItem(
                "Coffee",
                4.50,
                "Boost energy",
                onBuy: () => handlePurchase("Coffee", 4.50),
              ),
              shopItem(
                "Meal",
                12.00,
                "Boost food",
                onBuy: () => handlePurchase("Meal", 12.00),
              ),
              shopItem(
                "Gym Pass",
                25.00,
                "Boost balance",
                onBuy: () => handlePurchase("Gym Pass", 25.00),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget shopItem(
    String title,
    double price,
    String subtitle, {
    required VoidCallback onBuy,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "\$${formatter.format(price)}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: _saving ? null : onBuy,
                child: const Text("Buy"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> get _pages => [
    buildHomePage(),
    buildShopPage(),
    Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _account.lastStatementCents == null
                  ? 'No statement yet'
                  : 'Last statement: \$${formatter.format(_account.lastStatementCents! / 100)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '${_account.daysInPeriod} of ${AccountProgress.daysPerStatement} check-in days toward your next statement',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Current period earnings: \$${formatter.format(_account.periodEarningsCents / 100)}',
            ),
          ],
        ),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MyReality")),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;

            if (index == 1) {
              // Going to SHOP → remember where we came from
              if (currentPlace != Place.shop) lastMainPlace = currentPlace;
              currentPlace = Place.shop;
            }

            if (index == 0) {
              // Leaving SHOP → return to last place (home or office)
              currentPlace = lastMainPlace;
            }
          });
        },

        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail_outline),
            activeIcon: Icon(Icons.mail),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
