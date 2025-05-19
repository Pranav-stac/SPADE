import 'package:flutter/material.dart';
import 'package:aindicator/utils/app_colors.dart';
import 'package:aindicator/services/api_service.dart';
import 'package:aindicator/widgets/line_stations_card.dart';

class MetroLinesScreen extends StatefulWidget {
  const MetroLinesScreen({super.key});

  @override
  State<MetroLinesScreen> createState() => _MetroLinesScreenState();
}

class _MetroLinesScreenState extends State<MetroLinesScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  List<Map<String, dynamic>> _lines = [];
  Map<String, List<String>> _lineStations = {};

  @override
  void initState() {
    super.initState();
    _fetchLines();
  }

  Future<void> _fetchLines() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      final lines = await _apiService.getLines();
      _lines = lines;
      
      // Initialize tab controller after getting lines
      _tabController = TabController(length: _lines.length, vsync: this);
      
      // Fetch stations for each line
      for (final line in _lines) {
        final stations = await _apiService.getStations(line['id']);
        _lineStations[line['id']] = stations;
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load metro lines: $e';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getLineColor(String lineId) {
    switch (lineId) {
      case '1':
        return AppColors.line1Color;
      case '2':
        return AppColors.line2Color;
      case '3':
        return AppColors.line3Color;
      case '4':
        return AppColors.line4Color;
      default:
        return AppColors.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metro Lines'),
        backgroundColor: AppColors.primaryColor,
        bottom: _isLoading || _hasError
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: _lines.map((line) {
                  final lineColor = _getLineColor(line['id']);
                  return Tab(
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: lineColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Line ${line['id']}'),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchLines,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: _lines.map((line) {
                    final lineId = line['id'];
                    final lineName = line['name'];
                    final stations = _lineStations[lineId] ?? [];
                    final lineColor = _getLineColor(lineId);
                    
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: LineStationsCard(
                        lineId: lineId,
                        lineName: lineName,
                        stations: stations,
                        lineColor: lineColor,
                      ),
                    );
                  }).toList(),
                ),
    );
  }
} 