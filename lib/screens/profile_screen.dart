import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../models/fort_model.dart';
import '../services/conquest_storage_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/profile_stats_widget.dart';
import '../widgets/expedition_card_widget.dart';
import 'trek_history_screen.dart';
import '../app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ConquestStorageService _storageService = ConquestStorageService();
  final UserProfileService _profileService = UserProfileService();
  
  ConquestStats? _stats;
  Position? _currentPosition;
  String? _readableLocation;
  List<Fort> _nearbySuggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    
    final stats = await _storageService.getStats();
    final position = await _profileService.getCurrentLocation();
    
    String? locationName;
    if (position != null) {
      locationName = await _profileService.getReadableLocation(position);
    }

    List<Fort> suggestions = [];
    if (stats.expeditions.isEmpty && position != null) {
      suggestions = await _profileService.getNearbyFortSuggestions(
        LatLng(position.latitude, position.longitude),
      );
    }

    if (mounted) {
      setState(() {
        _stats = stats;
        _currentPosition = position;
        _readableLocation = locationName;
        _nearbySuggestions = suggestions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = _profileService.currentUser;
    final displayName = user?.displayName ?? 'Explorer';
    final photoUrl = user?.photoURL;
    final colorScheme = Theme.of(context).colorScheme;
    
    return RefreshIndicator(
      onRefresh: _loadProfileData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null ? Icon(Symbols.person, size: 40, color: colorScheme.primary) : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: Theme.of(context).textTheme.displayLarge),
                      Text(
                        user?.email ?? 'Join the expedition', 
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // Location Chip
            if (_currentPosition != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.location_on, size: 16, color: colorScheme.secondary),
                    const SizedBox(width: 6),
                    Text(
                      _readableLocation ?? '${_currentPosition!.latitude.toStringAsFixed(2)}, ${_currentPosition!.longitude.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Stats Dashboard
            ProfileStatsWidget(
              totalDistance: _stats?.totalDistanceKm ?? 0.0,
              totalTreks: _stats?.totalTreks ?? 0,
              fortsConquered: _stats?.conqueredFortIds.length ?? 0,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrekHistoryScreen(expeditions: _stats?.expeditions ?? []),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Expeditions or Suggestions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _stats!.expeditions.isNotEmpty ? 'Recent Expeditions' : 'Suggested for You',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                if (_stats!.expeditions.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrekHistoryScreen(expeditions: _stats?.expeditions ?? []),
                        ),
                      );
                    },
                    child: Text('View All', style: TextStyle(fontSize: 12, color: colorScheme.secondary)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_stats!.expeditions.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _stats!.expeditions.map((e) => ExpeditionCardWidget.recent(expedition: e)).toList(),
                ),
              )
            else if (_nearbySuggestions.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _nearbySuggestions.map((f) {
                    double dist = 0;
                    if (_currentPosition != null) {
                      dist = const Distance().as(
                        LengthUnit.Meter, 
                        LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 
                        f.location
                      );
                    }
                    return ExpeditionCardWidget.suggested(fort: f, distanceToUser: dist);
                  }).toList(),
                ),
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'Start your first trek to see achievements!',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
