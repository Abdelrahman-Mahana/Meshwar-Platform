import '../../models/parcel_model.dart';
import '../../mock_data.dart';
import '../contracts/i_parcels_repository.dart';

class ParcelsRepositoryImpl implements IParcelsRepository {
  final List<ParcelModel> _parcels = [MockData.activeParcel];

  @override
  Future<List<ParcelModel>> getParcels() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _parcels;
  }

  @override
  Future<ParcelModel?> getParcelDetails(String parcelId) async {
    try {
      return _parcels.firstWhere((p) => p.id == parcelId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ParcelModel> createParcel(ParcelModel parcel) async {
    await Future.delayed(const Duration(milliseconds: 350));
    _parcels.insert(0, parcel);
    return parcel;
  }

  @override
  Future<bool> verifyPickupOtp(String parcelId, String otp) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _parcels.indexWhere((p) => p.id == parcelId);
    if (index != -1 && _parcels[index].pickupOtp == otp) {
      _parcels[index] = _parcels[index].copyWith(status: ParcelStatusStep.handedOver);
      return true;
    }
    return false;
  }

  @override
  Future<bool> verifyDeliveryOtp(String parcelId, String otp) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _parcels.indexWhere((p) => p.id == parcelId);
    if (index != -1) {
      _parcels[index] = _parcels[index].copyWith(status: ParcelStatusStep.delivered);
      return true;
    }
    return false;
  }

  @override
  Future<bool> updateParcelStatus(String parcelId, ParcelStatusStep status) async {
    final index = _parcels.indexWhere((p) => p.id == parcelId);
    if (index != -1) {
      _parcels[index] = _parcels[index].copyWith(status: status);
      return true;
    }
    return false;
  }
}
