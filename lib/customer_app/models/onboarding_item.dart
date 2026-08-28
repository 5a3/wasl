import 'package:flutter/material.dart';

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final String badgeText;
  final List<Color> gradientColors;

  const OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.badgeText,
    required this.gradientColors,
  });
}
