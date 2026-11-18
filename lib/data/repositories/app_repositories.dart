import 'contracts/i_auth_repository.dart';
import 'contracts/i_rides_repository.dart';
import 'contracts/i_board_repository.dart';
import 'contracts/i_parcels_repository.dart';
import 'contracts/i_maps_repository.dart';
import 'contracts/i_chat_repository.dart';
import 'contracts/i_wallet_repository.dart';
import 'implementations/auth_repository_impl.dart';
import 'implementations/rides_repository_impl.dart';
import 'implementations/board_repository_impl.dart';
import 'implementations/parcels_repository_impl.dart';
import 'implementations/maps_repository_impl.dart';
import 'implementations/chat_repository_impl.dart';
import 'implementations/wallet_repository_impl.dart';

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

  /// Configure custom repository implementations (e.g. for Firebase or Testing)
  void configure({
    IAuthRepository? authRepo,
    IRidesRepository? ridesRepo,
    IBoardRepository? boardRepo,
    IParcelsRepository? parcelsRepo,
    IMapsRepository? mapsRepo,
    IChatRepository? chatRepo,
    IWalletRepository? walletRepo,
  }) {
    if (authRepo != null) auth = authRepo;
    if (ridesRepo != null) rides = ridesRepo;
    if (boardRepo != null) board = boardRepo;
    if (parcelsRepo != null) parcels = parcelsRepo;
    if (mapsRepo != null) maps = mapsRepo;
    if (chatRepo != null) chat = chatRepo;
    if (walletRepo != null) wallet = walletRepo;
  }
}
