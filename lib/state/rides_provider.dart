import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models/ride_model.dart';
import '../data/repositories/app_repositories.dart';

enum RideMode {
  seats,   // مقاعد
  parcels, // طرود
}

enum SortOption {
  closestTime, // الأقرب وقتاً
  cheapest,    // الأرخص
}

class RidesProvider extends ChangeNotifier {
  RideMode _rideMode = RideMode.seats;
  String _fromCity = 'الدوحة';
  String _toCity = 'الخور';
  String _date = 'الجمعة 6 نوفمبر';
  int _seatsCount = 1;

  // Search Filters
  SortOption _sortBy = SortOption.closestTime;
  String _timeSlot = 'أي وقت';
  bool _filterAcceptsParcels = false;
  bool _filterLadiesOnly = false;
  bool _filterInstantBooking = false;

  final List<RideModel> _allRides = List.from(MockData.initialRides);
  final List<RideModel> _myPublishedRides = [MockData.initialRides.first];
  final List<RideModel> _bookedRides = [MockData.initialRides.first];
  RideModel? _activeBooking = MockData.initialRides.first;

  RideMode get rideMode => _rideMode;
  String get fromCity => _fromCity;
  String get toCity => _toCity;
  String get date => _date;
  int get seatsCount => _seatsCount;
  SortOption get sortBy => _sortBy;
  String get timeSlot => _timeSlot;
  bool get filterAcceptsParcels => _filterAcceptsParcels;
  bool get filterLadiesOnly => _filterLadiesOnly;
  bool get filterInstantBooking => _filterInstantBooking;
  RideModel? get activeBooking => _activeBooking;
  List<RideModel> get myPublishedRides => List.unmodifiable(_myPublishedRides);
  List<RideModel> get bookedRides => List.unmodifiable(_bookedRides);

  void setRideMode(RideMode mode) {
    _rideMode = mode;
    notifyListeners();
  }

  void setRoute({String? from, String? to}) {
    if (from != null) _fromCity = from;
    if (to != null) _toCity = to;
    notifyListeners();
  }

  void swapLocations() {
    final temp = _fromCity;
    _fromCity = _toCity;
    _toCity = temp;
    notifyListeners();
  }

  void setDate(String newDate) {
    _date = newDate;
    notifyListeners();
  }

  void setSeatsCount(int count) {
    _seatsCount = count;
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortBy = option;
    notifyListeners();
  }

  void setTimeSlot(String slot) {
    _timeSlot = slot;
    notifyListeners();
  }

  void toggleFilterAcceptsParcels() {
    _filterAcceptsParcels = !_filterAcceptsParcels;
    notifyListeners();
  }

  void toggleFilterLadiesOnly() {
    _filterLadiesOnly = !_filterLadiesOnly;
    notifyListeners();
  }

  void toggleFilterInstantBooking() {
    _filterInstantBooking = !_filterInstantBooking;
    notifyListeners();
  }

  void resetFilters() {
    _sortBy = SortOption.closestTime;
    _timeSlot = 'أي وقت';
    _filterAcceptsParcels = false;
    _filterLadiesOnly = false;
    _filterInstantBooking = false;
    notifyListeners();
  }

  List<RideModel> get filteredRides {
    var list = _allRides.where((r) {
      if (_filterAcceptsParcels && !r.acceptsParcels) return false;
      if (_filterLadiesOnly && !r.isLadiesOnly) return false;
      if (_filterInstantBooking && !r.isInstantBooking) return false;
      return true;
    }).toList();

    if (_sortBy == SortOption.cheapest) {
      list.sort((a, b) => a.pricePerSeat.compareTo(b.pricePerSeat));
    } else {
      // Prioritize exact corridor match first
      list.sort((a, b) {
        final aMatch = (a.fromCity == _fromCity && a.toCity == _toCity) ? 1 : 0;
        final bMatch = (b.fromCity == _fromCity && b.toCity == _toCity) ? 1 : 0;
        return bMatch.compareTo(aMatch);
      });
    }
    return list;
  }

