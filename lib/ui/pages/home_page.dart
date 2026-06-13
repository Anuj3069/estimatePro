import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/api_client.dart';
import '../../providers/auth_provider.dart';
import 'estimate/create_estimate_page.dart';
import 'orders/my_orders_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const HomeContent(),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  bool _loaded = false;
  bool _loadingStats = false;
  int _totalOrders = 0;
  int _pendingOrders = 0;
  int _completedOrders = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _fetchDashboardStats();
    }
  }

  Future<void> _fetchDashboardStats() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) return;

    setState(() => _loadingStats = true);

    try {
      final response = await ApiClient.get(
        '/orders/order/user/${auth.userId}',
        token: auth.token,
      );
      if (!mounted) return;

      if (response['success'] == true && response['status'] == 200) {
        final orders = _extractOrders(response['body']);
        setState(() {
          _totalOrders = orders.length;
          _pendingOrders = orders.where(_isPendingOrder).length;
          _completedOrders = orders.where(_isCompletedOrder).length;
          _loadingStats = false;
        });
      } else {
        setState(() => _loadingStats = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  List<dynamic> _extractOrders(dynamic body) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      final orders = body['orders'] ?? body['data'];
      if (orders is List) return orders;
    }
    return [];
  }

  bool _isPendingOrder(dynamic order) {
    final status =
        order is Map ? order['status']?.toString().toLowerCase() : '';
    return status == 'pending';
  }

  bool _isCompletedOrder(dynamic order) {
    final status =
        order is Map ? order['status']?.toString().toLowerCase() : '';
    return status == 'completed' || status == 'paid' || status == 'success';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return RefreshIndicator(
      onRefresh: _fetchDashboardStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeCard(email: auth.email ?? 'User'),
            const SizedBox(height: 20),
            const _ServiceOptions(),
            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const _QuickActionsGrid(),
            const SizedBox(height: 24),
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _StatsCards(
              total: _totalOrders,
              pending: _pendingOrders,
              completed: _completedOrders,
              loading: _loadingStats,
            ),
            const SizedBox(height: 24),
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

class _WelcomeCard extends StatelessWidget {
  final String email;
  const _WelcomeCard({required this.email});

  @override
  Widget build(BuildContext context) {
    final name = email.split('@').first;
    final hour = DateTime.now().hour;
    var greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17) {
      greeting = 'Good Evening';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: const TextStyle(color: Colors.white70)),
                Text(
                  name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Welcome to Estimate Pro',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceOptions extends StatelessWidget {
  const _ServiceOptions();

  @override
  Widget build(BuildContext context) {
    final services = [
      _ServiceOption(
        title: 'Estimar',
        price: 'Rs. 299',
        icon: Icons.description_outlined,
        color: Colors.blue,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEstimatePage()),
          );
        },
      ),
      _ServiceOption(
        title: 'Khasra Super Imposed',
        price: 'Rs. 299',
        icon: Icons.map_outlined,
        color: Colors.teal,
      ),
      _ServiceOption(
        title: 'Naksha',
        price: 'Rs. 299',
        icon: Icons.architecture_outlined,
        color: Colors.deepOrange,
      ),
      _ServiceOption(
        title: 'Route Map',
        price: 'Rs. 299',
        icon: Icons.route_outlined,
        color: Colors.indigo,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 8,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 56,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ...services.map(
          (service) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ServiceTile(option: service),
          ),
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final _ServiceOption option;
  const _ServiceTile({required this.option});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: option.color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: option.onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _InstructionPage(title: option.title),
                ),
              );
            },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: option.color.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(option.icon, color: option.color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${option.title} @ ${option.price}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${option.title} sample PDF coming soon'),
                    ),
                  );
                },
                child: const Text('Sample PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceOption {
  final String title;
  final String price;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  _ServiceOption({
    required this.title,
    required this.price,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class _InstructionPage extends StatelessWidget {
  final String title;
  const _InstructionPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Is document ke liye aap diye hue mobile number par contact kar ke banwa sakte hain. Details WhatsApp kariye, within 1 working day aapko mil jaayega.',
            style: TextStyle(fontSize: 16, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

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
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
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

class _StatsCards extends StatelessWidget {
  final int total;
  final int pending;
  final int completed;
  final bool loading;

  const _StatsCards({
    required this.total,
    required this.pending,
    required this.completed,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Orders',
            value: loading ? '...' : total.toString(),
            icon: Icons.shopping_cart,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Pending',
            value: loading ? '...' : pending.toString(),
            icon: Icons.pending_actions,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Completed',
            value: loading ? '...' : completed.toString(),
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
        borderRadius: BorderRadius.circular(8),
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
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
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
