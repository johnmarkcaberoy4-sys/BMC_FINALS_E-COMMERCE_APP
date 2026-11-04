import 'package:flutter/material.dart';

class ShopCategory {
  final String name;
  final IconData icon;
  final List<String> keywords;

  const ShopCategory(this.name, this.icon, this.keywords);
}

const List<ShopCategory> shopCategories = [
  ShopCategory('Phones', Icons.smartphone, ['phone', 'iphone', 'pixel']),
  ShopCategory('Computers', Icons.laptop_mac, ['laptop', 'computer', 'mac']),
  ShopCategory('Watches', Icons.watch, ['watch']),
  ShopCategory('Audio', Icons.headphones, ['headphone', 'speaker', 'audio']),
  ShopCategory('Accessories', Icons.devices_other, [
    'case',
    'charger',
    'cable',
    'band',
    'accessory',
  ]),
];