  void bookRide(RideModel ride) {
    _activeBooking = ride;
    if (!_bookedRides.any((r) => r.id == ride.id)) {
      _bookedRides.insert(0, ride);
    }
    notifyListeners();
    // Sync with backend repository
    AppRepositories.instance.rides.bookRide(
      rideId: ride.id,
      seats: _seatsCount,
      pickupLocation: ride.pickupPoint,
      dropoffLocation: ride.dropoffPoint,
    ).ignore();
  }

  void confirmBooking(RideModel ride) {
    _activeBooking = ride;
    if (!_bookedRides.any((r) => r.id == ride.id)) {
      _bookedRides.insert(0, ride);
    }
    notifyListeners();
    AppRepositories.instance.rides.bookRide(
      rideId: ride.id,
      seats: _seatsCount,
      pickupLocation: ride.pickupPoint,
      dropoffLocation: ride.dropoffPoint,
    ).ignore();
  }

  void cancelBooking() {
    if (_activeBooking != null) {
      final cancelledId = _activeBooking!.id;
      _bookedRides.removeWhere((r) => r.id == cancelledId);
      _activeBooking = null;
      notifyListeners();
      AppRepositories.instance.rides.cancelBooking(cancelledId).ignore();
    } else {
      _activeBooking = null;
      notifyListeners();
    }
  }

  RideModel publishRide({
    required String driverName,
    required String driverCar,
    required String driverPhone,
    required String fromCity,
    required String toCity,
    required String pickupPoint,
    required String dropoffPoint,
    required String departureTime,
    required String departureDate,
    required int availableSeats,
    required int pricePerSeat,
    required bool acceptsParcels,
    required int parcelPrice,
    required bool isLadiesOnly,
    required bool isInstantBooking,
  }) {
    final newRide = RideModel(
      id: 'ride_${DateTime.now().millisecondsSinceEpoch}',
      driverName: driverName,
      driverCar: driverCar,
      driverPhone: driverPhone,
      fromCity: fromCity,
      toCity: toCity,
      pickupPoint: pickupPoint,
      dropoffPoint: dropoffPoint,
      departureTime: departureTime,
      departureDate: departureDate,
      remainingSeats: availableSeats,
      pricePerSeat: pricePerSeat,
      acceptsParcels: acceptsParcels,
      parcelPrice: parcelPrice,
      isVerified: true,
      isLadiesOnly: isLadiesOnly,
      isInstantBooking: isInstantBooking,
      driverRating: 4.9,
    );
    _allRides.insert(0, newRide);
    _myPublishedRides.insert(0, newRide);
    notifyListeners();
    AppRepositories.instance.rides.publishRide(newRide).ignore();
    return newRide;
  }

  void rescheduleRide({
    required String rideId,
    required String newDate,
    required String newTime,
  }) {
    final idx = _allRides.indexWhere((r) => r.id == rideId);
    if (idx != -1) {
      _allRides[idx] = _allRides[idx].copyWith(
        departureDate: newDate,
        departureTime: newTime,
      );
    }
    final pubIdx = _myPublishedRides.indexWhere((r) => r.id == rideId);
    if (pubIdx != -1) {
      _myPublishedRides[pubIdx] = _myPublishedRides[pubIdx].copyWith(
        departureDate: newDate,
        departureTime: newTime,
      );
    }
    final bookIdx = _bookedRides.indexWhere((r) => r.id == rideId);
    if (bookIdx != -1) {
      _bookedRides[bookIdx] = _bookedRides[bookIdx].copyWith(
        departureDate: newDate,
        departureTime: newTime,
      );
    }
    if (_activeBooking != null && _activeBooking!.id == rideId) {
      _activeBooking = _activeBooking!.copyWith(
        departureDate: newDate,
        departureTime: newTime,
      );
    }
    notifyListeners();
  }
}


