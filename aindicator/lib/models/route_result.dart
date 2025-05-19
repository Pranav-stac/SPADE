class RouteResult {
  final String source;
  final String destination;
  final List<String> route;
  final List<String> lines;
  final List<String> transit;
  final int fare;
  final String? error;

  RouteResult({
    required this.source,
    required this.destination,
    required this.route,
    required this.lines,
    required this.transit,
    required this.fare,
    this.error,
  });

  // Factory constructor to create a RouteResult from JSON
  factory RouteResult.fromJson(Map<String, dynamic> json, String source, String destination) {
    if (json.containsKey('error')) {
      return RouteResult.withError(json['error']);
    }
    
    return RouteResult(
      source: source,
      destination: destination,
      route: List<String>.from(json['route'] ?? []),
      lines: List<String>.from(json['lines'] ?? []),
      transit: List<String>.from(json['transit'] ?? []),
      fare: json['fare'] ?? 0,
      error: null,
    );
  }

  // Factory constructor for error cases
  factory RouteResult.withError(String errorMessage) {
    return RouteResult(
      source: '',
      destination: '',
      route: [],
      lines: [],
      transit: [],
      fare: 0,
      error: errorMessage,
    );
  }

  // Computed properties
  int get stationCount => route.length;
  bool get hasTransit => transit.isNotEmpty;
  int get transitCount => transit.length;
  
  bool get isMultiLine => lines.length > 1;
  
  String getLineColor(String line) {
    switch (line) {
      case 'Line 1':
        return '#3498DB'; // Blue
      case 'Line 2':
        return '#E74C3C'; // Red
      case 'Line 3':
        return '#2ECC71'; // Green
      case 'Line 4':
        return '#F39C12'; // Orange
      default:
        return '#3498DB'; // Default blue
    }
  }
} 