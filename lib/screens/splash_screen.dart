import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/user_view_model.dart';
import '../widgets/pmi_header_logo.dart';
import 'login_screen.dart';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
    
    // Navigate after animation completes
    Future.delayed(const Duration(seconds: 3), () {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => userViewModel.isLoggedIn 
              ? const HomePage() 
              : const LoginScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _animation,
                  child: Image.asset(
                    'assets/images/pmi_logo.png',
                    height: 150,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.eco, size: 100, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _animation,
                  child: const Text(
                    'PMI Tree Tracker',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _animation,
                  child: const Text(
                    'Planting a greener future',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 64),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
