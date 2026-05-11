import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../models/trek_session_model.dart';
import '../theme.dart';

class TrekStatsWidget extends StatefulWidget {
  final TrekSession session;

  const TrekStatsWidget({super.key, required this.session});

  @override
  State<TrekStatsWidget> createState() => _TrekStatsWidgetState();
}

class _TrekStatsWidgetState extends State<TrekStatsWidget> {
  bool _isExpanded = false;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: _isExpanded ? 20 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85), // Semi-transparent
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact View
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCompactStat('${widget.session.distanceCoveredKm.toStringAsFixed(2)} KM'),
                _buildDot(),
                _buildCompactStat(_formatDuration(widget.session.timeElapsed)),
                _buildDot(),
                _buildCompactStat('${widget.session.currentSpeedKmh.toStringAsFixed(1)} km/h'),
                _buildDot(),
                _buildCompactStat('↑${widget.session.elevationGainMeters.toInt()}m'),
              ],
            ),
            
            // Expanded View Details
            if (_isExpanded) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailedStat(Symbols.distance, 'Distance', '${widget.session.distanceCoveredKm.toStringAsFixed(2)}', 'km'),
                  _buildDetailedStat(Symbols.timer, 'Time', _formatDuration(widget.session.timeElapsed), ''),
                  _buildDetailedStat(Symbols.speed, 'Speed', '${widget.session.currentSpeedKmh.toStringAsFixed(1)}', 'km/h'),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: AppColors.onSurface,
      ),
    );
  }

  Widget _buildDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.circle,
        size: 4,
        color: AppColors.onSurface.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildDetailedStat(IconData icon, String label, String value, String unit) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ]
          ],
        ),
      ],
    );
  }
}
