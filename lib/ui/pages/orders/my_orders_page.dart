import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/services/api_client.dart';
import 'order_details_page.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  List<dynamic> orders = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (!auth.isLoggedIn) {
      setState(() {
        errorMessage = 'Please login to view your orders';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      debugPrint('Fetching orders for user: ${auth.userId}');
      debugPrint('Token: ${auth.token}');

      final response = await ApiClient.get(
        '/orders/order/user/${auth.userId}',
        token: auth.token,
      );

      debugPrint('API Response: $response');
      debugPrint('Response status: ${response['status']}');
      debugPrint('Response success: ${response['success']}');
      debugPrint('Response body type: ${response['body'].runtimeType}');

      if (response['success'] == true && response['status'] == 200) {
        final responseBody = response['body'];
        debugPrint('Response body type: ${responseBody.runtimeType}');
        debugPrint('Response body: $responseBody');

        // Handle the API response - it's a direct array
        List<dynamic> ordersList = [];

        try {
          if (responseBody is List) {
            ordersList = responseBody;
          } else if (responseBody is Map<String, dynamic>) {
            // Fallback if response format changes
            if (responseBody.containsKey('orders')) {
              final ordersData = responseBody['orders'];
              if (ordersData is List) {
                ordersList = ordersData;
              }
            } else if (responseBody.containsKey('data')) {
              final data = responseBody['data'];
              if (data is List) {
                ordersList = data;
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing response: $e');
        }

        setState(() {
          orders = ordersList;
          isLoading = false;
        });

        debugPrint('Orders loaded: ${orders.length}');
      } else {
        final errorMsg = response['body']?['message'] ??
            response['body']?.toString() ??
            'Failed to load orders';
        setState(() {
          errorMessage = errorMsg;
          isLoading = false;
        });
        debugPrint('Error response: $response');
      }
    } catch (e) {
      debugPrint('Network error: $e');
      setState(() {
        errorMessage = 'Network error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _deleteOrder(String orderId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      debugPrint('Deleting order: $orderId');

      // Add DELETE method to ApiClient
      final response = await ApiClient.delete(
        '/orders/order/$orderId',
        token: auth.token,
      );

      debugPrint('Delete response: $response');

      if (response['success'] == true) {
        setState(() {
          isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh the orders list
        _fetchOrders();
      } else {
        final errorMsg = response['body']?['message'] ??
            response['body']?.toString() ??
            'Failed to delete order';
        setState(() {
          errorMessage = errorMsg;
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Delete error: $e');
      setState(() {
        errorMessage = 'Network error: ${e.toString()}';
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your orders...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchOrders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No orders found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your orders will appear here once you place them',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderCard(
          order: order,
          onDelete: () => _deleteOrder(order['_id']),
          onRefresh: _fetchOrders,
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final dynamic order;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;

  const _OrderCard({
    required this.order,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final orderId = order['_id'] ?? 'Unknown';
    final status = order['status'] ?? 'Unknown';
    final createdAt = order['createdAt'] ?? '';
    final payment = order['payment'] ?? {};
    final totalAmount = payment['amount'] ?? 0.0;
    final requestType = order['requestType'] ?? 'Unknown';
    final date = order['date'] ?? '';

    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${orderId.toString().substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        requestType.toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status.toString().toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  date.isNotEmpty
                      ? date
                      : (createdAt.isNotEmpty
                          ? DateTime.tryParse(createdAt)
                                  ?.toString()
                                  .split(' ')[0] ??
                              'Unknown date'
                          : 'Unknown date'),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.currency_rupee, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Total: ₹${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailsPage(
                          order: order,
                          onOrderUpdated: onRefresh,
                        ),
                      ),
                    );
                  },
                  child: const Text('View Details'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showDeleteDialog(context, orderId),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Order',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text('Are you sure you want to delete this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
