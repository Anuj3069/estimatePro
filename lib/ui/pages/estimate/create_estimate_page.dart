// // lib/ui/pages/estimate/create_estimate_page.dart

// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:url_launcher/url_launcher.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:share_plus/share_plus.dart';
// import '../../../providers/auth_provider.dart';
// import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
// import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
// import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
// import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';

// /// Floor data model
// class FloorData {
//   String floorType;
//   String floorKey;
//   double builtUpArea;
//   TextEditingController areaCtrl;
//   String? errorMessage;

//   FloorData({
//     required this.floorType,
//     required this.floorKey,
//     this.builtUpArea = 0,
//   }) : areaCtrl = TextEditingController();

//   void dispose() {
//     areaCtrl.dispose();
//   }
// }

// /// Main Create Estimate Page
// class CreateEstimatePage extends StatefulWidget {
//   const CreateEstimatePage({super.key});

//   @override
//   State<CreateEstimatePage> createState() => _CreateEstimatePageState();
// }

// class _CreateEstimatePageState extends State<CreateEstimatePage> {
//   // 4 Steps: Property → Owner → Review → Generate & Pay
//   int _currentStep = 0;

//   // Property dimensions
//   final _lengthCtrl = TextEditingController();
//   final _widthCtrl = TextEditingController();

//   // Floor data
//   final List<FloorData> _floors = [];

//   final List<Map<String, String>> _floorOptions = [
//     {'type': 'Ground Floor', 'key': 'groundFloor'},
//     {'type': '1st Floor', 'key': 'firstFloor'},
//     {'type': '2nd Floor', 'key': 'secondFloor'},
//     {'type': '3rd Floor', 'key': 'thirdFloor'},
//     {'type': '4th Floor', 'key': 'fourthFloor'},
//   ];

//   // Owner data
//   final _ownerNameCtrl = TextEditingController();
//   final _ownerAddressCtrl = TextEditingController();
//   final _ownerPhoneCtrl = TextEditingController();

//   // Total Amount field
//   final _totalAmountCtrl = TextEditingController();

//   // Category only (no interior work)
//   String _selectedCategory = 'A';

//   // Form keys
//   final _propertyFormKey = GlobalKey<FormState>();
//   final _ownerFormKey = GlobalKey<FormState>();

//   // API States
//   bool _isGenerating = false;
//   bool _isDownloading = false;
//   bool _isPaymentProcessing = false;
//   String? _estimateId;
//   String? _generateError;

//   // Payment States
//   bool _paymentSuccess = false;
//   String? _paymentId;
//   String? _paymentError;
//   String? _orderId;
//   String? _paymentSessionId;

//   // Auth token (kept for future use if needed)
//   String? _authToken;

//   // Payment amount
//   static const int _basePaymentAmount = 500;

//   @override
//   void initState() {
//     super.initState();
//     _addFloor(0);
//     _loadAuthToken();
//     _initCashfree();
//   }

//   Future<void> _loadAuthToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     _authToken = prefs.getString("auth_token");
//         'Loaded auth token: ${_authToken != null ? "Found" : "Not found"}');
//   }

//   void _initCashfree() {
//     // Cashfree initialization - will be done when needed
//   }

//   @override
//   void dispose() {
//     _lengthCtrl.dispose();
//     _widthCtrl.dispose();
//     _totalAmountCtrl.dispose();
//     for (var floor in _floors) {
//       floor.dispose();
//     }
//     _ownerNameCtrl.dispose();
//     _ownerAddressCtrl.dispose();
//     _ownerPhoneCtrl.dispose();
//     super.dispose();
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // TOTAL AMOUNT VALIDATION
//   // ═══════════════════════════════════════════════════════════════════════
//   String? _validateTotalAmount(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Total amount is required';
//     }

//     final amount = double.tryParse(value);
//     if (amount == null) {
//       return 'Enter a valid amount';
//     }

//     // Minimum 10 lakh (1,000,000)
//     if (amount < 1000000) {
//       return 'Amount must be at least ₹10,00,000';
//     }

//     // Maximum 50 lakh (5,000,000)
//     if (amount > 5000000) {
//       return 'Amount cannot exceed ₹50,00,000';
//     }

//     return null;
//   }

//   double get _totalAmount => double.tryParse(_totalAmountCtrl.text) ?? 0;

//   // ═══════════════════════════════════════════════════════════════════════
//   // CALCULATIONS
//   // ═══════════════════════════════════════════════════════════════════════

//   // Base rate per sqft
//   double get _baseRatePerSqft => _selectedCategory == 'A' ? 2000 : 1800;

//   double get _totalArea =>
//       _floors.fold(0, (sum, floor) => sum + floor.builtUpArea);

//   // Total estimate (no interior charges)
//   double get _totalEstimate => _totalArea * _baseRatePerSqft;

//   double get _length => double.tryParse(_lengthCtrl.text) ?? 0;
//   double get _width => double.tryParse(_widthCtrl.text) ?? 0;
//   double get _maxArea => _length * _width;

//   double get _groundFloorArea {
//     final ground = _floors.where((f) => f.floorKey == 'groundFloor').toList();
//     return ground.isNotEmpty ? ground.first.builtUpArea : 0;
//   }

//   bool get _canAddMoreFloors => _floors.length < _floorOptions.length;

//   int? get _nextFloorIndex {
//     for (int i = 0; i < _floorOptions.length; i++) {
//       if (!_floors.any((f) => f.floorKey == _floorOptions[i]['key'])) {
//         return i;
//       }
//     }
//     return null;
//   }

//   void _addFloor(int index) {
//     if (index < _floorOptions.length) {
//       setState(() {
//         _floors.add(FloorData(
//           floorType: _floorOptions[index]['type']!,
//           floorKey: _floorOptions[index]['key']!,
//         ));
//       });
//     }
//   }

//   void _removeFloor(int index) {
//     if (_floors.length > 1 && _floors[index].floorKey != 'groundFloor') {
//       setState(() {
//         _floors[index].dispose();
//         _floors.removeAt(index);
//       });
//     } else {
//       _showSnackBar(
//           'Cannot Remove', 'Ground Floor is required.', Colors.orange);
//     }
//   }

//   String _getSheetType() {
//     List<String> floorKeys = [];
//     for (var option in _floorOptions) {
//       if (_floors.any((f) => f.floorKey == option['key'])) {
//         floorKeys.add(option['key']!);
//       }
//     }

//     String prefix = '';
//     for (int i = 0; i < floorKeys.length; i++) {
//       String abbr = '';
//       switch (floorKeys[i]) {
//         case 'groundFloor':
//           abbr = 'gf';
//           break;
//         case 'firstFloor':
//           abbr = 'ff';
//           break;
//         case 'secondFloor':
//           abbr = 'sf';
//           break;
//         case 'thirdFloor':
//           abbr = 'tf';
//           break;
//         case 'fourthFloor':
//           abbr = 'fof';
//           break;
//       }
//       prefix = i == 0 ? abbr : '${prefix}_$abbr';
//     }

//     return prefix; // Return just "gf" for ground floor only
//   }

//   // Get floor type for API payload
//   String _getFloorType() {
//     for (var floor in _floors) {
//       if (floor.floorKey == 'groundFloor') {
//         return 'gf';
//       }
//     }
//     return 'gf'; // Default to ground floor
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // PHONE VALIDATION
//   // ═══════════════════════════════════════════════════════════════════════
//   String? _validatePhone(String? value) {
//     if (value == null || value.isEmpty) {
//       return null; // Phone is optional
//     }

//     // Remove any spaces or dashes
//     final phone = value.replaceAll(RegExp(r'[\s-]'), '');

//     if (phone.length != 10) {
//       return 'Enter 10 digit mobile number';
//     }

//     // Indian mobile numbers start with 6, 7, 8, or 9
//     if (!RegExp(r'^[6-9]').hasMatch(phone)) {
//       return 'Invalid mobile number (should start with 6-9)';
//     }

//     if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
//       return 'Only digits allowed';
//     }

//     return null;
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // UI HELPERS
//   // ═══════════════════════════════════════════════════════════════════════
//   void _showSnackBar(String title, String message, Color color) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).hideCurrentSnackBar();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(
//               color == Colors.green
//                   ? Icons.check_circle
//                   : color == Colors.red
//                       ? Icons.error
//                       : Icons.warning,
//               color: Colors.white,
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title,
//                       style: const TextStyle(fontWeight: FontWeight.bold)),
//                   Text(message, style: const TextStyle(fontSize: 12)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _showErrorDialog(String title, String message, List<String> errors) {
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                   color: Colors.red.shade100, shape: BoxShape.circle),
//               child: Icon(Icons.error_outline, color: Colors.red.shade700),
//             ),
//             const SizedBox(width: 12),
//             Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(message),
//             if (errors.isNotEmpty) ...[
//               const SizedBox(height: 16),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.red.shade50,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.red.shade200),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: errors
//                       .map((e) => Padding(
//                             padding: const EdgeInsets.only(bottom: 4),
//                             child: Row(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 const Text('• ',
//                                     style: TextStyle(color: Colors.red)),
//                                 Expanded(
//                                     child: Text(e,
//                                         style: TextStyle(
//                                             color: Colors.red.shade700,
//                                             fontSize: 13))),
//                               ],
//                             ),
//                           ))
//                       .toList(),
//                 ),
//               ),
//             ],
//           ],
//         ),
//         actions: [
//           ElevatedButton(
//             onPressed: () => Navigator.pop(ctx),
//             style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red, foregroundColor: Colors.white),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   List<String> _validatePropertyStep() {
//     List<String> errors = [];

//     if (_lengthCtrl.text.isEmpty || _length <= 0) {
//       errors.add('Enter valid length');
//     }
//     if (_widthCtrl.text.isEmpty || _width <= 0) {
//       errors.add('Enter valid width');
//     }

//     if (_floors.isEmpty) {
//       errors.add('At least Ground Floor is required');
//       return errors;
//     }

