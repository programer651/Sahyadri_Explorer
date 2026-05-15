import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../app_theme.dart';
import '../main_scaffold.dart';
import '../screens/settings_screen.dart';
import '../screens/onboarding_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out of ZeniTrek?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Logout', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Not logged in';
    final photoUrl = user?.photoURL;
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: Column(
        children: [
          // Custom Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 64, bottom: 24, left: 24, right: 24),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              image: DecorationImage(
                image: const NetworkImage('https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&q=80&w=1000'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  colorScheme.primary.withValues(alpha: 0.8),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white24,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null ? const Icon(Symbols.person, color: Colors.white, size: 32) : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? 'ZeniTrek',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerTile(context, Symbols.home, 'Home', () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScaffold()));
                }),
                _buildDrawerTile(context, Symbols.map, 'Map View', () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScaffold()));
                }),
                _buildDrawerTile(context, Symbols.favorite, 'Favorites', () {
                  Navigator.pop(context);
                }, trailing: 'Coming Soon'),
                const Divider(height: 32, indent: 24, endIndent: 24),
                _buildDrawerTile(context, Symbols.settings, 'Settings', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                }),
                _buildDrawerTile(context, Symbols.info, 'About', () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => const AlertDialog(
                      title: Text('About ZeniTrek'),
                      content: Text('Your companion for discovering the majestic peaks and trails.\n\nVersion 1.0.0'),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Logout Item
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: Icon(Symbols.logout, color: colorScheme.error),
            title: Text('Logout', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
            onTap: () => _handleLogout(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(BuildContext context, IconData icon, String title, VoidCallback onTap, {String? trailing}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: trailing != null ? Text(trailing, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)) : null,
      onTap: onTap,
    );
  }
}
