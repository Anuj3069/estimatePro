// lib/ui/pages/help_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final TextEditingController feedbackCtrl = TextEditingController();

  // Change to your real values
  static const _phone = '9876543210';
  static const _whatsapp = '919876543210';
  static const _email = 'support@company.com';

  @override
  void dispose() {
    feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _callNow() async {
    final uri = Uri(scheme: 'tel', path: _phone);
    await launchUrl(uri);
  }

  Future<void> _chatWhatsApp() async {
    final uri = Uri.parse('https://wa.me/$_whatsapp');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _emailNow() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _email,
      queryParameters: {'subject': 'Support Request'},
    );
    await launchUrl(uri);
  }

  Future<void> _openLink(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _submit() {
    final text = feedbackCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter feedback.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submitted successfully.')),
    );

    feedbackCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    // When used inside DashboardShell, return only the content (no Scaffold)
    return _buildContent();
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // Available Status
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(radius: 8, backgroundColor: Colors.green),
              SizedBox(width: 10),
              Text(
                'We are Available Now!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 6),
          const Text(
            'Mon - Sat (10:00 am - 07:00 pm)',
            style: TextStyle(color: Colors.black54),
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionBtn(Icons.call, 'Call Now', _callNow),
              _actionBtn(Icons.chat, 'WhatsApp', _chatWhatsApp),
              _actionBtn(Icons.mail, 'Email Now', _emailNow),
            ],
          ),

          const SizedBox(height: 26),
          const Text(
            'Social Connect:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 14),

          // Social Links
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _socialBtn(Icons.camera_alt, 'https://instagram.com/'),
              _socialBtn(Icons.play_circle_fill, 'https://youtube.com/'),
              _socialBtn(Icons.facebook, 'https://facebook.com/'),
              _socialBtn(Icons.work, 'https://linkedin.com/'),
            ],
          ),

          const SizedBox(height: 22),
          const Divider(),
          const SizedBox(height: 10),

          // Feedback Section
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Feedback / Message for CEO :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: feedbackCtrl,
            maxLines: 5,
            maxLength: 250,
            decoration: InputDecoration(
              hintText: 'Share your idea here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '*Required',
              style: TextStyle(color: Colors.teal.shade700),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'SUBMIT',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Function fn) {
    return InkWell(
      onTap: () => fn(),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialBtn(IconData icon, String url) {
    return InkWell(
      onTap: () => _openLink(url),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(width: 2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }
}
