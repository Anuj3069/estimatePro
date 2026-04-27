import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'dashboard_shell.dart';

class OtpPage extends StatefulWidget {
  final String email;
  const OtpPage({super.key, required this.email});
  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _otpCtrl = TextEditingController();
  String? _errorMessage;
  bool _hasError = false;
  int _resendTimer = 0;
  bool _canResend = true;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 30;
      _canResend = false;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendTimer--);
      return _resendTimer > 0;
    }).then((_) {
      if (mounted) setState(() => _canResend = true);
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
    // Also show dialog for important errors
    _showErrorDialog(message);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: Colors.red.shade700),
            ),
            const SizedBox(width: 12),
            const Text('Verification Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Check your email and enter the correct 6-digit OTP',
                      style: TextStyle(fontSize: 13, color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _otpCtrl.clear();
            },
            child: const Text('Try Again'),
          ),
          if (_canResend)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resendOtp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Resend OTP'),
            ),
        ],
      ),
    );
  }

  Future<void> _resendOtp() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _clearError();
    
    final err = await auth.sendOtp(widget.email);
    
    if (!mounted) return;
    
    if (err == null) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('OTP sent successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _showError(err);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    
    // Validation
    if (otp.isEmpty) {
      _showError('Please enter the OTP');
      return;
    }
    
    if (otp.length != 6) {
      _showError('Please enter complete 6-digit OTP');
      return;
    }
    
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _showError('OTP should contain only numbers');
      return;
    }

    _clearError();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final err = await auth.verifyOtp(otp);
    
    if (!mounted) return;
    
    if (err == null) {
      // Success
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardShell()),
        (r) => false,
      );
    } else {
      // Error handling based on error type
      String errorMessage = err;
      if (err.toLowerCase().contains('invalid') || err.toLowerCase().contains('wrong')) {
        errorMessage = 'Invalid OTP! Please check and try again.';
      } else if (err.toLowerCase().contains('expired')) {
        errorMessage = 'OTP has expired. Please request a new one.';
      } else if (err.toLowerCase().contains('network') || err.toLowerCase().contains('internet')) {
        errorMessage = 'Network error! Please check your internet connection.';
      } else if (err.toLowerCase().contains('timeout')) {
        errorMessage = 'Server is not responding. Please try again later.';
      }
      _showError(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Email icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.email_outlined, size: 48, color: Colors.blue.shade700),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Enter Verification Code',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'We have sent a 6-digit OTP to',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              widget.email,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            
            const SizedBox(height: 32),
            
            // OTP Input with error state
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: _otpCtrl,
              autoDismissKeyboard: true,
              animationType: AnimationType.fade,
              keyboardType: TextInputType.number,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 50,
                fieldWidth: 45,
                activeFillColor: Colors.white,
                inactiveFillColor: Colors.grey.shade100,
                selectedFillColor: Colors.white,
                activeColor: _hasError ? Colors.red : Colors.blue,
                inactiveColor: _hasError ? Colors.red.shade200 : Colors.grey.shade300,
                selectedColor: Colors.blue,
                errorBorderColor: Colors.red,
              ),
              enableActiveFill: true,
              onChanged: (_) => _clearError(),
              beforeTextPaste: (text) {
                // Allow paste only if it's 6 digits
                return text != null && RegExp(r'^\d{6}$').hasMatch(text);
              },
            ),
            
            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
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
            
            // Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.verifying ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: auth.verifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Verify OTP',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Resend OTP
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive the code? ",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (_canResend)
                  TextButton(
                    onPressed: auth.sending ? null : _resendOtp,
                    child: Text(
                      auth.sending ? 'Sending...' : 'Resend OTP',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Text(
                    'Resend in ${_resendTimer}s',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Help text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline, size: 18, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Having trouble?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Check your spam/junk folder\n• Make sure email address is correct\n• Wait a few minutes and try again',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }
}
