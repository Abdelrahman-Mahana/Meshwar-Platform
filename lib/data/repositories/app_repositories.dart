import 'contracts/i_auth_repository.dart';
import 'contracts/i_rides_repository.dart';
import 'contracts/i_board_repository.dart';
import 'contracts/i_parcels_repository.dart';
import 'contracts/i_maps_repository.dart';
import 'contracts/i_chat_repository.dart';
import 'contracts/i_wallet_repository.dart';
import 'contracts/i_admin_repository.dart';
import 'contracts/i_worksite_repository.dart';
import 'contracts/i_provider_repository.dart';
import 'implementations/auth_repository_impl.dart';
import 'implementations/rides_repository_impl.dart';
import 'implementations/board_repository_impl.dart';
import 'implementations/parcels_repository_impl.dart';
import 'implementations/maps_repository_impl.dart';
import 'implementations/chat_repository_impl.dart';
import 'implementations/wallet_repository_impl.dart';
import 'implementations/admin_repository_impl.dart';
import 'implementations/worksite_repository_impl.dart';
import 'implementations/provider_repository_impl.dart';
import 'implementations/firebase/firebase_auth_repository.dart';
import 'implementations/firebase/firebase_rides_repository.dart';
import 'implementations/firebase/firebase_board_repository.dart';
import 'implementations/firebase/firebase_parcels_repository.dart';
import 'implementations/firebase/firebase_chat_repository.dart';
import 'implementations/firebase/firebase_wallet_repository.dart';
import 'implementations/firebase/firebase_admin_repository.dart';
import 'implementations/firebase/firebase_worksite_repository.dart';
import 'implementations/firebase/firebase_provider_repository.dart';

/// Central Dependency Injection & Repository Hub for MASHWAR Backend.
/// Allows zero-friction switching between Firebase, REST API, and Local/Mock implementations.
class AppRepositories {
  AppRepositories._();

  static final AppRepositories instance = AppRepositories._();

  late IAuthRepository auth = AuthRepositoryImpl();
  late IRidesRepository rides = RidesRepositoryImpl();
  late IBoardRepository board = BoardRepositoryImpl();
  late IParcelsRepository parcels = ParcelsRepositoryImpl();
  late IMapsRepository maps = MapsRepositoryImpl();
  late IChatRepository chat = ChatRepositoryImpl();
  late IWalletRepository wallet = WalletRepositoryImpl();
  late IAdminRepository admin = AdminRepositoryImpl();
  late IProviderRepository providers = ProviderRepositoryImpl();
  late IWorksiteRepository worksite = WorksiteRepositoryImpl(
    providerRepository: providers,
  );

  /// Switch all repositories to live production Firebase implementations.
  void useFirebase() {
    auth = FirebaseAuthRepository();
    rides = FirebaseRidesRepository();
    board = FirebaseBoardRepository();
    parcels = FirebaseParcelsRepository();
    chat = FirebaseChatRepository();
    wallet = FirebaseWalletRepository();
    maps = MapsRepositoryImpl();
    admin = FirebaseAdminRepository();
    providers = FirebaseProviderRepository();
    worksite = FirebaseWorksiteRepository();
  }

  /// Switch all repositories to local/offline mock implementations.
  ///
  /// Worksite and Auth dev mocks remain gated unless `APP_ENV=development`,
  /// `!USE_FIREBASE`, and `USE_DEV_MOCKS=true` (or explicit [allowDevMocks]).
  void useLocalMocks({
    bool? allowDevMocks,
    bool? seedSampleData,
  }) {
    auth = AuthRepositoryImpl(allowDevMocks: allowDevMocks);
    rides = RidesRepositoryImpl();
    board = BoardRepositoryImpl();
    parcels = ParcelsRepositoryImpl();
    chat = ChatRepositoryImpl();
    wallet = WalletRepositoryImpl();
    maps = MapsRepositoryImpl();
    admin = AdminRepositoryImpl();
    final devProviders = ProviderRepositoryImpl(
      allowDevMocks: allowDevMocks,
      seedSampleData: seedSampleData,
    );
    providers = devProviders;
    worksite = WorksiteRepositoryImpl(
      providerRepository: devProviders,
      allowDevMocks: allowDevMocks,
      seedSampleData: seedSampleData,
    );
  }

  /// Configure custom repository implementations (e.g. for Firebase or Testing).
  void configure({
    IAuthRepository? authRepo,
    IRidesRepository? ridesRepo,
    IBoardRepository? boardRepo,
    IParcelsRepository? parcelsRepo,
    IMapsRepository? mapsRepo,
    IChatRepository? chatRepo,
    IWalletRepository? walletRepo,
    IAdminRepository? adminRepo,
    IProviderRepository? providerRepo,
    IWorksiteRepository? worksiteRepo,
  }) {
    if (authRepo != null) auth = authRepo;
    if (ridesRepo != null) rides = ridesRepo;
    if (boardRepo != null) board = boardRepo;
    if (parcelsRepo != null) parcels = parcelsRepo;
    if (mapsRepo != null) maps = mapsRepo;
    if (chatRepo != null) chat = chatRepo;
    if (walletRepo != null) wallet = walletRepo;
    if (adminRepo != null) admin = adminRepo;
    if (providerRepo != null) providers = providerRepo;
    if (worksiteRepo != null) worksite = worksiteRepo;
  }
}
