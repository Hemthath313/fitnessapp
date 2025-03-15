// import 'package:fitness_app/utils/managers/color_manager.dart';
// import 'package:flutter/material.dart';
// import 'package:in_app_purchase/in_app_purchase.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class PremiumScreen extends StatefulWidget {
//   const PremiumScreen({super.key});

//   @override
//   _PremiumScreenState createState() => _PremiumScreenState();
// }

// class _PremiumScreenState extends State<PremiumScreen> {
//   final InAppPurchase _inAppPurchase = InAppPurchase.instance;
//   final String _premiumProductId = 'premium_membership';
//   bool _isPremium = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkPremiumStatus();
//   }

//   Future<void> _checkPremiumStatus() async {
//     final userId = 'user123'; // Replace with actual user ID
//     final doc =
//         await FirebaseFirestore.instance.collection('users').doc(userId).get();
//     setState(() {
//       _isPremium = doc.data()?['isPremium'] ?? false;
//     });
//   }

//   void _buyPremium() async {
//     final ProductDetailsResponse response =
//         await _inAppPurchase.queryProductDetails({_premiumProductId});
//     if (response.notFoundIDs.isNotEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Product not found.')),
//       );
//       return;
//     }

//     final productDetails = response.productDetails.first;
//     final purchaseParam = PurchaseParam(productDetails: productDetails);
//     _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: ColorManager.darkGrey,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Center(
//               child: Text(
//                 'Go Premium',
//                 style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white),
//               ),
//             ),
//             const SizedBox(height: 10),
//             Center(
//               child: Text(
//                 'Unlock all the power of this app and enjoy an enhanced fitness journey!',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 16, color: Colors.white70),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const ListTile(
//                 title: Text('Annual',
//                     style: TextStyle(fontWeight: FontWeight.bold)),
//                 subtitle: Text('First 30 days free - Then \$99.99/Year'),
//                 trailing: Chip(
//                     label: Text('Best Value',
//                         style: TextStyle(color: Colors.green))),
//               ),
//             ),
//             const SizedBox(height: 10),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const ListTile(
//                 title: Text('Monthly',
//                     style: TextStyle(fontWeight: FontWeight.bold)),
//                 subtitle: Text('First 7 days free - Then \$9.99/Month'),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Center(
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.orangeAccent,
//                   foregroundColor: Colors.white,
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8)),
//                 ),
//                 onPressed: _buyPremium,
//                 child: const Text('Start 7-day free trial'),
//               ),
//             ),
//             const Spacer(),
//             const Center(
//               child: Text(
//                 'By subscribing, you agree to the Terms of Service and Privacy Policy.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 12, color: Colors.white70),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
