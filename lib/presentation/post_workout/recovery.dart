import 'dart:async';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

class PostWorkoutRecoveryPage extends StatelessWidget {
  PostWorkoutRecoveryPage({super.key});

  final List<Map<String, dynamic>> recoverySections = [
    {
      'title': 'Stretching Routines',
      'icon': Icons.accessibility_new,
      'items': [
        {'name': 'Quad Stretch', 'duration': 30},
        {'name': 'Hamstring Stretch', 'duration': 30},
        {'name': 'Shoulder Stretch', 'duration': 20},
        {'name': 'Lower Back Stretch', 'duration': 30},
        {'name': 'Calf Stretch', 'duration': 30},
      ],
    },
    {
      'title': 'Recovery Tips',
      'icon': Icons.local_drink,
      'items': [
        'Hydrate immediately after workout.',
        'Consume a balanced meal with protein and carbs.',
        'Get adequate rest for muscle repair.',
        'Consider taking a cold shower for recovery.',
        'Use a foam roller for muscle relaxation.',
      ],
    },
    {
      'title': 'Sleep Management',
      'icon': Icons.bedtime,
      'items': [
        'Aim for 7-9 hours of quality sleep each night.',
        'Maintain a consistent sleep schedule.',
        'Avoid screens at least 30 minutes before bedtime.',
      ],
    },
    {
      'title': 'Protein Intake',
      'icon': Icons.fitness_center,
      'items': [
        'Consume 1.6-2.2g of protein per kg of body weight daily.',
        'Include a variety of protein sources such as eggs, chicken, and tofu.',
        'Post-workout protein intake aids in muscle recovery.',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.darkGrey,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Post Workout Recovery Tips',
            style: TextStyle(color: Colors.white)),
        backgroundColor: ColorManager.darkGrey,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: recoverySections
            .map((section) => _RecoverySection(
                  title: section['title'],
                  icon: section['icon'],
                  items: section['items'],
                ))
            .toList(),
      ),
    );
  }
}

class _RecoverySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<dynamic> items;

  const _RecoverySection({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ColorManager.black54,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 4,
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        children: items.map((item) {
          if (item is Map<String, dynamic>) {
            return _StretchTile(name: item['name'], duration: item['duration']);
          } else if (item is String) {
            return ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(item, style: const TextStyle(color: Colors.white)),
            );
          }
          return const SizedBox.shrink();
        }).toList(),
      ),
    );
  }
}

class _StretchTile extends StatefulWidget {
  final String name;
  final int duration;

  const _StretchTile({required this.name, required this.duration});

  @override
  State<_StretchTile> createState() => _StretchTileState();
}

class _StretchTileState extends State<_StretchTile> {
  int? _remainingTime;
  Timer? _timer;

  void _startTimer() {
    setState(() => _remainingTime = widget.duration);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime! > 0) {
        setState(() => _remainingTime = _remainingTime! - 1);
      } else {
        timer.cancel();
        Vibration.vibrate(duration: 500);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.name} stretch complete!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: _remainingTime != null
                ? (_remainingTime! / widget.duration)
                : 1.0,
            color: Colors.orange,
            backgroundColor: Colors.grey,
          ),
          Icon(Icons.access_time, color: Colors.orange),
        ],
      ),
      title: Text(widget.name, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        _remainingTime != null
            ? '$_remainingTime seconds remaining'
            : '${widget.duration} seconds',
        style: const TextStyle(color: Colors.white70),
      ),
      trailing: ElevatedButton(
        onPressed:
            _remainingTime == null || _remainingTime == 0 ? _startTimer : null,
        style: ElevatedButton.styleFrom(backgroundColor:ColorManager.limerGreen2),
        child: const Text('Start Timer',style: TextStyle(color: Colors.black),),
      ),
    );
  }
}
