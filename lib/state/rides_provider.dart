import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../core/config/app_environment.dart';
import '../data/mock_data.dart';
import '../data/models/ride_model.dart';
import '../data/repositories/app_repositories.dart';
import '../data/repositories/implementations/rides_repository_impl.dart';

enum RideMode {
  seats, // مقاعد
  parcels, // طرود
}

enum SortOption {
  closestTime, // الأقرب وقتاً
  cheapest, // الأرخص
}

class RideRatingRecord {
  final String rideId;
  final String driverName;
  final int rating;
  final List<String> tags;
  final int tipAmount;
  final String comment;
  final bool isParcel;
  final DateTime submittedAt;

  const RideRatingRecord({
    required this.rideId,
    required this.driverName,
    required this.rating,
    this.tags = const [],
    this.tipAmount = 0,
    this.comment = '',
    this.isParcel = false,
    required this.submittedAt,
  });
}

class RidesProvider extends ChangeNotifier {
  static bool get _isLiveBackendMode =>
      AppEnvironment.isFirebaseRuntimeActive ||
      AppEnvironment.flavor != AppFlavor.development;

  String? _boundUserId;
  RideMode _rideMode = RideMode.seats;
  String _fromCity = '';
  String _toCity = '';
  String _date = 'الجمعة 6 نوفمبر';
  int _seatsCount = 1;
  bool _isLoading = false;

  // Search Filters
  SortOption _sortBy = SortOption.closestTime;
  String _timeSlot = 'أي وقت';
  bool _filterAcceptsParcels = false;
  bool _filterLadiesOnly = false;
  bool _filterInstantBooking = false;

  final List<RideModel> _allRides = [];
  final List<RideModel> _myPublishedRides = [];
  final List<RideModel> _bookedRides = [];
  RideModel? _activeBooking;
  final Map<String, RideRatingRecord> _rideRatings = {};

  RidesProvider({String? initialUserId})
      : _boundUserId =
            (initialUserId != null && initialUserId.trim().isNotEmpty)
                ? initialUserId.trim()
                : null {
    if (!_isLiveBackendMode) {
      _allRides.addAll(MockData.initialRides);
      _myPublishedRides.addAll([
        MockData.initialRides.first,
        if (MockData.initialRides.length > 4) MockData.initialRides[4],
      ]);
      _bookedRides.addAll([
        MockData.initialRides.first,
        if (MockData.initialRides.length > 1) MockData.initialRides[1],
        if (MockData.initialRides.last.status == 'completed')
          MockData.initialRides.last,
      ]);
      _activeBooking = MockData.initialRides.first;
    }
  }

  /// Syncs active auth user identity from [AuthProvider], clearing any previous
  /// account's personal rides, bookings, and ratings on sign-out or user switch.
  void syncAuthSession({required String? uid}) {
    final clean = uid?.trim();
    final normalizedNext =
        (clean != null && clean.isNotEmpty) ? clean : null;
    final previousUid = _boundUserId;
    _boundUserId = normalizedNext;

    final uidChanged = previousUid != normalizedNext;
    final shouldClearOnNull = normalizedNext == null &&
        (_isLiveBackendMode || uidChanged) &&
        (_myPublishedRides.isNotEmpty ||
            _bookedRides.isNotEmpty ||
            _activeBooking != null ||
            _rideRatings.isNotEmpty);

    if (uidChanged || shouldClearOnNull) {
      _myPublishedRides.clear();
      _bookedRides.clear();
      _activeBooking = null;
      _rideRatings.clear();
      notifyListeners();
    }
  }

  RideMode get rideMode => _rideMode;
  String get fromCity => _fromCity;
  String get toCity => _toCity;
  String get date => _date;
  int get seatsCount => _seatsCount;
  bool get isLoading => _isLoading;
  SortOption get sortBy => _sortBy;
  String get timeSlot => _timeSlot;
  bool get filterAcceptsParcels => _filterAcceptsParcels;
  bool get filterLadiesOnly => _filterLadiesOnly;
  bool get filterInstantBooking => _filterInstantBooking;
  bool get hasCorridorQuery =>
      _fromCity.trim().isNotEmpty || _toCity.trim().isNotEmpty;
  RideModel? get activeBooking => _activeBooking;
  List<RideModel> get allRides => List.unmodifiable(_allRides);
  List<RideModel> get myPublishedRides => List.unmodifiable(_myPublishedRides);
  List<RideModel> get bookedRides => List.unmodifiable(_bookedRides);
  Map<String, RideRatingRecord> get rideRatings =>
      Map.unmodifiable(_rideRatings);

  RideRatingRecord? ratingForRide(String rideId) => _rideRatings[rideId];