//     for (var floor in _floors) {
//       if (floor.areaCtrl.text.isEmpty || floor.builtUpArea <= 0) {
//         errors.add('${floor.floorType}: Built-up area is required');
//       } else {
//         if (_maxArea > 0 && floor.builtUpArea > _maxArea) {
//           errors.add(
//               '${floor.floorType}: Area cannot exceed ${_maxArea.toStringAsFixed(0)} sqft');
//         }
//         if (floor.floorKey != 'groundFloor' &&
//             _groundFloorArea > 0 &&
//             floor.builtUpArea > _groundFloorArea) {
//           errors.add('${floor.floorType}: Cannot exceed Ground Floor');
//         }
//       }
//     }

//     return errors;
//   }

//   List<String> _validateOwnerStep() {
//     List<String> errors = [];

//     if (_ownerNameCtrl.text.trim().length < 3) {
//       errors.add('Enter valid name (min 3 characters)');
//     }

//     final phoneError = _validatePhone(_ownerPhoneCtrl.text);
//     if (_ownerPhoneCtrl.text.isNotEmpty && phoneError != null) {
//       errors.add(phoneError);
//     }

//     if (_ownerAddressCtrl.text.trim().length < 10) {
//       errors.add('Enter complete address (min 10 characters)');
//     }

//     // Validate total amount
//     final amountError = _validateTotalAmount(_totalAmountCtrl.text);
//     if (amountError != null) {
//       errors.add(amountError);
//     }

//     return errors;
//   }

//   void _goToNextStep() {
//     if (_currentStep == 0) {
//       final errors = _validatePropertyStep();
//       if (errors.isNotEmpty) {
//         _showErrorDialog('Validation Error', 'Please fix:', errors);
//         return;
//       }
//       if (!(_propertyFormKey.currentState?.validate() ?? false)) return;
//       setState(() => _currentStep = 1);
//     } else if (_currentStep == 1) {
//       final errors = _validateOwnerStep();
//       if (errors.isNotEmpty) {
//         _showErrorDialog('Validation Error', 'Please fix:', errors);
//         return;
//       }
//       if (!(_ownerFormKey.currentState?.validate() ?? false)) return;
//       setState(() => _currentStep = 2);
//     } else if (_currentStep == 2) {
//       // Review step → Go to Generate & Pay
//       setState(() => _currentStep = 3);
//     }
//   }

//   void _goToPreviousStep() {
//     if (_currentStep > 0) setState(() => _currentStep--);
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // CASHFREE PAYMENT FLOW
//   // ═══════════════════════════════════════════════════════════════════════
//   Future<void> _startPayment() async {
//     if (!mounted || _estimateId == null) return;

//     setState(() {
//       _isPaymentProcessing = true;
//       _paymentError = null;
//     });

//     try {

//       // Create order with estimateId as per your API
//       final requestBody = {
//         'amount': 1, // Amount in INR
//         'currency': 'INR',
//         'estimateId': _estimateId,
//       };

//           'Request URL: https://estimate-pro-backend.onrender.com/payments/create-order');

//       final response = await http
//           .post(
//             Uri.parse(
//                 'https://estimate-pro-backend.onrender.com/payments/create-order'),
//             headers: {
//               'Content-Type': 'application/json',
//             },
//             body: jsonEncode(requestBody),
//           )
//           .timeout(const Duration(seconds: 60));


//       if (!mounted) return;

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final data = jsonDecode(response.body);
//         final paymentSessionId = data['paymentSessionId'];
//         final orderId = data['orderId'];

//         if (paymentSessionId == null || orderId == null) {
//           setState(() {
//             _paymentError = 'Invalid response: missing payment details';
//             _isPaymentProcessing = false;
//           });
//           return;
//         }

//         setState(() {
//           _paymentSessionId = paymentSessionId;
//           _orderId = orderId;
//         });


//         // Open Cashfree payment page in webview
//         // _openCashfreePayment();

//         try {
//           // Create payment session
//           var cfSession = CFSessionBuilder()
//               .setOrderId(orderId)
//               .setPaymentSessionId(paymentSessionId)
//               .setEnvironment(CFEnvironment.SANDBOX)
//               .build();

//           // Create drop checkout payment
//           var cfDropCheckoutPayment =
//               CFDropCheckoutPaymentBuilder().setSession(cfSession).build();

//           var cfPaymentGatewayService = CFPaymentGatewayService();

//           // Set up callbacks
//           cfPaymentGatewayService.setCallback((paymentResult) {
//             _verifyPayment();
//           }, (error, errorMessage) {
//           });

//           // Start payment
//           await cfPaymentGatewayService.doPayment(cfDropCheckoutPayment);
//         } catch (e) {
//         }
//       } else {
//         // Error response
//         String errorMsg = 'Server Error ${response.statusCode}';
//         try {
//           final errorData = jsonDecode(response.body);
//           errorMsg = errorData['message'] ?? errorData['error'] ?? errorMsg;
//         } catch (_) {}


//         setState(() {
//           _paymentError = errorMsg;
//           _isPaymentProcessing = false;
//         });
//       }
//     } on TimeoutException {
//       if (!mounted) return;
//       setState(() {
//         _paymentError = 'Request timeout. Server may be starting up.';
//         _isPaymentProcessing = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _paymentError = 'Error: $e';
//         _isPaymentProcessing = false;
//       });
//     }
//   }

//   Future<void> _openCashfreePayment() async {
//     if (_paymentSessionId == null) return;

//     try {
//       // Clean the payment session ID but be less aggressive
//       String cleanSessionId = _paymentSessionId!.trim();

//       // Only remove obvious duplicates, keep the core session ID intact
//       if (cleanSessionId.contains('paymentpayment')) {
//         cleanSessionId = cleanSessionId.replaceAll('paymentpayment', 'payment');
//       }

//       // Remove trailing 'payment' only if it's clearly a suffix
//       if (cleanSessionId.endsWith('payment') &&
//           cleanSessionId.length > 'payment'.length + 10) {
//         cleanSessionId = cleanSessionId.substring(
//             0, cleanSessionId.length - 'payment'.length);
//       }

//       // Final trim
//       cleanSessionId = cleanSessionId.trim();


//       // More lenient validation - check if it looks like a valid ID
//       if (cleanSessionId.isEmpty || cleanSessionId.length < 10) {
//             'ERROR: Payment session ID too short or empty: $cleanSessionId');
//         setState(() {
//           _paymentError = 'Invalid payment session ID';
//           _isPaymentProcessing = false;
//         });
//         return;
//       }

//       // Try multiple possible URL formats for Cashfree
//       final urls = [
//         'https://payments.cashfree.com/links/$cleanSessionId',
//         'https://payments.cashfree.com/order/$cleanSessionId',
//         'https://payments.cashfree.com/checkout/$cleanSessionId',
//       ];

//       bool launched = false;

//       for (final url in urls) {
//         try {
//           final uri = Uri.parse(url);
//           final canLaunch = await canLaunchUrl(uri);


//           if (canLaunch) {
//             await launchUrl(
//               uri,
//               mode: LaunchMode.externalApplication,
//             );
//             launched = true;
//             break;
//           }
//         } catch (e) {
//           continue;
//         }
//       }

//       if (!mounted) return;

//       if (launched) {
//         // Show dialog to check payment status
//         _showPaymentVerificationDialog();
//       } else {
//         setState(() {
//           _paymentError =
//               'Could not launch payment page. Please check your session ID: $cleanSessionId';
//           _isPaymentProcessing = false;
//         });
//             'ERROR: Failed to launch any payment URL for session ID: $cleanSessionId');
//       }
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _paymentError = 'Error launching payment: $e';
//         _isPaymentProcessing = false;
//       });
//     }
//   }

//   void _showPaymentVerificationDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Payment in Progress'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const CircularProgressIndicator(),
//             const SizedBox(height: 16),
//             const Text('Please complete the payment in the browser.'),
//             const SizedBox(height: 8),
//             Text('Order ID: ${_orderId ?? ''}'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(ctx);
//               _verifyPayment();
//             },
//             child: const Text('I Have Paid'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _verifyPayment() async {
//     if (_orderId == null) return;

//     setState(() {
//       _isPaymentProcessing = true;
//     });

//     try {

//       final response = await http.get(
//         Uri.parse(
//             'https://estimate-pro-backend.onrender.com/payments/verify/$_orderId'),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//       ).timeout(const Duration(seconds: 30));


//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         // Check for payment success based on actual API response structure
//         bool isPaymentSuccessful = false;

//         if (data['payment_status'] == 'SUCCESS' ||
//             data['success'] == true ||
//             data['status'] == 'success') {
//           isPaymentSuccessful = true;
//         }

//         if (isPaymentSuccessful) {
//           setState(() {
//             _paymentSuccess = true;
//             _paymentError = null;
//             _isPaymentProcessing = false;
//           });

//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content:
//                     Text('✓ Payment Successful! You can now download PDF.'),
//                 backgroundColor: Colors.green,
//                 behavior: SnackBarBehavior.floating,
//                 duration: Duration(seconds: 3),
//               ),
//             );
//           }
//         } else {
//           setState(() {
//             _paymentError = 'Payment verification failed. Please try again.';
//             _isPaymentProcessing = false;
//           });
//         }
//       } else {
//         setState(() {
//           _paymentError =
//               'Payment verification failed. Please contact support.';
//           _isPaymentProcessing = false;
//         });
//       }
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _paymentError = 'Error verifying payment: $e';
//         _isPaymentProcessing = false;
//       });
//     }
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // GENERATE ESTIMATE
//   // ═══════════════════════════════════════════════════════════════════════
//   Future<void> _generateEstimate() async {
//     if (!mounted) return;

//     setState(() {
//       _isGenerating = true;
//       _generateError = null;
//       _estimateId = null;
//       _paymentSuccess = false;
//       _paymentId = null;
//     });

//     try {
//       Map<String, dynamic> dimensions = {'length': _length, 'width': _width};
//       for (var floor in _floors) {
//         dimensions[floor.floorKey] = floor.builtUpArea;
//       }

//       final body = {
//         'dimensions': dimensions,
//         'ownerDetais': {
//           'name': _ownerNameCtrl.text.trim(),
//           'address': _ownerAddressCtrl.text.trim(),
//         },
//         'sheetType': _getSheetType(),
//         'floorType': _getFloorType(),
//         'totalArea': _totalArea,
//         'totalAmount': _totalAmount,
//       };


