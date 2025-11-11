import 'package:flutter/material.dart';

class ImageUtils {
  // Create grayscale color filter matrix
  static const ColorFilter grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, // Red channel
    0.2126, 0.7152, 0.0722, 0, 0, // Green channel
    0.2126, 0.7152, 0.0722, 0, 0, // Blue channel
    0,      0,      0,      1, 0, // Alpha channel
  ]);
}
