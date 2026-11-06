import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final bool isAdmin;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final theme = Theme.of(context);
    final activeColor = const Color(0xFF6A1B9A); // Primary Purple

    // Order: Home(0), Browse(1), Chat(2), Bookings(3), Manage(4), Profile(5)
    final List<Map<String, dynamic>> navItems = [
      {'index': 0, 'icon': Icons.home_rounded, 'label': langProvider.translate('home')},
      {'index': 1, 'icon': Icons.explore_rounded, 'label': langProvider.translate('browse')},
      {'index': 2, 'icon': Icons.chat_bubble_rounded, 'label': 'Chat'}, 
    ];

    if (!isAdmin) {
      navItems.add({'index': 3, 'icon': Icons.calendar_month_rounded, 'label': langProvider.translate('bookings')});
    } else {
      navItems.add({'index': 4, 'icon': Icons.dashboard_customize_rounded, 'label': 'Manage'});
    }

    navItems.add({'index': 5, 'icon': Icons.person_rounded, 'label': langProvider.translate('profile')});

    int displayIndex = navItems.indexWhere((item) => item['index'] == selectedIndex);
    if (displayIndex == -1) displayIndex = 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: activeColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: BottomNavigationBar(
          currentIndex: displayIndex,
          onTap: (index) {
            onTap(navItems[index]['index']);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: activeColor,
          unselectedItemColor: const Color(0xFFBDBDBD),
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          elevation: 0,
          items: navItems.map((item) {
            return BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(item['icon'], size: 24),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item['icon'], size: 22, color: activeColor),
              ),
              label: item['label'],
            );
          }).toList(),
        ),
      ),
    );
  }
}