//       if (!mounted) return;
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);

//       final response = await http
//           .post(
//             Uri.parse(
//                 'https://estimate-pro-backend.onrender.com/estimate/generate'),
//             headers: {
//               'Content-Type': 'application/json',
//               if (authProvider.userId != null) 'userId': authProvider.userId!,
//               if (authProvider.token != null)
//                 'Authorization': 'Bearer ${authProvider.token}',
//             },
//             body: jsonEncode(body),
//           )
//           .timeout(const Duration(seconds: 120));


//       if (!mounted) return;

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           _estimateId = data['estimateId'];
//           _isGenerating = false;
//           _generateError = null;
//         });

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('✓ Estimate generated! Now pay to download.'),
//               backgroundColor: Colors.green,
//               behavior: SnackBarBehavior.floating,
//             ),
//           );
//         }
//       } else {
//         String errorMsg = 'Failed (${response.statusCode})';
//         try {
//           final data = jsonDecode(response.body);
//           errorMsg = data['message'] ?? data['error'] ?? errorMsg;
//         } catch (_) {}

//         setState(() {
//           _generateError = errorMsg;
//           _isGenerating = false;
//         });
//       }
//     } on TimeoutException {
//       if (!mounted) return;
//       setState(() {
//         _generateError = 'Timeout. Server may be starting. Try again.';
//         _isGenerating = false;
//       });
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         _generateError = 'Error: $e';
//         _isGenerating = false;
//       });
//     }
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // DOWNLOAD PDF
//   // ═══════════════════════════════════════════════════════════════════════
//   Future<void> _downloadPDF() async {
//     if (!mounted) return;

//     if (_estimateId == null) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text('Please generate estimate first'),
//               backgroundColor: Colors.orange),
//         );
//       }
//       return;
//     }

//     setState(() {
//       _isDownloading = true;
//     });

//     try {
//       final url =
//           'https://estimate-pro-backend.onrender.com/estimate/generate/download/$_estimateId';

//       if (!mounted) return;
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);

//       // Download PDF with Authorization header

//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           if (authProvider.userId != null) 'userid': authProvider.userId!,
//           if (authProvider.token != null)
//             'Authorization': 'Bearer ${authProvider.token}',
//         },
//       ).timeout(const Duration(seconds: 60));

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         // Get temporary directory
//         final tempDir = await getTemporaryDirectory();
//         final fileName = 'estimate_$_estimateId.pdf';
//         final filePath = '${tempDir.path}/$fileName';

//         // Save PDF to file
//         final file = File(filePath);
//         await file.writeAsBytes(response.bodyBytes);


//         // Open the PDF file
//         final fileUri = Uri.file(filePath);
//         final canLaunch = await canLaunchUrl(fileUri);

//         if (!mounted) return;

//         if (canLaunch) {
//           try {
//             await launchUrl(fileUri, mode: LaunchMode.externalApplication);

//             if (mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('PDF downloaded and opened!'),
//                   backgroundColor: Colors.green,
//                 ),
//               );
//             }
//           } catch (e) {
//             if (mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('Could not open PDF: $e'),
//                   backgroundColor: Colors.orange,
//                 ),
//               );
//             }
//           }
//         } else {
//           // Fallback: try to share the file using share_plus
//           try {
//             await Share.shareXFiles([XFile(filePath)], text: 'PDF Estimate');
//             if (mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('PDF shared successfully'),
//                   backgroundColor: Colors.green,
//                 ),
//               );
//             }
//           } catch (e) {
//             if (mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('PDF saved to: $filePath'),
//                   backgroundColor: Colors.blue,
//                   duration: const Duration(seconds: 5),
//                 ),
//               );
//             }
//           }
//         }

//         if (mounted) {
//           setState(() {
//             _isDownloading = false;
//           });
//         }
//       } else {
//             'Download failed: ${response.statusCode} - ${response.body}');
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Download failed: ${response.statusCode}'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//         if (mounted) {
//           setState(() {
//             _isDownloading = false;
//           });
//         }
//       }
//     } catch (e) {
//       if (!mounted) return;

