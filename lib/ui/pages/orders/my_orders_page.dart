import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/services/api_client.dart';
import '../estimate/create_estimate_page.dart';

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

      final response = await ApiClient.get(
        '/orders/order/user/${auth.userId}',
        token: auth.token,
      );


      if (response['success'] == true && response['status'] == 200) {
        final responseBody = response['body'];

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
        }

        setState(() {
          orders = ordersList;
          isLoading = false;
        });

      } else {
        final errorMsg = response['body']?['message'] ??
            response['body']?.toString() ??
            'Failed to load orders';
        setState(() {
          errorMessage = errorMsg;
          isLoading = false;
        });
      }
    } catch (e) {
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

      // Add DELETE method to ApiClient
      final response = await ApiClient.delete(
        '/orders/order/$orderId',
        token: auth.token,
      );


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

  Future<void> _updateOwnerDetails(
    dynamic order, {
    required String name,
    required String address,
  }) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final orderId = order['_id']?.toString();

    if (orderId == null || orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final existingInputs = Map<String, dynamic>.from(order['inputs'] ?? {});
      final updateData = {
        'inputs': {
          ...existingInputs,
          'ownerDetais': {
            'name': name.trim(),
            'address': address.trim(),
          },
        },
      };

      final response = await ApiClient.put(
        '/orders/order/$orderId',
        updateData,
        token: auth.token,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Owner details updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _fetchOrders();
      } else {
        final errorMsg = response['body']?['message'] ??
            response['body']?.toString() ??
            'Failed to update owner details';
        setState(() {
          errorMessage = errorMsg;
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
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

  Future<String?> _generateOrderEstimate(dynamic order) async {
    final inputs = _asMap(order['inputs']);
    final dimensions = _asMap(inputs['dimensions']);
    final ownerDetails =
        _asMap(inputs['ownerDetais'] ?? inputs['ownerDetails']);
    final estimateId = inputs['estimateId']?.toString();

    if (estimateId == null || estimateId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estimate ID not found for this order'),
          backgroundColor: Colors.orange,
        ),
      );
      return null;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final body = {
        'estimateId': estimateId,
        'dimensions': dimensions,
        'ownerDetais': ownerDetails,
        'sheetType': inputs['sheetType'],
        'floorType': inputs['floorType'],
        'totalArea': inputs['totalArea'],
        'totalAmount': inputs['totalAmount'],
      };

      final response = await http
          .post(
            Uri.parse('${ApiClient.base}/estimate/generate'),
            headers: {
              'Content-Type': 'application/json',
              if (auth.userId != null) 'userId': auth.userId!,
              if (auth.token != null) 'Authorization': 'Bearer ${auth.token}',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['estimateId']?.toString() ?? estimateId;
      }

      var errorDetail = response.body;
      try {
        final errorJson = jsonDecode(response.body);
        errorDetail =
            errorJson['error'] ?? errorJson['message'] ?? response.body;
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generate failed: $errorDetail'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Generate timeout. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generate error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return null;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  Future<void> _downloadOrderPdf(dynamic order) async {
    final estimateId = await _generateOrderEstimate(order);
    if (estimateId == null || estimateId.isEmpty) return;

    await _downloadEstimatePdf(estimateId);
  }

  Future<void> _downloadEstimatePdf(String estimateId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final url = Uri.parse(
        '${ApiClient.base}/estimate/generate/download/$estimateId',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (auth.userId != null) 'userid': auth.userId!,
          if (auth.token != null) 'Authorization': 'Bearer ${auth.token}',
        },
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/estimate_$estimateId.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        final result = await OpenFilex.open(filePath);

        if (!mounted) return;

        if (result.type == ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF opened successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (result.type == ResultType.noAppToOpen) {
          await Share.shareXFiles(
            [XFile(filePath)],
            text: 'Construction Estimate PDF',
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open PDF: ${result.message}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        var errorDetail = response.body;
        try {
          final errorJson = jsonDecode(response.body);
          errorDetail =
              errorJson['error'] ?? errorJson['message'] ?? response.body;
        } catch (_) {}

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $errorDetail'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download timeout. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openPendingOrderForm(dynamic order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEstimatePage(initialOrder: order),
      ),
    );

    if (mounted) {
      _fetchOrders();
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No orders found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
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
          onEdit: (name, address) => _updateOwnerDetails(
            order,
            name: name,
            address: address,
          ),
          onDownload: () => _downloadOrderPdf(order),
          onOpenPendingOrder: () => _openPendingOrderForm(order),
          onDelete: () => _deleteOrder(order['_id']),
        );
      },
    );
  }
}

class _OrderCard extends StatefulWidget {
  final dynamic order;
  final Future<void> Function(String name, String address) onEdit;
  final Future<void> Function() onDownload;
  final Future<void> Function() onOpenPendingOrder;
  final VoidCallback onDelete;

  const _OrderCard({
    required this.order,
    required this.onEdit,
    required this.onDownload,
    required this.onOpenPendingOrder,
    required this.onDelete,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final orderId = order['_id'] ?? 'Unknown';
    final status = order['status'] ?? 'Unknown';
    final createdAt = order['createdAt'] ?? '';
    final payment = order['payment'] ?? {};
    final totalAmount = payment['amount'] ?? 0.0;
    final requestType = order['requestType'] ?? 'Unknown';
    final date = order['date'] ?? '';
    final inputs = order['inputs'] ?? {};
    final ownerDetails = _ownerDetails(inputs);
    final ownerName = ownerDetails['name']?.toString() ?? 'Unknown owner';
    final normalizedStatus = status.toString().toUpperCase();
    final canDownload = normalizedStatus == 'PAID';
    final isPending = normalizedStatus == 'PENDING';

    Color statusColor;
    IconData statusIcon;

    switch (status.toString().toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'completed':
      case 'paid':
      case 'success':
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
                        'Order #${_shortId(orderId)}',
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
                      const SizedBox(height: 4),
                      Text(
                        ownerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                  'Total: ${_formatAmount(totalAmount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: isPending
                      ? () => widget.onOpenPendingOrder()
                      : () => _showEditDialog(context, ownerDetails),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                if (canDownload)
                  OutlinedButton.icon(
                    onPressed: _isDownloading ? null : _download,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download, size: 18),
                    label: const Text('Download'),
                  ),
                IconButton.filledTonal(
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

  Future<void> _download() async {
    setState(() {
      _isDownloading = true;
    });

    await widget.onDownload();

    if (mounted) {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  String _shortId(dynamic value) {
    final id = value?.toString() ?? 'Unknown';
    final length = id.length < 8 ? id.length : 8;
    return id.substring(0, length).toUpperCase();
  }

  String _formatAmount(dynamic value) {
    final amount = value is num ? value : num.tryParse(value.toString()) ?? 0;
    return 'Rs. ${amount.toStringAsFixed(2)}';
  }

  Map<String, dynamic> _ownerDetails(dynamic inputs) {
    if (inputs is! Map) return {};

    final details = inputs['ownerDetais'] ?? inputs['ownerDetails'];
    if (details is Map<String, dynamic>) return details;
    if (details is Map) return Map<String, dynamic>.from(details);

    return {};
  }

  void _showEditDialog(
    BuildContext context,
    Map<String, dynamic> ownerDetails,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: ownerDetails['name']?.toString() ?? '',
    );
    final addressController = TextEditingController(
      text: ownerDetails['address']?.toString() ?? '',
    );
    var isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Owner Details'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  minLines: 2,
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        isSaving = true;
                      });
                      await widget.onEdit(
                        nameController.text,
                        addressController.text,
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      nameController.dispose();
      addressController.dispose();
    });
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
              widget.onDelete();
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
