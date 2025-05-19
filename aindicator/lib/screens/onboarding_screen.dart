import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aindicator/screens/home_screen.dart';
import 'package:aindicator/utils/app_colors.dart';
import 'package:aindicator/widgets/gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      title: 'Welcome to A-Indicator',
      description: 'Your ultimate companion for navigating the Ahmedabad Metro system with ease and confidence.',
      imageUrl: 'assets/welcome.png',
      color: AppColors.primaryColor,
    ),
    OnboardingItem(
      title: 'Find the Fastest Routes',
      description: 'Get optimal routes between any two stations with detailed information about transit points and travel time.',
      imageUrl: 'assets/fastestroute.png',
      color: AppColors.line2Color,
    ),
    OnboardingItem(
      title: 'Fare Information',
      description: 'Know exactly how much your journey will cost with accurate fare information between stations.',
      imageUrl: 'assets/fare.png',
      color: AppColors.line3Color,
    ),
    OnboardingItem(
      title: 'Metro Line Information',
      description: 'Explore all metro lines and stations with detailed information about each line and its connectivity.',
      imageUrl: 'assets/liveinfo.png',
      color: AppColors.line4Color,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page View
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _onboardingItems.length,
            itemBuilder: (context, index) {
              return _buildOnboardingPage(_onboardingItems[index]);
            },
          ),
          
          // Skip button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _navigateToHome,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          // Bottom navigation
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Page indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _onboardingItems.length,
                    (index) => _buildPageIndicator(index),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Next or Get Started button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: GradientButton(
                    onPressed: () {
                      if (_currentPage == _onboardingItems.length - 1) {
                        _navigateToHome();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    text: _currentPage == _onboardingItems.length - 1
                        ? 'Get Started'
                        : 'Next',
                    gradient: LinearGradient(
                      colors: [
                        _onboardingItems[_currentPage].color,
                        _onboardingItems[_currentPage].color.withOpacity(0.8),
                      ],
                    ),
                    width: double.infinity,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingItem item) {
    return Container(
      decoration: BoxDecoration(
        color: item.color,
      ),
      child: Column(
        children: [
          // Image section (top 60%)
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(item.imageUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    item.color.withOpacity(0.7),
                    BlendMode.srcATop,
                  ),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      item.color,
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          
          // Content section (bottom 40%)
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 20),
                  
                  Text(
                    item.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    bool isCurrentPage = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 10,
      width: isCurrentPage ? 30 : 10,
      decoration: BoxDecoration(
        color: isCurrentPage ? Colors.white : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final String imageUrl;
  final Color color;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.color,
  });
} 