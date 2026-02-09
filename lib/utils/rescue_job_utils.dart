import 'package:flutter/material.dart';

/// Rescue Job utility class for calculating bonuses and discounts
class RescueJobUtils {
  // Discount tiers for customers based on reassignment count
  static const Map<int, double> customerDiscountTiers = {
    1: 0.10, // 10% discount on first reassignment
    2: 0.15, // 15% discount on second reassignment
    3: 0.20, // 20% discount on third+ reassignment
  };

  // Bonus tiers for rescue workers based on reassignment level
  static const Map<int, double> workerBonusTiers = {
    1: 0.05, // 5% bonus for accepting 1st rescue
    2: 0.07, // 7% bonus for accepting 2nd rescue
    3: 0.10, // 10% bonus for accepting 3rd+ rescue
  };

  static const double maxCustomerDiscount = 0.25;
  static const double maxWorkerBonus = 0.15;

  /// Calculate customer discount based on reassignment count
  static double getCustomerDiscount(int reassignmentCount) {
    if (reassignmentCount <= 0) return 0.0;
    final tier = reassignmentCount > 3 ? 3 : reassignmentCount;
    final discount = customerDiscountTiers[tier] ?? 0.0;
    return discount > maxCustomerDiscount ? maxCustomerDiscount : discount;
  }

  /// Calculate worker bonus based on rescue level
  static double getWorkerBonus(int rescueLevel) {
    if (rescueLevel <= 0) return 0.0;
    final tier = rescueLevel > 3 ? 3 : rescueLevel;
    final bonus = workerBonusTiers[tier] ?? 0.0;
    return bonus > maxWorkerBonus ? maxWorkerBonus : bonus;
  }

  /// Calculate final price for customer after discount
  static Map<String, double> calculateCustomerPricing({
    required double originalPrice,
    required int reassignmentCount,
  }) {
    final discountPercent = getCustomerDiscount(reassignmentCount);
    final discountAmount = originalPrice * discountPercent;
    final finalPrice = originalPrice - discountAmount;

    return {
      'originalPrice': originalPrice,
      'discountPercent': discountPercent,
      'discountAmount': discountAmount,
      'finalPrice': finalPrice,
    };
  }

  /// Calculate worker earnings including rescue bonus
  static Map<String, double> calculateWorkerEarnings({
    required double basePrice,
    required int rescueLevel,
  }) {
    final bonusPercent = getWorkerBonus(rescueLevel);
    final bonusAmount = basePrice * bonusPercent;
    final totalEarnings = basePrice + bonusAmount;

    return {
      'basePrice': basePrice,
      'bonusPercent': bonusPercent,
      'bonusAmount': bonusAmount,
      'totalEarnings': totalEarnings,
    };
  }

  /// Get rescue job theme colors
  static RescueJobTheme getRescueTheme(int rescueLevel) {
    switch (rescueLevel) {
      case 1:
        return RescueJobTheme(
          primaryColor: const Color(0xFFFF6B35),
          secondaryColor: const Color(0xFFFF8F65),
          gradientColors: [const Color(0xFFFF6B35), const Color(0xFFFF9F6B)],
          badgeText: 'RESCUE JOB',
          heroEmoji: '🦸',
        );
      case 2:
        return RescueJobTheme(
          primaryColor: const Color(0xFFE91E63),
          secondaryColor: const Color(0xFFF06292),
          gradientColors: [const Color(0xFFE91E63), const Color(0xFFFF5C93)],
          badgeText: 'URGENT RESCUE',
          heroEmoji: '⚡',
        );
      default:
        return RescueJobTheme(
          primaryColor: const Color(0xFF9C27B0),
          secondaryColor: const Color(0xFFBA68C8),
          gradientColors: [const Color(0xFF9C27B0), const Color(0xFFCE93D8)],
          badgeText: 'CRITICAL RESCUE',
          heroEmoji: '🔥',
        );
    }
  }
}

/// Theme class for rescue job UI styling
class RescueJobTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final List<Color> gradientColors;
  final String badgeText;
  final String heroEmoji;

  RescueJobTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.gradientColors,
    required this.badgeText,
    required this.heroEmoji,
  });
}
