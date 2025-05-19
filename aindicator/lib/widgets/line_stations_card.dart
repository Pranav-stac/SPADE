import 'package:flutter/material.dart';
import 'package:aindicator/utils/app_colors.dart';

class LineStationsCard extends StatelessWidget {
  final String lineId;
  final String lineName;
  final List<String> stations;
  final Color lineColor;

  const LineStationsCard({
    super.key,
    required this.lineId,
    required this.lineName,
    required this.stations,
    required this.lineColor,
  });

  // Helper method to get estimated time between stations
  String _getTimeBetweenStations(int index) {
    // This is a simplified approach - in a real app, you'd get this data from the backend
    // For now, we'll use a simple calculation based on line and station index
    int baseTime = 2; // Base time in minutes
    
    // Different lines might have different speeds
    if (lineId == "1") baseTime = 2;
    else if (lineId == "2") baseTime = 3;
    else if (lineId == "3") baseTime = 2;
    else if (lineId == "4") baseTime = 3;
    
    // Return the time as a string
    return "$baseTime min";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Line $lineId',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: lineColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lineName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Line Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line Stats
                Row(
                  children: [
                    _buildStatItem(
                      Icons.location_on,
                      '${stations.length} Stations',
                      lineColor,
                    ),
                    const SizedBox(width: 16),
                    _buildStatItem(
                      Icons.access_time,
                      '5:00 AM - 11:00 PM',
                      lineColor,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Stations List
                const Text(
                  'Stations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Stations Timeline
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stations.length,
                  itemBuilder: (context, index) {
                    final station = stations[index];
                    final isFirst = index == 0;
                    final isLast = index == stations.length - 1;
                    
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline
                        Column(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: isFirst || isLast
                                    ? lineColor
                                    : Colors.white,
                                border: Border.all(
                                  color: lineColor,
                                  width: 2,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            if (index < stations.length - 1)
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
                                      _getTimeBetweenStations(index),
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
                        
                        const SizedBox(width: 12),
                        
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
                                    fontWeight: isFirst || isLast
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isFirst || isLast
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                if (isFirst)
                                  Text(
                                    'Start',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: lineColor,
                                    ),
                                  )
                                else if (isLast)
                                  Text(
                                    'End',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: lineColor,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
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
} 