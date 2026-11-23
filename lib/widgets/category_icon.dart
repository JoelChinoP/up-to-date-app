import 'package:flutter/material.dart';

IconData categoryIcon(String category) => switch (category) {
  'Luz' => Icons.bolt_outlined,
  'Agua' => Icons.water_drop_outlined,
  'Internet' => Icons.wifi,
  'Teléfono' => Icons.phone_outlined,
  'Streaming' => Icons.subscriptions_outlined,
  'Alquiler' => Icons.home_outlined,
  _ => Icons.receipt_long_outlined,
};
