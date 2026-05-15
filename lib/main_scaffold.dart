import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/map_screen.dart';
import 'screens/live_tracking_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/app_drawer.dart';
import 'models/fort_model.dart';
import 'app_theme.dart';
import 'state/navigation_state_manager.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  Fort? _activeFort;

  late final List<Widget> _screens = [
    MapScreen(
      onStartTrek: (fort) {
        setState(() {
          _activeFort = fort;
        });
        NavigationStateManager().selectedIndex.value = 1; // Switch to Live tracking tab
      },
    ),
    LiveTrackingScreen(activeFort: _activeFort),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NavigationStateManager().selectedIndex,
      builder: (context, selectedIndex, child) {
        return Scaffold(
          extendBody: true,
          drawer: const AppDrawer(),
          appBar: AppBar(
            shape: Border(
              bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3), width: 1),
            ),
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Symbols.menu, color: Theme.of(context).colorScheme.primary),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Text(
              'ZENITREK',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 18,
                    letterSpacing: 2.0,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      final photoUrl = snapshot.data?.photoURL;
                      return Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                          image: photoUrl != null 
                            ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                            : null,
                        ),
                        child: photoUrl == null ? Icon(Symbols.person, size: 20, color: Theme.of(context).colorScheme.onSurface) : null,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          body: selectedIndex == 1 
              ? LiveTrackingScreen(activeFort: _activeFort) // dynamically pass active fort
              : _screens[selectedIndex],
          bottomNavigationBar: SafeArea(
            child: Container(
              height: 80,
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, selectedIndex, Symbols.explore, 'Map'),
                  _buildNavItem(1, selectedIndex, Symbols.distance, 'Live'),
                  _buildNavItem(2, selectedIndex, Symbols.person, 'Profile'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, int selectedIndex, IconData icon, String label) {
    bool isSelected = selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: () => NavigationStateManager().selectedIndex.value = index,
      child: Container(
        width: 80,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              size: 24,
              fill: isSelected ? 1 : 0,
            ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
