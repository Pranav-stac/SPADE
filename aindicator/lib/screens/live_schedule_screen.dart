import 'package:flutter/material.dart';
import 'dart:async';
import 'package:aindicator/utils/app_colors.dart';
import 'package:aindicator/services/api_service.dart';
import 'package:aindicator/widgets/loading_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class LiveScheduleScreen extends StatefulWidget {
  final String? preselectedStation;

  const LiveScheduleScreen({
    super.key,
    this.preselectedStation,
  });

  @override
  State<LiveScheduleScreen> createState() => _LiveScheduleScreenState();
}

class _LiveScheduleScreenState extends State<LiveScheduleScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _stationController = TextEditingController();

  List<String> _allStations = [];
  List<String> _filteredStations = [];
  List<Map<String, dynamic>> _nextTrains = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isSearching = false;
  DateTime _currentTime = DateTime.now();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    
    if (widget.preselectedStation != null) {
      _stationController.text = widget.preselectedStation!;
    }
    
    _loadData();
    
    // Set up a timer to refresh data every minute
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  @override
  void dispose() {
    _stationController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      // Load all stations
      final allStations = await _apiService.getAllStations();
      
      setState(() {
        _allStations = allStations;
        _filteredStations = allStations;
        _isLoading = false;
      });
      
      // If a station is preselected, load its schedule
      if (widget.preselectedStation != null) {
        _loadStationSchedule();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load data: $e';
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _currentTime = DateTime.now();
    });
    
    if (_stationController.text.isNotEmpty) {
      _loadStationSchedule();
    }
  }

  Future<void> _loadStationSchedule() async {
    if (_stationController.text.isEmpty) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      final nextTrains = await _apiService.getNextTrains(
        _stationController.text,
        count: 10,
      );
      
      setState(() {
        _nextTrains = nextTrains;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load schedule: $e';
      });
    }
  }

  void _filterStations(String query) {
    setState(() {
      _filteredStations = _allStations
          .where((station) => station.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  String _formatWaitTime(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    } else if (seconds < 3600) {
      return '${(seconds / 60).floor()} min';
    } else {
      final hours = (seconds / 3600).floor();
      final minutes = ((seconds % 3600) / 60).floor();
      return '$hours h ${minutes > 0 ? '$minutes min' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Train Schedule'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Container(
        color: AppColors.backgroundColor,
        child: Column(
          children: [
            // Station search bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _stationController,
                    decoration: InputDecoration(
                      hintText: 'Enter station name',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _stationController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _stationController.clear();
                                  _isSearching = false;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      _filterStations(value);
                      setState(() {
                        _isSearching = value.isNotEmpty;
                      });
                    },
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          _isSearching = false;
                        });
                        _loadStationSchedule();
                      }
                    },
                  ),
                  if (_isSearching)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        itemCount: _filteredStations.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_filteredStations[index]),
                            onTap: () {
                              setState(() {
                                _stationController.text = _filteredStations[index];
                                _isSearching = false;
                              });
                              _loadStationSchedule();
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            
            // Current time display
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Time: ${DateFormat('HH:mm:ss').format(_currentTime)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshData,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
            
            // Schedule content
            Expanded(
              child: _isLoading
                  ? const Center(child: LoadingIndicator())
                  : _hasError
                      ? _buildErrorWidget()
                      : _stationController.text.isEmpty
                          ? _buildEmptyStateWidget()
                          : _nextTrains.isEmpty
                              ? _buildNoTrainsWidget()
                              : _buildScheduleList(),
            ),
          ],
        ),
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
            onPressed: _loadStationSchedule,
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

  Widget _buildEmptyStateWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/search_station.png',
            width: 150,
            height: 150,
          ).animate().fadeIn(),
          const SizedBox(height: 24),
          const Text(
            'Search for a station to view live schedules',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
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
          Text(
            'No upcoming trains for ${_stationController.text}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 12),
          const Text(
            'Check back during operational hours or try a different station',
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

  Widget _buildScheduleList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _nextTrains.length,
      itemBuilder: (context, index) {
        final train = _nextTrains[index];
        final waitTimeSeconds = train['seconds_until'] ?? 0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getLineColor(train['corridor'] ?? ''),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.train,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            title: Text(
              train['corridor'] ?? 'Unknown Line',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Departs at: ${train['departure_time'] ?? 'Unknown'}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Destination: ${train['destination'] ?? 'Unknown'}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getWaitTimeColor(waitTimeSeconds),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _formatWaitTime(waitTimeSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Platform ${train['platform'] ?? 'Unknown'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 100).ms).slideX(
              begin: 0.1,
              end: 0,
              delay: (index * 100).ms,
              curve: Curves.easeOutQuad,
            );
      },
    );
  }

  Color _getLineColor(String corridor) {
    if (corridor.contains('Line 1') || corridor.contains('East-West')) {
      return AppColors.line1Color;
    } else if (corridor.contains('Line 2') || corridor.contains('North-South')) {
      return AppColors.line2Color;
    } else if (corridor.contains('Line 3') || corridor.contains('Motera')) {
      return AppColors.line3Color;
    } else if (corridor.contains('Line 4') || corridor.contains('GNLU')) {
      return AppColors.line4Color;
    } else {
      return AppColors.primaryColor;
    }
  }

  Color _getWaitTimeColor(int seconds) {
    if (seconds < 300) { // Less than 5 minutes
      return Colors.red;
    } else if (seconds < 900) { // Less than 15 minutes
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
} 