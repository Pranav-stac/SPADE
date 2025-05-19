import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aindicator/utils/app_colors.dart';
import 'package:aindicator/services/api_service.dart';
import 'package:aindicator/screens/train_tracking_screen.dart';
import 'package:aindicator/widgets/loading_indicator.dart';
import 'package:intl/intl.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late AnimationController _pulseController;
  late AnimationController _trainAnimationController;
  final TransformationController _transformationController = TransformationController();
  
  List<Map<String, dynamic>> _trainLocations = [];
  List<Map<String, dynamic>> _lines = [];
  Map<String, List<String>> _stationsByLine = {};
  Map<String, Map<String, dynamic>> _stationDetails = {};
  
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  DateTime _currentTime = DateTime.now();
  String? _selectedStationId;
  Map<String, dynamic>? _selectedTrain;
  Timer? _refreshTimer;
  bool _isMapZoomed = false;
  double _zoomLevel = 1.0;
  
  // Line path definitions
  final Map<String, List<Offset>> _linePaths = {};
  
  // Colors and styling
  final Map<String, Color> _lineColors = {
    '1': AppColors.line1Color,
    '2': AppColors.line2Color,
    '3': AppColors.line3Color,
    '4': AppColors.line4Color,
  };
  
  // Station positions (normalized 0.0-1.0 coordinates)
  final Map<String, Offset> _stationPositions = {};
  
  @override
  void initState() {
    super.initState();
    
    // Setup animation controllers
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _trainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    
    // Initialize the map with a slightly spread out view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Set initial zoom level to make map more spread out
        final Matrix4 matrix = Matrix4.identity()
          ..scale(1.5);
        _transformationController.value = matrix;
        _zoomLevel = 1.5;
        _isMapZoomed = true;
      }
    });
    
    _loadData();
    
    // Set up a timer to refresh data every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _refreshData();
      }
    });
    
    // Lock the orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _trainAnimationController.dispose();
    _refreshTimer?.cancel();
    _transformationController.dispose();
    
    // Reset orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      // Load metro lines data
      final lines = await _apiService.getLines();
      
      // Process stations for each line
      Map<String, List<String>> stationsByLine = {};
      Map<String, Map<String, dynamic>> stationDetails = {};
      
      for (var line in lines) {
        final String lineId = line['id'];
        final stations = await _apiService.getStations(lineId);
        stationsByLine[lineId] = stations;
        
        // Generate normalized station positions for this line
        _generateLineStationPositions(lineId, stations);
      }
      
      // Get train locations
      final trainLocations = await _apiService.getTrainLocations();
      
      setState(() {
        _lines = lines;
        _stationsByLine = stationsByLine;
        _stationDetails = stationDetails;
        _trainLocations = trainLocations;
        _currentTime = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load map data: $e';
      });
    }
  }

  Future<void> _refreshData() async {
    try {
      // Get train locations
      final trainLocations = await _apiService.getTrainLocations();
      
      setState(() {
        _trainLocations = trainLocations;
        _currentTime = DateTime.now();
      });
    } catch (e) {
      // Silent failure on background refresh
      print('Failed to refresh train locations: $e');
    }
  }

  // Generate normalized positions for stations on each line
  void _generateLineStationPositions(String lineId, List<String> stations) {
    if (stations.isEmpty) {
      print('Warning: No stations for line $lineId');
      return;
    }
    
    try {
      // Define path points for each line
      switch (lineId) {
        case '1': // East-West Line - horizontal S shape
          _linePaths[lineId] = _generateSPath(
            start: const Offset(0.1, 0.3),
            end: const Offset(0.9, 0.3),
            controlPoints: [
              const Offset(0.3, 0.25),
              const Offset(0.7, 0.35),
            ],
            steps: stations.length > 0 ? stations.length : 1, // Ensure at least 1 step
          );
          break;
        case '2': // North-South Line - vertical path
          _linePaths[lineId] = _generateCurvedPath(
            start: const Offset(0.5, 0.1),
            end: const Offset(0.5, 0.9),
            controlPoints: [
              const Offset(0.45, 0.3),
              const Offset(0.55, 0.7),
            ],
            steps: stations.length > 0 ? stations.length : 1, // Ensure at least 1 step
          );
          break;
        case '3': // Motera to Mahatma Mandir - curved path
          _linePaths[lineId] = _generateSPath(
            start: const Offset(0.5, 0.1),
            end: const Offset(0.8, 0.7),
            controlPoints: [
              const Offset(0.6, 0.3),
              const Offset(0.7, 0.5),
            ],
            steps: stations.length > 0 ? stations.length : 1, // Ensure at least 1 step
          );
          break;
        case '4': // GNLU to GIFT City - short path
          _linePaths[lineId] = _generateCurvedPath(
            start: const Offset(0.7, 0.55),
            end: const Offset(0.9, 0.6),
            controlPoints: [
              const Offset(0.8, 0.57),
            ],
            steps: stations.length > 0 ? stations.length : 1, // Ensure at least 1 step
          );
          break;
      }
      
      // Assign station positions - make sure the list sizes match and handle potential null values
      if (_linePaths.containsKey(lineId) && _linePaths[lineId] != null && _linePaths[lineId]!.isNotEmpty) {
        final pathPoints = _linePaths[lineId]!;
        
        if (pathPoints.length < stations.length) {
          print('Warning: Path points (${pathPoints.length}) fewer than stations (${stations.length}) for line $lineId');
        }
        
        for (int i = 0; i < stations.length; i++) {
          if (i >= pathPoints.length) {
            // Handle case where there aren't enough points for all stations
            print('Warning: Not enough path points for station at index $i on line $lineId');
            // Use the last available point for the remaining stations
            if (pathPoints.isNotEmpty) {
              _stationPositions[stations[i]] = pathPoints.last;
            } else {
              // Fallback position if no points available
              _stationPositions[stations[i]] = Offset(0.5 + (i * 0.05), 0.5);
            }
          } else {
            final station = stations[i];
            _stationPositions[station] = pathPoints[i];
          }
        }
      } else {
        print('Error: No path generated for line $lineId');
        _createFallbackPath(lineId, stations);
      }
    } catch (e) {
      print('Error generating positions for line $lineId: $e');
      // Create a simple fallback path for this line
      _createFallbackPath(lineId, stations);
    }
  }
  
  // Create a simple fallback path if the complex path generation fails
  void _createFallbackPath(String lineId, List<String> stations) {
    if (stations.isEmpty) return;
    
    // Create a simple horizontal line
    List<Offset> simplePath = [];
    double startX = 0.1;
    double endX = 0.9;
    double y = 0.2 + (int.parse(lineId) * 0.2).clamp(0.0, 0.6); // Spread lines vertically but clamp to safe range
    
    double step = stations.length > 1 ? (endX - startX) / (stations.length - 1) : 0.0;
    for (int i = 0; i < stations.length; i++) {
      simplePath.add(Offset(startX + (step * i), y));
    }
    
    _linePaths[lineId] = simplePath;
    
    // Assign station positions
    for (int i = 0; i < stations.length; i++) {
      _stationPositions[stations[i]] = simplePath[i];
    }
  }

  List<Offset> _generateCurvedPath({
    required Offset start,
    required Offset end,
    required List<Offset> controlPoints,
    required int steps,
  }) {
    List<Offset> path = [];
    
    for (int i = 0; i < steps; i++) {
      double t = i / (steps - 1);
      
      if (controlPoints.length == 1) {
        // Quadratic Bezier curve
        double u = 1 - t;
        double tt = t * t;
        double uu = u * u;
        
        double x = uu * start.dx + 2 * u * t * controlPoints[0].dx + tt * end.dx;
        double y = uu * start.dy + 2 * u * t * controlPoints[0].dy + tt * end.dy;
        
        path.add(Offset(x, y));
      } else {
        // Cubic Bezier curve
        double u = 1 - t;
        double tt = t * t;
        double uu = u * u;
        double uuu = uu * u;
        double ttt = tt * t;
        
        double x = uuu * start.dx + 
                    3 * uu * t * controlPoints[0].dx + 
                    3 * u * tt * controlPoints[1].dx + 
                    ttt * end.dx;
        double y = uuu * start.dy + 
                    3 * uu * t * controlPoints[0].dy + 
                    3 * u * tt * controlPoints[1].dy + 
                    ttt * end.dy;
        
        path.add(Offset(x, y));
      }
    }
    
    return path;
  }

  List<Offset> _generateSPath({
    required Offset start,
    required Offset end,
    required List<Offset> controlPoints,
    required int steps,
  }) {
    // Ensure we have at least 1 step to prevent division by zero
    if (steps < 1) steps = 1;
    
    // Generate an S-shaped path using multiple Bezier curves
    if (steps < 4) return _generateCurvedPath(start: start, end: end, controlPoints: controlPoints, steps: steps);
    
    int halfSteps = steps ~/ 2;
    if (halfSteps < 1) halfSteps = 1; // Safety check
    
    List<Offset> firstHalf = _generateCurvedPath(
      start: start,
      end: Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2),
      controlPoints: [controlPoints.isNotEmpty ? controlPoints[0] : Offset(start.dx, end.dy)],
      steps: halfSteps,
    );
    
    List<Offset> secondHalf = _generateCurvedPath(
      start: Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2),
      end: end,
      controlPoints: [controlPoints.length > 1 ? controlPoints[1] : Offset(end.dx, start.dy)],
      steps: steps - halfSteps,
    );
    
    // Make sure we don't try to access an empty list
    if (firstHalf.isEmpty) return secondHalf;
    if (secondHalf.isEmpty) return firstHalf;
    
    // Safely combine the halves, checking for out of range access
    List<Offset> result = [...firstHalf];
    if (secondHalf.length > 1) {
      result.addAll(secondHalf.sublist(1));
    } else if (secondHalf.isNotEmpty) {
      result.add(secondHalf[0]);
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Metro Map'),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            icon: Icon(_isMapZoomed ? Icons.zoom_out : Icons.zoom_in),
            onPressed: _toggleZoom,
            tooltip: _isMapZoomed ? 'Zoom Out' : 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: _isLoading
            ? const Center(child: LoadingIndicator())
            : _hasError
                ? _buildErrorWidget()
                : Stack(
                    children: [
                      // Enhanced background gradient for better map visibility
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFF8FDFF),  // Very light blue-white
                              Color(0xFFEDF7F0),  // Very light green
                              Color(0xFFEAF5FD),  // Very light blue
                            ],
                          ),
                        ),
                      ),
                      
                      // Interactive map - make it start with a slightly higher zoom level
                      Expanded(
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 1.0,
                          maxScale: 3.0,
                          boundaryMargin: const EdgeInsets.all(50.0), // Allow some overflow scrolling
                          onInteractionEnd: (ScaleEndDetails details) {
                            setState(() {
                              _zoomLevel = _transformationController.value.getMaxScaleOnAxis();
                              _isMapZoomed = _zoomLevel > 1.2;
                            });
                          },
                          child: Stack(
                            children: [
                              // Metro lines
                              ..._buildMetroLines(),
                              
                              // Stations
                              ..._buildStationMarkers(),
                              
                              // Trains
                              ..._buildTrainMarkers(),
                              
                              // Selection details panel
                              if (_selectedStationId != null || _selectedTrain != null)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: _buildSelectionInfoPanel(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  void _toggleZoom() {
    if (_isMapZoomed) {
      _transformationController.value = Matrix4.identity();
      setState(() {
        _isMapZoomed = false;
        _zoomLevel = 1.0;
      });
    } else {
      // Zoom to center
      final Matrix4 matrix = Matrix4.identity()
        ..translate(-(MediaQuery.of(context).size.width / 4), -(MediaQuery.of(context).size.height / 4))
        ..scale(2.0);
      _transformationController.value = matrix;
      setState(() {
        _isMapZoomed = true;
        _zoomLevel = 2.0;
      });
    }
  }

  List<Widget> _buildMetroLines() {
    List<Widget> lines = [];
    
    for (var line in _lines) {
      final String lineId = line['id'];
      final Color lineColor = _lineColors[lineId] ?? AppColors.primaryColor;
      
      if (_linePaths.containsKey(lineId) && _linePaths[lineId]!.isNotEmpty) {
        lines.add(
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
            painter: MetroLinePainter(
              path: _linePaths[lineId]!,
              color: lineColor,
              lineWidth: 6.0,
            ),
          ),
        );
      }
    }
    
    return lines;
  }

  List<Widget> _buildStationMarkers() {
    List<Widget> stationMarkers = [];
    
    _stationPositions.forEach((station, position) {
      // Skip stations without position data
      if (position == null) {
        debugPrint('Warning: Station $station has no position data');
        return; // Skip this station
      }

      final isSelected = _selectedStationId == station;
      final stationSize = isSelected ? 12.0 : 8.0;
      final fontSize = isSelected ? 12.0 : 10.0;
      final textColor = isSelected ? Colors.black : Colors.black87;
      final bgColor = isSelected ? Colors.amber.shade200 : Colors.white.withOpacity(0.7);
      
      // Get the line color for this station
      String? lineId;
      for (var entry in _stationsByLine.entries) {
        if (entry.value.contains(station)) {
          lineId = entry.key;
          break;
        }
      }
      final Color stationColor = lineId != null 
          ? (_lineColors[lineId] ?? AppColors.primaryColor)
          : Colors.blue;
      
      // Always show the station name regardless of zoom level
      stationMarkers.add(
        Positioned(
          left: position.dx - stationSize / 2,
          top: position.dy - stationSize / 2,
          child: GestureDetector(
            onTap: () => _selectStation(station),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: stationSize,
                  height: stationSize,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.amber : stationColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.8),
                              spreadRadius: 2,
                              blurRadius: 5,
                            )
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                // Always show the station name, regardless of zoom level
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    station,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
    
    return stationMarkers;
  }

  List<Widget> _buildTrainMarkers() {
    List<Widget> trainMarkers = [];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height - 100;
    
    for (var train in _trainLocations) {
      final String lineId = train['line_id'] ?? '1';
      final Color lineColor = _lineColors[lineId] ?? AppColors.primaryColor;
      
      try {
        // Calculate train position on the path
        final progress = train['progress'] ?? 0.0;
        final fromStation = train['from_station'];
        final toStation = train['to_station'];
        
        // Make sure both stations exist and have positions
        if (fromStation != null && toStation != null && 
            _stationPositions.containsKey(fromStation) && 
            _stationPositions.containsKey(toStation)) {
          
          final fromPos = _stationPositions[fromStation]!;
          final toPos = _stationPositions[toStation]!;
          
          // Interpolate position
          final position = Offset(
            fromPos.dx + (toPos.dx - fromPos.dx) * progress,
            fromPos.dy + (toPos.dy - fromPos.dy) * progress
          );
          
          // Calculate rotation angle
          final angle = math.atan2(toPos.dy - fromPos.dy, toPos.dx - fromPos.dx);
          
          final bool isSelected = _selectedTrain != null && 
                                  _selectedTrain!['trip_id'] == train['trip_id'];
          
          trainMarkers.add(
            Positioned(
              left: position.dx * screenWidth - 15,
              top: position.dy * screenHeight - 15,
              child: GestureDetector(
                onTap: () => _selectTrain(train),
                child: AnimatedRotation(
                  turns: angle / (2 * math.pi),
                  duration: const Duration(milliseconds: 500),
                  child: AnimatedScale(
                    scale: isSelected ? 1.5 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      width: 30,
                      height: 15,
                      decoration: BoxDecoration(
                        color: lineColor,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: lineColor.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 4,
                                )
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 1),
                                )
                              ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.train,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ).animate(
                      controller: _pulseController,
                    ).scaleXY(
                      begin: 1.0,
                      end: 1.1,
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          // Debug missing station info
          if (fromStation == null || toStation == null) {
            print('Warning: Missing from/to station for train ${train['trip_id']}');
          } else if (!_stationPositions.containsKey(fromStation)) {
            print('Warning: No position for from_station $fromStation');
          } else if (!_stationPositions.containsKey(toStation)) {
            print('Warning: No position for to_station $toStation');
          }
        }
      } catch (e) {
        print('Error placing train ${train['trip_id']}: $e');
      }
    }
    
    return trainMarkers;
  }

  void _selectStation(String stationId) {
    setState(() {
      if (_selectedStationId == stationId) {
        _selectedStationId = null;
      } else {
        _selectedStationId = stationId;
        _selectedTrain = null;
      }
    });
  }

  void _selectTrain(Map<String, dynamic> train) {
    setState(() {
      if (_selectedTrain != null && _selectedTrain!['trip_id'] == train['trip_id']) {
        _selectedTrain = null;
      } else {
        _selectedTrain = train;
        _selectedStationId = null;
      }
    });
  }

  Widget _buildSelectionInfoPanel() {
    Color panelColor;
    Widget content;
    
    if (_selectedTrain != null) {
      final String lineId = _selectedTrain!['line_id'] ?? '1';
      panelColor = _lineColors[lineId] ?? AppColors.primaryColor;
      content = _buildTrainInfoPanel(_selectedTrain!);
    } else {
      // Find line for this station
      String? lineId;
      for (var entry in _stationsByLine.entries) {
        if (entry.value.contains(_selectedStationId)) {
          lineId = entry.key;
          break;
        }
      }
      panelColor = _lineColors[lineId ?? '1'] ?? AppColors.primaryColor;
      content = _buildStationInfoPanel(_selectedStationId!);
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: panelColor.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: panelColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: panelColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedTrain != null ? Icons.train : Icons.location_on,
                  color: panelColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedTrain != null 
                        ? 'Train ${_selectedTrain!['trip_id']}'
                        : _selectedStationId!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: panelColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _selectedStationId = null;
                      _selectedTrain = null;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
          
          // Action button
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedTrain != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrainTrackingScreen(
                          preselectedTripId: _selectedTrain!['trip_id'],
                        ),
                      ),
                    );
                  } else {
                    // Navigate to station details or schedule
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: panelColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _selectedTrain != null ? 'Track This Train' : 'View Schedule',
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTrainInfoPanel(Map<String, dynamic> train) {
    final bool isAtStation = train.containsKey('at_station');
    final String status = isAtStation
        ? 'At ${train['at_station']}'
        : 'En route: ${train['from_station']} → ${train['to_station']}';
    
    final double progress = train['progress'] ?? 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status and time
        Text(
          status,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // Progress bar for en route trains
        if (!isAtStation) ...[
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _lineColors[train['line_id'] ?? '1'] ?? AppColors.primaryColor,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Arrives in: ${_formatTime(train['seconds_to_next_station'] ?? 0)}',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Departs in: ${_formatTime(train['seconds_until_departure'] ?? 0)}',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
        
        // Line info
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _lineColors[train['line_id'] ?? '1'] ?? AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Line ${train['line_id']} - ${train['line']}',
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
              Icons.arrow_forward,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Direction: ${train['direction'] ?? 'Unknown'}',
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStationInfoPanel(String stationName) {
    String? lineId;
    for (var entry in _stationsByLine.entries) {
      if (entry.value.contains(stationName)) {
        lineId = entry.key;
        break;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line information
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _lineColors[lineId ?? '1'] ?? AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Line ${lineId ?? 'Unknown'}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Upcoming trains
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _apiService.getNextTrains(stationName, count: 3),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text(
                'No upcoming trains at this station',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              );
            }
            
            final nextTrains = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upcoming Trains:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...nextTrains.map((train) {
                  final waitTimeSeconds = train['seconds_until'] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.train,
                          size: 16,
                          color: _getWaitTimeColor(waitTimeSeconds),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${train['corridor'] ?? 'Unknown Line'} to ${train['destination'] ?? 'Unknown'}',
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getWaitTimeColor(waitTimeSeconds),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _formatTime(waitTimeSeconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      ],
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

  Color _getWaitTimeColor(int seconds) {
    if (seconds < 300) { // Less than 5 minutes
      return Colors.red;
    } else if (seconds < 900) { // Less than 15 minutes
      return Colors.orange;
    } else {
      return Colors.green;
    }
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
}

// Custom painter for metro lines
class MetroLinePainter extends CustomPainter {
  final List<Offset> path;
  final Color color;
  final double lineWidth;
  
  MetroLinePainter({
    required this.path,
    required this.color,
    this.lineWidth = 4.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    
    final scaledPath = path.map((point) {
      return Offset(point.dx * size.width, point.dy * size.height);
    }).toList();
    
    // Draw line segments
    for (int i = 0; i < scaledPath.length - 1; i++) {
      canvas.drawLine(scaledPath[i], scaledPath[i + 1], paint);
    }
    
    // Draw connection dots
    for (int i = 1; i < scaledPath.length - 1; i++) {
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(scaledPath[i], lineWidth / 2, dotPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant MetroLinePainter oldDelegate) {
    return path != oldDelegate.path || 
           color != oldDelegate.color || 
           lineWidth != oldDelegate.lineWidth;
  }
} 