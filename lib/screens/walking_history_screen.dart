import 'package:material_ui/material_ui.dart';
import '../models/walking_activity_model.dart';
import '../services/walking_storage_service.dart';
import '../state/navigation_state_manager.dart';
import 'walking_activity_detail_screen.dart';

class WalkingHistoryScreen extends StatefulWidget {
  const WalkingHistoryScreen({super.key});

  @override
  State<WalkingHistoryScreen> createState() => _WalkingHistoryScreenState();
}

class _WalkingHistoryScreenState extends State<WalkingHistoryScreen> {
  final WalkingStorageService _storageService = WalkingStorageService();
  List<WalkingActivity> _activities = [];
  double _totalDistanceKm = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final activities = await _storageService.getActivities();
    final totalDist = await _storageService.getTotalDistance();

    if (mounted) {
      setState(() {
        _activities = activities;
        _totalDistanceKm = totalDist;
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[dt.month - 1];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month ${dt.day}, ${dt.year} • $hour:$minute $period';
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Walking Activities',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (_activities.isNotEmpty) ...[
                    // Summary Header Card
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF0EA5E9),
                              const Color(0xFF0284C7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0EA5E9)
                                  .withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem(
                              title: 'TOTAL WALKS',
                              value: '${_activities.length}',
                              icon: Icons.directions_walk,
                            ),
                            Container(
                              width: 1,
                              height: 44,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            _buildSummaryItem(
                              title: 'DISTANCE',
                              value:
                                  '${_totalDistanceKm.toStringAsFixed(1)} KM',
                              icon: Icons.alt_route,
                            ),
                            Container(
                              width: 1,
                              height: 44,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            _buildSummaryItem(
                              title: 'AVG DIST',
                              value: _activities.isEmpty
                                  ? '0.0 KM'
                                  : '${(_totalDistanceKm / _activities.length).toStringAsFixed(1)} KM',
                              icon: Icons.trending_up,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Section Title
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Text(
                              'RECORDED SESSIONS',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5E9)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _activities.length.toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0EA5E9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Activities List
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final activity = _activities[index];
                          return _buildActivityCard(context, activity);
                        },
                        childCount: _activities.length,
                      ),
                    ),
                  ],

                  // Empty State
                  if (_activities.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0EA5E9)
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.directions_walk,
                                  size: 64,
                                  color: Color(0xFF0EA5E9),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No Walks Recorded Yet',
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(fontSize: 20),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Track your walks, neighborhood strolls, or hikes independently from fort treks.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  NavigationStateManager()
                                      .navigateToLive(walkingMode: true);
                                },
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Start Walking Activity'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0EA5E9),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(BuildContext context, WalkingActivity activity) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    WalkingActivityDetailScreen(activity: activity),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Date & Arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0EA5E9)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.directions_walk,
                            color: Color(0xFF0EA5E9),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(activity.startTime),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (activity.startLocationName != null)
                              Text(
                                activity.startLocationName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Metrics Row: Distance, Duration, Avg Speed, Max Speed
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatInfo(
                      context,
                      Icons.straighten,
                      '${activity.distanceKm.toStringAsFixed(2)} KM',
                      'DISTANCE',
                      const Color(0xFF0EA5E9),
                    ),
                    _buildStatInfo(
                      context,
                      Icons.timer_outlined,
                      _formatDuration(activity.duration),
                      'DURATION',
                      Colors.amber.shade700,
                    ),
                    _buildStatInfo(
                      context,
                      Icons.speed,
                      '${activity.avgSpeedKmh.toStringAsFixed(1)} km/h',
                      'AVG SPEED',
                      Colors.purple.shade400,
                    ),
                    _buildStatInfo(
                      context,
                      Icons.bolt,
                      '${activity.maxSpeedKmh.toStringAsFixed(1)} km/h',
                      'MAX SPEED',
                      Colors.deepOrangeAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatInfo(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

