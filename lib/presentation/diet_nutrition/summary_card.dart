// import 'package:fitness_app/presentation/home/providers/home_provider.dart';
// import 'package:fitness_app/utils/managers/color_manager.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class SummaryCard extends StatelessWidget {
//   final int remainingCalories;

//   const SummaryCard({Key? key, required this.remainingCalories})
//       : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final homeProvider = Provider.of<HomeProvider>(context);
//     final userData = homeProvider.userData;

//     double storedBMR = userData['bmr'] ?? 0.0;
//     double storedBMI = userData['bmi'] ?? 0.0;

//     int dailyCalories =
//         (storedBMR > 0) ? storedBMR.toInt() : (storedBMI * 30).toInt();

//     double weight = userData['weight'] ?? 60.0; // fallback weight if not stored
//     int protein = (weight * 2.0).toInt(); // 2g per kg
//     int carbs = (weight * 4.0).toInt(); // 4g per kg
//     int fats = (weight * 1.0).toInt(); // 1g per kg

//     return Card(
//       color: ColorManager.black54,
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _progressBar(
//                 'Calories', dailyCalories, remainingCalories, Colors.orange),
//             // You can add more progress bars for Protein, Carbs, Fats if needed
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _progressBar(String label, int total, int remaining, Color color) {
//     double progress = (total - remaining) / total;
//     progress = progress.clamp(0.0, 1.0);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style:
//               const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 6),
//         LinearProgressIndicator(
//           value: progress,
//           backgroundColor: Colors.grey.shade800,
//           color: color,
//           minHeight: 8,
//         ),
//         const SizedBox(height: 4),
//         Text(
//           '${total - remaining} / $total kcal consumed',
//           style: const TextStyle(color: Colors.white70, fontSize: 12),
//         ),
//       ],
//     );
//   }
// }
