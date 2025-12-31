import 'package:flutter/material.dart';
import 'dart:async';
import 'views/auth/signup_dialog.dart';
import 'views/dashboard/dashboard_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'views/auth/login_dialog.dart';
import 'services/auth_service.dart';
import 'package:provider/provider.dart';
import 'services/notification_service.dart';
import 'widgets/notification_manager.dart';
import 'services/feature_notification_service.dart';
import 'services/chat_service.dart';
import 'views/chat/chat_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final notificationService = NotificationService();
  final featureNotificationService = FeatureNotificationService(notificationService);
  final chatService = ChatService();
  
  // Try to create required indexes
  try {
    await chatService.createRequiredIndexes();
  } catch (e) {
    debugPrint('Index creation triggered: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: notificationService),
        ChangeNotifierProvider.value(value: chatService),
        Provider.value(value: featureNotificationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Pulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 172, 15, 239),
        ),
        useMaterial3: true,
      ),
      home: NotificationManager(
        child: const AuthCheckPage(),
      ),
    );
  }
}

class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({super.key});

  @override
  State<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isUserLoggedIn();
    if (isLoggedIn) {
      final userType = await _authService.getUserType();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        )
      : const MyHomePage();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPage < 2) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _handleLoginSuccess(String email, String userType) async {
    await _authService.saveUserSession(email, userType);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DashboardPage(),
        ),
      );
    }
  }

  void _handleSignupSuccess(String email, String userType) async {
    await _authService.saveUserSession(email, userType);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DashboardPage(),
        ),
      );
    }
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LoginDialog(
        onLoginSuccess: _handleLoginSuccess,
      ),
    );
  }

  void _showSignupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SignupDialog(
        onSignupSuccess: _handleSignupSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8CCFF), Color(0xFF9C4DFF)],
            stops: [0.1, 0.9],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroSection(context),
              const SizedBox(height: 60),
              _buildContactSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF6C14F0), const Color(0xFF9C4DFF).withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: isDesktop ? 80.0 : 40.0,
              horizontal: 20.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    // Logo and App Name at the top
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.pets,
                            size: isDesktop ? 50 : 35,
                            color: const Color(0xFF6C14F0),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          'PetPulse',
                          style: TextStyle(
                            fontSize: isDesktop ? 52 : 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    // Login and Register Buttons 
                    Container(
                      width: isDesktop ? 500 : constraints.maxWidth * 0.9,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Join Our Community Today!',
                            style: TextStyle(
                              fontSize: isDesktop ? 24 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showLoginDialog(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF6C14F0),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 24,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 5,
                                  ),
                                  icon: const Icon(Icons.login),
                                  label: const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showSignupDialog(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF25CAF),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 24,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 5,
                                  ),
                                  icon: const Icon(Icons.person_add),
                                  label: const Text(
                                    'Register',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Description
                    Container(
                      width: isDesktop ? constraints.maxWidth * 0.7 : constraints.maxWidth * 0.9,
                      padding: const EdgeInsets.all(5),
                      child: Text(
                        'Your all-in-one companion for pet care, health tracking, and veterinary assistance. Making pet parenting easier, healthier, and more enjoyable.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isDesktop ? 22 : 18,
                          height: 1.5,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    
                    // Animated Services Section
                    _buildAnimatedServicesSection(isDesktop, constraints),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedServicesSection(bool isDesktop, BoxConstraints constraints) {
    final services = [
      {'icon': Icons.pets, 'title': 'Notification service', 'description': 'Never miss an appointment'},
      {'icon': Icons.spa, 'title': 'Find Companions', 'description': 'Easily find perfect matches'},
      {'icon': Icons.hotel, 'title': 'Health tracking', 'description': 'Keep track of your pet'},
      {'icon': Icons.local_pharmacy, 'title': 'Ask about health', 'description': 'Ask your vet or AI'},
    ];

    return Column(
      children: [
        Text(
          'Our Services',
          style: TextStyle(
            fontSize: isDesktop ? 32 : 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: isDesktop ? 300 : 250,
          width: isDesktop ? 800 : constraints.maxWidth,
          child: AnimatedServicesWidget(services: services),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Get in Touch',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 40,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _buildContactItem(Icons.phone, '+94786843856'),
              _buildContactItem(Icons.email, 'ofcl.petpulse@gmail.com'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C14F0), Color(0xFFA554FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.pets,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 10),
          const Text(
            'PetPulse',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselItem(String imagePath, String title, String description) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Image.asset(
              imagePath,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(15),
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C14F0),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedServicesWidget extends StatefulWidget {
  final List<Map<String, dynamic>> services;

  const AnimatedServicesWidget({super.key, required this.services});

  @override
  State<AnimatedServicesWidget> createState() => _AnimatedServicesWidgetState();
}

class _AnimatedServicesWidgetState extends State<AnimatedServicesWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Create animations for each service
    _animations = List.generate(
      widget.services.length,
      (index) => CurvedAnimation(
        parent: _controller,
        curve: Interval(
          index * 0.2,
          index * 0.2 + 0.6,
          curve: Curves.easeInOut,
        ),
      ),
    );

    _slideAnimations = _animations.map((animation) {
      return Tween<Offset>(
        begin: const Offset(0.5, 0),
        end: Offset.zero,
      ).animate(animation);
    }).toList();

    // Start the animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: widget.services.length,
      itemBuilder: (context, index) {
        final service = widget.services[index];
        return FadeTransition(
          opacity: _animations[index],
          child: SlideTransition(
            position: _slideAnimations[index],
            child: Container(
              width: 250,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      service['icon'] as IconData,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    service['title'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    service['description'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}