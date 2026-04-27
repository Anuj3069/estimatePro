// lib/ui/widgets/main_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../pages/login_page.dart';
import '../pages/help_page.dart';
import '../pages/orders/my_orders_page.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final email = auth.email ?? 'user@example.com';
    final name = email.split('@').first;
    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();

    return Drawer(
      child: Column(
        children: [
          // ─────────────────────────────────────────────────────────
          // Drawer Header with User Info
          // ─────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFF1a1a2e),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // User Name
                Text(
                  'Hi, ${name.isNotEmpty ? name[0].toUpperCase() + name.substring(1) : 'User'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                // User Email
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // ─────────────────────────────────────────────────────────
          // Menu Items
          // ─────────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),

                // Main Actions
                _DrawerItem(
                  icon: Icons.shopping_bag_outlined,
                  title: 'My Orders',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyOrdersPage()),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.video_library_outlined,
                  title: 'Video Tutorial',
                  onTap: () => _showComingSoon(context, 'Video Tutorial'),
                ),
                _DrawerItem(
                  icon: Icons.layers_outlined,
                  title: 'Bulk Order',
                  onTap: () => _showComingSoon(context, 'Bulk Order'),
                ),
                _DrawerItem(
                  icon: Icons.local_offer_outlined,
                  title: 'Offers',
                  onTap: () => _showComingSoon(context, 'Offers'),
                ),
                _DrawerItem(
                  icon: Icons.currency_rupee,
                  title: 'Pricing',
                  onTap: () => _showComingSoon(context, 'Pricing'),
                ),

                const Divider(height: 24),

                // Info Section
                _DrawerItem(
                  icon: Icons.info_outline,
                  title: 'About Us',
                  onTap: () => _showComingSoon(context, 'About Us'),
                ),
                _DrawerItem(
                  icon: Icons.call_outlined,
                  title: 'Contact Us',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpPage()),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _showComingSoon(context, 'Privacy Policy'),
                ),
                _DrawerItem(
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  onTap: () => _showComingSoon(context, 'Terms & Conditions'),
                ),
                _DrawerItem(
                  icon: Icons.restore,
                  title: 'Return & Cancellation',
                  onTap: () =>
                      _showComingSoon(context, 'Return & Cancellation'),
                ),
              ],
            ),
          ),

          // ─────────────────────────────────────────────────────────
          // Logout Button at Bottom
          // ─────────────────────────────────────────────────────────
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () => _showLogoutDialog(context, auth),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await auth.logout();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Drawer Item Widget
// ═══════════════════════════════════════════════════════════════════
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
    );
  }
}
