import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models/route_alert_model.dart';

class AlertsProvider extends ChangeNotifier {
  final List<RouteAlertModel> _alerts = List.from(MockData.initialAlerts);

  List<RouteAlertModel> get alerts => _alerts;

  void toggleAlert(String id) {
    final index = _alerts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final current = _alerts[index];
      _alerts[index] = current.copyWith(isActive: !current.isActive);
      notifyListeners();
    }
  }

  void deleteAlert(String id) {
    _alerts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void addAlert({
    required String fromCity,
    required String toCity,
    required String dateRange,
    required String category,
  }) {
    final newAlert = RouteAlertModel(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      fromCity: fromCity,
      toCity: toCity,
      dateRange: dateRange,
      category: category,
      isActive: true,
      isExpired: false,
    );
    _alerts.insert(0, newAlert);
    notifyListeners();
  }
}

