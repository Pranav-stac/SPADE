import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aindicator/models/route_result.dart';

class ApiService {
  static const String baseUrl = 'https://a-indicatorbackend.onrender.com';
  static const String linesEndpoint = '/metro/lines';
  static const String stationsEndpoint = '/metro/stations';
  static const String routeEndpoint = '/metro/route';
  // New endpoints
  static const String nextTrainsEndpoint = '/next_trains';
  static const String trainLocationsEndpoint = '/train_locations';
  static const String trainScheduleEndpoint = '/train_schedule';
  static const String stationScheduleEndpoint = '/station_schedule';
  static const String routeWithScheduleEndpoint = '/route_with_schedule';
  static const String nextScheduleEndpoint = '/next_schedule';
  
  // Cache keys
  static const String _cacheKeyLines = 'cached_metro_lines';
  static const String _cacheKeyAllStations = 'cached_all_stations';
  static const String _cacheKeyStationsByLine = 'cached_stations_line_';
  static const String _cacheKeyFavoriteRoutes = 'favorite_routes';
  
  // Cache duration in hours
  static const int _cacheDuration = 24;
  
  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  
  // Private constructor
  ApiService._internal();
  
  // Factory constructor
  factory ApiService() {
    return _instance;
  }
  
  // In-memory cache
  Map<String, dynamic> _memoryCache = {};
  
  // Initialize and load all data at once
  Future<void> initializeData() async {
    await Future.wait([
      getLines(),
      getAllStations(),
    ]);
  }
  
  // Get all metro lines
  Future<List<Map<String, dynamic>>> getLines() async {
    // Check memory cache first
    if (_memoryCache.containsKey(_cacheKeyLines)) {
      return _memoryCache[_cacheKeyLines];
    }
    
    // Check shared preferences cache
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKeyLines);
    
