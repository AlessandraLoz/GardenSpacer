import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_bed.dart';

class BedStore {
  static const _key = 'saved_beds';

  Future<List<SavedBed>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in list)
        SavedBed.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<List<SavedBed>> upsert(SavedBed bed) async {
    final beds = await loadAll();
    final next = [
      for (final existing in beds)
        if (existing.name.toLowerCase() != bed.name.toLowerCase()) existing,
      bed,
    ];
    next.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    await _write(next);
    return next;
  }

  Future<List<SavedBed>> delete(String name) async {
    final beds = await loadAll();
    final next = [
      for (final existing in beds)
        if (existing.name.toLowerCase() != name.toLowerCase()) existing,
    ];
    await _write(next);
    return next;
  }

  Future<void> _write(List<SavedBed> beds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final bed in beds) bed.toJson()]),
    );
  }
}
