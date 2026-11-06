import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:weddingpro_connect/models/user_model.dart';
import 'package:weddingpro_connect/models/booking_model.dart';
import 'package:weddingpro_connect/providers/auth_provider.dart';
import 'package:weddingpro_connect/services/booking_service.dart';
import 'package:weddingpro_connect/screens/notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool isEditing = false;
  
  int totalBookings = 0;
  int confirmedBookings = 0;
  int pendingBookings = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() async {
    try {
      final bookings = await BookingService.getMyBookings();
      if (mounted) {
        setState(() {
          totalBookings = bookings.length;
          confirmedBookings = bookings.where((b) => b.status == BookingStatus.confirmed).length;
          pendingBookings = bookings.where((b) => b.status == BookingStatus.pending).length;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final primaryPurple = const Color(0xFF6A1B9A);
    final darkPurple = const Color(0xFF2D1B4D);
    final accentPink = const Color(0xFFD84B6B);
    final userData = auth.userData;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F5),
      body: Column(
        children: [
          // PURPLE TOP BAR with Notification
          Container(
            padding: EdgeInsets.fromLTRB(24, topPadding + 10, 12, 25),
            width: double.infinity,
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
                const Text(
                  'My Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Avatar Section
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: accentPink,
                        child: Text(
                          userData?.fullName.isNotEmpty == true ? userData!.fullName[0].toUpperCase() : 'J',
                          style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(Icons.camera_alt, size: 18, color: primaryPurple.withOpacity(0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      userData?.fullName ?? 'User Name',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: darkPurple),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      userData?.email ?? 'email@example.com',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: darkPurple.withOpacity(0.5), fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentPink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      userData?.role.name.toUpperCase() ?? 'USER',
                      style: TextStyle(color: accentPink, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Stats Cards
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildStatCard(totalBookings.toString(), 'Total', accentPink),
                        _buildStatCard(confirmedBookings.toString(), 'Confirmed', const Color(0xFF4CAF50)),
                        _buildStatCard(pendingBookings.toString(), 'Pending', const Color(0xFFFFB300)),
                      ],
                    ),
                  ),

                  // Info Container
                  const SizedBox(height: 30),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Personal Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkPurple)),
                            Text('Edit', style: TextStyle(color: accentPink, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 25),
                        _buildInfoField(Icons.person_outline, 'FULL NAME', userData?.fullName ?? 'Not set', darkPurple),
                        _buildInfoField(Icons.phone_outlined, 'PHONE', userData?.phone ?? 'Not set', darkPurple),
                        _buildInfoField(Icons.favorite_border, 'WEDDING DATE', userData?.weddingDate != null ? DateFormat('dd MMM yyyy').format(userData!.weddingDate!) : 'Not set', darkPurple),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(thickness: 0.5),
                        ),
                        
                        Text('LOCATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentPink, letterSpacing: 0.8)),
                        const SizedBox(height: 20),
                        _buildInfoField(Icons.map_outlined, 'STATE / PROVINCE *', userData?.state ?? 'Not set', darkPurple),
                        _buildInfoField(Icons.location_on_outlined, 'CITY / DISTRICT *', userData?.city ?? 'Not set', darkPurple),
                      ],
                    ),
                  ),
                  
                  // Sign Out Button
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => auth.signOut(),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('SIGN OUT'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(IconData icon, String label, String value, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: primary.withOpacity(0.4)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primary.withOpacity(0.3))),
                    const SizedBox(height: 4),
                    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primary), overflow: TextOverflow.ellipsis, maxLines: 2),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, thickness: 0.3),
        ],
      ),
    );
  }
}
