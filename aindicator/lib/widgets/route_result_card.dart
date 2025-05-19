import 'package:flutter/material.dart';
import 'package:aindicator/models/route_result.dart';
import 'package:aindicator/utils/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RouteResultCard extends StatelessWidget {
  final RouteResult routeResult;

  const RouteResultCard({
    super.key,
    required this.routeResult,
  });

  @override
  Widget build(BuildContext context) {
    if (routeResult.error != null) {
      return _buildErrorCard(routeResult.error!);
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Summary
            _buildRouteSummary(),
            
            const Divider(height: 32),
            
            // Route Details
            const Row(
              children: [
                Icon(
                  Icons.route,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Route Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Route Stations
            _buildRouteStations(),
            
            const SizedBox(height: 24),
            
            // Fare Information
            _buildFareInfo(),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 500.ms)
    .slideY(begin: 0.2, end: 0);
  }

  Widget _buildErrorCard(String error) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: AppColors.error.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Please try different stations or check your connection.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 500.ms);
  }

  Widget _buildRouteSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source to Destination
          Row(
            children: [
              const Icon(
                Icons.subway,
                color: AppColors.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeResult.source,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'to',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      routeResult.destination,
                      style: const TextStyle(
                        fontSize: 16,
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
          
          const SizedBox(height: 16),
          
          // Journey Stats
          Row(
            children: [
              _buildStatItem(
                Icons.location_on,
                '${routeResult.stationCount} Stations',
                AppColors.line1Color,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                Icons.sync_alt,
                routeResult.hasTransit
                    ? '${routeResult.transitCount} Transfers'
                    : 'Direct Route',
                routeResult.hasTransit ? AppColors.line2Color : AppColors.success,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Lines Used
          Row(
            children: [
              _buildStatItem(
                Icons.linear_scale,
                'Lines: ${routeResult.lines.join(", ")}',
                AppColors.line3Color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteStations() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
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
            final nextStation = routeResult.route[index + 1];
            // This is a simplified approach - in a real app, you'd need to determine
            // which line connects these two stations
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
                    Container(
                      width: 2,
                      height: 40,
                      color: lineColor,
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
    );
  }

  Widget _buildFareInfo() {
    return Container(
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
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
                'Fare',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              Text(
                '₹${routeResult.fare}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              // Share or save route
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
} 