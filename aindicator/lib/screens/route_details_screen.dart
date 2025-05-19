import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aindicator/models/route_result.dart';
import 'package:aindicator/utils/app_colors.dart';
import 'package:aindicator/screens/live_schedule_screen.dart';

class RouteDetailsScreen extends StatelessWidget {
  final RouteResult routeResult;
  final VoidCallback? onAddToFavorites;

  const RouteDetailsScreen({
    super.key,
    required this.routeResult,
    this.onAddToFavorites,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Details'),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        actions: [
          // Add to favorites button
          if (onAddToFavorites != null)
            IconButton(
              icon: const Icon(Icons.star_border),
              tooltip: 'Add to favorites',
              onPressed: onAddToFavorites,
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share route functionality
              _shareRoute(context);
            },
          ),
        ],
      ),
      body: Container(
        color: AppColors.backgroundColor,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route Summary Card
                _buildRouteSummaryCard(),
                
                const SizedBox(height: 20),
                
                // Route Details
                _buildSectionHeader('Route Details', Icons.route),
                
                const SizedBox(height: 12),
                
                // Route Stations Timeline
                _buildRouteStationsTimeline(),
                
                const SizedBox(height: 20),
                
                // New Schedule Information Section
                _buildSectionHeader('Schedule Information', Icons.schedule),
                
                const SizedBox(height: 12),
                
                // Schedule Info Card
                _buildScheduleInfoCard(context),
                
                const SizedBox(height: 20),
                
                // Fare Information
                _buildSectionHeader('Fare Information', Icons.attach_money),
                
                const SizedBox(height: 12),
                
                // Fare Card
                _buildFareCard(context),
                
                const SizedBox(height: 20),
                
                // Travel Tips
                _buildSectionHeader('Travel Tips', Icons.lightbulb_outline),
                
                const SizedBox(height: 12),
                
                // Tips Card
                _buildTipsCard(),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: onAddToFavorites != null ? FloatingActionButton(
        onPressed: onAddToFavorites,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.star),
      ) : null,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source to Destination
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.subway,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routeResult.source,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.arrow_downward,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${routeResult.stationCount} stations',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        routeResult.destination,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Divider(height: 32),
            
            // Journey Stats
            Row(
              children: [
                _buildStatItem(
                  Icons.access_time,
                  '${_estimateTravelTime()} min',
                  'Est. Time',
                  AppColors.line1Color,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  Icons.sync_alt,
                  routeResult.hasTransit ? '${routeResult.transitCount}' : 'None',
                  'Transfers',
                  routeResult.hasTransit ? AppColors.line2Color : AppColors.success,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  Icons.attach_money,
                  '₹${routeResult.fare}',
                  'Fare',
                  AppColors.line3Color,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Lines Used
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.linear_scale,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Metro Lines',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          routeResult.lines.join(', '),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 400.ms)
    .slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteStationsTimeline() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: routeResult.route.length,
          itemBuilder: (context, index) {
            final station = routeResult.route[index];
            final isFirst = index == 0;
            final isLast = index == routeResult.route.length - 1;
            final isTransit = routeResult.transit.contains(station);
            
            // Determine line color
            Color lineColor = AppColors.primaryColor;
            if (index < routeResult.route.length - 1) {
              if (index < routeResult.lines.length) {
                final line = routeResult.lines[index];
                if (line == "Line 1") lineColor = AppColors.line1Color;
                else if (line == "Line 2") lineColor = AppColors.line2Color;
                else if (line == "Line 3") lineColor = AppColors.line3Color;
                else if (line == "Line 4") lineColor = AppColors.line4Color;
              }
            }
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isFirst || isLast || isTransit
                            ? lineColor
                            : Colors.white,
                        border: Border.all(
                          color: lineColor,
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: isTransit
                          ? const Icon(
                              Icons.sync_alt,
                              color: Colors.white,
                              size: 14,
                            )
                          : isFirst
                              ? const Icon(
                                  Icons.arrow_upward,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : isLast
                                  ? const Icon(
                                      Icons.arrow_downward,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : null,
                    ),
                    if (index < routeResult.route.length - 1)
                      Column(
                        children: [
                          Container(
                            width: 2,
                            height: 20,
                            color: lineColor,
                          ),
                          // Time indicator
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: lineColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: lineColor.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${_getTimeBetweenStations(index)} min',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: lineColor,
                              ),
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 20,
                            color: lineColor,
                          ),
                        ],
                      ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                // Station Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isFirst || isLast || isTransit
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isFirst || isLast || isTransit
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isFirst)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Start',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (isLast)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.line2Color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'End',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.line2Color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (isTransit)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Transfer Station',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 500.ms, delay: 200.ms)
    .slideY(begin: 0.2, end: 0);
  }

  Widget _buildScheduleInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Live Schedule',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LiveScheduleScreen(
                          preselectedStation: routeResult.route.first,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View Schedule'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.train,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Next train from ${routeResult.route.first}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.dividerColor,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Check live train schedules for exact departure times',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Trains run approximately every 5-15 minutes during peak hours',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (routeResult.isMultiLine)
              Row(
                children: [
                  const Icon(
                    Icons.transfer_within_a_station,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Transfer required at ${routeResult.transit.join(", ")}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFareCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.attach_money,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Fare',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '₹${routeResult.fare}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    // Copy fare to clipboard
                    Clipboard.setData(ClipboardData(text: '₹${routeResult.fare}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fare copied to clipboard'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white70,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Fares may vary based on time of day and special events. Children under 5 travel free.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 500.ms, delay: 400.ms)
    .slideY(begin: 0.2, end: 0);
  }

  Widget _buildTipsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTipItem(
              Icons.access_time,
              'Peak Hours',
              'Expect more crowded trains during 8-10 AM and 5-7 PM.',
              AppColors.line1Color,
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              Icons.credit_card,
              'Payment Options',
              'Use metro card for faster entry and discounted fares.',
              AppColors.line2Color,
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              Icons.transfer_within_a_station,
              'Transfers',
              'Follow the signs for smooth transfers between lines.',
              AppColors.line3Color,
            ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 500.ms, delay: 600.ms)
    .slideY(begin: 0.2, end: 0);
  }

  Widget _buildTipItem(IconData icon, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to estimate travel time based on number of stations
  int _estimateTravelTime() {
    // Simple calculation: 2-3 minutes per station
    return (routeResult.stationCount * 2.5).round();
  }

  // Helper method to get time between stations
  int _getTimeBetweenStations(int index) {
    // This is a simplified approach - in a real app, you'd get this data from the backend
    // For now, we'll use a simple calculation based on the line
    int baseTime = 2; // Base time in minutes
    
    // Different lines might have different speeds
    if (index < routeResult.lines.length) {
      final line = routeResult.lines[index];
      if (line == "Line 1") baseTime = 2;
      else if (line == "Line 2") baseTime = 3;
      else if (line == "Line 3") baseTime = 2;
      else if (line == "Line 4") baseTime = 3;
    }
    
    return baseTime;
  }

  // Share route functionality
  void _shareRoute(BuildContext context) {
    final String routeText = 'A-Indicator Route: ${routeResult.source} to ${routeResult.destination}\n'
        'Stations: ${routeResult.stationCount}\n'
        'Fare: ₹${routeResult.fare}\n'
        'Lines: ${routeResult.lines.join(", ")}';
    
    Clipboard.setData(ClipboardData(text: routeText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Route details copied to clipboard'),
        backgroundColor: AppColors.success,
      ),
    );
  }
} 