import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models/ride_model.dart';

enum RideMode {
  seats,   // كراسي
  parcels, // طرود
}

enum SortOption {
  closestTime, // الأقرب وقتاً
  cheapest,    // الأرخص
}

class RidesProvider extends ChangeNotifier {
  RideMode _rideMode = RideMode.seats;
  String _fromCity = 'كفر الشيخ';
  String _toCity = 'القاهرة';
  String _date = 'الجمعة 6 نوفمبر';
  int _seatsCount = 1;

  // Search Filters
  SortOption _sortBy = SortOption.closestTime;
  String _timeSlot = 'أي وقت';
  bool _filterAcceptsParcels = false;
  bool _filterLadiesOnly = false;
  bool _filterInstantBooking = false;

  final List<RideModel> _allRides = List.from(MockData.initialRides);
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

  void setRideMode(RideMode mode) {
    _rideMode = mode;
    notifyListeners();
  }

  void setRoute({String? from, String? to}) {
    if (from != null) _fromCity = from;
    if (to != null) _toCity = to;
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
    }
    return list;
  }

  void bookRide(RideModel ride) {
    _activeBooking = ride;
    notifyListeners();
  }

  void confirmBooking(RideModel ride) {
    _activeBooking = ride;
    notifyListeners();
  }

  void cancelBooking() {
    _activeBooking = null;
    notifyListeners();
  }
}

