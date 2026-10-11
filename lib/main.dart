import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/campus_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LBRCEApp());
}

// =====================================================
// APP THEME & CONSTANTS
// =====================================================

const Color navy = Color(0xFF06377D);
const Color blue = Color(0xFF0866F5);
const Color cyan = Color(0xFF06B6D4);
const Color purple = Color(0xFF713BFA);
const Color green = Color(0xFF05AE72);
const Color orange = Color(0xFFF58B00);
const Color bg = Color(0xFFF3F7FF);
const String campusImage = 'assets/images/lbrce_campus.png';

// Official LBRCE Main Campus Coordinates (College Gate / Entrance)
const double campusLat = 16.749072;
const double campusLng = 80.634794;

class LBRCEApp extends StatelessWidget {
  const LBRCEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LBRCE Smart Campus Navigator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: blue,
          primary: blue,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

// =====================================================
// CAMPUS PLACE MODEL
// =====================================================

class CampusPlace {
  final String name;
  final String category;
  final String description;
  final IconData icon;
  final Color color;
  final double? latitude;
  final double? longitude;

  const CampusPlace({
    required this.name,
    required this.category,
    required this.description,
    required this.icon,
    required this.color,
    this.latitude,
    this.longitude,
  });

  CampusPlace copyWith({
    String? name,
    String? category,
    String? description,
    IconData? icon,
    Color? color,
    double? latitude,
    double? longitude,
  }) {
    return CampusPlace(
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

const List<CampusPlace> defaultPlaces = [
  CampusPlace(
    name: 'Admin Block',
    category: 'Administration',
    description: 'Campus administration, Principal office and examination section.',
    icon: Icons.account_balance_rounded,
    color: blue,
    latitude: 16.7491981,
    longitude: 80.6349428,
  ),
  CampusPlace(
    name: 'ECE Block',
    category: 'Academic',
    description: 'Electronics and Communication Engineering department and labs.',
    icon: Icons.memory_rounded,
    color: purple,
    latitude: 16.7487050,
    longitude: 80.6343259,
  ),
  CampusPlace(
    name: 'CSE Block',
    category: 'Academic',
    description: 'Computer Science and Engineering department and computing centers.',
    icon: Icons.computer_rounded,
    color: green,
    latitude: 16.7488546,
    longitude: 80.6325671,
  ),
  CampusPlace(
    name: 'Block 2',
    category: 'Academic',
    description: 'Academic classrooms, IT department, and student facilities.',
    icon: Icons.apartment_rounded,
    color: cyan,
    latitude: 16.7487812,
    longitude: 80.6334290,
  ),
  CampusPlace(
    name: 'Block 4',
    category: 'Academic',
    description: 'Mechanical and Civil Engineering academic block and studios.',
    icon: Icons.school_rounded,
    color: orange,
    latitude: 16.7499810,
    longitude: 80.6328110,
  ),
  CampusPlace(
    name: 'Block 5',
    category: 'Academic',
    description: 'Classrooms, freshman department, and science faculties.',
    icon: Icons.domain_rounded,
    color: Color(0xFFDB2777),
    latitude: 16.7499166,
    longitude: 80.6338981,
  ),
  CampusPlace(
    name: 'Canteen',
    category: 'Facilities',
    description: 'Campus dining, cafeteria, snacks, and beverage facilities.',
    icon: Icons.restaurant_rounded,
    color: orange,
    latitude: 16.7481178,
    longitude: 80.6352734,
  ),
  CampusPlace(
    name: 'Guest House',
    category: 'Facilities',
    description: 'Campus guest accommodation and visiting faculty suites.',
    icon: Icons.hotel_rounded,
    color: green,
  ),
  CampusPlace(
    name: 'Engineering Labs',
    category: 'Academic',
    description: 'Workshop, thermal lab, machinery and core engineering laboratories.',
    icon: Icons.science_rounded,
    color: purple,
    latitude: 16.7490826,
    longitude: 80.6319421,
  ),
  CampusPlace(
    name: 'Parking',
    category: 'Facilities',
    description: 'Designated campus parking for student and staff vehicles.',
    icon: Icons.local_parking_rounded,
    color: Color(0xFF54738F),
    latitude: 16.7499050,
    longitude: 80.6349180,
  ),
  CampusPlace(
    name: 'Auditorium',
    category: 'Facilities',
    description: 'Main auditorium for seminars, cultural fests and college events.',
    icon: Icons.event_rounded,
    color: purple,
  ),
  CampusPlace(
    name: 'Hostels',
    category: 'Hostels',
    description: 'On-campus resident student hostels and mess facilities.',
    icon: Icons.bed_rounded,
    color: cyan,
    latitude: 16.7483281,
    longitude: 80.6358779,
  ),
  CampusPlace(
    name: 'Aerospace Department',
    category: 'Academic',
    description: 'Aerospace engineering department, wind tunnel and propulsion lab.',
    icon: Icons.flight_rounded,
    color: green,
    latitude: 16.7488660,
    longitude: 80.6325500,
  ),
  CampusPlace(
    name: 'Central Library',
    category: 'Library',
    description: 'Digital library, reference sections, journals and quiet study halls.',
    icon: Icons.local_library_rounded,
    color: orange,
    latitude: 16.7488472,
    longitude: 80.6342374,
  ),
  CampusPlace(
    name: 'Student Services',
    category: 'Administration',
    description: 'Training & placement cell, student grievance and welfare desk.',
    icon: Icons.groups_rounded,
    color: purple,
  ),
];

// Helper to get effective place with custom coordinates
CampusPlace getEffectivePlace(
  CampusPlace original,
  Map<String, Map<String, double>> customCoords,
) {
  final override = customCoords[original.name];
  if (override != null) {
    return original.copyWith(
      latitude: override['latitude'],
      longitude: override['longitude'],
    );
  }
  return original;
}

// Calculate straight-line distance formatted
String? formatDistance(Position? userPos, CampusPlace place) {
  if (userPos == null || place.latitude == null || place.longitude == null) {
    return null;
  }
  final meters = Geolocator.distanceBetween(
    userPos.latitude,
    userPos.longitude,
    place.latitude!,
    place.longitude!,
  );
  if (meters < 1000) {
    return '${meters.round()} m away';
  } else {
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }
}

// URL launcher helper
Future<void> launchCampusUrl(
  BuildContext context,
  String urlString, {
  LaunchMode mode = LaunchMode.externalApplication,
}) async {
  try {
    final uri = Uri.parse(urlString);
    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      await launchUrl(uri, mode: mode);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open map or browser for link: $urlString'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

// =====================================================
// REUSABLE CAMPUS PHOTO WIDGET
// =====================================================

class CampusPhoto extends StatelessWidget {
  final double? height;
  final double? width;
  final BoxFit fit;

  const CampusPhoto({
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      color: navy,
      child: Image.asset(
        campusImage,
        width: width ?? double.infinity,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width ?? double.infinity,
            height: height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [navy, blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'LAKIREDDY BALI REDDY COLLEGE OF ENGINEERING',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'MYLAVARAM, KRISHNA DT., AP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =====================================================
// SPLASH / WELCOME SCREEN
// =====================================================

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0635BD),
              Color(0xFF0759E9),
              Color(0xFF00B8D4),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: 12),
                            const Icon(
                              Icons.account_balance_rounded,
                              size: 78,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'LBRCE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Smart Campus',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Navigator',
                              style: TextStyle(
                                color: Color(0xFF27F4FF),
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Explore campus buildings, find facilities, '
                              'save your favourite places and navigate with ease.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 22),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: const AspectRatio(
                                aspectRatio: 16 / 9,
                                child: CampusPhoto(
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MainScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: const Text(
                                  'Explore Campus',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: navy,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Your campus, one tap away',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// =====================================================
// MAIN SCREEN AND BOTTOM NAVIGATION
// =====================================================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedTab = 0;
  Set<String> savedPlaces = {};
  Map<String, Map<String, double>> customCoordinates = {};
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final bookmarks = await CampusStorage.loadBookmarks();
      final coordinates = await CampusStorage.loadAllCoordinates();
      if (mounted) {
        setState(() {
          savedPlaces = bookmarks;
          customCoordinates = coordinates;
        });
      }
    } catch (_) {
      // Gracefully continue with defaults
    }
  }

  Future<void> toggleSaved(CampusPlace place) async {
    setState(() {
      if (savedPlaces.contains(place.name)) {
        savedPlaces.remove(place.name);
      } else {
        savedPlaces.add(place.name);
      }
    });
    try {
      await CampusStorage.saveBookmarks(savedPlaces);
    } catch (_) {}
  }

  Future<void> updatePlaceCoordinates(
    String buildingName,
    double lat,
    double lng,
  ) async {
    try {
      await CampusStorage.saveCoordinates(buildingName, lat, lng);
      final coords = await CampusStorage.loadAllCoordinates();
      if (mounted) {
        setState(() {
          customCoordinates = coords;
        });
      }
    } catch (_) {}
  }

  Future<void> resetPlaceCoordinates(String buildingName) async {
    try {
      await CampusStorage.clearCoordinates(buildingName);
      final coords = await CampusStorage.loadAllCoordinates();
      if (mounted) {
        setState(() {
          customCoordinates = coords;
        });
      }
    } catch (_) {}
  }

  void onPositionUpdated(Position? pos) {
    if (mounted) {
      setState(() {
        currentPosition = pos;
      });
    }
  }

  void openPlace(CampusPlace place) {
    final effectivePlace = getEffectivePlace(place, customCoordinates);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceDetailsScreen(
          place: effectivePlace,
          isSaved: savedPlaces.contains(place.name),
          currentPosition: currentPosition,
          hasCustomPin: customCoordinates.containsKey(place.name),
          onSave: () => toggleSaved(place),
          onUpdateCoordinates: (lat, lng) =>
              updatePlaceCoordinates(place.name, lat, lng),
          onResetCoordinates: () => resetPlaceCoordinates(place.name),
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void showCampusInfoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        color: blue,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LBRCE Campus Guide',
                            style: TextStyle(
                              color: navy,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Lakireddy Bali Reddy College of Engg.',
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                const Text(
                  'About the Institution',
                  style: TextStyle(
                    color: navy,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Autonomous Institution, affiliated to JNTUK. Approved by AICTE, Accredited with NAAC "A" Grade and NBA (CSE, IT, ECE, EEE & ME). Located in Mylavaram, Krishna District, AP - 521230.',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F1FF),
                    child: Icon(Icons.language_rounded, color: blue),
                  ),
                  title: const Text('Official College Website'),
                  subtitle: const Text('https://www.lbrce.ac.in'),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                  onTap: () {
                    Navigator.pop(context);
                    launchCampusUrl(this.context, 'https://www.lbrce.ac.in');
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.phone_in_talk_rounded, color: green),
                  ),
                  title: const Text('Campus Help & Office'),
                  subtitle: const Text('+91 08659 222933 / 222934'),
                  trailing: const Icon(Icons.call_rounded, size: 20),
                  onTap: () {
                    Navigator.pop(context);
                    launchCampusUrl(this.context, 'tel:+918659222933');
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFECE0),
                    child: Icon(Icons.restart_alt_rounded, color: orange),
                  ),
                  title: const Text('Reset All Saved GPS Pins & Bookmarks'),
                  subtitle: const Text('Clear local device overrides'),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirmed = await showDialog<bool>(
                      context: this.context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear Saved Data?'),
                        content: const Text(
                          'This will reset your bookmarks and all custom building GPS coordinates to defaults.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await CampusStorage.clearAll();
                      if (mounted) {
                        setState(() {
                          savedPlaces.clear();
                          customCoordinates.clear();
                        });
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Local data reset successfully.'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectivePlacesList = defaultPlaces
        .map((p) => getEffectivePlace(p, customCoordinates))
        .toList();

    final pages = [
      ExploreScreen(
        places: effectivePlacesList,
        savedPlaces: savedPlaces,
        currentPosition: currentPosition,
        onSave: toggleSaved,
        onOpen: openPlace,
        onSwitchTab: (index) => setState(() => selectedTab = index),
        onOpenMenu: showCampusInfoSheet,
      ),
      SavedScreen(
        places: effectivePlacesList,
        savedPlaces: savedPlaces,
        currentPosition: currentPosition,
        onSave: toggleSaved,
        onOpen: openPlace,
        onBrowseExplore: () => setState(() => selectedTab = 0),
      ),
      GPSPage(
        currentPosition: currentPosition,
        onPositionChanged: onPositionUpdated,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedTab,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() => selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'My GPS',
          ),
        ],
      ),
    );
  }
}

// =====================================================
// EXPLORE SCREEN
// =====================================================

class ExploreScreen extends StatefulWidget {
  final List<CampusPlace> places;
  final Set<String> savedPlaces;
  final Position? currentPosition;
  final ValueChanged<CampusPlace> onSave;
  final ValueChanged<CampusPlace> onOpen;
  final ValueChanged<int> onSwitchTab;
  final VoidCallback onOpenMenu;

  const ExploreScreen({
    super.key,
    required this.places,
    required this.savedPlaces,
    required this.currentPosition,
    required this.onSave,
    required this.onOpen,
    required this.onSwitchTab,
    required this.onOpenMenu,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';
  String selectedCategory = 'All';

  final categories = const [
    'All',
    'Academic',
    'Facilities',
    'Administration',
    'Hostels',
    'Library',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlaces = widget.places.where((place) {
      final matchesSearch = searchText.isEmpty ||
          place.name.toLowerCase().contains(searchText.toLowerCase()) ||
          place.category.toLowerCase().contains(searchText.toLowerCase()) ||
          place.description.toLowerCase().contains(searchText.toLowerCase());

      final matchesCategory = selectedCategory == 'All' ||
          place.category == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with navigation actions
          SliverToBoxAdapter(
            child: Container(
              color: navy,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: widget.onOpenMenu,
                        icon: const Icon(
                          Icons.menu_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        tooltip: 'Campus Info & Settings',
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LBRCE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'SMART CAMPUS NAVIGATOR',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => widget.onSwitchTab(2),
                        icon: Icon(
                          widget.currentPosition != null
                              ? Icons.my_location_rounded
                              : Icons.location_searching_rounded,
                          color: widget.currentPosition != null
                              ? const Color(0xFF27F4FF)
                              : Colors.white,
                          size: 26,
                        ),
                        tooltip: widget.currentPosition != null
                            ? 'GPS Active - Tap for Details'
                            : 'Enable My GPS Location',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Campus banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              decoration: BoxDecoration(
                color: navy,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: const AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CampusPhoto(
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: navy.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore Places',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Find buildings, classrooms and facilities around campus.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search field
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => searchText = value.trim());
                },
                decoration: InputDecoration(
                  hintText: 'Search campus places...',
                  prefixIcon: const Icon(Icons.search, color: blue),
                  suffixIcon: searchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => searchText = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),

          // Category filters
          SliverToBoxAdapter(
            child: SizedBox(
              height: 49,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                children: categories.map((category) {
                  final active = category == selectedCategory;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: active,
                      onSelected: (_) {
                        setState(() => selectedCategory = category);
                      },
                      selectedColor: blue,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: active ? Colors.white : navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Interactive Summary Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      title: 'Total Places',
                      value: '${widget.places.length}',
                      icon: Icons.domain_rounded,
                      color: blue,
                      onTap: () {
                        setState(() {
                          selectedCategory = 'All';
                          searchText = '';
                          _searchController.clear();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Showing all campus destinations'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SummaryCard(
                      title: 'Saved',
                      value: '${widget.savedPlaces.length}',
                      icon: Icons.bookmark_added_rounded,
                      color: orange,
                      onTap: () => widget.onSwitchTab(1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SummaryCard(
                      title: 'GPS Status',
                      value: widget.currentPosition != null ? 'Active' : 'Enable',
                      icon: Icons.location_on_rounded,
                      color: widget.currentPosition != null ? green : cyan,
                      onTap: () => widget.onSwitchTab(2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Destinations heading
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 5, 18, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Campus Destinations',
                      style: TextStyle(
                        color: navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${filteredPlaces.length} found',
                    style: const TextStyle(
                      color: blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Destination list
          if (filteredPlaces.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        size: 54,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No campus places found matching your filter.',
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            selectedCategory = 'All';
                            searchText = '';
                            _searchController.clear();
                          });
                        },
                        child: const Text('Reset Search & Filters'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final place = filteredPlaces[index];
                    final distanceText =
                        formatDistance(widget.currentPosition, place);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PlaceCard(
                        place: place,
                        distanceText: distanceText,
                        isSaved: widget.savedPlaces.contains(place.name),
                        onSave: () {
                          widget.onSave(place);
                          final nowSaved =
                              !widget.savedPlaces.contains(place.name);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                nowSaved
                                    ? '${place.name} added to saved'
                                    : '${place.name} removed from saved',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        onTap: () => widget.onOpen(place),
                      ),
                    );
                  },
                  childCount: filteredPlaces.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =====================================================
// SUMMARY CARD WIDGET
// =====================================================

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 98,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// PLACE CARD WIDGET
// =====================================================

class PlaceCard extends StatelessWidget {
  final CampusPlace place;
  final String? distanceText;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onTap;

  const PlaceCard({
    super.key,
    required this.place,
    this.distanceText,
    required this.isSaved,
    required this.onSave,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: place.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  place.icon,
                  size: 28,
                  color: place.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          place.category,
                          style: TextStyle(
                            color: place.color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (distanceText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.directions_walk_rounded,
                                  size: 11,
                                  color: green,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  distanceText!,
                                  style: const TextStyle(
                                    color: green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSave,
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? orange : blue,
                ),
                tooltip: isSaved ? 'Remove Bookmark' : 'Save Bookmark',
              ),
              const Icon(
                Icons.chevron_right,
                color: blue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// SAVED PLACES SCREEN
// =====================================================

class SavedScreen extends StatefulWidget {
  final List<CampusPlace> places;
  final Set<String> savedPlaces;
  final Position? currentPosition;
  final ValueChanged<CampusPlace> onSave;
  final ValueChanged<CampusPlace> onOpen;
  final VoidCallback onBrowseExplore;

  const SavedScreen({
    super.key,
    required this.places,
    required this.savedPlaces,
    required this.currentPosition,
    required this.onSave,
    required this.onOpen,
    required this.onBrowseExplore,
  });

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final TextEditingController _searchController = TextEditingController();
  String search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saved = widget.places.where((place) {
      final isBookmarked = widget.savedPlaces.contains(place.name);
      final matches = search.isEmpty ||
          place.name.toLowerCase().contains(search.toLowerCase()) ||
          place.category.toLowerCase().contains(search.toLowerCase());
      return isBookmarked && matches;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved Places',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [navy, blue, purple],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Saved Places',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.savedPlaces.isEmpty
                      ? 'No places bookmarked yet.'
                      : '${widget.savedPlaces.length} campus places bookmarked for quick access.',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          if (widget.savedPlaces.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(15),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => search = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search saved places...',
                  prefixIcon: const Icon(Icons.search, color: blue),
                  suffixIcon: search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => search = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          Expanded(
            child: widget.savedPlaces.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: blue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bookmark_border_rounded,
                              size: 64,
                              color: blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No saved places yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: navy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Bookmark your favourite classrooms, labs, canteen or library from Explore.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: widget.onBrowseExplore,
                            icon: const Icon(Icons.explore_rounded),
                            label: const Text('Browse Campus Places'),
                            style: FilledButton.styleFrom(
                              backgroundColor: blue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : saved.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('No saved places match your search.'),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => search = '');
                              },
                              child: const Text('Clear Search Filter'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: saved.length,
                        itemBuilder: (context, index) {
                          final place = saved[index];
                          final distanceText =
                              formatDistance(widget.currentPosition, place);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PlaceCard(
                              place: place,
                              distanceText: distanceText,
                              isSaved: true,
                              onSave: () {
                                widget.onSave(place);
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Removed ${place.name} from saved',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              onTap: () => widget.onOpen(place),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// PLACE DETAILS SCREEN
// =====================================================

class PlaceDetailsScreen extends StatefulWidget {
  final CampusPlace place;
  final bool isSaved;
  final Position? currentPosition;
  final bool hasCustomPin;
  final VoidCallback onSave;
  final Function(double lat, double lng) onUpdateCoordinates;
  final VoidCallback onResetCoordinates;

  const PlaceDetailsScreen({
    super.key,
    required this.place,
    required this.isSaved,
    required this.currentPosition,
    required this.hasCustomPin,
    required this.onSave,
    required this.onUpdateCoordinates,
    required this.onResetCoordinates,
  });

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  late bool isCurrentlySaved;
  late CampusPlace currentPlace;
  late bool hasCustomCoordinates;

  @override
  void initState() {
    super.initState();
    isCurrentlySaved = widget.isSaved;
    currentPlace = widget.place;
    hasCustomCoordinates = widget.hasCustomPin;
  }

  Future<void> openDirections() async {
    final lat = currentPlace.latitude;
    final lng = currentPlace.longitude;

    if (lat != null && lng != null) {
      final userPos = widget.currentPosition;
      final String url;
      if (userPos != null) {
        url = 'https://www.google.com/maps/dir/?api=1'
            '&origin=${userPos.latitude},${userPos.longitude}'
            '&destination=$lat,$lng'
            '&travelmode=walking';
      } else {
        url = 'https://www.google.com/maps/dir/?api=1'
            '&destination=$lat,$lng'
            '&travelmode=walking';
      }
      await launchCampusUrl(context, url);
    } else {
      // Destination has no coordinates set yet - search by campus name
      final searchQuery = Uri.encodeComponent(
        '${currentPlace.name}, Lakireddy Bali Reddy College of Engineering, Mylavaram',
      );
      final url = 'https://www.google.com/maps/search/?api=1&query=$searchQuery';
      await launchCampusUrl(context, url);
    }
  }

  void showEditPinDialog() {
    final latController = TextEditingController(
      text: currentPlace.latitude != null
          ? currentPlace.latitude.toString()
          : '',
    );
    final lngController = TextEditingController(
      text: currentPlace.longitude != null
          ? currentPlace.longitude.toString()
          : '',
    );
    String? dialogError;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.edit_location_alt_rounded, color: blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GPS Pin: ${currentPlace.name}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter exact coordinates for this building. They will be stored locally on this device.',
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: latController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Latitude (-90 to 90)',
                        hintText: 'e.g. 16.749198',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lngController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Longitude (-180 to 180)',
                        hintText: 'e.g. 80.634942',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        dialogError!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (widget.currentPosition != null)
                      OutlinedButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            latController.text = widget.currentPosition!.latitude
                                .toStringAsFixed(7);
                            lngController.text = widget
                                .currentPosition!.longitude
                                .toStringAsFixed(7);
                            dialogError = null;
                          });
                        },
                        icon: const Icon(Icons.my_location_rounded, size: 18),
                        label: const Text('Use My Current GPS Position'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                if (hasCustomCoordinates)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      widget.onResetCoordinates();
                      setState(() {
                        hasCustomCoordinates = false;
                        // Find default place
                        final orig = defaultPlaces.firstWhere(
                          (p) => p.name == currentPlace.name,
                          orElse: () => currentPlace,
                        );
                        currentPlace = orig;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pin reset to default coordinates.'),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    child: const Text('Reset Pin'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final latStr = latController.text.trim();
                    final lngStr = lngController.text.trim();

                    final lat = double.tryParse(latStr);
                    final lng = double.tryParse(lngStr);

                    if (lat == null || lat < -90 || lat > 90) {
                      setDialogState(() {
                        dialogError = 'Enter a valid latitude between -90 and 90.';
                      });
                      return;
                    }
                    if (lng == null || lng < -180 || lng > 180) {
                      setDialogState(() {
                        dialogError =
                            'Enter a valid longitude between -180 and 180.';
                      });
                      return;
                    }

                    widget.onUpdateCoordinates(lat, lng);
                    Navigator.pop(dialogCtx);

                    setState(() {
                      currentPlace = currentPlace.copyWith(
                        latitude: lat,
                        longitude: lng,
                      );
                      hasCustomCoordinates = true;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Saved custom GPS pin for ${currentPlace.name}.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Save Pin'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showServiceInfo(String title, String details, IconData icon, Color color) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                details,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(backgroundColor: navy),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distanceText =
        formatDistance(widget.currentPosition, currentPlace);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Details'),
        actions: [
          IconButton(
            icon: Icon(
              isCurrentlySaved ? Icons.bookmark : Icons.bookmark_border,
              color: isCurrentlySaved ? orange : Colors.white,
            ),
            tooltip: isCurrentlySaved ? 'Remove Bookmark' : 'Add Bookmark',
            onPressed: () {
              widget.onSave();
              setState(() {
                isCurrentlySaved = !isCurrentlySaved;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isCurrentlySaved
                        ? 'Added to Saved Places'
                        : 'Removed from Saved Places',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner with place icon overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                const AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CampusPhoto(
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      currentPlace.icon,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Text(
            currentPlace.name,
            style: const TextStyle(
              color: navy,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: currentPlace.color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                currentPlace.category,
                style: TextStyle(
                  color: currentPlace.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            currentPlace.description,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 14,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 18),

          // Coordinates & Distance Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F0FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 28,
                      color: blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Coordinates',
                                style: TextStyle(
                                  color: blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              if (hasCustomCoordinates) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: purple.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Custom Pin',
                                    style: TextStyle(
                                      color: purple,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentPlace.latitude != null &&
                                    currentPlace.longitude != null
                                ? '${currentPlace.latitude!.toStringAsFixed(6)}, '
                                    '${currentPlace.longitude!.toStringAsFixed(6)}'
                                : 'No GPS pin assigned yet. (Tap Set GPS Pin below)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: currentPlace.latitude != null
                                  ? navy
                                  : Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (distanceText != null) ...[
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_walk_rounded,
                        size: 20,
                        color: green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Straight-line distance: $distanceText',
                        style: const TextStyle(
                          color: green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Action 1: Get Directions Button
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: openDirections,
              icon: const Icon(Icons.navigation_rounded),
              label: Text(
                currentPlace.latitude != null
                    ? 'Get Walking Directions (Maps)'
                    : 'Search Destination in Google Maps',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Action 2: Set / Edit GPS Pin Button
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: showEditPinDialog,
              icon: const Icon(Icons.edit_location_alt_rounded),
              label: Text(
                hasCustomCoordinates
                    ? 'Edit Custom GPS Pin'
                    : 'Set / Edit GPS Pin',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: navy,
                side: const BorderSide(color: navy, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Action 3: Bookmark Button
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                widget.onSave();
                setState(() {
                  isCurrentlySaved = !isCurrentlySaved;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isCurrentlySaved
                          ? 'Saved to favourite places'
                          : 'Removed from favourite places',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              icon: Icon(
                isCurrentlySaved
                    ? Icons.bookmark_remove_rounded
                    : Icons.bookmark_add_rounded,
                color: isCurrentlySaved ? orange : blue,
              ),
              label: Text(
                isCurrentlySaved ? 'Remove from Saved' : 'Save this Place',
                style: TextStyle(
                  color: isCurrentlySaved ? orange : blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isCurrentlySaved ? orange : blue,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 26),

          const Text(
            'Campus Facilities & Services',
            style: TextStyle(
              color: navy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 14),

          // Service information tiles with working tap action
          Row(
            children: [
              Expanded(
                child: ServiceTile(
                  icon: Icons.account_balance,
                  title: 'Office Facilities',
                  color: blue,
                  onTap: () => showServiceInfo(
                    'Administrative Office Facilities',
                    '• Principal & Directors Secretariat: Ground Floor\n'
                        '• Autonomous Examination Cell: 1st Floor\n'
                        '• Accounts & Student Fee Counter: Ground Floor\n'
                        '• Working Hours: 9:00 AM to 5:00 PM\n'
                        '• Contact: Ext 101, 102',
                    Icons.account_balance,
                    blue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ServiceTile(
                  icon: Icons.groups,
                  title: 'Student Services',
                  color: purple,
                  onTap: () => showServiceInfo(
                    'Student Support & Affairs',
                    '• Training & Placement (T&P) Cell: Block 2, 2nd Floor\n'
                        '• Student Activity Center (SAC) & Clubs\n'
                        '• NSS / NCC Unit & Social Services\n'
                        '• Grievance Redressal & Counselling Desk\n'
                        '• Scholarship Guidance Helpdesk',
                    Icons.groups,
                    purple,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ServiceTile(
                  icon: Icons.settings,
                  title: 'Administration',
                  color: green,
                  onTap: () => showServiceInfo(
                    'College Governance & Address',
                    '• Lakireddy Bali Reddy College of Engineering (Autonomous)\n'
                        '• Mylavaram, Krishna District, AP - 521230\n'
                        '• Phone: 08659-222933, 222934\n'
                        '• Email: lbrce@lbrce.ac.in\n'
                        '• NAAC "A" Grade & NBA Accredited',
                    Icons.settings,
                    green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// =====================================================
// SERVICE TILE WIDGET
// =====================================================

class ServiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const ServiceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: navy,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// GPS SCREEN
// =====================================================

class GPSPage extends StatefulWidget {
  final Position? currentPosition;
  final ValueChanged<Position?> onPositionChanged;

  const GPSPage({
    super.key,
    required this.currentPosition,
    required this.onPositionChanged,
  });

  @override
  State<GPSPage> createState() => _GPSPageState();
}

class _GPSPageState extends State<GPSPage> {
  Position? position;
  bool loading = false;
  String statusMessage = 'Tap below to find and enable your real-time GPS location.';
  bool serviceDisabled = false;
  bool permissionDeniedForever = false;
  DateTime? lastFetchedTime;

  @override
  void initState() {
    super.initState();
    position = widget.currentPosition;
    if (position != null) {
      statusMessage = 'GPS coordinates loaded successfully.';
    }
  }

  @override
  void didUpdateWidget(covariant GPSPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPosition != position) {
      setState(() {
        position = widget.currentPosition;
      });
    }
  }

  Future<void> getCurrentLocation() async {
    if (loading) return;

    setState(() {
      loading = true;
      serviceDisabled = false;
      permissionDeniedForever = false;
      statusMessage = 'Checking GPS location services...';
    });

    try {
      // 1. Check if location services (GPS) are enabled on the device
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          serviceDisabled = true;
          loading = false;
          statusMessage =
              'Device location is turned off. Please turn on GPS location services in device settings.';
        });
        return;
      }

      // 2. Check and request location permissions properly
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        setState(() {
          statusMessage = 'Requesting location permission...';
        });
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          loading = false;
          statusMessage =
              'Location permission denied. Permission is required to show your campus position.';
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          permissionDeniedForever = true;
          loading = false;
          statusMessage =
              'Location permission is permanently denied. Please enable location permissions in App Settings.';
        });
        return;
      }

      // 3. Permission granted: fetch user's real GPS position
      setState(() {
        statusMessage = 'Acquiring satellite signal and coordinates...';
      });

      Position currentPos;
      try {
        currentPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 14),
          ),
        );
      } catch (_) {
        // Fallback to last known position if active GPS timed out
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          currentPos = lastKnown;
        } else {
          rethrow;
        }
      }

      if (!mounted) return;
      setState(() {
        position = currentPos;
        lastFetchedTime = DateTime.now();
        statusMessage = 'Current GPS location acquired successfully.';
        loading = false;
      });

      widget.onPositionChanged(currentPos);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        statusMessage =
            'Could not acquire GPS fix. Please ensure you are in an open area with location enabled.';
      });
    }
  }

  Future<void> openGoogleMapsWithCurrentLocation() async {
    final current = position;
    if (current == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable and fetch your current location first.'),
        ),
      );
      return;
    }

    final url =
        'https://www.google.com/maps/search/?api=1&query=${current.latitude},${current.longitude}';
    await launchCampusUrl(context, url);
  }

  Future<void> openDirectionsToCampus() async {
    final current = position;
    final String url;
    if (current != null) {
      url = 'https://www.google.com/maps/dir/?api=1'
          '&origin=${current.latitude},${current.longitude}'
          '&destination=$campusLat,$campusLng'
          '&travelmode=walking';
    } else {
      url = 'https://www.google.com/maps/dir/?api=1'
          '&destination=$campusLat,$campusLng'
          '&travelmode=walking';
    }
    await launchCampusUrl(context, url);
  }

  void copyCoordinatesToClipboard() {
    if (position == null) return;
    final text = '${position!.latitude}, ${position!.longitude}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied coordinates: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My GPS'),
      ),
      body: ListView(
        children: [
          // Illustrative Map Panel with live status
          Container(
            height: 270,
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFDCEFD9),
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: MapPatternPainter(),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: blue),
                      tooltip: 'Refresh Location',
                      onPressed: loading ? null : getCurrentLocation,
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: blue.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: blue.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: position != null ? green : blue,
                      child: Icon(
                        position != null
                            ? Icons.my_location_rounded
                            : Icons.location_searching_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: position != null ? green : navy,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          position != null
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          position != null
                              ? 'Live GPS Available'
                              : 'GPS Standby',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Location Details Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: position != null ? green : blue,
                        child: const Icon(
                          Icons.navigation_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Location',
                              style: TextStyle(
                                color: navy,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              position == null
                                  ? 'Latitude & Longitude not yet acquired'
                                  : '${position!.latitude.toStringAsFixed(6)}, ${position!.longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: position != null
                                    ? navy
                                    : Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (position != null)
                        IconButton(
                          icon: const Icon(
                            Icons.copy_rounded,
                            color: blue,
                            size: 20,
                          ),
                          tooltip: 'Copy Coordinates',
                          onPressed: copyCoordinatesToClipboard,
                        ),
                    ],
                  ),
                  const Divider(height: 22),
                  Text(
                    statusMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: serviceDisabled || permissionDeniedForever
                          ? Colors.redAccent
                          : Colors.blueGrey.shade700,
                    ),
                  ),
                  if (position != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Accuracy: ±${position!.accuracy.toStringAsFixed(1)} m'
                      '${lastFetchedTime != null ? " • Updated: ${lastFetchedTime!.hour.toString().padLeft(2, '0')}:${lastFetchedTime!.minute.toString().padLeft(2, '0')}:${lastFetchedTime!.second.toString().padLeft(2, '0')}" : ""}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Action: Service Disabled -> Open Location Settings
          if (serviceDisabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: FilledButton.icon(
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Open Device Location Settings'),
                style: FilledButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),

          // Action: Permanently Denied -> Open App Settings
          if (permissionDeniedForever)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: FilledButton.icon(
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
                icon: const Icon(Icons.app_settings_alt_rounded),
                label: const Text('Open App Settings to Enable Permissions'),
                style: FilledButton.styleFrom(
                  backgroundColor: purple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),

          // Primary Enable / Find Location Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: loading ? null : getCurrentLocation,
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        position != null
                            ? Icons.refresh_rounded
                            : Icons.my_location_rounded,
                      ),
                label: Text(
                  loading
                      ? 'Finding Location...'
                      : position != null
                          ? 'Refresh My Current Location'
                          : 'Enable Location',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),

          // Button: Open in Google Maps (Current Location)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: position != null
                    ? openGoogleMapsWithCurrentLocation
                    : null,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Open Current Location in Google Maps'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Button: Walk / Navigate to LBRCE Campus Entrance
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: openDirectionsToCampus,
                icon: const Icon(Icons.directions_walk_rounded, color: green),
                label: const Text(
                  'Directions to LBRCE Main Campus Gate',
                  style: TextStyle(color: navy),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: green, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Campus Reference Pin Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueGrey.shade100),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.school_rounded,
                    color: blue,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Official Campus Entrance Pin',
                          style: TextStyle(
                            color: navy,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '16.749072, 80.634794',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Mylavaram, Krishna Dt., AP',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: openDirectionsToCampus,
                    child: const Text('View Gate'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// DECORATIVE MAP PATTERN PAINTER
// =====================================================

class MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final thinRoadPaint = Paint()
      ..color = const Color(0xFFB8DAB1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 1; i < 7; i++) {
      final x = size.width * i / 7;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x - 25, size.height),
        roadPaint,
      );

      canvas.drawLine(
        Offset(0, size.height * i / 7),
        Offset(size.width, size.height * i / 7 + 12),
        roadPaint,
      );
    }

    for (int i = 0; i < 10; i++) {
      final y = size.height * i / 10;

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + 10),
        thinRoadPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MapPatternPainter oldDelegate) {
    return false;
  }
}