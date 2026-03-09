class CategoryUtils {
  static String normalizeName(String? name) {
    if (name == null || name.isEmpty) return 'Service';
    
    // Explicit map for requested renames
    if (name.toLowerCase() == 'plumbing snd water') return 'Plumbing';
    
    // Pattern based renames
    String normalized = name;
    
    // 1. Handle "Service" suffix
    if (normalized.endsWith(' Services')) {
      final base = normalized.replaceAll(' Services', '');
      if (['Cleaning', 'Electrical', 'Laundry', 'Repair', 'Carpentry', 'Painting'].contains(base)) {
        normalized = base;
      }
    }
    
    // 2. Handle common variations
    final lower = normalized.toLowerCase();
    if (lower.contains('plumbing')) return 'Plumbing';
    if (lower.contains('cleaning')) return 'Cleaning';
    if (lower.contains('electric')) return 'Electrical';
    if (lower.contains('laundry')) return 'Laundry';
    if (lower.contains('gas') || lower.contains('cylinder') || lower.contains('lpg') || lower.contains('cooking') || lower.contains('fire')) return 'Gas';
    if (lower.contains('appliance')) return 'Appliances';
    if (lower.contains('furniture')) return 'Furniture';
    if (lower.contains('automotive') || lower.contains('car')) return 'Automotive';
    if (lower.contains('paint')) return 'Painting';
    if (lower.contains('pest')) return 'Pest Control';
    if (lower.contains('wifi')) return 'Wifi';
    if (lower.contains('garden')) return 'Gardening';
    
    return normalized;
  }
}
