// lib/ui/pages/dashboard_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/main_drawer.dart';
import 'home_page.dart';
import 'help_page.dart';

/// Main Dashboard Shell - Shows after successful login
/// Contains: AppBar + Drawer (Side Nav) + Bottom Navigation + Pages
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Pages for Bottom Navigation
  final List<Widget> _pages = [
    const HomeContent(),
    const HelpPage(),
    const OffersPage(),
    const RSharePage(),
  ];

  // Page titles
  final List<String> _titles = [
    'Home',
    'Help',
    'Offers',
    'RShare',
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      
      // ─────────────────────────────────────────────────────────
      // App Bar
      // ─────────────────────────────────────────────────────────
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          // User email badge
          if (auth.email != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    auth.email!.split('@').first,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ),
            ),
          // Notifications
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
        ],
      ),

      // ─────────────────────────────────────────────────────────
      // Side Navigation Drawer
      // ─────────────────────────────────────────────────────────
      drawer: const MainDrawer(),

      // ─────────────────────────────────────────────────────────
      // Body - Current Page
      // ─────────────────────────────────────────────────────────
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // ─────────────────────────────────────────────────────────
      // Bottom Navigation Bar
      // ─────────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.help_outline),
              activeIcon: Icon(Icons.help),
              label: 'Help',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_offer_outlined),
              activeIcon: Icon(Icons.local_offer),
              label: 'Offers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.share_outlined),
              activeIcon: Icon(Icons.share),
              label: 'RShare',
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Placeholder Pages for Bottom Nav
// ═══════════════════════════════════════════════════════════════════

class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No Offers Available',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later for exciting offers!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class RSharePage extends StatelessWidget {
  const RSharePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.share, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Refer & Share',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share the app with friends and earn rewards!',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share link copied!')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Referral Link'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
