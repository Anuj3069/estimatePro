// lib/ui/pages/estimate/estimate_summary_page.dart

import 'package:flutter/material.dart';

/// Estimate Summary Page - Shows final estimate with PDF-like view
class EstimateSummaryPage extends StatelessWidget {
  final Map<String, dynamic> estimateData;

  const EstimateSummaryPage({super.key, required this.estimateData});

  @override
  Widget build(BuildContext context) {
    final floors = estimateData['floors'] as List<dynamic>;
    final owner = estimateData['owner'] as Map<String, dynamic>;
    final category = estimateData['category'] as String;
    final ratePerSqft = estimateData['ratePerSqft'] as double;
    final totalArea = estimateData['totalArea'] as double;
    final totalEstimate = estimateData['totalEstimate'] as double;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estimate Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareEstimate(context),
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadPDF(context),
            tooltip: 'Download PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Estimate Card (PDF-like)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'ESTIMATE PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Construction Cost Estimate',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Estimate ID & Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estimate No.',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                Text(
                                  '#EST${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Date',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                Text(
                                  _formatDate(DateTime.now()),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Owner Details Section
                        _sectionTitle('Owner Details'),
                        const SizedBox(height: 12),
                        _infoRow(Icons.person, 'Name', owner['name']),
                        _infoRow(Icons.phone, 'Phone', '+91 ${owner['phone']}'),
                        _infoRow(Icons.location_on, 'Address', owner['address']),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Floor Details Section
                        _sectionTitle('Floor Details'),
                        const SizedBox(height: 12),

                        // Floor table header
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Expanded(flex: 2, child: Text('Floor', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(child: Text('W × L', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                              Expanded(child: Text('Area', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                            ],
                          ),
                        ),

                        // Floor rows
                        ...floors.map((floor) {
                          final f = floor as Map<String, dynamic>;
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      Icon(
                                        f['floorType'] == 'Ground Floor' ? Icons.home : Icons.layers,
                                        size: 18,
                                        color: f['floorType'] == 'Ground Floor' ? Colors.green : Colors.blue,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          f['floorType'],
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${_formatNum(f['width'])} × ${_formatNum(f['height'])}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${_formatNum(f['area'])} sqft',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        // Total area row
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Built-up Area',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${totalArea.toStringAsFixed(2)} sqft',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Category & Rate Section
                        _sectionTitle('Cost Calculation'),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Category'),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: category == 'A' ? Colors.amber : Colors.blue,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      'Category $category ${category == 'A' ? '(Premium)' : '(Standard)'}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Rate per sqft'),
                                  Text(
                                    '₹${ratePerSqft.toInt()}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Calculation'),
                                  Text(
                                    '${totalArea.toStringAsFixed(2)} sqft × ₹${ratePerSqft.toInt()}',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Final Amount
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade400, Colors.green.shade600],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'TOTAL ESTIMATED COST',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹ ${_formatCurrency(totalEstimate)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '(${_numberToWords(totalEstimate.toInt())})',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Disclaimer
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This is an estimated cost. Actual cost may vary based on site conditions and material prices.',
                                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Generated by Estimate Pro',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareEstimate(context),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadPDF(context),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Download PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Create New Estimate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                icon: const Icon(Icons.add),
                label: const Text('Create New Estimate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.grey),
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

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatNum(dynamic num) {
    if (num is double) {
      return num.toStringAsFixed(num.truncateToDouble() == num ? 0 : 2);
    }
    return num.toString();
  }

  String _formatCurrency(double amount) {
    // Indian number format
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Crore';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} Lakh';
    }
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{2})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _numberToWords(int number) {
    if (number >= 10000000) {
      final crores = number ~/ 10000000;
      final lakhs = (number % 10000000) ~/ 100000;
      if (lakhs > 0) {
        return 'Rupees $crores Crore $lakhs Lakh Only';
      }
      return 'Rupees $crores Crore Only';
    } else if (number >= 100000) {
      final lakhs = number ~/ 100000;
      final thousands = (number % 100000) ~/ 1000;
      if (thousands > 0) {
        return 'Rupees $lakhs Lakh $thousands Thousand Only';
      }
      return 'Rupees $lakhs Lakh Only';
    } else if (number >= 1000) {
      return 'Rupees ${number ~/ 1000} Thousand Only';
    }
    return 'Rupees $number Only';
  }

  void _shareEstimate(BuildContext context) {
    // Share functionality - placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality - Coming Soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _downloadPDF(BuildContext context) {
    // PDF download - placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF Download - Coming Soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
