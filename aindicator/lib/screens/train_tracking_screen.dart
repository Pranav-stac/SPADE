import 'package:flutter/material.dart';
import 'dart:async';
import 'package:aindicator/utils/app_colors.dart';
import 'package:aindicator/services/api_service.dart';
import 'package:aindicator/widgets/loading_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class TrainTrackingScreen extends StatefulWidget {
  final String? preselectedTripId;

  const TrainTrackingScreen({
    super.key,
    this.preselectedTripId,
  });

  @override
  State<TrainTrackingScreen> createState() => _TrainTrackingScreenState();
}

class _TrainTrackingScreenState extends State<TrainTrackingScreen> {
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> _trainLocations = [];
  Map<String, dynamic>? _selectedTrain;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  DateTime _currentTime = DateTime.now();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Set up a timer to refresh data every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      // Get all current train locations
      final trainLocations = await _apiService.getTrainLocations();
      
      setState(() {
        _trainLocations = trainLocations;
        _currentTime = DateTime.now();
        _isLoading = false;
      });
      
      // If a trip ID is preselected, select that train
      if (widget.preselectedTripId != null) {
        _selectTrainByTripId(widget.preselectedTripId!);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load train locations: $e';
      });
    }
  }

  void _selectTrainByTripId(String tripId) {
    for (var train in _trainLocations) {
      if (train['trip_id'] == tripId) {
        setState(() {
          _selectedTrain = train;
        });
        return;
      }
    }
  }

  Future<void> _refreshData() async {
    try {
      final trainLocations = await _apiService.getTrainLocations();
      
      setState(() {
        _trainLocations = trainLocations;
        _currentTime = DateTime.now();
        
        // If a train was selected, update its data
        if (_selectedTrain != null) {
          final String tripId = _selectedTrain!['trip_id'];
          _selectedTrain = trainLocations.firstWhere(
            (train) => train['trip_id'] == tripId,
            orElse: () => _selectedTrain!,
          );
        }
      });
    } catch (e) {
      // Silent failure on background refresh
      print('Failed to refresh train locations: $e');
    }
  }

  String _formatProgress(double progress) {
    return '${(progress * 100).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Train Tracking'),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        color: AppColors.backgroundColor,
        child: _isLoading
            ? const Center(child: LoadingIndicator())
            : _hasError
                ? _buildErrorWidget()
                : _trainLocations.isEmpty
                    ? _buildNoTrainsWidget()
                    : _buildTrackingContent(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 64,
          ).animate().fadeIn(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildNoTrainsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/no_trains.png',
            width: 150,
            height: 150,
          ).animate().fadeIn(),
          const SizedBox(height: 24),
          const Text(
            'No trains currently running',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 12),
          const Text(
            'Check back during operational hours',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 450.ms),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _refreshData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildTrackingContent() {
    return Column(
      children: [
        // Time info bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trains in service: ${_trainLocations.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Updated: ${DateFormat('HH:mm:ss').format(_currentTime)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        
        // Main content - map or list depending on selection
        Expanded(
          child: _selectedTrain == null
              ? _buildTrainList()
              : _buildTrainDetails(),
        ),
      ],
    );
  }

  Widget _buildTrainList() {
    // Check if there are no trains running
    if (_trainLocations.isEmpty) {
      return _buildNoTrainsWidget();
    }
    
    // Group trains by line
    final Map<String, List<Map<String, dynamic>>> trainsByLine = {};
    
    for (var train in _trainLocations) {
      final String line = train['line'] ?? 'Unknown';
      if (!trainsByLine.containsKey(line)) {
        trainsByLine[line] = [];
      }
      trainsByLine[line]!.add(train);
    }
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        for (var entry in trainsByLine.entries)
          _buildLineSection(entry.key, entry.value),
      ],
    );
  }

  Widget _buildLineSection(String line, List<Map<String, dynamic>> trains) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getLineColor(line),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                line,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${trains.length} trains)',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        ...trains.map((train) => _buildTrainCard(train)).toList(),
        const Divider(thickness: 1),
      ],
    );
  }

  Widget _buildTrainCard(Map<String, dynamic> train) {
    final String status = train.containsKey('at_station')
        ? 'At ${train['at_station']}'
        : 'En route: ${train['from_station']} → ${train['to_station']}';
    
    final double progress = train['progress'] ?? 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTrain = train;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.train,
                    color: _getLineColor(train['line'] ?? ''),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Train ${train['trip_id']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: train.containsKey('at_station')
                          ? AppColors.success
                          : AppColors.info,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      train.containsKey('at_station') ? 'At Station' : 'En Route',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (train.containsKey('at_station'))
                Text(
                  'Departs in: ${train['seconds_until_departure'] != null ? _formatTime(train['seconds_until_departure']) : 'Unknown'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getLineColor(train['line'] ?? ''),
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatProgress(progress),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Arrives in: ${train['seconds_to_next_station'] != null ? _formatTime(train['seconds_to_next_station']) : 'Unknown'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainDetails() {
    if (_selectedTrain == null) {
      return const Center(child: Text('No train selected'));
    }
    
    final train = _selectedTrain!;
    final String line = train['line'] ?? 'Unknown';
    final String direction = train['direction'] ?? 'Unknown';
    final bool isAtStation = train.containsKey('at_station');
    
    return Column(
      children: [
        // Train info header
        Container(
          width: double.infinity,
          color: _getLineColor(line).withOpacity(0.1),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.train,
                    color: _getLineColor(line),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Train ${train['trip_id']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '$line - $direction',
                          style: TextStyle(
                            fontSize: 14,
                            color: _getLineColor(line),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedTrain = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isAtStation ? AppColors.success : AppColors.info,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isAtStation ? 'At Station' : 'En Route',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              isAtStation
                  ? _buildAtStationInfo(train)
                  : _buildEnRouteInfo(train),
            ],
          ),
        ),
        
        // Train route visualization
        Expanded(
          child: _buildTrainRouteVisualization(),
        ),
      ],
    );
  }

  Widget _buildAtStationInfo(Map<String, dynamic> train) {
    final String stationName = train['at_station'] ?? 'Unknown Station';
    final String departureTime = train['departure_time'] ?? 'Unknown';
    final int secondsUntilDeparture = train['seconds_until_departure'] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Currently at $stationName',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.schedule,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Departing at $departureTime',
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.timer,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Departs in ${_formatTime(secondsUntilDeparture)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnRouteInfo(Map<String, dynamic> train) {
    final String fromStation = train['from_station'] ?? 'Unknown';
    final String toStation = train['to_station'] ?? 'Unknown';
    final double progress = train['progress'] ?? 0.0;
    final String arrivalTime = train['arrival_time'] ?? 'Unknown';
    final int secondsToArrival = train['seconds_to_next_station'] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$fromStation → $toStation',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getLineColor(train['line'] ?? ''),
                  ),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatProgress(progress),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.schedule,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Arriving at $arrivalTime',
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.timer,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Arrives in ${_formatTime(secondsToArrival)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrainRouteVisualization() {
    // This would be a placeholder for a full route visualization
    // In a real implementation, this could show a line map with the train's position
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.map,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Route visualization would appear here',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Data'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    } else if (seconds < 3600) {
      final minutes = (seconds / 60).floor();
      final remainingSeconds = seconds % 60;
      return '$minutes min${remainingSeconds > 0 ? ' $remainingSeconds sec' : ''}';
    } else {
      final hours = (seconds / 3600).floor();
      final minutes = ((seconds % 3600) / 60).floor();
      return '$hours hr${minutes > 0 ? ' $minutes min' : ''}';
    }
  }

  Color _getLineColor(String line) {
    if (line.contains('Line 1') || line.contains('East-West')) {
      return AppColors.line1Color;
    } else if (line.contains('Line 2') || line.contains('North-South')) {
      return AppColors.line2Color;
    } else if (line.contains('Line 3') || line.contains('Motera')) {
      return AppColors.line3Color;
    } else if (line.contains('Line 4') || line.contains('GNLU')) {
      return AppColors.line4Color;
    } else {
      return AppColors.primaryColor;
    }
  }
} 