/// Shared Qatar municipality, city, and logistics hub alias matcher.
///
/// Used across [RidesProvider], [BoardProvider], and [AlertsProvider] to ensure
/// consistent bilingual (Arabic/English) corridor and alert matching.
class QatarCityMatcher {
  QatarCityMatcher._();

  static const Map<String, List<String>> cityAliases = {
    'الدوحة': [
      'doha',
      'الدوحة',
      'مشيرب',
      'الخليج الغربي',
      'west bay',
      'msheireb',
    ],
    'لوسيل': ['lusail', 'لوسيل', 'marina'],
    'الخور': ['al khor', 'alkhor', 'khor', 'الخور'],
    'الوكرة': ['al wakrah', 'wakrah', 'الوكرة'],
    'الريان': ['al rayyan', 'rayyan', 'الريان'],
    'المنطقة الصناعية': [
      'industrial area',
      'industrial',
      'المنطقة الصناعية',
      'الصناعية',
    ],
    'دخان': ['dukhan', 'دخان'],
    'مسيعيد': ['mesaieed', 'مسيعيد'],
    'أم صلال': ['umm salal', 'أم صلال', 'ام صلال'],
    'الضعاين': ['al daayen', 'daayen', 'الضعاين'],
    'الشمال': ['al shamal', 'shamal', 'الشمال'],
    'رأس لفان': ['ras laffan', 'رأس لفان', 'راس لفان'],
    'المدينة التعليمية': ['education city', 'المدينة التعليمية'],
    'مطار حمد الدولي': [
      'hamad international airport',
      'hia',
      'airport',
      'مطار حمد الدولي',
      'المطار',
    ],
  };

  /// Checks whether two city strings refer to the same canonical Qatar city/area.
  static bool areCitiesEquivalent(String a, String b) {
    final cleanA = a.trim().toLowerCase();
    final cleanB = b.trim().toLowerCase();
    if (cleanA.isEmpty || cleanB.isEmpty) return false;
    if (cleanA == cleanB) return true;

    for (final entry in cityAliases.entries) {
      final group = <String>{
        entry.key.toLowerCase(),
        ...entry.value.map((v) => v.toLowerCase()),
      };
      if (group.contains(cleanA) && group.contains(cleanB)) {
        return true;
      }
    }
    return false;
  }

  /// Checks whether [query] matches any candidate city/area field using bilingual aliases.
  static bool matchesCityField(String query, List<String?> candidates) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;

    final expandedQueries = <String>{q};
    for (final entry in cityAliases.entries) {
      if (entry.key.toLowerCase().contains(q) ||
          entry.value.any((alias) => alias.contains(q) || q.contains(alias))) {
        expandedQueries.add(entry.key.toLowerCase());
        expandedQueries.addAll(entry.value.map((e) => e.toLowerCase()));
      }
    }

    for (final raw in candidates) {
      if (raw == null || raw.trim().isEmpty) continue;
      final candidate = raw.trim().toLowerCase();
      for (final token in expandedQueries) {
        if (candidate.contains(token) || token.contains(candidate)) {
          return true;
        }
      }
    }
    return false;
  }
}
