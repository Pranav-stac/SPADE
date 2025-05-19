import 'package:flutter/material.dart';
import 'package:aindicator/utils/app_colors.dart';
import 'package:aindicator/services/api_service.dart';

class FareInfoScreen extends StatefulWidget {
  const FareInfoScreen({super.key});

  @override
  State<FareInfoScreen> createState() => _FareInfoScreenState();
}

class _FareInfoScreenState extends State<FareInfoScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _fareCategories = [];
  String? _selectedSource;
  String? _selectedDestination;
  List<String> _stations = [];

  @override
  void initState() {
    super.initState();
    _loadFareInfo();
    _loadStations();
  }

  Future<void> _loadFareInfo() async {
    setState(() {
      _isLoading = true;
    });

    // In a real app, you would fetch this from the API
    // For now, we'll use hardcoded fare information
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _fareCategories = [
        {
          'title': 'Standard Fares',
          'description': 'Regular metro fares based on distance traveled',
          'icon': Icons.attach_money,
          'color': AppColors.line1Color,
          'items': [
            {'range': '0-3 km', 'fare': '₹10'},
            {'range': '3-6 km', 'fare': '₹15'},
            {'range': '6-12 km', 'fare': '₹20'},
            {'range': '12-18 km', 'fare': '₹25'},
            {'range': '18-24 km', 'fare': '₹30'},
            {'range': '24+ km', 'fare': '₹35'},
          ],
        },
        {
          'title': 'Concession Fares',
          'description': 'Discounted fares for eligible passengers',
          'icon': Icons.card_membership,
          'color': AppColors.line2Color,
          'items': [
            {'category': 'Students', 'discount': '30% off'},
            {'category': 'Senior Citizens', 'discount': '25% off'},
            {'category': 'Children (5-12 years)', 'discount': '50% off'},
            {'category': 'Children (below 5 years)', 'discount': 'Free'},
            {'category': 'Differently Abled', 'discount': '50% off'},
          ],
        },
        {
          'title': 'Pass Options',
          'description': 'Travel passes for regular commuters',
          'icon': Icons.card_travel,
          'color': AppColors.line3Color,
          'items': [
            {'type': 'Daily Pass', 'fare': '₹70'},
            {'type': 'Weekly Pass', 'fare': '₹300'},
            {'type': 'Monthly Pass', 'fare': '₹1000'},
            {'type': 'Quarterly Pass', 'fare': '₹2500'},
          ],
        },
        {
          'title': 'Group Fares',
          'description': 'Special fares for group travel',
          'icon': Icons.group,
          'color': AppColors.line4Color,
          'items': [
            {'group': '5-10 people', 'discount': '10% off'},
            {'group': '11-20 people', 'discount': '15% off'},
            {'group': '21+ people', 'discount': '20% off'},
          ],
        },
      ];
      _isLoading = false;
    });
  }

  Future<void> _loadStations() async {
    try {
      final stations = await _apiService.getAllStations();
      setState(() {
        _stations = stations;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load stations: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fare Information'),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source and Destination Dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSource,
                          hint: const Text('Select Source'),
                          items: _stations.map((station) {
                            return DropdownMenuItem(
                              value: station,
                              child: Text(station),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSource = value;
                            });
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedDestination,
                          hint: const Text('Select Destination'),
                          items: _stations.map((station) {
                            return DropdownMenuItem(
                              value: station,
                              child: Text(station),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDestination = value;
                            });
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _selectedSource != null && _selectedDestination != null
                        ? () {
                            // Fetch fare information based on selection
                            // For now, just show a dialog with a message
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Fare Information'),
                                content: Text('Fare from $_selectedSource to $_selectedDestination is ₹20'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Get Fare Information'),
                  ),

                  const SizedBox(height: 24),

                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: AppColors.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Fare Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Fares are calculated based on the distance traveled. Children under 5 travel free.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Fare Categories
                  ...List.generate(_fareCategories.length, (index) {
                    final category = _fareCategories[index];
                    return _buildFareCategory(category);
                  }),

                  const SizedBox(height: 24),

                  // Payment Methods
                  const Text(
                    'Payment Methods',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentMethods(),

                  const SizedBox(height: 24),

                  // Note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Fares are subject to change. Please check the official website for the most up-to-date information.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildFareCategory(Map<String, dynamic> category) {
    final Color color = category['color'];
    final List<dynamic> items = category['items'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              category['icon'],
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              category['title'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          category['description'],
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(items.length, (index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.containsKey('range')
                              ? item['range']
                              : item.containsKey('category')
                                  ? item['category']
                                  : item.containsKey('type')
                                      ? item['type']
                                      : item['group'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        item.containsKey('fare')
                            ? item['fare']
                            : item['discount'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    final List<Map<String, dynamic>> methods = [
      {
        'name': 'Metro Card',
        'icon': Icons.credit_card,
        'color': AppColors.line1Color,
      },
      {
        'name': 'Cash',
        'icon': Icons.money,
        'color': AppColors.line2Color,
      },
      {
        'name': 'UPI',
        'icon': Icons.phone_android,
        'color': AppColors.line3Color,
      },
      {
        'name': 'Credit/Debit Card',
        'icon': Icons.payment,
        'color': AppColors.line4Color,
      },
    ];

    return Row(
      children: List.generate(methods.length, (index) {
        final method = methods[index];
        return Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: method['color'].withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      method['icon'],
                      color: method['color'],
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    method['name'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
} 