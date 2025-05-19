import 'package:flutter/material.dart';
import 'package:aindicator/utils/app_colors.dart';
import 'package:aindicator/services/api_service.dart';
import 'package:aindicator/screens/route_finder_screen.dart';

class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<String> _allStations = [];
  List<String> _filteredStations = [];
  Map<String, List<String>> _stationsByLine = {};
  
  @override
  void initState() {
    super.initState();
    _loadStations();
    
    _searchController.addListener(() {
      _filterStations(_searchController.text);
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadStations() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Get all stations
      final allStations = await _apiService.getAllStations();
      
      // Get stations by line
      final lines = await _apiService.getLines();
      Map<String, List<String>> stationsByLine = {};
      
      for (var line in lines) {
        final String lineId = line['id'];
        final String lineName = line['name'];
        final stations = await _apiService.getStations(lineId);
        stationsByLine[lineName] = stations;
      }
      
      setState(() {
        _allStations = allStations;
        _filteredStations = allStations;
        _stationsByLine = stationsByLine;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load stations: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  
  void _filterStations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStations = _allStations;
      } else {
        _filteredStations = _allStations
            .where((station) => station.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }
  
  void _selectStation(String station) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteFinderScreen(
          preselectedSource: station,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Metro Stations'),
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All Stations'),
              Tab(text: 'By Line'),
            ],
            indicatorColor: Colors.white,
            indicatorWeight: 3,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildAllStationsTab(),
                  _buildStationsByLineTab(),
                ],
              ),
      ),
    );
  }
  
  Widget _buildAllStationsTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search stations',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryColor,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        
        // Station count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${_filteredStations.length} stations',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (_searchController.text.isNotEmpty)
                Text(
                  'Showing results for "${_searchController.text}"',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Stations list
        Expanded(
          child: _filteredStations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 48,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No stations found for "${_searchController.text}"',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _filteredStations.length,
                  itemBuilder: (context, index) {
                    final station = _filteredStations[index];
                    
                    // Determine which line this station belongs to
                    String stationLine = '';
                    Color stationColor = AppColors.primaryColor;
                    
                    for (var entry in _stationsByLine.entries) {
                      if (entry.value.contains(station)) {
                        stationLine = entry.key;
                        if (stationLine.contains('Line 1')) {
                          stationColor = AppColors.line1Color;
                        } else if (stationLine.contains('Line 2')) {
                          stationColor = AppColors.line2Color;
                        } else if (stationLine.contains('Line 3')) {
                          stationColor = AppColors.line3Color;
                        } else if (stationLine.contains('Line 4')) {
                          stationColor = AppColors.line4Color;
                        }
                        break;
                      }
                    }
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: stationColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.train,
                            color: stationColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          station,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          stationLine,
                          style: TextStyle(
                            fontSize: 12,
                            color: stationColor,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.directions,
                            color: AppColors.primaryColor,
                          ),
                          onPressed: () => _selectStation(station),
                          tooltip: 'Find route to this station',
                        ),
                        onTap: () => _selectStation(station),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildStationsByLineTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stationsByLine.length,
      itemBuilder: (context, index) {
        final lineName = _stationsByLine.keys.elementAt(index);
        final stations = _stationsByLine[lineName] ?? [];
        
        // Determine line color
        Color lineColor = AppColors.primaryColor;
        if (lineName.contains('Line 1')) {
          lineColor = AppColors.line1Color;
        } else if (lineName.contains('Line 2')) {
          lineColor = AppColors.line2Color;
        } else if (lineName.contains('Line 3')) {
          lineColor = AppColors.line3Color;
        } else if (lineName.contains('Line 4')) {
          lineColor = AppColors.line4Color;
        }
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ExpansionTile(
            initiallyExpanded: index == 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: lineColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    lineName.split(' - ').first,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lineName.split(' - ').last,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '${stations.length} stations',
                style: TextStyle(
                  fontSize: 12,
                  color: lineColor,
                ),
              ),
            ),
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stations.length,
                itemBuilder: (context, stationIndex) {
                  final station = stations[stationIndex];
                  final isFirst = stationIndex == 0;
                  final isLast = stationIndex == stations.length - 1;
                  
                  return ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 2,
                          height: 24,
                          color: isFirst ? Colors.transparent : lineColor,
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isFirst || isLast ? lineColor : Colors.white,
                            border: Border.all(
                              color: lineColor,
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 24,
                          color: isLast ? Colors.transparent : lineColor,
                        ),
                      ],
                    ),
                    title: Text(
                      station,
                      style: TextStyle(
                        fontWeight: isFirst || isLast
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.directions,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                      onPressed: () => _selectStation(station),
                      tooltip: 'Find route to this station',
                    ),
                    onTap: () => _selectStation(station),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
} 