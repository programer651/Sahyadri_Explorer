import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'screens/map_screen.dart';
import 'screens/live_tracking_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/app_drawer.dart';
import 'models/fort_model.dart';
import 'theme.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  Fort? _activeFort;

  late final List<Widget> _screens = [
    MapScreen(
      onStartTrek: (fort) {
        setState(() {
          _activeFort = fort;
          _selectedIndex = 1; // Switch to Live tracking tab
        });
      },
    ),
    LiveTrackingScreen(activeFort: _activeFort),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBFB),
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0x1F000000), width: 1),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Symbols.menu, color: AppColors.primaryContainer),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'SAHYADRI EXPLORER',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 18,
                letterSpacing: 2.0,
                color: AppColors.primaryContainer,
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
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF5F5F4)),
                  image: const DecorationImage(
                    image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuC5bzyJvs1dPbbDGhnGMc8kehdF_lk8bt8PikfStYWkwP4hkilIgY5ahnnc8iZrvonFh1ra3O5VXrKmUTV_LXQ0MO2nWpno1gs87lraETkG6n5gW6oeRXFFr1yD9GfZO3Hffg5cSA6_NtR9WDL3oss8WpLiVtAL4HqLE94TFUMETAgZ1-APnTxlJZ0s0JwA0hjK6jNZyq1oH8rc0ldCk1dTP43UuCkvB7oOvTLyDjowT87qwjJkAJxdT8wDKaOJrb-C2X3mtTokLcA'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _selectedIndex == 1 
          ? LiveTrackingScreen(activeFort: _activeFort) // dynamically pass active fort
          : _screens[_selectedIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 80,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Symbols.explore, 'Map'),
            _buildNavItem(1, Symbols.distance, 'Live'),
            _buildNavItem(2, Symbols.person, 'Profile'),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        width: 80,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF78716C),
              size: 24,
              fill: isSelected ? 1 : 0,
            ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF78716C),
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
