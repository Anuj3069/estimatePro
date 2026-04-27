import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/services/api_client.dart';

class OrderDetailsPage extends StatefulWidget {
  final dynamic order;
  final VoidCallback onOrderUpdated;

  const OrderDetailsPage({
    super.key,
    required this.order,
    required this.onOrderUpdated,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  bool isUpdating = false;
  bool isDeleting = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Form controllers for update
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _amountController;
  late String _selectedPaymentStatus;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    final inputs = widget.order['inputs'] ?? {};
    final dimensions = inputs['dimensions'] ?? {};
    final payment = widget.order['payment'] ?? {};

    _widthController = TextEditingController(
      text: dimensions['width']?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: dimensions['length']?.toString() ??
          dimensions['height']?.toString() ??
          '',
    );
    _amountController = TextEditingController(
      text: payment['amount']?.toString() ?? '',
    );
    _selectedPaymentStatus = payment['status'] ?? 'pending';
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _updateOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      isUpdating = true;
    });

    try {
      final updateData = {
        "customerId": widget.order['customerId']['_id'],
        "requestType": widget.order['requestType']?.toLowerCase() ?? 'estimate',
        "inputs": {
          "width": double.tryParse(_widthController.text) ?? 0,
          "height": double.tryParse(_heightController.text) ?? 0,
        },
        "payment": {
          "amount": double.tryParse(_amountController.text) ?? 0,
          "status": _selectedPaymentStatus,
        },
      };


      final response = await ApiClient.put(
        '/orders/order/${widget.order['_id']}',
        updateData,
        token: auth.token,
      );
      if (!mounted) return;


      if (response['success'] == true) {
        setState(() {
          isUpdating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onOrderUpdated();
        Navigator.pop(context);
      } else {
        final errorMsg = response['body']?['message'] ??
            response['body']?.toString() ??
            'Failed to update order';
        setState(() {
          isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: isDeleting ? null : () => _showDeleteDialog(),
            icon: isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete Order',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Information Card
            _buildOrderInfoCard(),
            const SizedBox(height: 16),

            // Update Form
            _buildUpdateForm(),
            const SizedBox(height: 16),

            // Update Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isUpdating ? null : _updateOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: isUpdating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Updating...'),
                        ],
                      )
                    : const Text('Update Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    final order = widget.order;
    final customer = order['customerId'] ?? {};
    final inputs = order['inputs'] ?? {};
    final dimensions = inputs['dimensions'] ?? {};
    final payment = order['payment'] ?? {};

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
                'Order ID',
                order['_id']?.toString().substring(0, 8).toUpperCase() ??
                    'Unknown'),
            _buildInfoRow('Request Type',
                order['requestType']?.toString().toUpperCase() ?? 'Unknown'),
            _buildInfoRow('Status',
                order['status']?.toString().toUpperCase() ?? 'Unknown'),
            _buildInfoRow(
                'Customer Email', customer['email']?.toString() ?? 'Unknown'),
            _buildInfoRow('Date', order['date']?.toString() ?? 'Unknown'),
            _buildInfoRow('Created At',
                order['createdAt']?.toString().split('T')[0] ?? 'Unknown'),
            const Divider(height: 24),
            Text(
              'Current Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (dimensions['width'] != null)
              _buildInfoRow('Width', '${dimensions['width']}'),
            if (dimensions['length'] != null)
              _buildInfoRow('Length', '${dimensions['length']}'),
            if (dimensions['height'] != null)
              _buildInfoRow('Height', '${dimensions['height']}'),
            if (dimensions['groundFloor'] != null)
              _buildInfoRow(
                  'Ground Floor', '${dimensions['groundFloor']} sqft'),
            if (dimensions['firstFloor'] != null)
              _buildInfoRow('First Floor', '${dimensions['firstFloor']} sqft'),
            if (inputs['sheetType'] != null)
              _buildInfoRow('Sheet Type', inputs['sheetType']),
            if (inputs['ownerDetais'] != null &&
                inputs['ownerDetais']['name'] != null)
              _buildInfoRow('Owner Name', inputs['ownerDetais']['name']),
            if (inputs['ownerDetais'] != null &&
                inputs['ownerDetais']['address'] != null)
              _buildInfoRow('Address', inputs['ownerDetais']['address']),
            if (payment['amount'] != null)
              _buildInfoRow('Amount', '₹${payment['amount']}'),
            if (payment['currency'] != null)
              _buildInfoRow('Currency', payment['currency']),
            if (payment['status'] != null)
              _buildInfoRow('Payment Status', payment['status']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Order',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _widthController,
                decoration: const InputDecoration(
                  labelText: 'Width',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter width';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: 'Height/Length',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.height),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter height/length';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedPaymentStatus,
                decoration: const InputDecoration(
                  labelText: 'Payment Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'failed', child: Text('Failed')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentStatus = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text(
            'Are you sure you want to delete this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteOrder();
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

  Future<void> _deleteOrder() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      isDeleting = true;
    });

    try {
      final response = await ApiClient.delete(
        '/orders/order/${widget.order['_id']}',
        token: auth.token,
      );
      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          isDeleting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onOrderUpdated();
        Navigator.pop(context);
      } else {
        final errorMsg = response['body']?['message'] ??
            response['body']?.toString() ??
            'Failed to delete order';
        setState(() {
          isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
