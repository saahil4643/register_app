import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RouteService extends ChangeNotifier {
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  static const String _storageKey = 'sales_routes_v1';
  bool _initialized = false;

  final List<String> _routes = [
    'Route 1 - Market Yard & Main Bazar',
    'Route 2 - Station Road & Commercial Zone',
    'Route 3 - Highway & Industrial Estate',
    'Route 4 - City Center & Suburbs',
    'Route 5 - North Zone Beat',
  ];

  List<String> get routes => List.unmodifiable(_routes);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_storageKey);
      if (saved != null && saved.isNotEmpty) {
        for (var r in saved) {
          if (!_routes.contains(r)) {
            _routes.add(r);
          }
        }
      }
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing RouteService: $e');
      _initialized = true;
    }
  }

  Future<void> addRoute(String routeName) async {
    final trimmed = routeName.trim();
    if (trimmed.isEmpty || _routes.contains(trimmed)) return;
    _routes.add(trimmed);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _routes);
    } catch (e) {
      debugPrint('Error saving route: $e');
    }
  }
}
