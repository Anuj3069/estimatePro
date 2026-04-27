// lib/ui/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'estimate/create_estimate_page.dart';
import 'orders/my_orders_page.dart';

/// Home Page - Used standalone (legacy) or as content in DashboardShell
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: const HomeContent(),
    );
  }
}

/// Home Content - The actual content of home page
/// Can be used inside DashboardShell or standalone
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return RefreshIndicator(
      onRefresh: () async {
        // Add your refresh logic here
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─────────────────────────────────────────────────────────
            // Welcome Card
            // ─────────────────────────────────────────────────────────
            _WelcomeCard(email: auth.email ?? 'User'),

            const SizedBox(height: 20),

            // ─────────────────────────────────────────────────────────
            // Quick Actions
            // ─────────────────────────────────────────────────────────
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const _QuickActionsGrid(),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────────────────────
            // Recent Activity / Stats
            // ─────────────────────────────────────────────────────────
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const _StatsCards(),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────────────────────
            // Recent Orders / Activity
            // ─────────────────────────────────────────────────────────
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const _RecentActivityList(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Welcome Card Widget
// ═══════════════════════════════════════════════════════════════════
class _WelcomeCard extends StatelessWidget {
  final String email;
  const _WelcomeCard({required this.email});

  @override
  Widget build(BuildContext context) {
    final name = email.split('@').first;
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17) {
      greeting = 'Good Evening';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a1a2e),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Welcome to Estimate Pro',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Quick Actions Grid
// ═══════════════════════════════════════════════════════════════════
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
          'New Estimate', Icons.add_circle_outline, Colors.blue, 'estimate'),
      _QuickAction(
          'My Orders', Icons.shopping_bag_outlined, Colors.orange, 'orders'),
      _QuickAction('Bulk Order', Icons.layers_outlined, Colors.purple, 'bulk'),
      _QuickAction('Pricing', Icons.currency_rupee, Colors.green, 'pricing'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          onTap: () {
            if (action.route == 'estimate') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateEstimatePage()),
              );
            } else if (action.route == 'orders') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyOrdersPage()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${action.title} - Coming Soon!')),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: action.color.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.icon, color: action.color, size: 28),
                const SizedBox(height: 6),
                Text(
                  action.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: action.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  _QuickAction(this.title, this.icon, this.color, this.route);
}

// ═══════════════════════════════════════════════════════════════════
// Stats Cards
// ═══════════════════════════════════════════════════════════════════
class _StatsCards extends StatelessWidget {
  const _StatsCards();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Orders',
            value: '0',
            icon: Icons.shopping_cart,
            color: Colors.blue,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Pending',
            value: '0',
            icon: Icons.pending_actions,
            color: Colors.orange,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Completed',
            value: '0',
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Recent Activity List
// ═══════════════════════════════════════════════════════════════════
class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList();

  @override
  Widget build(BuildContext context) {
    // Empty state
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No recent activity',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your recent orders and estimates will appear here',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
