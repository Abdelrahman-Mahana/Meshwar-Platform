import '../../models/parcel_model.dart';

abstract class IParcelsRepository {
  Future<List<ParcelModel>> getParcels();
  Future<ParcelModel?> getParcelDetails(String parcelId);
  Future<ParcelModel> createParcel(ParcelModel parcel);
  Future<bool> verifyPickupOtp(String parcelId, String otp);
  Future<bool> verifyDeliveryOtp(String parcelId, String otp);
  Future<bool> updateParcelStatus(String parcelId, ParcelStatusStep status);
}
