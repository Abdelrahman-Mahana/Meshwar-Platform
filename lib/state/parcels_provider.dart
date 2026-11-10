import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models/parcel_model.dart';

class ParcelsProvider extends ChangeNotifier {
  final List<ParcelModel> _parcels = [MockData.activeParcel];

  List<ParcelModel> get parcels => _parcels;
  ParcelModel get currentTrackingParcel => _parcels.first;

  void sendParcel({
    required String driverName,
    required String route,
    required String description,
    required ParcelSize size,
    required double weightKg,
    required int estimatedValue,
    required String receiverName,
    required String receiverPhone,
    required int fee,
  }) {
    final newParcel = ParcelModel(
      id: 'parcel_${DateTime.now().millisecondsSinceEpoch}',
      driverName: driverName,
      route: route,
      description: description,
      size: size,
      weightKg: weightKg,
      estimatedValue: estimatedValue,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      fee: fee,
      pickupOtp: '4 8 2 1',
      status: ParcelStatusStep.requested,
    );
    _parcels.insert(0, newParcel);
    notifyListeners();
  }
}

