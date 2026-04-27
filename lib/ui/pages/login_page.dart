import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'otp_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool online = true;
  String? _errorMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((results) {
      setState(() {
        // Check if any result is NOT none (means we have connectivity)
        online = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      });
    });
  }

  void _clearError() {
    if (_hasError) {
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final email = value.trim();
    if (!email.contains('@')) {
      return 'Please enter a valid email (missing @)';
    }
    if (!email.contains('.')) {
      return 'Please enter a valid email (missing domain)';
    }
    // More thorough email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _sendOtp() async {
    _clearError();
    
    // Validate form
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Check internet
    if (!online) {
      _showErrorDialog(
        'No Internet Connection',
        'Please check your internet connection and try again.',
        Icons.wifi_off,
        Colors.orange,
      );
      return;
    }

    final email = emailCtrl.text.trim();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    final err = await auth.sendOtp(email);
    
    if (!mounted) return;
    
    if (err == null) {
      // Success - navigate to OTP page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpPage(email: email)),
      );
    } else {
      // Handle different error types
      String title = 'Error';
      String message = err;
      IconData icon = Icons.error_outline;
      Color color = Colors.red;

      if (err.toLowerCase().contains('network') || err.toLowerCase().contains('internet')) {
        title = 'Network Error';
        message = 'Unable to connect to server. Please check your internet connection.';
        icon = Icons.wifi_off;
        color = Colors.orange;
      } else if (err.toLowerCase().contains('timeout') || err.toLowerCase().contains('not responding')) {
        title = 'Server Timeout';
        message = 'Server is taking too long to respond. Please try again in a moment.';
        icon = Icons.timer_off;
        color = Colors.orange;
      } else if (err.toLowerCase().contains('invalid') || err.toLowerCase().contains('not found')) {
        title = 'Invalid Email';
        message = 'This email is not registered. Please check and try again.';
        icon = Icons.email_outlined;
        color = Colors.red;
      } else if (err.toLowerCase().contains('too many')) {
        title = 'Too Many Attempts';
        message = 'Too many OTP requests. Please wait a few minutes before trying again.';
        icon = Icons.access_time;
        color = Colors.orange;
      }

      _showError(message);
      _showErrorDialog(title, message, icon, color);
    }
  }

  void _showErrorDialog(String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                
                // Logo/Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.calculate_outlined,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Estimate Pro',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Construction Cost Calculator',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // No Internet Banner
                if (!online)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No Internet Connection',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              Text(
                                'Please check your connection',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your email to receive OTP',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                
                const SizedBox(height: 24),
                
                // Email Input
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  onFieldSubmitted: (_) => _sendOtp(),
                  onChanged: (_) => _clearError(),
                  validator: _validateEmail,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'example@gmail.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: _hasError ? Colors.red : null,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _hasError ? Colors.red : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _hasError ? Colors.red : Colors.blue,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                
                // Error Message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Send OTP Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (!online || auth.sending) ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: auth.sending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Send OTP',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Server Status Info
                if (auth.sending)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connecting to server...',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              Text(
                                'This may take a moment on first request',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }
}
