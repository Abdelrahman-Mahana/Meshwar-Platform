import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models/parcel_model.dart';
import '../data/models/ride_model.dart';
import '../data/repositories/app_repositories.dart';

class ParcelsProvider extends ChangeNotifier {
  final List<ParcelModel> _parcels = List.from(MockData.initialParcels);
  bool _isLoading = false;

  List<ParcelModel> get parcels => List.unmodifiable(_parcels);
  bool get isLoading => _isLoading;
  ParcelModel get currentTrackingParcel =>
      _parcels.isNotEmpty ? _parcels.first : MockData.activeParcel;
  ParcelModel? get activeTrackingParcel =>
      _parcels.isNotEmpty ? _parcels.first : null;

  static String _generate4DigitOtp() {
    final rng = Random.secure();
    return '${1000 + rng.nextInt(9000)}';
  }

  fb_auth.User? _resolveCurrentAuthUser() {
    try {
      if (Firebase.apps.isEmpty) return null;
      return fb_auth.FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Loads parcels from [AppRepositories.instance.parcels] and merges with
  /// curated seed parcels so tracking & route-parcel examples are ready immediately.
  Future<void> loadParcels() async {
    _isLoading = true;
    notifyListeners();
    try {
      final remote = await AppRepositories.instance.parcels.getParcels();
      final mergedById = <String, ParcelModel>{};
      for (final p in remote) {
        if (p.id.isNotEmpty) {
          mergedById[p.id] = p;
        }
      }
      for (final local in _parcels) {
        mergedById.putIfAbsent(local.id, () => local);
      }
      for (final seed in MockData.initialParcels) {
        mergedById.putIfAbsent(seed.id, () => seed);
      }
      _parcels
        ..clear()
        ..addAll(mergedById.values);
    } catch (_) {
      if (_parcels.isEmpty) {
        _parcels.addAll(MockData.initialParcels);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates either:
  /// 1. A traveler-matched parcel shipment (via [ride] or [driverName]/[driverId]), OR
  /// 2. A standalone on-route parcel request (when no specific traveler is chosen yet),
  /// minting fresh 4-digit pickup & delivery OTPs and syncing with `parcels` repository.
  ParcelModel sendParcel({
    String driverName = '',
    String? driverId,
    RideModel? ride,
    String? route,
    String? fromCity,
    String? toCity,
    String? stopoverCity,
    required String description,
    ParcelSize size = ParcelSize.small,
    double weightKg = 1.0,
    int estimatedValue = 100,
    required String receiverName,
    required String receiverPhone,
    String? senderId,
    String? senderName,
    String? senderPhone,
    int? fee,
  }) {
    final authUser = _resolveCurrentAuthUser();
    final resolvedSenderId = (senderId != null && senderId.trim().isNotEmpty)
        ? senderId.trim()
        : ((authUser != null && authUser.uid.isNotEmpty)
            ? authUser.uid
            : MockData.currentUser.id);
    final resolvedSenderName =
        (senderName != null && senderName.trim().length >= 2)
            ? senderName.trim()
            : ((authUser?.displayName != null &&
                    authUser!.displayName!.trim().length >= 2)
                ? authUser.displayName!.trim()
                : MockData.currentUser.fullName);
    final resolvedSenderPhone =
        (senderPhone != null && senderPhone.trim().isNotEmpty)
            ? senderPhone.trim()
            : (authUser?.phoneNumber?.trim().isNotEmpty == true
                ? authUser!.phoneNumber!.trim()
                : MockData.currentUser.phone);

    final resolvedDriverName = driverName.trim().isNotEmpty
        ? driverName.trim()
        : (ride?.driverName.trim() ?? '');
    final resolvedDriverId = (driverId != null && driverId.trim().isNotEmpty)
        ? driverId.trim()
        : ride?.driverId;
    final resolvedFrom = (fromCity != null && fromCity.trim().isNotEmpty)
        ? fromCity.trim()
        : ride?.fromCity;
    final resolvedTo = (toCity != null && toCity.trim().isNotEmpty)
        ? toCity.trim()
        : ride?.toCity;
    final resolvedStopover =
        (stopoverCity != null && stopoverCity.trim().isNotEmpty)
            ? stopoverCity.trim()
            : ride?.stopoverCity;

    final resolvedRoute = (route != null && route.trim().isNotEmpty)
        ? route.trim()
        : ((resolvedFrom != null && resolvedTo != null)
            ? '$resolvedFrom ← $resolvedTo${ride != null ? " · ${ride.departureTime}" : ""}'
            : 'Route Parcel');

    final resolvedFee = fee ?? ride?.parcelPrice ?? 25;
    final pickupOtp = _generate4DigitOtp();
    var deliveryOtp = _generate4DigitOtp();
    if (deliveryOtp == pickupOtp) {
      deliveryOtp = _generate4DigitOtp();
    }

    final initialStatus =
        (ride != null && ride.isInstantBooking && resolvedDriverName.isNotEmpty)
            ? ParcelStatusStep.accepted
            : ParcelStatusStep.requested;

    final newParcel = ParcelModel(
      id: 'parcel_${DateTime.now().millisecondsSinceEpoch}',
      senderId: resolvedSenderId,
      senderName: resolvedSenderName,
      senderPhone: resolvedSenderPhone,
      driverId: resolvedDriverId,
      driverName: resolvedDriverName,
      fromCity: resolvedFrom,
      toCity: resolvedTo,
      stopoverCity: resolvedStopover,
      route: resolvedRoute,
      description: description.trim(),
      size: size,
      weightKg: weightKg.clamp(0.1, 50.0),
      estimatedValue: estimatedValue.clamp(0, 100000),
      receiverName: receiverName.trim(),
      receiverPhone: receiverPhone.trim(),
      fee: resolvedFee.clamp(0, 10000),
      pickupOtp: pickupOtp,
      deliveryOtp: deliveryOtp,
      status: initialStatus,
    );
    _parcels.insert(0, newParcel);
    notifyListeners();
    AppRepositories.instance.parcels.createParcel(newParcel).ignore();
    return newParcel;
  }

  /// Matches an unassigned standalone route parcel request to a traveler's [RideModel].
  void assignTravelerToParcel({
    required String parcelId,
    required RideModel ride,
  }) {
    final index = _parcels.indexWhere((p) => p.id == parcelId);
    if (index == -1) return;
    final current = _parcels[index];
    _parcels[index] = current.copyWith(
      driverId: ride.driverId,
      driverName: ride.driverName,
      fromCity: current.fromCity ?? ride.fromCity,
      toCity: current.toCity ?? ride.toCity,
      route: '${ride.fromCity} ← ${ride.toCity} · ${ride.departureTime}',
      fee: ride.parcelPrice > 0 ? ride.parcelPrice : current.fee,
      status: ParcelStatusStep.accepted,
    );
    notifyListeners();
    AppRepositories.instance.parcels
        .updateParcelStatus(parcelId, ParcelStatusStep.accepted)
        .ignore();
  }

  Future<bool> verifyPickupOtp(String parcelId, String otp) async {
    final index = _parcels.indexWhere((p) => p.id == parcelId);
    if (index == -1) return false;
    final cleanInput = otp.replaceAll(' ', '').trim();
    final cleanStored = _parcels[index].pickupOtp.replaceAll(' ', '').trim();
    if (cleanInput.isEmpty || cleanInput != cleanStored) return false;

    _parcels[index] =
        _parcels[index].copyWith(status: ParcelStatusStep.handedOver);
    notifyListeners();
    AppRepositories.instance.parcels.verifyPickupOtp(parcelId, otp).ignore();
    return true;
  }

  Future<bool> verifyDeliveryOtp(String parcelId, String otp) async {
    final index = _parcels.indexWhere((p) => p.id == parcelId);
    if (index == -1) return false;
    final cleanInput = otp.replaceAll(' ', '').trim();
    final storedDelivery =
        _parcels[index].deliveryOtp?.replaceAll(' ', '').trim() ?? '';
    if (cleanInput.isEmpty) return false;
    if (storedDelivery.isNotEmpty && cleanInput != storedDelivery) {
      return false;
    }

    _parcels[index] =
        _parcels[index].copyWith(status: ParcelStatusStep.delivered);
    notifyListeners();
    AppRepositories.instance.parcels.verifyDeliveryOtp(parcelId, otp).ignore();
    return true;
  }

  void updateParcelStatus(String id, ParcelStatusStep newStatus) {
    final index = _parcels.indexWhere((p) => p.id == id);
    if (index != -1) {
      _parcels[index] = _parcels[index].copyWith(status: newStatus);
      notifyListeners();
      AppRepositories.instance.parcels.updateParcelStatus(id, newStatus).ignore();
    }
  }

  void cancelParcel(String id) {
    _parcels.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
