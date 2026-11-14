import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';

class PainReliefData {
  static final List<Map<String, dynamic>> painZones = [
    {
      'title': 'Leg Pain Relief',
      'subtitle': 'Soreness from running or leg day',
      'icon': Icons.directions_run,
      'color': ColorManager.warning,
      'routines': [
        {'name': 'Calf Stretch', 'duration': 45},
        {'name': 'Hamstring Reach', 'duration': 60},
        {'name': 'Quad Pull', 'duration': 45},
        {'name': 'Butterfly Stretch', 'duration': 60},
        {'name': 'Legs Up the Wall', 'duration': 120},
      ]
    },
    {
      'title': 'Lower Back Ease',
      'subtitle': 'Relief for desk workers',
      'icon': Icons.weekend,
      'color': ColorManager.info,
      'routines': [
        {'name': 'Cat-Cow Stretch', 'duration': 60},
        {'name': 'Child\'s Pose', 'duration': 90},
        {'name': 'Cobra Stretch', 'duration': 45},
        {'name': 'Knee to Chest', 'duration': 60},
        {'name': 'Spinal Twist', 'duration': 45},
      ]
    },
    {
      'title': 'Neck & Shoulders',
      'subtitle': 'Reduce tension and stiffness',
      'icon': Icons.accessibility_new,
      'color': ColorManager.violet,
      'routines': [
        {'name': 'Neck Rolls', 'duration': 60},
        {'name': 'Shoulder Shrugs', 'duration': 45},
        {'name': 'Cross-Body Arm Stretch', 'duration': 45},
        {'name': 'Upper Trapezius Stretch', 'duration': 45},
      ]
    },
    {
      'title': 'Knee Mobility',
      'subtitle': 'Gentle movements for stiff knees',
      'icon': Icons.airline_seat_legroom_extra,
      'color': ColorManager.success,
      'routines': [
        {'name': 'Seated Leg Lifts', 'duration': 45},
        {'name': 'Hamstring Curl (Standing)', 'duration': 45},
        {'name': 'Calf Raises', 'duration': 30},
        {'name': 'Wall Sit (Gentle)', 'duration': 30},
      ]
    },
  ];
}
