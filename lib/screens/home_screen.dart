import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weddingpro_connect/providers/auth_provider.dart';
import 'package:weddingpro_connect/providers/language_provider.dart';
import 'package:weddingpro_connect/providers/theme_provider.dart';
import 'package:weddingpro_connect/services/booking_service.dart';
import 'package:weddingpro_connect/services/notification_service.dart';
import 'package:weddingpro_connect/widgets/bottom_nav_bar.dart';
import 'package:weddingpro_connect/screens/browse_screen.dart';
import 'package:weddingpro_connect/screens/profile_screen.dart';
import 'package:weddingpro_connect/screens/management_screen.dart';
import 'package:weddingpro_connect/screens/bookings_screen.dart';
import 'package:weddingpro_connect/screens/chat_list_screen.dart';
import 'package:weddingpro_connect/screens/login_selection_screen.dart';
import 'package:weddingpro_connect/screens/notifications_screen.dart';
import 'package:weddingpro_connect/models/user_model.dart';
import 'package:weddingpro_connect/models/booking_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _pendingCategory;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Request permissions (Location and Notifications) when Home Screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    final bool isAdmin = authProvider.userData?.role == UserRole.admin;

    final List<Widget> screens = [
      HomeContent(
        scaffoldKey: _scaffoldKey,
        isAdmin: isAdmin,
        onCategorySelect: (cat) {
          setState(() {
            _pendingCategory = cat;
            _selectedIndex = 1;
          });
        },
        onSeeAllBookings: () => setState(() => _selectedIndex = 3),
      ),
      BrowseScreen(initialCategory: _pendingCategory),
      const ChatListScreen(),
      const BookingsScreen(), 
      ManagementScreen(scaffoldKey: _scaffoldKey),
      const ProfileScreen(), 
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9F7F5),
      drawer: _buildProfessionalDrawer(context, langProvider, authProvider, themeProvider, isAdmin),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        isAdmin: isAdmin,
        onTap: (index) {
          if (index == 5 && !authProvider.isLoggedIn) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginSelectionScreen()),
            );
            return;
          }
          setState(() {
            _selectedIndex = index;
            if (index != 1) _pendingCategory = null;
          });
        },
      ),
    );
  }

  Widget _buildProfessionalDrawer(BuildContext context, LanguageProvider lang, AuthProvider auth, ThemeProvider themeProvider, bool isAdmin) {
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF6A1B9A);
    
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF9C27B0), primaryColor]
              ),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                CircleAvatar(
                  radius: 38, 
                  backgroundColor: Colors.white24, 
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Text(
                      (auth.userData?.fullName.isNotEmpty ?? false)
                          ? auth.userData!.fullName[0].toUpperCase()
                          : '?', 
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)
                    ),
                  )
                ),
                const SizedBox(height: 16),
                Text(auth.isLoggedIn ? auth.userData?.fullName ?? 'User' : 'Guest Account', 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                if (auth.isLoggedIn)
                  Text(auth.userData?.email ?? '', 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _drawerItem(context, Icons.home_rounded, 'Home', () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 0);
                }),
                _drawerItem(context, Icons.chat_rounded, 'Messages', () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 2);
                }),
                _drawerItem(context, Icons.person_rounded, lang.translate('profile'), () {
                  Navigator.pop(context);
                  if (!auth.isLoggedIn) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginSelectionScreen()));
                  } else {
                    setState(() => _selectedIndex = 5);
                  }
                }),
                if (isAdmin)
                  _drawerItem(context, Icons.admin_panel_settings_rounded, 'Admin Panel', () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = 4);
                  }),
                ListTile(
                  leading: Icon(Icons.dark_mode_rounded, color: primaryColor),
                  title: Text(lang.translate('dark_mode')),
                  trailing: Switch(
                    value: themeProvider.isDarkMode, 
                    onChanged: (v) => themeProvider.toggleTheme(v),
                    activeThumbColor: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (auth.isLoggedIn)
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    auth.signOut();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(lang.translate('logout')),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6A1B9A)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}

class HomeContent extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Function(String) onCategorySelect;
  final VoidCallback onSeeAllBookings;
  final bool isAdmin;

  const HomeContent({
    super.key, 
    required this.scaffoldKey,
    required this.onCategorySelect,
    required this.onSeeAllBookings,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    final userName = (userData?.fullName.isNotEmpty == true) 
        ? userData!.fullName 
        : (authProvider.isLoggedIn ? 'User' : 'Guest');
    final primaryPurple = const Color(0xFF6A1B9A);
    final accentPurple = const Color(0xFF9C27B0);
    final topPadding = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PURPLE HEADER section
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, topPadding + 10, 16, 30),
            decoration: BoxDecoration(
              color: primaryPurple,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryPurple.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    // NOTIFICATION ICON
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => scaffoldKey.currentState?.openDrawer(),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Main Promo Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryPurple, accentPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find Your Dream Team',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Browse 8+ verified wedding professionals',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () => onCategorySelect(''), // General browse
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search, color: primaryPurple, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Start exploring',
                            style: TextStyle(
                              color: primaryPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Your Bookings Section
          if (!isAdmin && authProvider.isLoggedIn) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 35, 24, 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Bookings',
                    style: TextStyle(
                      color: Color(0xFF2D1B4D),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextButton(
                    onPressed: onSeeAllBookings,
                    child: Text(
                      'See all',
                      style: TextStyle(color: primaryPurple.withOpacity(0.6), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            FutureBuilder<List<Booking>>(
              future: BookingService.getMyBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final bookings = (snapshot.data ?? []).take(2).toList();
                if (bookings.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text('No recent bookings', style: TextStyle(color: Colors.grey)),
                  );
                }
                return Column(
                  children: bookings.map((b) => _buildBookingCard(b)).toList(),
                );
              },
            ),
          ],

          // Browse by Category Section
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 35, 24, 20),
            child: Text(
              'Browse by Category',
              style: TextStyle(
                color: Color(0xFF2D1B4D),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 0,
              childAspectRatio: 0.8,
              children: [
                _buildCategoryItem(Icons.camera_alt_outlined, 'Photography', 'Photography', const Color(0xFFFFF0F0), Colors.red.shade400),
                _buildCategoryItem(Icons.music_note_outlined, 'Music & DJ', 'Music', const Color(0xFFF5EEFF), Colors.purple.shade400),
                _buildCategoryItem(Icons.home_outlined, 'Venue', 'Venue', const Color(0xFFFFF9E6), Colors.orange.shade300),
                _buildCategoryItem(Icons.content_cut_outlined, 'Hair & Makeup', 'Makeup', const Color(0xFFFFF0F5), Colors.pink.shade300),
                _buildCategoryItem(Icons.local_shipping_outlined, 'Transportation', 'Transport', const Color(0xFFE6F7FF), Colors.blue.shade300),
                _buildCategoryItem(Icons.card_giftcard_outlined, 'Catering & Cake', 'Catering', const Color(0xFFF0FFF4), Colors.green.shade400),
                _buildCategoryItem(Icons.videocam_outlined, 'Videography', 'Videography', const Color(0xFFFFF0F0), Colors.red.shade400),
                _buildCategoryItem(Icons.edit_outlined, 'Florist', 'Florist', const Color(0xFFF5EEFF), Colors.purple.shade400),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.vendorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF2D1B4D),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${booking.vendorCategory} • Florist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              booking.status.name[0].toUpperCase() + booking.status.name.substring(1),
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label, String key, Color bgColor, Color iconColor) {
    return InkWell(
      onTap: () => onCategorySelect(key),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D1B4D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
