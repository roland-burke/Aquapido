import 'package:flutter/material.dart';

class Constants {
  static const double IMAGE_HEIGHT = 60.0;
  static const List<int> cupSizes = [100, 200, 300, 330, 400, 500];
  static const CARD_MARGIN = EdgeInsets.all(11);
  static const CARD_ELEVATION = 2.5;
  static const WATER_UNIT_L = 'L';
  static const WATER_UNIT_ML = 'ml';

  static final List<Image> cupImages = [
    Image.asset(
      'assets/images/cup_100ml.png',
      height: IMAGE_HEIGHT,
    ),
    Image.asset(
      'assets/images/cup_200ml.png',
      height: IMAGE_HEIGHT,
    ),
    Image.asset(
      'assets/images/cup_300ml.png',
      height: IMAGE_HEIGHT,
    ),
    Image.asset(
      'assets/images/cup_330ml.png',
      height: IMAGE_HEIGHT,
    ),
    Image.asset(
      'assets/images/cup_400ml.png',
      height: IMAGE_HEIGHT,
    ),
    Image.asset(
      'assets/images/cup_500ml.png',
      height: IMAGE_HEIGHT,
    ),
    Image.asset(
      'assets/images/cup_custom.png',
      height: IMAGE_HEIGHT,
    ),
  ];
}
