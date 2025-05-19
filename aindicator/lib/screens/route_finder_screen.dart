import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aindicator/utils/app_colors.dart';
import 'package:aindicator/widgets/station_selector.dart';
import 'package:aindicator/widgets/route_result_card.dart';
import 'package:aindicator/models/route_result.dart';
import 'package:aindicator/services/api_service.dart';
import 'package:aindicator/screens/route_details_screen.dart';

class RouteFinderScreen extends StatefulWidget {
  final String? preselectedSource;
  final String? preselectedDestination;

  const RouteFinderScreen({
    super.key,
    this.preselectedSource,
    this.preselectedDestination,
  });

  @override
  State<RouteFinderScreen> createState() => _RouteFinderScreenState();
}

class _RouteFinderScreenState extends State<RouteFinderScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  
  List<String> _allStations = [];
  List<String> _filteredSourceStations = [];
  List<String> _filteredDestinationStations = [];
  List<Map<String, dynamic>> _favoriteRoutes = [];
  
  bool _isSourceFocused = false;
  bool _isDestinationFocused = false;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showFavorites = false;
  
  @override
  void initState() {
    super.initState();
    
    // Set preselected values if provided
    if (widget.preselectedSource != null) {
      _sourceController.text = widget.preselectedSource!;
    }
    
    if (widget.preselectedDestination != null) {
      _destinationController.text = widget.preselectedDestination!;
    }
    
    _loadData();
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Get all stations from cache
      final allStations = await _apiService.getAllStations();
      
      // Get favorite routes
      final favoriteRoutes = await _apiService.getFavoriteRoutes();
      
      setState(() {
        _allStations = allStations;
        _filteredSourceStations = allStations;
        _filteredDestinationStations = allStations;
        _favoriteRoutes = favoriteRoutes;
        _isLoading = false;
      });
      
      // If both source and destination are preselected, find route automatically
      if (widget.preselectedSource != null && widget.preselectedDestination != null) {
        _findRoute();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load data: $e';
      });
    }
  }

  void _filterSourceStations(String query) {
    setState(() {
      _filteredSourceStations = _allStations
          .where((station) => station.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _filterDestinationStations(String query) {
    setState(() {
      _filteredDestinationStations = _allStations
          .where((station) => station.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _selectSourceStation(String station) {
    setState(() {
      _sourceController.text = station;
      _isSourceFocused = false;
    });
  }

  void _selectDestinationStation(String station) {
    setState(() {
      _destinationController.text = station;
      _isDestinationFocused = false;
    });
  }

  void _selectFavoriteRoute(Map<String, dynamic> route) async {
    setState(() {
      _sourceController.text = route['source'];
      _destinationController.text = route['destination'];
      _showFavorites = false;
      _isLoading = true;
    });
    
    try {
      // Find route directly
      final result = await _apiService.findRoute(
        route['source'],
        route['destination'],
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (result.error != null) {
        setState(() {
          _hasError = true;
          _errorMessage = result.error!;
        });
        return;
      }
      
      // Navigate directly to the route details screen
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RouteDetailsScreen(
            routeResult: result,
            onAddToFavorites: _showAddToFavoritesDialog,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to find route: $e';
      });
    }
  }

  Future<void> _findRoute() async {
    if (_sourceController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both source and destination stations'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_sourceController.text == _destinationController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Source and destination cannot be the same'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      final result = await _apiService.findRoute(
        _sourceController.text,
        _destinationController.text,
      );

      setState(() {
        _isLoading = false;
      });
      
      if (result.error != null) {
        setState(() {
          _hasError = true;
          _errorMessage = result.error!;
        });
        return;
      }
      
      // Navigate to the route details screen
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RouteDetailsScreen(
            routeResult: result,
            onAddToFavorites: _showAddToFavoritesDialog,
          ),
        ),
      );
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to find route: $e';
      });
    }
  }

  void _showAddToFavoritesDialog() {
    if (_sourceController.text.isEmpty || _destinationController.text.isEmpty) return;
    
    final TextEditingController nameController = TextEditingController();
    nameController.text = '${_sourceController.text} to ${_destinationController.text}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save to Favorites'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Give this route a name:'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Route Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _apiService.addFavoriteRoute(
                _sourceController.text,
                _destinationController.text,
                nameController.text,
              );
              Navigator.pop(context);
              
              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Route added to favorites'),
                  backgroundColor: AppColors.success,
                ),
              );
              
              // Refresh favorite routes
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _swapStations() {
    final temp = _sourceController.text;
    setState(() {
      _sourceController.text = _destinationController.text;
      _destinationController.text = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Finder'),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () {
              setState(() {
                _showFavorites = !_showFavorites;
                _isSourceFocused = false;
                _isDestinationFocused = false;
              });
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() {
            _isSourceFocused = false;
            _isDestinationFocused = false;
            _showFavorites = false;
          });
        },
        child: Container(
          color: AppColors.backgroundColor,
          child: SafeArea(
            child: Column(
              children: [
                // Station Selection Card - More compact
                Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and subtitle in a row to save space
                        Row(
                          children: [
                            const Icon(
                              Icons.directions_subway,
                              color: AppColors.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Plan Your Journey',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Find the fastest route',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Add to favorites button
                            if (_sourceController.text.isNotEmpty && 
                                _destinationController.text.isNotEmpty &&
                                _sourceController.text != _destinationController.text)
                              IconButton(
                                onPressed: _showAddToFavoritesDialog,
                                icon: const Icon(
                                  Icons.star_border,
                                  color: AppColors.primaryColor,
                                ),
                                tooltip: 'Add to favorites',
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Source and destination in a more compact layout
                        Row(
                          children: [
                            // Source station
                            Expanded(
                              child: CompactStationSelector(
                                controller: _sourceController,
                                label: 'From',
                                hint: 'Source',
                                icon: Icons.location_on,
                                iconColor: AppColors.line1Color,
                                onTap: () {
                                  setState(() {
                                    _isSourceFocused = true;
                                    _isDestinationFocused = false;
                                    _showFavorites = false;
                                  });
                                },
                              ),
                            ),
                            
                            // Swap button
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: _swapStations,
                                icon: const Icon(
                                  Icons.swap_horiz,
                                  color: AppColors.primaryColor,
                                  size: 20,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                                  padding: const EdgeInsets.all(8),
                                ),
                              ),
                            ),
                            
                            // Destination station
                            Expanded(
                              child: CompactStationSelector(
                                controller: _destinationController,
                                label: 'To',
                                hint: 'Destination',
                                icon: Icons.location_on,
                                iconColor: AppColors.line2Color,
                                onTap: () {
                                  setState(() {
                                    _isSourceFocused = false;
                                    _isDestinationFocused = true;
                                    _showFavorites = false;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Find Route Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _findRoute,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 48),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search),
                                    SizedBox(width: 8),
                                    Text(
                                      'Find Route',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Favorite Routes, Station Suggestions, or Error Message
                if (_showFavorites)
                  _buildFavoriteRoutesList()
                else if (_isSourceFocused && _filteredSourceStations.isNotEmpty)
                  _buildStationsList(_filteredSourceStations, _selectSourceStation, AppColors.line1Color)
                else if (_isDestinationFocused && _filteredDestinationStations.isNotEmpty)
                  _buildStationsList(_filteredDestinationStations, _selectDestinationStation, AppColors.line2Color)
                else if (_hasError)
                  _buildErrorMessage()
                else
                  _buildEmptyState(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFavoriteRoutesList() {
    if (_favoriteRoutes.isEmpty) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_border,
                  color: AppColors.textLight,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'No favorite routes yet',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Add routes to favorites for quick access',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Favorite Routes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _favoriteRoutes.length,
                itemBuilder: (context, index) {
                  final route = _favoriteRoutes[index];
                  return Dismissible(
                    key: Key(route['source'] + route['destination']),
                    background: Container(
                      color: AppColors.error,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      _apiService.removeFavoriteRoute(
                        route['source'],
                        route['destination'],
                      );
                      setState(() {
                        _favoriteRoutes.removeAt(index);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Route removed from favorites'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child: ListTile(
                      title: Text(
                        route['name'] ?? 'Favorite Route',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${route['source']} → ${route['destination']}',
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.textLight,
                      ),
                      onTap: () => _selectFavoriteRoute(route),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStationsList(List<String> stations, Function(String) onSelect, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: stations.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(
                stations[index],
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () => onSelect(stations[index]),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.subway,
                  color: color,
                  size: 20,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textLight,
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildErrorMessage() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                width: 100,
                height: 100,
                opacity: const AlwaysStoppedAnimation(0.3),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select stations to find the best route',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Enter your source and destination stations to get the fastest route, fare information, and transit details',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showFavorites = true;
                  });
                },
                icon: const Icon(Icons.star),
                label: const Text('View Favorite Routes'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Compact version of station selector for the new layout
class CompactStationSelector extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const CompactStationSelector({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 4),
        
        // Input field
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            onTap: onTap,
            readOnly: true,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: iconColor,
                size: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}