//       // Store context reference to prevent race condition
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Download error: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       if (mounted) {
//         setState(() {
//           _isDownloading = false;
//         });
//       }
//     }
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // FORMAT NUMBER
//   // ═══════════════════════════════════════════════════════════════════════
//   String _formatNumber(double number) {
//     return number.toStringAsFixed(0).replaceAllMapped(
//           RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
//           (Match m) => '${m[1]},',
//         );
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // BUILD UI
//   // ═══════════════════════════════════════════════════════════════════════
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Create Estimate'), elevation: 0),
//       body: Column(
//         children: [
//           _buildStepIndicator(),
//           Expanded(child: _buildCurrentStep()),
//           _buildBottomNav(),
//         ],
//       ),
//     );
//   }

//   Widget _buildCurrentStep() {
//     switch (_currentStep) {
//       case 0:
//         return _buildPropertyStep();
//       case 1:
//         return _buildOwnerStep();
//       case 2:
//         return _buildReviewStep();
//       case 3:
//         return _buildPaymentStep();
//       default:
//         return _buildPropertyStep();
//     }
//   }

//   Widget _buildStepIndicator() {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//       color: Colors.grey.shade100,
//       child: Row(
//         children: [
//           _stepCircle(0, 'Property'),
//           _stepLine(0),
//           _stepCircle(1, 'Owner'),
//           _stepLine(1),
//           _stepCircle(2, 'Review'),
//           _stepLine(2),
//           _stepCircle(3, 'Pay'),
//         ],
//       ),
//     );
//   }

//   Widget _stepCircle(int step, String label) {
//     final isActive = _currentStep >= step;
//     final isCurrent = _currentStep == step;
//     return Expanded(
//       child: Column(
//         children: [
//           Container(
//             width: 28,
//             height: 28,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: isActive ? Colors.green : Colors.grey.shade300,
//               border:
//                   isCurrent ? Border.all(color: Colors.blue, width: 2) : null,
//             ),
//             child: Center(
//               child: isActive && !isCurrent
//                   ? const Icon(Icons.check, color: Colors.white, size: 16)
//                   : Text('${step + 1}',
//                       style: TextStyle(
//                           color: isActive ? Colors.white : Colors.grey,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 12)),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(label,
//               style: TextStyle(
//                   fontSize: 10,
//                   color: isActive ? Colors.black : Colors.grey,
//                   fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
//         ],
//       ),
//     );
//   }

//   Widget _stepLine(int afterStep) {
//     final isActive = _currentStep > afterStep;
//     return Container(
//         width: 20,
//         height: 2,
//         color: isActive ? Colors.green : Colors.grey.shade300,
//         margin: const EdgeInsets.only(bottom: 16));
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // STEP 1: PROPERTY
//   // ═══════════════════════════════════════════════════════════════════════
//   Widget _buildPropertyStep() {
//     return Form(
//       key: _propertyFormKey,
//       child: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           // Dimensions Card
//           Card(
//             elevation: 2,
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                             color: Colors.purple.shade100,
//                             borderRadius: BorderRadius.circular(8)),
//                         child: Icon(Icons.straighten,
//                             color: Colors.purple.shade700, size: 20),
//                       ),
//                       const SizedBox(width: 12),
//                       const Text('Property Dimensions',
//                           style: TextStyle(
//                               fontSize: 16, fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextFormField(
//                           controller: _lengthCtrl,
//                           keyboardType: const TextInputType.numberWithOptions(
//                               decimal: true),
//                           inputFormatters: [
//                             FilteringTextInputFormatter.allow(
//                                 RegExp(r'^\d*\.?\d*'))
//                           ],
//                           decoration: const InputDecoration(
//                               labelText: 'Length (ft) *',
//                               border: OutlineInputBorder()),
//                           validator: (v) => (v == null ||
//                                   v.isEmpty ||
//                                   (double.tryParse(v) ?? 0) <= 0)
//                               ? 'Required'
//                               : null,
//                           onChanged: (_) => setState(() {}),
//                         ),
//                       ),
//                       const Padding(
//                           padding: EdgeInsets.symmetric(horizontal: 12),
//                           child: Text('×', style: TextStyle(fontSize: 20))),
//                       Expanded(
//                         child: TextFormField(
//                           controller: _widthCtrl,
//                           keyboardType: const TextInputType.numberWithOptions(
//                               decimal: true),
//                           inputFormatters: [
//                             FilteringTextInputFormatter.allow(
//                                 RegExp(r'^\d*\.?\d*'))
//                           ],
//                           decoration: const InputDecoration(
//                               labelText: 'Width (ft) *',
//                               border: OutlineInputBorder()),
//                           validator: (v) => (v == null ||
//                                   v.isEmpty ||
//                                   (double.tryParse(v) ?? 0) <= 0)
//                               ? 'Required'
//                               : null,
//                           onChanged: (_) => setState(() {}),
//                         ),
//                       ),
//                     ],
//                   ),
//                   if (_maxArea > 0) ...[
//                     const SizedBox(height: 12),
//                     Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                           color: Colors.blue.shade50,
//                           borderRadius: BorderRadius.circular(8)),
//                       child: Row(
//                         children: [
//                           Icon(Icons.info_outline,
//                               color: Colors.blue.shade700, size: 18),
//                           const SizedBox(width: 8),
//                           Text('Max Area: ${_maxArea.toStringAsFixed(0)} sqft',
//                               style: TextStyle(
//                                   color: Colors.blue.shade700,
//                                   fontWeight: FontWeight.w500)),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text('Floor-wise Built-up Area',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//               if (_canAddMoreFloors && _nextFloorIndex != null)
//                 TextButton.icon(
//                   onPressed: () => _addFloor(_nextFloorIndex!),
//                   icon: const Icon(Icons.add, size: 18),
//                   label: const Text('Add Floor'),
//                   style: TextButton.styleFrom(foregroundColor: Colors.green),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           ..._floors
//               .asMap()
//               .entries
//               .map((e) => _buildFloorCard(e.value, e.key)),
//           if (_totalArea > 0) ...[
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                   color: Colors.green.shade50,
//                   borderRadius: BorderRadius.circular(8)),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text('Total Built-up Area',
//                       style: TextStyle(fontWeight: FontWeight.w600)),
//                   Text('${_totalArea.toStringAsFixed(0)} sqft',
//                       style: const TextStyle(
//                           fontWeight: FontWeight.bold, color: Colors.green)),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildFloorCard(FloorData floor, int index) {
//     final isGround = floor.floorKey == 'groundFloor';
//     return Card(
//       margin: const EdgeInsets.only(bottom: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                   color:
//                       isGround ? Colors.green.shade100 : Colors.blue.shade100,
//                   borderRadius: BorderRadius.circular(8)),
//               child: Icon(isGround ? Icons.home : Icons.layers,
//                   color: isGround ? Colors.green : Colors.blue, size: 20),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(floor.floorType,
//                       style: const TextStyle(fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 8),
//                   TextFormField(
//                     controller: floor.areaCtrl,
//                     keyboardType:
//                         const TextInputType.numberWithOptions(decimal: true),
//                     inputFormatters: [
//                       FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
//                     ],
//                     decoration: InputDecoration(
//                       labelText: 'Built-up Area *',
//                       suffixText: 'sqft',
//                       border: const OutlineInputBorder(),
//                       isDense: true,
//                       helperText: isGround
//                           ? (_maxArea > 0
//                               ? 'Max: ${_maxArea.toStringAsFixed(0)}'
//                               : null)
//                           : (_groundFloorArea > 0
//                               ? 'Max: ${_groundFloorArea.toStringAsFixed(0)}'
//                               : null),
//                       helperStyle: TextStyle(color: Colors.orange.shade700),
//                     ),
//                     onChanged: (v) => setState(
//                         () => floor.builtUpArea = double.tryParse(v) ?? 0),
//                   ),
//                 ],
//               ),
//             ),
//             if (!isGround)
//               IconButton(
//                   onPressed: () => _removeFloor(index),
//                   icon: const Icon(Icons.close, color: Colors.red, size: 20)),
//           ],
//         ),
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // STEP 2: OWNER
//   // ═══════════════════════════════════════════════════════════════════════
//   Widget _buildOwnerStep() {
//     return Form(
//       key: _ownerFormKey,
//       child: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           const Text('Owner Details',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 16),
//           TextFormField(
//             controller: _ownerNameCtrl,
//             textCapitalization: TextCapitalization.words,
//             decoration: const InputDecoration(
//               labelText: 'Owner Name *',
//               hintText: 'e.g., Mr. Sufiyan Khan S/o Mr. Riyaz Khan',
//               prefixIcon: Icon(Icons.person_outline),
//               border: OutlineInputBorder(),
//             ),
//             validator: (v) => (v == null || v.trim().length < 3)
//                 ? 'Enter valid name (min 3 chars)'
//                 : null,
//           ),
//           const SizedBox(height: 16),
//           TextFormField(
//             controller: _ownerPhoneCtrl,
//             keyboardType: TextInputType.phone,
//             inputFormatters: [
//               FilteringTextInputFormatter.digitsOnly,
//               LengthLimitingTextInputFormatter(10),
//             ],
//             decoration: const InputDecoration(
//               labelText: 'Mobile Number',
//               hintText: '9876543210',
//               prefixIcon: Icon(Icons.phone_outlined),
//               prefixText: '+91 ',
//               border: OutlineInputBorder(),
//               helperText: '10 digit Indian mobile number (starts with 6-9)',
//             ),
//             validator: _validatePhone,
//           ),
//           const SizedBox(height: 16),
//           TextFormField(
//             controller: _ownerAddressCtrl,
//             maxLines: 3,
//             textCapitalization: TextCapitalization.sentences,
//             decoration: const InputDecoration(
//               labelText: 'Property Address *',
//               hintText:
//                   'Plot No., Kh. No., Ward, Colony, City, District, State',
//               prefixIcon: Padding(
//                   padding: EdgeInsets.only(bottom: 50),
//                   child: Icon(Icons.location_on_outlined)),
//               border: OutlineInputBorder(),
//               alignLabelWithHint: true,
//             ),
//             validator: (v) => (v == null || v.trim().length < 10)
//                 ? 'Enter complete address'
//                 : null,
//           ),
//           const SizedBox(height: 24),

//           // Total Amount Field
//           Card(
//             elevation: 2,
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                             color: Colors.green.shade100,
//                             borderRadius: BorderRadius.circular(8)),
//                         child: Icon(Icons.currency_rupee,
//                             color: Colors.green.shade700, size: 20),
//                       ),
//                       const SizedBox(width: 12),
//                       const Text('Total Amount',
//                           style: TextStyle(
//                               fontSize: 16, fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   TextFormField(
//                     controller: _totalAmountCtrl,
//                     keyboardType:
//                         const TextInputType.numberWithOptions(decimal: true),
//                     inputFormatters: [
//                       FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
//                     ],
//                     decoration: const InputDecoration(
//                       labelText: 'Total Amount *',
//                       hintText: 'Enter amount between ₹10,00,000 - ₹50,00,000',
//                       prefixIcon: Icon(Icons.currency_rupee_outlined),
//                       prefixText: '₹ ',
//                       border: OutlineInputBorder(),
//                       helperText: 'Minimum: ₹10,00,000 | Maximum: ₹50,00,000',
//                       helperStyle: TextStyle(color: Colors.green),
//                     ),
//                     validator: _validateTotalAmount,
//                     onChanged: (_) => setState(() {}),
//                   ),
//                   if (_totalAmount > 0) ...[
//                     const SizedBox(height: 12),
//                     Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color:
//                             _totalAmount >= 1000000 && _totalAmount <= 5000000
//                                 ? Colors.green.shade50
//                                 : Colors.red.shade50,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(
//                           color:
//                               _totalAmount >= 1000000 && _totalAmount <= 5000000
//                                   ? Colors.green.shade200
//                                   : Colors.red.shade200,
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             _totalAmount >= 1000000 && _totalAmount <= 5000000
//                                 ? Icons.check_circle_outline
//                                 : Icons.error_outline,
//                             color: _totalAmount >= 1000000 &&
//                                     _totalAmount <= 5000000
//                                 ? Colors.green.shade700
//                                 : Colors.red.shade700,
//                             size: 18,
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               _totalAmount >= 1000000 && _totalAmount <= 5000000
//                                   ? 'Valid amount: ₹${_formatNumber(_totalAmount)}'
//                                   : 'Amount must be between ₹10,00,000 - ₹50,00,000',
//                               style: TextStyle(
//                                 color: _totalAmount >= 1000000 &&
//                                         _totalAmount <= 5000000
//                                     ? Colors.green.shade700
//                                     : Colors.red.shade700,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // STEP 3: REVIEW
//   // ═══════════════════════════════════════════════════════════════════════
//   Widget _buildReviewStep() {
//     return ListView(
//       padding: const EdgeInsets.all(16),
//       children: [
//         const Text('Review Your Estimate',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//         const SizedBox(height: 16),

//         // Property Details Card
//         _buildReviewCard(
//           'Property Details',
//           Icons.home_work,
//           Colors.purple,
//           [
//             _reviewRow('Dimensions',
//                 '${_length.toStringAsFixed(0)} × ${_width.toStringAsFixed(0)} ft'),
//             _reviewRow('Plot Area', '${_maxArea.toStringAsFixed(0)} sqft'),
//             const Divider(),
//             ..._floors.map((f) => _reviewRow(
//                 f.floorType, '${f.builtUpArea.toStringAsFixed(0)} sqft')),
//             const Divider(),
//             _reviewRow(
//                 'Total Built-up', '${_totalArea.toStringAsFixed(0)} sqft',
//                 isBold: true, color: Colors.green),
//           ],
//         ),

//         const SizedBox(height: 12),

//         // Owner Details Card
//         _buildReviewCard(
//           'Owner Details',
//           Icons.person,
//           Colors.blue,
//           [
//             _reviewRow('Name', _ownerNameCtrl.text.trim()),
//             if (_ownerPhoneCtrl.text.isNotEmpty)
//               _reviewRow('Mobile', '+91 ${_ownerPhoneCtrl.text.trim()}'),
//             _reviewRow('Address', _ownerAddressCtrl.text.trim()),
//           ],
//         ),

//         const SizedBox(height: 12),

//         // Total Amount Card
//         _buildReviewCard(
//           'Total Amount',
//           Icons.currency_rupee,
//           Colors.green,
//           [
//             _reviewRow('Amount', '₹${_formatNumber(_totalAmount)}',
//                 isBold: true, color: Colors.green),
//           ],
//         ),

//         const SizedBox(height: 16),

//         // Category Selection
//         const Text('Select Category',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//         const SizedBox(height: 12),
//         _buildCategoryCard(
//           'A',
//           'Premium Construction',
//           '₹1,800/sqft',
//           'High-quality materials\nPremium finishes & fittings\nBetter structural design',
//           Colors.amber,
//           Icons.star,
//         ),
//         const SizedBox(height: 10),
//         _buildCategoryCard(
//           'B',
//           'Standard Construction',
//           '₹1,500/sqft',
//           'Good quality materials\nStandard finishes\nCost-effective option',
//           Colors.blue,
//           Icons.apartment,
//         ),

//         const SizedBox(height: 16),

//         const SizedBox(height: 20),

//         // Cost Breakdown
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//                 colors: [Colors.green.shade400, Colors.green.shade600]),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Column(
//             children: [
//               const Text('Cost Breakdown',
//                   style: TextStyle(color: Colors.white70, fontSize: 14)),
//               const SizedBox(height: 12),
//               _costRow(
//                   'Base Cost (${_totalArea.toStringAsFixed(0)} sqft × ₹${_baseRatePerSqft.toInt()})',
//                   _totalEstimate),
//               const Divider(color: Colors.white30, height: 24),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text('Total Estimate',
//                       style: TextStyle(color: Colors.white, fontSize: 16)),
//                   Text('₹ ${_formatNumber(_totalEstimate)}',
//                       style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold)),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _costRow(String label, double amount) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(label,
//             style: const TextStyle(color: Colors.white70, fontSize: 13)),
//         Text('₹ ${_formatNumber(amount)}',
//             style: const TextStyle(
//                 color: Colors.white, fontWeight: FontWeight.w500)),
//       ],
//     );
//   }

//   Widget _buildReviewCard(
//       String title, IconData icon, Color color, List<Widget> children) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                       color: color.withValues(alpha: 0.1),
//                       borderRadius: BorderRadius.circular(8)),
//                   child: Icon(icon, color: color, size: 20),
//                 ),
//                 const SizedBox(width: 12),
//                 Text(title,
//                     style: const TextStyle(
//                         fontSize: 16, fontWeight: FontWeight.bold)),
//               ],
//             ),
//             const SizedBox(height: 12),
//             ...children,
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _reviewRow(String label, String value,
//       {bool isBold = false, Color? color}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: TextStyle(color: Colors.grey.shade600)),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Text(
//               value,
//               textAlign: TextAlign.right,
//               style: TextStyle(
//                   fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
//                   color: color),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCategoryCard(String cat, String title, String rate,
//       String description, Color color, IconData icon) {
//     final isSelected = _selectedCategory == cat;
//     return GestureDetector(
//       onTap: () => setState(() => _selectedCategory = cat),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//               color: isSelected ? color : Colors.grey.shade300,
//               width: isSelected ? 2 : 1),
//         ),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                   color: color.withValues(alpha: 0.2),
//                   borderRadius: BorderRadius.circular(10)),
//               child: Icon(icon, color: color, size: 24),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title,
//                       style: const TextStyle(
//                           fontWeight: FontWeight.bold, fontSize: 15)),
//                   const SizedBox(height: 4),
//                   Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                     decoration: BoxDecoration(
//                         color: color, borderRadius: BorderRadius.circular(12)),
//                     child: Text(rate,
//                         style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 11)),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(description,
//                       style: TextStyle(
//                           fontSize: 11,
//                           color: Colors.grey.shade600,
//                           height: 1.3)),
//                 ],
//               ),
//             ),
//             Container(
//               width: 20,
//               height: 20,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(
//                   color: isSelected ? color : Colors.grey.shade400,
//                   width: 2,
//                 ),
//                 color: isSelected ? color : Colors.transparent,
//               ),
//               child: isSelected
//                   ? Icon(
//                       Icons.check,
//                       size: 14,
//                       color: Colors.white,
//                     )
//                   : null,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // STEP 4: PAYMENT
//   // ═══════════════════════════════════════════════════════════════════════
//   Widget _buildPaymentStep() {
//     return ListView(
//       padding: const EdgeInsets.all(16),
//       children: [
//         const Text('Generate & Pay',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//         const SizedBox(height: 16),

//         // Generate Button
//         if (_estimateId == null) ...[
//           Container(
//             width: double.infinity,
//             height: 50,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                   colors: [Colors.blue.shade400, Colors.blue.shade600]),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: ElevatedButton(
//               onPressed: _isGenerating ? null : _generateEstimate,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.transparent,
//                 shadowColor: Colors.transparent,
//                 foregroundColor: Colors.white,
//               ),
//               child: _isGenerating
//                   ? const Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor:
//                                   AlwaysStoppedAnimation<Color>(Colors.white)),
//                         ),
//                         SizedBox(width: 12),
//                         Text('Generating...'),
//                       ],
//                     )
//                   : const Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.description),
//                         SizedBox(width: 8),
//                         Text('Generate Estimate',
//                             style: TextStyle(fontSize: 16)),
//                       ],
//                     ),
//             ),
//           ),
//           if (_generateError != null) ...[
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade50,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.red.shade200),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.error_outline,
//                       color: Colors.red.shade700, size: 20),
//                   const SizedBox(width: 8),
//                   Expanded(
//                       child: Text(_generateError!,
//                           style: TextStyle(color: Colors.red.shade700))),
//                 ],
//               ),
//             ),
//           ],
//         ],

//         // Payment Section
//         if (_estimateId != null) ...[
//           const SizedBox(height: 20),
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.green.shade50,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.green.shade200),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.check_circle,
//                     color: Colors.green.shade700, size: 24),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Estimate Generated!',
//                           style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green.shade700)),
//                       const SizedBox(height: 4),
//                       Text('Estimate ID: $_estimateId',
//                           style: const TextStyle(
//                               color: Colors.green, fontSize: 12)),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 20),
//           const Text('Payment Details',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 12),

