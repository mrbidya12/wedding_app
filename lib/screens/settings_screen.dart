import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weddingpro_connect/providers/auth_provider.dart';
import 'package:weddingpro_connect/providers/language_provider.dart';
import 'package:weddingpro_connect/providers/theme_provider.dart';
import 'package:weddingpro_connect/screens/profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [secondaryColor, primaryColor],
            ),
          ),
        ),
        elevation: 0,
        title: Text(
          langProvider.translate('settings').toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          _buildSectionHeader(langProvider.translate('account'), primaryColor),
          _buildSettingItem(
            context: context,
            icon: Icons.person_rounded,
            title: langProvider.translate('edit_profile'),
            subtitle: langProvider.translate('edit_profile_sub'),
            primaryColor: primaryColor,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          _buildSettingItem(
            context: context,
            icon: Icons.notifications_active_rounded,
            title: langProvider.translate('notifications'),
            subtitle: langProvider.translate('notifications_sub'),
            primaryColor: primaryColor,
            trailing: Switch(
              value: true, 
              onChanged: (v) {},
              activeColor: primaryColor,
            ),
          ),
          
          _buildSectionHeader(langProvider.translate('preferences'), primaryColor),
          _buildSettingItem(
            context: context,
            icon: Icons.translate_rounded,
            title: langProvider.translate('language'),
            subtitle: 'Current: ${langProvider.currentLocale.languageCode.toUpperCase()}',
            primaryColor: primaryColor,
            onTap: () => _showLanguageDialog(context, langProvider, primaryColor),
          ),
          _buildSettingItem(
            context: context,
            icon: Icons.dark_mode_rounded,
            title: langProvider.translate('dark_mode'),
            subtitle: langProvider.translate('dark_mode_sub'),
            primaryColor: primaryColor,
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(value),
              activeColor: primaryColor,
            ),
          ),

          _buildSectionHeader(langProvider.translate('support'), primaryColor),
          _buildSettingItem(
            context: context,
            icon: Icons.help_center_rounded,
            title: langProvider.translate('help'),
            subtitle: 'FAQs and support center',
            primaryColor: primaryColor,
          ),
          _buildSettingItem(
            context: context,
            icon: Icons.shield_rounded,
            title: langProvider.translate('privacy'),
            subtitle: 'Your data and privacy settings',
            primaryColor: primaryColor,
          ),
          _buildSettingItem(
            context: context,
            icon: Icons.verified_user_rounded,
            title: langProvider.translate('terms'),
            subtitle: 'Usage terms and conditions',
            primaryColor: primaryColor,
          ),

          const SizedBox(height: 30),
          if (authProvider.isLoggedIn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                onPressed: () {
                  authProvider.signOut();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text(langProvider.translate('logout').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
              ),
            ),
          
          const SizedBox(height: 40),
          const Center(
            child: Text(
              'KBIDU • Version 1.2.0',
              style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 25, 24, 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: color.withOpacity(0.6),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primaryColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryColor, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black87)),
        subtitle: subtitle.isNotEmpty ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)) : null,
        trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[300]),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider langProvider, Color primaryColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language', style: TextStyle(fontWeight: FontWeight.w900)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _langOption(context, 'English', 'en', langProvider, primaryColor),
            _langOption(context, 'Odia (ଓଡ଼ିଆ)', 'or', langProvider, primaryColor),
            _langOption(context, 'Hindi (हिंदी)', 'hi', langProvider, primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _langOption(BuildContext context, String name, String code, LanguageProvider langProvider, Color color) {
    bool isSelected = langProvider.currentLocale.languageCode == code;
    return ListTile(
      title: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: isSelected ? color : Colors.black87)),
      trailing: isSelected ? Icon(Icons.check_circle_rounded, color: color) : null,
      onTap: () {
        langProvider.changeLanguage(code);
        Navigator.pop(context);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    );
  }
}
