import '../../models/worksite_models.dart';

/// Repository contract for Qatar Worksite Supply provider profiles,
/// QID verification review workflows, and saved requester worksites.
abstract class IProviderRepository {
  Future<ProviderProfile?> getProviderProfile(String userId);

  Future<ProviderProfile> upsertProviderProfile(ProviderProfile profile);

  Future<ProviderProfile> submitProviderVerification({
    required String userId,
    required String qidNumber,
    required String qidFrontUrl,
    required String qidBackUrl,
    String? selfieUrl,
    String? vehicleType,
    String? vehiclePlate,
    List<String> serviceMunicipalities = const [],
    List<String> supplySpecialties = const [],
  });

  Future<List<ProviderProfile>> listPendingVerifications({int limit = 50});

  Future<ProviderProfile> reviewProviderApproval({
    required String userId,
    required ProviderApprovalStatus decision,
    required String reviewerId,
    String? reason,
  });

  Future<SavedWorksite> saveWorksite(SavedWorksite worksite);

  Future<List<SavedWorksite>> listSavedWorksites(String ownerUserId);
}