//           const Card(
//             elevation: 2,
//             child: Padding(
//               padding: EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   const Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text('PDF Download Fee', style: TextStyle(fontSize: 16)),
//                       Text(
//                         '₹$_basePaymentAmount',
//                         style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.green),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Pay ₹$_basePaymentAmount to download your estimate PDF',
//                     style: const TextStyle(color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 20),

//           // Payment Button
//           Container(
//             width: double.infinity,
//             height: 50,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                   colors: [Colors.green.shade400, Colors.green.shade600]),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: ElevatedButton(
//               onPressed: _isPaymentProcessing || _paymentSuccess
//                   ? null
//                   : _startPayment,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.transparent,
//                 shadowColor: Colors.transparent,
//                 foregroundColor: Colors.white,
//               ),
//               child: _isPaymentProcessing
//                   ? const Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor:
//                                   AlwaysStoppedAnimation<Color>(Colors.white)),
//                         ),
//                         SizedBox(width: 12),
//                         Text('Processing...'),
//                       ],
//                     )
//                   : const Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.payment),
//                         SizedBox(width: 8),
//                         Text('Pay ₹$_basePaymentAmount',
//                             style: TextStyle(fontSize: 16)),
//                       ],
//                     ),
//             ),
//           ),

//           if (_paymentError != null) ...[
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade50,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.red.shade200),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.error_outline,
//                       color: Colors.red.shade700, size: 20),
//                   const SizedBox(width: 8),
//                   Expanded(
//                       child: Text(_paymentError!,
//                           style: TextStyle(color: Colors.red.shade700))),
//                 ],
//               ),
//             ),
//           ],