  static const Map<String, List<String>> _cityAliases = {
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

  static bool _matchesCityField(String query, List<String?> candidates) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;

    final expandedQueries = <String>{q};
    for (final entry in _cityAliases.entries) {
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

  /// Fetches live rides from [AppRepositories.instance.rides].
  /// In live Firebase/production mode, never merges [MockData.initialRides].
  Future<void> loadRides() async {
    _isLoading = true;
    notifyListeners();
    try {
      final repo = AppRepositories.instance.rides;
      if (_isLiveBackendMode) {
        final results = await Future.wait<List<RideModel>>([
          repo.searchRides(fromCity: '', toCity: ''),
          repo.getMyBookedRides(),
          repo.getMyDriverRides(),
        ]);
        final remotePublic = results[0];
        final remoteBooked = results[1];
        final remoteDriver = results[2];

        final driverById = <String, RideModel>{
          for (final ride in remoteDriver)
            if (ride.id.isNotEmpty) ride.id: ride,
        };
        for (final local in _myPublishedRides) {
          if (local.id.isNotEmpty) {
            driverById.putIfAbsent(local.id, () => local);
          }
        }
        _myPublishedRides
          ..clear()
          ..addAll(driverById.values);

        final bookedById = <String, RideModel>{
          for (final ride in remoteBooked)
            if (ride.id.isNotEmpty) ride.id: ride,
        };
        for (final local in _bookedRides) {
          if (local.id.isNotEmpty) {
            bookedById.putIfAbsent(local.id, () => local);
          }
        }
        _bookedRides
          ..clear()
          ..addAll(bookedById.values);

        if (_activeBooking != null &&
            !_bookedRides.any((r) => r.id == _activeBooking!.id)) {
          _activeBooking = null;
        }
        if (_activeBooking == null) {
          for (final r in _bookedRides) {
            if (r.status != 'cancelled' && r.status != 'completed') {
              _activeBooking = r;
              break;
            }
          }
        }

        final publicById = <String, RideModel>{
          for (final ride in remotePublic)
            if (ride.id.isNotEmpty) ride.id: ride,
        };
        for (final own in _myPublishedRides) {
          if (own.id.isNotEmpty) {
            publicById.putIfAbsent(own.id, () => own);
          }
        }
        _allRides
          ..clear()
          ..addAll(publicById.values);
        return;
      }

      final remoteRides = await repo.searchRides(
        fromCity: '',
        toCity: '',
      );
      final mergedById = <String, RideModel>{};
      for (final ride in remoteRides) {
        if (ride.id.isNotEmpty) {
          mergedById[ride.id] = ride;
        }
      }
      for (final local in _myPublishedRides) {
        mergedById.putIfAbsent(local.id, () => local);
      }
      for (final seed in MockData.initialRides) {
        mergedById.putIfAbsent(seed.id, () => seed);
      }
      _allRides
        ..clear()
        ..addAll(mergedById.values);
    } catch (_) {
      if (!_isLiveBackendMode && _allRides.isEmpty) {
        _allRides.addAll(MockData.initialRides);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets or clears active corridor search (`from` / `to`). Passing empty
  /// strings or omitting parameters returns to browsing all available trips.
  void searchCorridor({String? from, String? to}) {
    _fromCity = (from ?? '').trim();
    _toCity = (to ?? '').trim();
    notifyListeners();
  }

  void clearRoute() {
    _fromCity = '';
    _toCity = '';
    notifyListeners();
  }

  void setRideMode(RideMode mode) {
    _rideMode = mode;
    if (mode == RideMode.parcels) {
      _filterAcceptsParcels = true;
    }
    notifyListeners();
  }

  void setRoute({String? from, String? to}) {
    if (from != null) _fromCity = from.trim();
    if (to != null) _toCity = to.trim();
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
    _seatsCount = count.clamp(1, 10);
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

  void setFilterAcceptsParcels(bool value) {
    _filterAcceptsParcels = value;
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
    final fromQ = _fromCity.trim();
    final toQ = _toCity.trim();

    final list = _allRides.where((r) {
      if (r.status == 'cancelled' || r.status == 'completed') return false;
      if ((_filterAcceptsParcels || _rideMode == RideMode.parcels) &&
          !r.acceptsParcels) {
        return false;
      }
      if (_filterLadiesOnly && !r.isLadiesOnly) return false;
      if (_filterInstantBooking && !r.isInstantBooking) return false;

      if (fromQ.isNotEmpty) {
        final matchesOrigin = _matchesCityField(
          fromQ,
          [r.fromCity, r.pickupPoint, r.stopoverCity],
        );
        if (!matchesOrigin) return false;
      }

      if (toQ.isNotEmpty) {
        final matchesDest = _matchesCityField(
          toQ,
          [r.toCity, r.dropoffPoint, r.stopoverCity],
        );
        if (!matchesDest) return false;
      }

      return true;
    }).toList();

    if (_sortBy == SortOption.cheapest) {
      list.sort((a, b) => a.pricePerSeat.compareTo(b.pricePerSeat));
    } else if (fromQ.isNotEmpty || toQ.isNotEmpty) {
      // Rank exact city-to-city matches above partial/stopover matches.
      list.sort((a, b) {
        final aExact = ((fromQ.isEmpty || a.fromCity == fromQ) &&
                (toQ.isEmpty || a.toCity == toQ))
            ? 1
            : 0;
        final bExact = ((fromQ.isEmpty || b.fromCity == fromQ) &&
                (toQ.isEmpty || b.toCity == toQ))
            ? 1
            : 0;
        return bExact.compareTo(aExact);
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
    AppRepositories.instance.rides
        .bookRide(
          rideId: ride.id,
          seats: _seatsCount,
          pickupLocation: ride.pickupPoint,
          dropoffLocation: ride.dropoffPoint,
        )
        .ignore();
  }

  void confirmBooking(RideModel ride) {
    bookRide(ride);
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

  /// Marks a ride as completed in memory and syncs gracefully with [AppRepositories.instance.rides].
  RideModel? completeRide(String rideId, {RideModel? fallbackRide}) {
    RideModel? updated;

    final allIdx = _allRides.indexWhere((r) => r.id == rideId);
    if (allIdx != -1) {
      updated = _allRides[allIdx].copyWith(status: 'completed');
      _allRides[allIdx] = updated;
    }

    final pubIdx = _myPublishedRides.indexWhere((r) => r.id == rideId);
    if (pubIdx != -1) {
      updated = _myPublishedRides[pubIdx].copyWith(status: 'completed');
      _myPublishedRides[pubIdx] = updated;
    }

    final bookIdx = _bookedRides.indexWhere((r) => r.id == rideId);
    if (bookIdx != -1) {
      updated = _bookedRides[bookIdx].copyWith(status: 'completed');
      _bookedRides[bookIdx] = updated;
    } else if (fallbackRide != null) {
      updated ??= fallbackRide.copyWith(status: 'completed');
      _bookedRides.insert(0, updated);
    }

    if (_activeBooking != null && _activeBooking!.id == rideId) {
      updated ??= _activeBooking!.copyWith(status: 'completed');
      _activeBooking = updated;
    }

    notifyListeners();

    if (updated != null) {
      final repo = AppRepositories.instance.rides;
      if (repo is! RidesRepositoryImpl) {
        repo.publishRide(updated).ignore();
      }
    }
    return updated;
  }

  /// Persists a passenger/sender trip rating, updates the driver's average rating & ride status,
  /// and syncs gracefully with [AppRepositories.instance.rides].
  Future<RideModel?> submitRideRating({
    String? rideId,
    String? driverName,
    required int rating,
    List<String> tags = const [],
    int tipAmount = 0,
    String? comment,
    bool isParcel = false,
  }) async {
    final clampedRating = rating.clamp(1, 5);
    final cleanId = rideId?.trim() ?? '';
    final cleanDriver = driverName?.trim() ?? '';

    RideModel? target;
    if (cleanId.isNotEmpty) {
      for (final r in [
        ..._bookedRides,
        ..._allRides,
        ..._myPublishedRides,
        if (_activeBooking != null) _activeBooking!,
      ]) {
        if (r.id == cleanId) {
          target = r;
          break;
        }
      }
    }

    if (target == null && cleanDriver.isNotEmpty) {
      for (final r in [
        if (_activeBooking != null) _activeBooking!,
        ..._bookedRides,
        ..._allRides,
      ]) {
        if (r.driverName.trim().toLowerCase() == cleanDriver.toLowerCase()) {
          target = r;
          break;
        }
      }
    }

    target ??= _activeBooking ??
        (_bookedRides.isNotEmpty
            ? _bookedRides.first
            : (_allRides.isNotEmpty ? _allRides.first : null));

    final recordId = target?.id ??
        (cleanId.isNotEmpty
            ? cleanId
            : 'review_${DateTime.now().millisecondsSinceEpoch}');

    _rideRatings[recordId] = RideRatingRecord(
      rideId: recordId,
      driverName: target?.driverName ??
          (cleanDriver.isNotEmpty ? cleanDriver : 'MASHWAR Captain'),
      rating: clampedRating,
      tags: List<String>.unmodifiable(tags),
      tipAmount: tipAmount.clamp(0, 5000),
      comment: comment?.trim() ?? '',
      isParcel: isParcel,
      submittedAt: DateTime.now(),
    );

    if (target == null) {
      notifyListeners();
      return null;
    }

    final newDriverRating = double.parse(
      (((target.driverRating * 4) + clampedRating) / 5)
          .clamp(1.0, 5.0)
          .toStringAsFixed(2),
    );
    final cleanComment = comment?.trim() ?? '';
    final feedbackParts = <String>[
      if (tags.isNotEmpty) tags.join('، '),
      if (cleanComment.isNotEmpty) cleanComment,
    ];
    final updatedNotes = feedbackParts.isNotEmpty
        ? feedbackParts.join(' — ')
        : target.notes;

    final updatedRide = target.copyWith(
      driverRating: newDriverRating,
      status: 'completed',
      notes: updatedNotes,
    );

    void updateList(List<RideModel> list) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].id == updatedRide.id) {
          list[i] = updatedRide;
        } else if (list[i].driverName == updatedRide.driverName) {
          list[i] = list[i].copyWith(driverRating: newDriverRating);
        }
      }
    }

    updateList(_allRides);
    updateList(_myPublishedRides);
    updateList(_bookedRides);
    if (!_bookedRides.any((r) => r.id == updatedRide.id)) {
      _bookedRides.insert(0, updatedRide);
    }
    if (_activeBooking != null && _activeBooking!.id == updatedRide.id) {
      _activeBooking = updatedRide;
    }

    notifyListeners();

    try {
      final repo = AppRepositories.instance.rides;
      if (repo is! RidesRepositoryImpl) {
        await repo.publishRide(updatedRide);
      } else {
        await repo.getRideDetails(updatedRide.id);
      }
    } catch (_) {
      // Keep local optimistic rating & completed status intact when offline.
    }

    return updatedRide;
  }

  String? _resolveCurrentAuthUid() {
    try {
      if (Firebase.apps.isEmpty) return null;
      final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid;
      return (uid != null && uid.isNotEmpty) ? uid : null;
    } catch (_) {
      return null;
    }
  }

  RideModel publishRide({
    String? driverId,
    required String driverName,
    required String driverCar,
    required String driverPhone,
    required String fromCity,
    required String toCity,
    String? stopover,
    String? stopoverCity,
    String pickupPoint = '',
    String dropoffPoint = '',
    required String departureTime,
    required String departureDate,
    required int availableSeats,
    required int pricePerSeat,
    bool acceptsParcels = true,
    int parcelPrice = 20,
    String? maxParcelSize,
    String? notes,
    bool isLadiesOnly = false,
    bool isInstantBooking = true,
  }) {
    final resolvedStopover =
        (stopoverCity != null && stopoverCity.trim().isNotEmpty)
            ? stopoverCity.trim()
            : ((stopover != null && stopover.trim().isNotEmpty)
                ? stopover.trim()
                : null);
    final resolvedDriverId = (driverId != null && driverId.trim().isNotEmpty)
        ? driverId.trim()
        : (_resolveCurrentAuthUid() ??
            _boundUserId ??
            (_isLiveBackendMode ? '' : MockData.currentUser.id));

    final newRide = RideModel(
      id: 'ride_${DateTime.now().millisecondsSinceEpoch}',
      driverId: resolvedDriverId,
      driverName: driverName.trim().isNotEmpty
          ? driverName.trim()
          : (_isLiveBackendMode ? '' : MockData.currentUser.fullName),
      driverCar: driverCar.trim().isNotEmpty ? driverCar.trim() : 'Sedan',
      driverPhone: driverPhone.trim().isNotEmpty
          ? driverPhone.trim()
          : (_isLiveBackendMode ? '' : MockData.currentUser.phone),
      fromCity: fromCity.trim(),
      toCity: toCity.trim(),
      stopoverCity: resolvedStopover,
      pickupPoint:
          pickupPoint.trim().isNotEmpty ? pickupPoint.trim() : fromCity.trim(),
      dropoffPoint:
          dropoffPoint.trim().isNotEmpty ? dropoffPoint.trim() : toCity.trim(),
      departureTime: departureTime.trim(),
      departureDate: departureDate.trim(),
      remainingSeats: availableSeats.clamp(1, 10),
      pricePerSeat: pricePerSeat.clamp(0, 5000),
      acceptsParcels: acceptsParcels,
      parcelPrice: acceptsParcels ? parcelPrice.clamp(0, 5000) : 0,
      maxParcelSize: maxParcelSize,
      notes: (notes != null && notes.trim().isNotEmpty) ? notes.trim() : null,
      isVerified: true,
      isLadiesOnly: isLadiesOnly,
      isInstantBooking: isInstantBooking,
      driverRating: 4.9,
      status: 'active',
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
