import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/map_screen.dart';
import 'screens/live_tracking_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/app_drawer.dart';
import 'models/fort_model.dart';
import 'state/navigation_state_manager.dart';
import 'state/trek_state_manager.dart';
import 'state/walking_state_manager.dart';
import 'services/live_session_storage_service.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with WidgetsBindingObserver {
  Fort? _activeFort;
  bool _isWalkingMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NavigationStateManager().isWalkingMode.addListener(_handleWalkingModeChange);
    _restoreActiveSessionIfAny();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      TrekStateManager().saveCurrentState();
      WalkingStateManager().saveCurrentState();
    }
  }

  Future<void> _restoreActiveSessionIfAny() async {
    final sessionStorage = LiveSessionStorageService();
    final activeType = await sessionStorage.getActiveSessionType();
    if (activeType == ActiveSessionType.fortTrek) {
      final trekManager = TrekStateManager();
      final restored = await trekManager.restoreActiveSession();
      if (restored && mounted) {
        setState(() {
          _activeFort = trekManager.session?.activeFort;
          _isWalkingMode = false;
        });
        NavigationStateManager().isWalkingMode.value = false;
      }
    } else if (activeType == ActiveSessionType.walking) {
      final walkingManager = WalkingStateManager();
      final restored = await walkingManager.restoreActiveSession();
      if (restored && mounted) {
        setState(() {
          _isWalkingMode = true;
        });
        NavigationStateManager().isWalkingMode.value = true;
      }
    }
  }

  void _handleWalkingModeChange() {
    if (mounted) {
      setState(() {
        _isWalkingMode = NavigationStateManager().isWalkingMode.value;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NavigationStateManager().isWalkingMode.removeListener(_handleWalkingModeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return ValueListenableBuilder<int>(
      valueListenable: NavigationStateManager().selectedIndex,
      builder: (context, selectedIndex, child) {
        return Scaffold(
          extendBody: true,
          drawer: const AppDrawer(),
          appBar: AppBar(
            shape: Border(
              bottom: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(
                  Icons.menu,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
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
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          image: photoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(photoUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: photoUrl == null
                            ? Icon(
                                Icons.person,
                                size: 20,
                                color: Theme.of(context).colorScheme.onSurface,
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          body: IndexedStack(
            index: selectedIndex,
            children: [
              MapScreen(
                onStartTrek: (fort) {
                  final trekManager = TrekStateManager();
                  if (trekManager.isTrekking || trekManager.isPaused) {
                    NavigationStateManager().navigateToLive(walkingMode: false);
                    return;
                  }
                  setState(() {
                    _activeFort = fort;
                    _isWalkingMode = false;
                  });
                  NavigationStateManager().navigateToLive(walkingMode: false);
                },
                onStartWalk: () {
                  final walkingManager = WalkingStateManager();
                  if (walkingManager.isWalking || walkingManager.isPaused) {
                    NavigationStateManager().navigateToLive(walkingMode: true);
                    return;
                  }
                  setState(() {
                    _isWalkingMode = true;
                  });
                  NavigationStateManager().navigateToLive(walkingMode: true);
                },
              ),
              LiveTrackingScreen(
                activeFort: _activeFort ?? TrekStateManager().session?.activeFort,
                initialWalkingMode: _isWalkingMode,
                onModeChanged: (isWalking) {
                  setState(() {
                    _isWalkingMode = isWalking;
                  });
                  NavigationStateManager().isWalkingMode.value = isWalking;
                },
              ),
              const ProfileScreen(),
            ],
          ),
          bottomNavigationBar: SafeArea(
            bottom: true,
            child: Container(
              height: 80,
              margin: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: bottomPadding > 0 ? 8 : 16,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    0,
                    selectedIndex,
                    Icons.explore_outlined,
                    'Map',
                  ),
                  _buildNavItem(1, selectedIndex, Icons.directions_run, 'Live'),
                  _buildNavItem(
                    2,
                    selectedIndex,
                    Icons.person_outline,
                    'Profile',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    int index,
    int selectedIndex,
    IconData icon,
    String label,
  ) {
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
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
              size: 24,
              fill: isSelected ? 1 : 0,
            ),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
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