    if (cachedData != null) {
      final cacheTime = prefs.getInt('${_cacheKeyLines}_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      // Check if cache is still valid (24 hours)
      if (currentTime - cacheTime < _cacheDuration * 60 * 60 * 1000) {
        final List<dynamic> decodedData = jsonDecode(cachedData);
        final List<Map<String, dynamic>> lines = List<Map<String, dynamic>>.from(
          decodedData.map((item) => Map<String, dynamic>.from(item))
        );
        
        // Store in memory cache
        _memoryCache[_cacheKeyLines] = lines;
        
        return lines;
      }
    }
    
    // Fetch from API if no valid cache
    try {
      final response = await http.get(Uri.parse('$baseUrl$linesEndpoint'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> linesData = data['lines'];
        final List<Map<String, dynamic>> lines = List<Map<String, dynamic>>.from(
          linesData.map((item) => Map<String, dynamic>.from(item))
        );
        
        // Cache the data
        prefs.setString(_cacheKeyLines, jsonEncode(lines));
        prefs.setInt('${_cacheKeyLines}_time', DateTime.now().millisecondsSinceEpoch);
        
        // Store in memory cache
        _memoryCache[_cacheKeyLines] = lines;
        
        return lines;
      } else {
        throw Exception('Failed to load lines: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load lines: $e');
    }
  }
  
  // Get stations for a specific line
  Future<List<String>> getStations(String lineId) async {
    final cacheKey = '$_cacheKeyStationsByLine$lineId';
    
    // Check memory cache first
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey];
    }
    
    // Check shared preferences cache
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(cacheKey);
    
    if (cachedData != null) {
      final cacheTime = prefs.getInt('${cacheKey}_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      // Check if cache is still valid (24 hours)
      if (currentTime - cacheTime < _cacheDuration * 60 * 60 * 1000) {
        final List<dynamic> decodedData = jsonDecode(cachedData);
        final List<String> stations = List<String>.from(decodedData);
        
        // Store in memory cache
        _memoryCache[cacheKey] = stations;
        
        return stations;
      }
    }
    
    // Fetch from API if no valid cache
    try {
      final response = await http.get(Uri.parse('$baseUrl$stationsEndpoint/$lineId'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> stationsData = data['stations'];
        final List<String> stations = List<String>.from(stationsData);
        
        // Cache the data
        prefs.setString(cacheKey, jsonEncode(stations));
        prefs.setInt('${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);
        
        // Store in memory cache
        _memoryCache[cacheKey] = stations;
        
        return stations;
      } else {
        throw Exception('Failed to load stations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load stations: $e');
    }
  }
  
  // Get all stations from all lines
  Future<List<String>> getAllStations() async {
    // Check memory cache first
    if (_memoryCache.containsKey(_cacheKeyAllStations)) {
      return _memoryCache[_cacheKeyAllStations];
    }
    
    // Check shared preferences cache
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKeyAllStations);
    
    if (cachedData != null) {
      final cacheTime = prefs.getInt('${_cacheKeyAllStations}_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      // Check if cache is still valid (24 hours)
      if (currentTime - cacheTime < _cacheDuration * 60 * 60 * 1000) {
        final List<dynamic> decodedData = jsonDecode(cachedData);
        final List<String> allStations = List<String>.from(decodedData);
        
        // Store in memory cache
        _memoryCache[_cacheKeyAllStations] = allStations;
        
        return allStations;
      }
    }
    
    // Fetch all lines first
    final lines = await getLines();
    
    // Fetch stations for each line
    List<String> allStations = [];
    
    for (var line in lines) {
      final String lineId = line['id'];
      final stations = await getStations(lineId);
      allStations.addAll(stations);
    }
    
    // Remove duplicates and sort
    allStations = allStations.toSet().toList();
    allStations.sort();
    
    // Cache the data
    prefs.setString(_cacheKeyAllStations, jsonEncode(allStations));
    prefs.setInt('${_cacheKeyAllStations}_time', DateTime.now().millisecondsSinceEpoch);
    
    // Store in memory cache
    _memoryCache[_cacheKeyAllStations] = allStations;
    
    return allStations;
  }
  
  // Find route between two stations
  Future<RouteResult> findRoute(String source, String destination) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$routeEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'source': source,
          'destination': destination,
        }),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return RouteResult.fromJson(data, source, destination);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return RouteResult.withError(errorData['error'] ?? 'Failed to find route');
      }
    } catch (e) {
      return RouteResult.withError('Failed to find route: $e');
    }
  }
  
  // Save a route to favorites
  Future<void> addFavoriteRoute(String source, String destination, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKeyFavoriteRoutes);
    
    List<Map<String, dynamic>> favorites = [];
    
    if (cachedData != null) {
      final List<dynamic> decodedData = jsonDecode(cachedData);
      favorites = List<Map<String, dynamic>>.from(
        decodedData.map((item) => Map<String, dynamic>.from(item))
      );
    }
    
    // Check if route already exists
    final existingIndex = favorites.indexWhere(
      (route) => route['source'] == source && route['destination'] == destination
    );
    
    if (existingIndex != -1) {
      // Update existing route
      favorites[existingIndex]['name'] = name;
    } else {
      // Add new route
      favorites.add({
        'source': source,
        'destination': destination,
        'name': name,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
    
    // Save to shared preferences
    prefs.setString(_cacheKeyFavoriteRoutes, jsonEncode(favorites));
  }
  
  // Get favorite routes
  Future<List<Map<String, dynamic>>> getFavoriteRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKeyFavoriteRoutes);
    
    if (cachedData != null) {
      final List<dynamic> decodedData = jsonDecode(cachedData);
      return List<Map<String, dynamic>>.from(
        decodedData.map((item) => Map<String, dynamic>.from(item))
      );
    }
    
    return [];
  }
  
  // Remove a favorite route
  Future<void> removeFavoriteRoute(String source, String destination) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKeyFavoriteRoutes);
    
    if (cachedData != null) {
      final List<dynamic> decodedData = jsonDecode(cachedData);
      List<Map<String, dynamic>> favorites = List<Map<String, dynamic>>.from(
        decodedData.map((item) => Map<String, dynamic>.from(item))
      );
      
      // Remove the route
      favorites.removeWhere(
        (route) => route['source'] == source && route['destination'] == destination
      );
      
      // Save to shared preferences
      prefs.setString(_cacheKeyFavoriteRoutes, jsonEncode(favorites));
    }
  }
  
  // Clear all caches
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKeyLines);
    await prefs.remove(_cacheKeyAllStations);
    
    // Clear line-specific caches
    final lines = await getLines();
    for (var line in lines) {
      final String lineId = line['id'];
      await prefs.remove('$_cacheKeyStationsByLine$lineId');
    }
    
    // Clear memory cache
    _memoryCache.clear();
  }
  
  // NEW METHODS FOR TRAIN SCHEDULES AND TRACKING
  
  // Get next trains for a station
  Future<List<Map<String, dynamic>>> getNextTrains(String stationName, {String? time, int count = 5}) async {
    try {
      final queryParams = {
        'station': stationName,
        if (time != null) 'time': time,
        'count': count.toString(),
      };
      
      final uri = Uri.parse('$baseUrl$nextTrainsEndpoint').replace(queryParameters: queryParams);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final nextTrains = List<Map<String, dynamic>>.from(data['next_trains']);
        
        // Check for empty response
        if (nextTrains.isEmpty) {
          // Log to console that no trains are available
          print('No upcoming trains for station: $stationName');
        }
        
        return nextTrains;
      } else {
        throw Exception('Failed to load next trains: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load next trains: $e');
    }
  }
  
  // Get current train locations
  Future<List<Map<String, dynamic>>> getTrainLocations({String? time}) async {
    try {
      final queryParams = {
        if (time != null) 'time': time,
      };
      
      final uri = Uri.parse('$baseUrl$trainLocationsEndpoint').replace(queryParameters: queryParams);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final trains = List<Map<String, dynamic>>.from(data['trains']);
        
        // Check for empty response with trains data
        if (trains.isEmpty) {
          // Log to console that no trains are running
          print('API response indicates no trains currently running');
        }
        
        return trains;
      } else {
        throw Exception('Failed to load train locations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load train locations: $e');
    }
  }
  
  // Get schedule for a specific train
  Future<Map<String, dynamic>> getTrainSchedule(String tripId) async {
    try {
      final queryParams = {
        'trip_id': tripId,
      };
      
      final uri = Uri.parse('$baseUrl$trainScheduleEndpoint').replace(queryParameters: queryParams);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get train schedule');
      }
    } catch (e) {
      throw Exception('Failed to get train schedule: $e');
    }
  }
  
  // Get schedule for a specific station
  Future<Map<String, dynamic>> getStationSchedule(String stationName) async {
    try {
      final queryParams = {
        'station': stationName,
      };
      
      final uri = Uri.parse('$baseUrl$stationScheduleEndpoint').replace(queryParameters: queryParams);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get station schedule');
      }
    } catch (e) {
      throw Exception('Failed to get station schedule: $e');
    }
  }
  
  // Find route with schedule info
  Future<Map<String, dynamic>> findRouteWithSchedule(String source, String destination, {String? time}) async {
    try {
      final queryParams = {
        'source': source,
        'destination': destination,
        if (time != null) 'time': time,
      };
      
      final uri = Uri.parse('$baseUrl$routeWithScheduleEndpoint').replace(queryParameters: queryParams);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to find route with schedule');
      }
    } catch (e) {
      throw Exception('Failed to find route with schedule: $e');
    }
  }
  
  // Get next schedule for a station
  Future<Map<String, dynamic>> getNextSchedule(String stationName, {String? line, String? time}) async {
    try {
      final queryParams = {
        'station': stationName,
        if (line != null) 'line': line,
        if (time != null) 'time': time,
      };
      
      final uri = Uri.parse('$baseUrl$nextScheduleEndpoint').replace(queryParameters: queryParams);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get next schedule');
      }
    } catch (e) {
      throw Exception('Failed to get next schedule: $e');
    }
  }
} 