//           if (_paymentSuccess) ...[
//             const SizedBox(height: 20),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.green.shade50,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.green.shade200),
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.check_circle,
//                           color: Colors.green.shade700, size: 24),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text('Payment Successful!',
//                             style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.green.shade700)),
//                       ),
//                     ],
//                   ),
//                   if (_paymentId != null) ...[
//                     const SizedBox(height: 8),
//                     Text('Payment ID: $_paymentId',
//                         style: TextStyle(
//                             color: Colors.green.shade600, fontSize: 12)),
//                   ],
//                   const SizedBox(height: 16),
//                   Container(
//                     width: double.infinity,
//                     height: 50,
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(colors: [
//                         Colors.purple.shade400,
//                         Colors.purple.shade600
//                       ]),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: ElevatedButton(
//                       onPressed: _isDownloading ? null : _downloadPDF,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.transparent,
//                         shadowColor: Colors.transparent,
//                         foregroundColor: Colors.white,
//                       ),
//                       child: _isDownloading
//                           ? const Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 SizedBox(
//                                   width: 20,
//                                   height: 20,
//                                   child: CircularProgressIndicator(
//                                       strokeWidth: 2,
//                                       valueColor: AlwaysStoppedAnimation<Color>(
//                                           Colors.white)),
//                                 ),
//                                 SizedBox(width: 12),
//                                 Text('Downloading...'),
//                               ],
//                             )
//                           : const Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(Icons.download),
//                                 SizedBox(width: 8),
//                                 Text('Download PDF',
//                                     style: TextStyle(fontSize: 16)),
//                               ],
//                             ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ],
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // BOTTOM NAVIGATION
//   // ═══════════════════════════════════════════════════════════════════════
//   Widget _buildBottomNav() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black.withValues(alpha: 0.1),
//               blurRadius: 4,
//               offset: const Offset(0, -2))
//         ],
//       ),
//       child: Row(
//         children: [
//           if (_currentStep > 0)
//             Expanded(
//               child: ElevatedButton(
//                 onPressed: _goToPreviousStep,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.grey.shade200,
//                   foregroundColor: Colors.black,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                 ),
//                 child: const Text('Previous', style: TextStyle(fontSize: 16)),
//               ),
//             ),
//           if (_currentStep > 0) const SizedBox(width: 12),
//           Expanded(
//             child: ElevatedButton(
//               onPressed: _currentStep < 3 ? _goToNextStep : null,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12)),
//               ),
//               child: Text(_currentStep < 3 ? 'Next' : 'Complete',
//                   style: const TextStyle(fontSize: 16)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// lib/ui/pages/estimate/create_estimate_page.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart'; // ✅ Added
import '../../../providers/auth_provider.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';

/// Floor data model
class FloorData {
  String floorType;
  String floorKey;
  double builtUpArea;
  TextEditingController areaCtrl;
  String? errorMessage;

  FloorData({
    required this.floorType,
    required this.floorKey,
    this.builtUpArea = 0,
  }) : areaCtrl = TextEditingController();

  void dispose() {
    areaCtrl.dispose();
  }
}

/// Main Create Estimate Page
class CreateEstimatePage extends StatefulWidget {
  final dynamic initialOrder;

  const CreateEstimatePage({
    super.key,
    this.initialOrder,
  });

  @override
  State<CreateEstimatePage> createState() => _CreateEstimatePageState();
}

class _CreateEstimatePageState extends State<CreateEstimatePage> {
  // 4 Steps: Property → Owner → Review → Generate & Pay
  int _currentStep = 0;

  // Property dimensions
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();

  // Floor data
  static const int _maxFloorCount = 3;
  final List<FloorData> _floors = [];

  final List<Map<String, String>> _floorOptions = [
    {'type': 'Ground Floor', 'key': 'groundFloor'},
    {'type': '1st Floor', 'key': 'firstFloor'},
    {'type': '2nd Floor', 'key': 'secondFloor'},
    {'type': '3rd Floor', 'key': 'thirdFloor'},
    {'type': '4th Floor', 'key': 'fourthFloor'},
  ];

  // Owner data
  final _ownerNameCtrl = TextEditingController();
  final _ownerFirstNameCtrl = TextEditingController();
  final _ownerRelativeNameCtrl = TextEditingController();
  final _ownerSurnameCtrl = TextEditingController();
  final _ownerAddressCtrl = TextEditingController();
  final _ownerPhoneCtrl = TextEditingController();
  String _ownerRelation = 'S/o';

  // Total Amount field
  final _totalAmountCtrl = TextEditingController();

  // Category only (no interior work)
  final String _selectedCategory = 'A';

  // Form keys
  final _propertyFormKey = GlobalKey<FormState>();
  final _ownerFormKey = GlobalKey<FormState>();

  // API States
  bool _isGenerating = false;
  bool _isDownloading = false;
  bool _isPaymentProcessing = false;
  String? _estimateId;
  String? _existingEstimateId;
  String? _generateError;

  // Payment States
  bool _paymentSuccess = false;
  String? _paymentId;
  String? _paymentError;
  String? _orderId;

  // Payment amount
  static const int _basePaymentAmount = 500;

  bool get _isOrderReviewMode => widget.initialOrder != null;
  bool get _isPendingOrder =>
      widget.initialOrder?['status']?.toString().toLowerCase() == 'pending';
  bool get _canEditFields => !_isOrderReviewMode || _isPendingOrder;

  @override
  void initState() {
    super.initState();
    if (_isOrderReviewMode) {
      _prefillFromOrder(widget.initialOrder);
    } else {
      _addFloor(0);
    }
    _initCashfree();
  }

  void _prefillFromOrder(dynamic order) {
    final inputs = _asMap(order['inputs']);
    final dimensions = _asMap(inputs['dimensions']);
    final ownerDetails =
        _asMap(inputs['ownerDetais'] ?? inputs['ownerDetails']);

    _existingEstimateId = inputs['estimateId']?.toString();
    _lengthCtrl.text = dimensions['length']?.toString() ?? '';
    _widthCtrl.text = dimensions['width']?.toString() ?? '';
    _ownerNameCtrl.text = ownerDetails['name']?.toString() ?? '';
    _ownerFirstNameCtrl.text = _ownerNameCtrl.text;
    _ownerAddressCtrl.text = ownerDetails['address']?.toString() ?? '';
    _totalAmountCtrl.text = inputs['totalAmount']?.toString() ?? '';

    for (final option in _floorOptions) {
      final key = option['key']!;
      final area = dimensions[key];
      if (area == null) continue;

      final areaValue = double.tryParse(area.toString()) ?? 0;
      final floor = FloorData(
        floorType: option['type']!,
        floorKey: key,
      );
      floor.builtUpArea = areaValue;
      floor.areaCtrl.text = area.toString();
      _floors.add(floor);
    }

    if (_floors.isEmpty) {
      final floor = FloorData(
        floorType: _floorOptions.first['type']!,
        floorKey: _floorOptions.first['key']!,
      );
      _floors.add(floor);
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  void _initCashfree() {
    // Cashfree initialization - will be done when needed
  }

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _totalAmountCtrl.dispose();
    for (var floor in _floors) {
      floor.dispose();
    }
    _ownerNameCtrl.dispose();
    _ownerFirstNameCtrl.dispose();
    _ownerRelativeNameCtrl.dispose();
    _ownerSurnameCtrl.dispose();
    _ownerAddressCtrl.dispose();
    _ownerPhoneCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TOTAL AMOUNT VALIDATION
  // ═══════════════════════════════════════════════════════════════════════
  String? _validateTotalAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Total amount is required';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Enter a valid amount';
    }

    if (_minimumTotalAmount <= 0 || _maximumTotalAmount <= 0) {
      return 'Enter built-up area first';
    }

    if (amount < _minimumTotalAmount) {
      return 'Amount must be at least Rs. ${_formatNumber(_minimumTotalAmount)}';
    }

    if (amount > _maximumTotalAmount) {
      return 'Amount cannot exceed Rs. ${_formatNumber(_maximumTotalAmount)}';
    }

    return null;
  }

  double get _totalAmount => double.tryParse(_totalAmountCtrl.text) ?? 0;

  double get _minimumTotalAmount => _totalArea * 1000;

  double get _maximumTotalAmount => _totalArea * 2600;

  bool get _isTotalAmountInRange =>
      _totalAmount >= _minimumTotalAmount && _totalAmount <= _maximumTotalAmount;

  void _syncOwnerName() {
    if (_isOrderReviewMode) return;

    final parts = [
      _ownerFirstNameCtrl.text.trim(),
      _ownerRelation,
      _ownerRelativeNameCtrl.text.trim(),
      _ownerSurnameCtrl.text.trim(),
    ].where((part) => part.isNotEmpty).join(' ');

    _ownerNameCtrl.text = parts;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CALCULATIONS
  // ═══════════════════════════════════════════════════════════════════════

  // Base rate per sqft
  double get _baseRatePerSqft => _selectedCategory == 'A' ? 2000 : 1800;

  double get _totalArea =>
      _floors.fold(0, (sum, floor) => sum + floor.builtUpArea);

  // Total estimate (no interior charges)
  double get _totalEstimate => _totalArea * _baseRatePerSqft;

  double get _length => double.tryParse(_lengthCtrl.text) ?? 0;
  double get _width => double.tryParse(_widthCtrl.text) ?? 0;
  double get _maxArea => _length * _width;

  double get _groundFloorArea {
    final ground = _floors.where((f) => f.floorKey == 'groundFloor').toList();
    return ground.isNotEmpty ? ground.first.builtUpArea : 0;
  }

  bool get _canAddMoreFloors =>
      _floors.length < _maxFloorCount && _floors.length < _floorOptions.length;

  int? get _nextFloorIndex {
    for (int i = 0; i < _floorOptions.length; i++) {
      if (!_floors.any((f) => f.floorKey == _floorOptions[i]['key'])) {
        return i;
      }
    }
    return null;
  }

  void _addFloor(int index) {
    if (!_canAddMoreFloors) {
      _showSnackBar(
          'Limit Reached', 'You can add a maximum of 3 floors.', Colors.orange);
      return;
    }

    if (index < _floorOptions.length) {
      setState(() {
        _floors.add(FloorData(
          floorType: _floorOptions[index]['type']!,
          floorKey: _floorOptions[index]['key']!,
        ));
      });
    }
  }

  void _removeFloor(int index) {
    if (_floors.length > 1 && _floors[index].floorKey != 'groundFloor') {
      setState(() {
        _floors[index].dispose();
        _floors.removeAt(index);
      });
    } else {
      _showSnackBar(
          'Cannot Remove', 'Ground Floor is required.', Colors.orange);
    }
  }

  String _getSheetType() {
    List<String> floorKeys = [];
    for (var option in _floorOptions) {
      if (_floors.any((f) => f.floorKey == option['key'])) {
        floorKeys.add(option['key']!);
      }
    }

    String prefix = '';
    for (int i = 0; i < floorKeys.length; i++) {
      String abbr = '';
      switch (floorKeys[i]) {
        case 'groundFloor':
          abbr = 'gf';
          break;
        case 'firstFloor':
          abbr = 'ff';
          break;
        case 'secondFloor':
          abbr = 'sf';
          break;
        case 'thirdFloor':
          abbr = 'tf';
          break;
        case 'fourthFloor':
          abbr = 'fof';
          break;
      }
      prefix = i == 0 ? abbr : '${prefix}_$abbr';
    }

    return prefix;
  }

  String _getFloorType() {
    List<String> floorKeys = [];
    for (var option in _floorOptions) {
      if (_floors.any((f) => f.floorKey == option['key'])) {
        floorKeys.add(option['key']!);
      }
    }

    String prefix = '';
    for (int i = 0; i < floorKeys.length; i++) {
      String abbr = '';
      switch (floorKeys[i]) {
        case 'groundFloor':
          abbr = 'gf';
          break;
        case 'firstFloor':
          abbr = 'ff';
          break;
        case 'secondFloor':
          abbr = 'sf';
          break;
        case 'thirdFloor':
          abbr = 'tf';
          break;
        case 'fourthFloor':
          abbr = 'fof';
          break;
      }
      prefix = i == 0 ? abbr : '${prefix}_$abbr';
    }

    return prefix;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PHONE VALIDATION
  // ═══════════════════════════════════════════════════════════════════════
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final phone = value.replaceAll(RegExp(r'[\s-]'), '');

    if (phone.length != 10) {
      return 'Enter 10 digit mobile number';
    }

    if (!RegExp(r'^[6-9]').hasMatch(phone)) {
      return 'Invalid mobile number (should start with 6-9)';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return 'Only digits allowed';
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UI HELPERS
  // ═══════════════════════════════════════════════════════════════════════
  void _showSnackBar(String title, String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green
                  ? Icons.check_circle
                  : color == Colors.red
                      ? Icons.error
                      : Icons.warning,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(message, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorDialog(String title, String message, List<String> errors) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.red.shade100, shape: BoxShape.circle),
              child: Icon(Icons.error_outline, color: Colors.red.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: errors
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(color: Colors.red)),
                                Expanded(
                                    child: Text(e,
                                        style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 13))),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<String> _validatePropertyStep() {
    List<String> errors = [];

    if (_lengthCtrl.text.isEmpty || _length <= 0) {
      errors.add('Enter valid length');
    }
    if (_widthCtrl.text.isEmpty || _width <= 0) {
      errors.add('Enter valid width');
    }

    if (_floors.isEmpty) {
      errors.add('At least Ground Floor is required');
      return errors;
    }

    for (var floor in _floors) {
      if (floor.areaCtrl.text.isEmpty || floor.builtUpArea <= 0) {
        errors.add('${floor.floorType}: Built-up area is required');
      } else {
        if (_maxArea > 0 && floor.builtUpArea > _maxArea) {
          errors.add(
              '${floor.floorType}: Area cannot exceed ${_maxArea.toStringAsFixed(0)} sqft');
        }
        if (floor.floorKey != 'groundFloor' &&
            _groundFloorArea > 0 &&
            floor.builtUpArea > _groundFloorArea) {
          errors.add('${floor.floorType}: Cannot exceed Ground Floor');
        }
      }
    }

    return errors;
  }

  List<String> _validateOwnerStep() {
    List<String> errors = [];
    _syncOwnerName();

    if (_isOrderReviewMode) {
      if (_ownerNameCtrl.text.trim().length < 3) {
        errors.add('Enter valid name (min 3 characters)');
      }
    } else {
      if (_ownerFirstNameCtrl.text.trim().length < 3) {
        errors.add('Enter valid name (min 3 characters)');
      }

      if (_ownerRelativeNameCtrl.text.trim().length < 2) {
        errors.add('Enter valid father/husband name');
      }

      if (_ownerSurnameCtrl.text.trim().length < 2) {
        errors.add('Enter valid surname');
      }
    }

    final phoneError = _validatePhone(_ownerPhoneCtrl.text);
    if (_ownerPhoneCtrl.text.isNotEmpty && phoneError != null) {
      errors.add(phoneError);
    }

    if (_ownerAddressCtrl.text.trim().length < 10) {
      errors.add('Enter complete address (min 10 characters)');
    }

    final amountError = _validateTotalAmount(_totalAmountCtrl.text);
    if (amountError != null) {
      errors.add(amountError);
    }

    return errors;
  }

  void _goToNextStep() {
    if (_currentStep == 0) {
      final errors = _validatePropertyStep();
      if (errors.isNotEmpty) {
        _showErrorDialog('Validation Error', 'Please fix:', errors);
        return;
      }
      if (!(_propertyFormKey.currentState?.validate() ?? false)) return;
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      final errors = _validateOwnerStep();
      if (errors.isNotEmpty) {
        _showErrorDialog('Validation Error', 'Please fix:', errors);
        return;
      }
      if (!(_ownerFormKey.currentState?.validate() ?? false)) return;
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      setState(() => _currentStep = 3);
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CASHFREE PAYMENT FLOW
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> _startPayment() async {
    if (!mounted || _estimateId == null) return;

    setState(() {
      _isPaymentProcessing = true;
      _paymentError = null;
    });

    try {

      final requestBody = {
        'amount': 1,
        'currency': 'INR',
        'estimateId': _estimateId,
      };


      final response = await http
          .post(
            Uri.parse(
                'https://estimate-pro-backend.onrender.com/payments/create-order'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 60));


      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final paymentSessionId = data['paymentSessionId'];
        final orderId = data['orderId'];

        if (paymentSessionId == null || orderId == null) {
          setState(() {
            _paymentError = 'Invalid response: missing payment details';
            _isPaymentProcessing = false;
          });
          return;
        }

        setState(() {
          _orderId = orderId;
        });


        try {
          var cfSession = CFSessionBuilder()
              .setOrderId(orderId)
              .setPaymentSessionId(paymentSessionId)
              .setEnvironment(CFEnvironment.SANDBOX)
              .build();

          var cfWebCheckoutPayment =
              CFWebCheckoutPaymentBuilder().setSession(cfSession).build();

          var cfPaymentGatewayService = CFPaymentGatewayService();

          cfPaymentGatewayService.setCallback((paymentResult) {
            _verifyPayment();
          }, (error, errorMessage) {
            if (mounted) {
              setState(() {
                _paymentError = errorMessage;
                _isPaymentProcessing = false;
              });
            }
          });

          await cfPaymentGatewayService.doPayment(cfWebCheckoutPayment);
        } catch (e) {
          if (mounted) {
            setState(() {
              _paymentError = 'Payment error: $e';
              _isPaymentProcessing = false;
            });
          }
        }
      } else {
        String errorMsg = 'Server Error ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['message'] ?? errorData['error'] ?? errorMsg;
        } catch (_) {}


        setState(() {
          _paymentError = errorMsg;
          _isPaymentProcessing = false;
        });
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _paymentError = 'Request timeout. Server may be starting up.';
        _isPaymentProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _paymentError = 'Error: $e';
        _isPaymentProcessing = false;
      });
    }
  }

  Future<void> _verifyPayment() async {
    if (_orderId == null) return;

    setState(() {
      _isPaymentProcessing = true;
    });

    try {

      final response = await http.get(
        Uri.parse(
            'https://estimate-pro-backend.onrender.com/payments/verify/$_orderId'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));


      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        bool isPaymentSuccessful = false;

        if (data['payment_status'] == 'SUCCESS' ||
            data['success'] == true ||
            data['status'] == 'success') {
          isPaymentSuccessful = true;
        }

        if (isPaymentSuccessful) {
          setState(() {
            _paymentSuccess = true;
            _paymentError = null;
            _isPaymentProcessing = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('✓ Payment Successful! You can now download PDF.'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          setState(() {
            _paymentError = 'Payment verification failed. Please try again.';
            _isPaymentProcessing = false;
          });
        }
      } else {
        setState(() {
          _paymentError =
              'Payment verification failed. Please contact support.';
          _isPaymentProcessing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _paymentError = 'Error verifying payment: $e';
        _isPaymentProcessing = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GENERATE ESTIMATE
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> _generateEstimate() async {
    if (!mounted) return;

    setState(() {
      _isGenerating = true;
      _generateError = null;
      _estimateId = null;
      _paymentSuccess = false;
      _paymentId = null;
    });

    try {
      _syncOwnerName();
      Map<String, dynamic> dimensions = {'length': _length, 'width': _width};
      for (var floor in _floors) {
        dimensions[floor.floorKey] = floor.builtUpArea;
      }

      final body = {
        if (_existingEstimateId != null) 'estimateId': _existingEstimateId,
        'dimensions': dimensions,
        'ownerDetais': {
          'name': _ownerNameCtrl.text.trim(),
          'address': _ownerAddressCtrl.text.trim(),
        },
        'sheetType': _getSheetType(),
        'floorType': _getFloorType(),
        'totalArea': _totalArea,
        'totalAmount': _totalAmount,
      };


      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final response = await http
          .post(
            Uri.parse(
                'https://estimate-pro-backend.onrender.com/estimate/generate'),
            headers: {
              'Content-Type': 'application/json',
              if (authProvider.userId != null) 'userId': authProvider.userId!,
              if (authProvider.token != null)
                'Authorization': 'Bearer ${authProvider.token}',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 120));


      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _estimateId = data['estimateId'];
          _isGenerating = false;
          _generateError = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Estimate generated! Now pay to download.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        String errorMsg = 'Failed (${response.statusCode})';
        try {
          final data = jsonDecode(response.body);
          errorMsg = data['message'] ?? data['error'] ?? errorMsg;
        } catch (_) {}

        setState(() {
          _generateError = errorMsg;
          _isGenerating = false;
        });
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _generateError = 'Timeout. Server may be starting. Try again.';
        _isGenerating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generateError = 'Error: $e';
        _isGenerating = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DOWNLOAD PDF  ✅ FIXED: open_filex instead of url_launcher for local files
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> _downloadPDF() async {
    if (!mounted) return;

    if (_estimateId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please generate estimate first'),
              backgroundColor: Colors.orange),
        );
      }
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final url =
          'https://estimate-pro-backend.onrender.com/estimate/generate/download/$_estimateId';

      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (authProvider.userId != null) 'userid': authProvider.userId!,
          if (authProvider.token != null)
            'Authorization': 'Bearer ${authProvider.token}',
        },
      ).timeout(const Duration(seconds: 60));

      if (!mounted) return;


      if (response.statusCode == 200) {
        // ✅ Use getApplicationDocumentsDirectory — safe for FileProvider on Android
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'estimate_$_estimateId.pdf';
        final filePath = '${dir.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // ✅ Use OpenFilex — handles Android FileProvider automatically
        final result = await OpenFilex.open(filePath);

        if (!mounted) return;

        if (result.type == ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ PDF opened successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (result.type == ResultType.noAppToOpen) {
          // No PDF viewer installed — fallback to share sheet
          try {
            await Share.shareXFiles(
              [XFile(filePath)],
              text: 'Construction Estimate PDF',
            );
          } catch (shareErr) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('PDF saved at: $filePath'),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        } else {
          // Other errors (permissionDenied, error, etc.)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not open PDF: ${result.message}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        // HTTP error from server

        String errorDetail = response.body;
        try {
          final errorJson = jsonDecode(response.body);
          errorDetail =
              errorJson['error'] ?? errorJson['message'] ?? response.body;
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Download failed (${response.statusCode}): $errorDetail'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
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
    } finally {
      // ✅ Use finally — guarantees _isDownloading is always reset
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FORMAT NUMBER
  // ═══════════════════════════════════════════════════════════════════════
  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Estimate'), elevation: 0),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(child: _buildCurrentStep()),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPropertyStep();
      case 1:
        return _buildOwnerStep();
      case 2:
        return _buildReviewStep();
      case 3:
        return _buildPaymentStep();
      default:
        return _buildPropertyStep();
    }
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          _stepCircle(0, 'Property'),
          _stepLine(0),
          _stepCircle(1, 'Owner'),
          _stepLine(1),
          _stepCircle(2, 'Review'),
          _stepLine(2),
          _stepCircle(3, 'Pay'),
        ],
      ),
    );
  }

  Widget _stepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.green : Colors.grey.shade300,
              border:
                  isCurrent ? Border.all(color: Colors.blue, width: 2) : null,
            ),
            child: Center(
              child: isActive && !isCurrent
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text('${step + 1}',
                      style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: isActive ? Colors.black : Colors.grey,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _stepLine(int afterStep) {
    final isActive = _currentStep > afterStep;
    return Container(
        width: 20,
        height: 2,
        color: isActive ? Colors.green : Colors.grey.shade300,
        margin: const EdgeInsets.only(bottom: 16));
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STEP 1: PROPERTY
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildPropertyStep() {
    return Form(
      key: _propertyFormKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.straighten,
                            color: Colors.purple.shade700, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Property Dimensions',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _lengthCtrl,
                          enabled: _canEditFields,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'))
                          ],
                          decoration: const InputDecoration(
                              labelText: 'Length (ft) *',
                              border: OutlineInputBorder()),
                          validator: (v) => (v == null ||
                                  v.isEmpty ||
                                  (double.tryParse(v) ?? 0) <= 0)
                              ? 'Required'
                              : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('×', style: TextStyle(fontSize: 20))),
                      Expanded(
                        child: TextFormField(
                          controller: _widthCtrl,
                          enabled: _canEditFields,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'))
                          ],
                          decoration: const InputDecoration(
                              labelText: 'Width (ft) *',
                              border: OutlineInputBorder()),
                          validator: (v) => (v == null ||
                                  v.isEmpty ||
                                  (double.tryParse(v) ?? 0) <= 0)
                              ? 'Required'
                              : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  if (_maxArea > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade700, size: 18),
                          const SizedBox(width: 8),
                          Text('Max Area: ${_maxArea.toStringAsFixed(0)} sqft',
                              style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Floor-wise Built-up Area',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (_canEditFields &&
                  _canAddMoreFloors &&
                  _nextFloorIndex != null)
                TextButton.icon(
                  onPressed: () => _addFloor(_nextFloorIndex!),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Floor'),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ..._floors
              .asMap()
              .entries
              .map((e) => _buildFloorCard(e.value, e.key)),
          if (_totalArea > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Built-up Area',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('${_totalArea.toStringAsFixed(0)} sqft',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloorCard(FloorData floor, int index) {
    final isGround = floor.floorKey == 'groundFloor';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color:
                      isGround ? Colors.green.shade100 : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(isGround ? Icons.home : Icons.layers,
                  color: isGround ? Colors.green : Colors.blue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(floor.floorType,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: floor.areaCtrl,
                    enabled: _canEditFields,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                    decoration: InputDecoration(
                      labelText: 'Built-up Area *',
                      suffixText: 'sqft',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      helperText: isGround
                          ? (_maxArea > 0
                              ? 'Max: ${_maxArea.toStringAsFixed(0)}'
                              : null)
                          : (_groundFloorArea > 0
                              ? 'Max: ${_groundFloorArea.toStringAsFixed(0)}'
                              : null),
                      helperStyle: TextStyle(color: Colors.orange.shade700),
                    ),
                    onChanged: (v) => setState(
                        () => floor.builtUpArea = double.tryParse(v) ?? 0),
                  ),
                ],
              ),
            ),
            if (_canEditFields && !isGround)
              IconButton(
                  onPressed: () => _removeFloor(index),
                  icon: const Icon(Icons.close, color: Colors.red, size: 20)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STEP 2: OWNER
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildOwnerStep() {
    return Form(
      key: _ownerFormKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Owner Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_isOrderReviewMode) ...[
            TextFormField(
              controller: _ownerNameCtrl,
              enabled: _canEditFields,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name *',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Enter valid name (min 3 chars)'
                  : null,
            ),
          ] else ...[
            TextFormField(
              controller: _ownerFirstNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'e.g., Sufiyan',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Enter valid name (min 3 chars)'
                  : null,
              onChanged: (_) => _syncOwnerName(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _ownerRelation,
              decoration: const InputDecoration(
                labelText: 'Relation *',
                prefixIcon: Icon(Icons.family_restroom_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'S/o', child: Text('S/o = Son of')),
                DropdownMenuItem(
                    value: 'D/o', child: Text('D/o = Daughter of')),
                DropdownMenuItem(value: 'W/o', child: Text('W/o = Wife of')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _ownerRelation = value);
                _syncOwnerName();
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ownerRelativeNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'e.g., Riyaz',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'Enter valid name'
                  : null,
              onChanged: (_) => _syncOwnerName(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ownerSurnameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Surname *',
                hintText: 'e.g., Khan',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'Enter valid surname'
                  : null,
              onChanged: (_) => _syncOwnerName(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ownerPhoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                hintText: '9876543210',
                prefixIcon: Icon(Icons.phone_outlined),
                prefixText: '+91 ',
                border: OutlineInputBorder(),
                helperText: '10 digit Indian mobile number (starts with 6-9)',
              ),
              validator: _validatePhone,
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _ownerAddressCtrl,
            enabled: _canEditFields,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Property Address *',
              hintText:
                  'Plot No., Kh. No., Ward, Colony, City, District, State',
              prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 50),
                  child: Icon(Icons.location_on_outlined)),
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            validator: (v) => (v == null || v.trim().length < 10)
                ? 'Enter complete address'
                : null,
          ),
          const SizedBox(height: 24),

          // Total Amount Field
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.currency_rupee,
                            color: Colors.green.shade700, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Total Amount',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _totalAmountCtrl,
                    enabled: _canEditFields,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                    decoration: InputDecoration(
                      labelText: 'Total Amount *',
                      hintText:
                          'Enter amount between Rs. ${_formatNumber(_minimumTotalAmount)} - Rs. ${_formatNumber(_maximumTotalAmount)}',
                      prefixIcon: const Icon(Icons.currency_rupee_outlined),
                      prefixText: 'Rs. ',
                      border: const OutlineInputBorder(),
                      helperText:
                          'Minimum: Rs. ${_formatNumber(_minimumTotalAmount)} | Maximum: Rs. ${_formatNumber(_maximumTotalAmount)}',
                      helperStyle: const TextStyle(color: Colors.green),
                    ),
                    validator: _validateTotalAmount,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_totalAmount > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isTotalAmountInRange
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isTotalAmountInRange
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isTotalAmountInRange
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: _isTotalAmountInRange
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isTotalAmountInRange
                                  ? 'Valid amount: Rs. ${_formatNumber(_totalAmount)}'
                                  : 'Amount must be between Rs. ${_formatNumber(_minimumTotalAmount)} - Rs. ${_formatNumber(_maximumTotalAmount)}',
                              style: TextStyle(
                                color: _isTotalAmountInRange
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STEP 3: REVIEW
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildReviewStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Review Your Estimate',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        _buildReviewCard(
          'Property Details',
          Icons.home_work,
          Colors.purple,
          [
            _reviewRow('Dimensions',
                '${_length.toStringAsFixed(0)} × ${_width.toStringAsFixed(0)} ft'),
            _reviewRow('Plot Area', '${_maxArea.toStringAsFixed(0)} sqft'),
            const Divider(),
            ..._floors.map((f) => _reviewRow(
                f.floorType, '${f.builtUpArea.toStringAsFixed(0)} sqft')),
            const Divider(),
            _reviewRow(
                'Total Built-up', '${_totalArea.toStringAsFixed(0)} sqft',
                isBold: true, color: Colors.green),
          ],
        ),

        const SizedBox(height: 12),

        _buildReviewCard(
          'Owner Details',
          Icons.person,
          Colors.blue,
          [
            _reviewRow('Name', _ownerNameCtrl.text.trim()),
            if (_ownerPhoneCtrl.text.isNotEmpty)
              _reviewRow('Mobile', '+91 ${_ownerPhoneCtrl.text.trim()}'),
            _reviewRow('Address', _ownerAddressCtrl.text.trim()),
          ],
        ),

        const SizedBox(height: 12),

        _buildReviewCard(
          'Total Amount',
          Icons.currency_rupee,
          Colors.green,
          [
            _reviewRow('Amount', '₹${_formatNumber(_totalAmount)}',
                isBold: true, color: Colors.green),
          ],
        ),

        const SizedBox(height: 20),

        // Cost Breakdown
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text('Cost Breakdown',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 12),
              _costRow(
                  'Base Cost (${_totalArea.toStringAsFixed(0)} sqft × ₹${_baseRatePerSqft.toInt()})',
                  _totalEstimate),
              const Divider(color: Colors.white30, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Estimate',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  Text('₹ ${_formatNumber(_totalEstimate)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _costRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text('₹ ${_formatNumber(amount)}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildReviewCard(
      String title, IconData icon, Color color, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _reviewRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STEP 4: PAYMENT
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildPaymentStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Generate & Pay',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Generate Button
        if (_estimateId == null) ...[
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateEstimate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
              ),
              child: _isGenerating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white)),
                        ),
                        SizedBox(width: 12),
                        Text('Generating...'),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description),
                        SizedBox(width: 8),
                        Text('Generate Estimate',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
            ),
          ),
          if (_generateError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_generateError!,
                          style: TextStyle(color: Colors.red.shade700))),
                ],
              ),
            ),
          ],
        ],

        // Estimate Generated success banner
        if (_estimateId != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estimate Generated!',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700)),
                      const SizedBox(height: 4),
                      Text('Estimate ID: $_estimateId',
                          style: const TextStyle(
                              color: Colors.green, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text('Payment Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          const Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PDF Download Fee',
                          style: TextStyle(fontSize: 16)),
                      Text(
                        '₹$_basePaymentAmount',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pay ₹$_basePaymentAmount to download your estimate PDF',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Pay Button
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: _isPaymentProcessing || _paymentSuccess
                  ? null
                  : _startPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
              ),
              child: _isPaymentProcessing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white)),
                        ),
                        SizedBox(width: 12),
                        Text('Processing...'),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment),
                        SizedBox(width: 8),
                        Text('Pay ₹$_basePaymentAmount',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
            ),
          ),

          if (_paymentError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_paymentError!,
                          style: TextStyle(color: Colors.red.shade700))),
                ],
              ),
            ),
          ],

          // Payment Success + Download Section
          if (_paymentSuccess) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Payment Successful!',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700)),
                      ),
                    ],
                  ),
                  if (_paymentId != null) ...[
                    const SizedBox(height: 8),
                    Text('Payment ID: $_paymentId',
                        style: TextStyle(
                            color: Colors.green.shade600, fontSize: 12)),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.purple.shade400,
                        Colors.purple.shade600
                      ]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _isDownloading ? null : _downloadPDF,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                      ),
                      child: _isDownloading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white)),
                                ),
                                SizedBox(width: 12),
                                Text('Downloading...'),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.download),
                                SizedBox(width: 8),
                                Text('Download PDF',
                                    style: TextStyle(fontSize: 16)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: ElevatedButton(
                onPressed: _goToPreviousStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Previous', style: TextStyle(fontSize: 16)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep < 3 ? _goToNextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_currentStep < 3 ? 'Next' : 'Complete',
                  style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
