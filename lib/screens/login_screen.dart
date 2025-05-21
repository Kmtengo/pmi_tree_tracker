import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/leaf_pattern_background.dart';
import '../widgets/pmi_button_styles.dart';

import '../view_models/user_view_model.dart';
import 'home_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<UserViewModel>(
        builder: (context, userViewModel, child) {
          return LeafPatternBackground(
            isFormPage: true,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo and Title
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              child: Image.asset(
                                'assets/images/pmi_logo.png',
                                height: 60,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.eco,
                                  size: 60,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'PMI Tree Tracker',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Kenya Tree Planting Initiative',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _isObscured,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscured ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isObscured = !_isObscured;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            
                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: const Text('Forgot Password?'),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: userViewModel.isLoading
                                    ? null
                                    : () async {
                                        if (_formKey.currentState!.validate()) {
                                          final success = await userViewModel.login(
                                            _emailController.text.trim(),
                                            _passwordController.text,
                                          );
                                          
                                          if (success && mounted && context.mounted) {
                                            Navigator.of(context).pushReplacement(
                                              MaterialPageRoute(builder: (_) => const HomePage()),
                                            );
                                          } else if (mounted && context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(userViewModel.error ?? 'Login failed'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },                                style: PMIButtonStyles.primaryButton(context),
                                child: userViewModel.isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Login', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Demo Login Shortcut
                            TextButton(
                              onPressed: userViewModel.isLoading
                                  ? null
                                  : () async {
                                      final success = await userViewModel.login(
                                        'john.doe@example.com',
                                        'password',
                                      );
                                      
                                      if (success && mounted && context.mounted) {
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(builder: (_) => const HomePage()),
                                        );
                                      }
                                    },
                              child: const Text('Demo Login'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
