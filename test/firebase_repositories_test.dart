import 'package:flutter_test/flutter_test.dart';
import 'package:mashwar/data/repositories/app_repositories.dart';
import 'package:mashwar/data/repositories/contracts/i_auth_repository.dart';
import 'package:mashwar/data/repositories/contracts/i_rides_repository.dart';
import 'package:mashwar/data/repositories/contracts/i_board_repository.dart';
import 'package:mashwar/data/repositories/contracts/i_parcels_repository.dart';
import 'package:mashwar/data/repositories/contracts/i_wallet_repository.dart';
import 'package:mashwar/data/repositories/contracts/i_chat_repository.dart';
import 'package:mashwar/data/repositories/contracts/i_provider_repository.dart';
import 'package:mashwar/data/repositories/contracts/i_worksite_repository.dart';
import 'package:mashwar/data/repositories/implementations/provider_repository_impl.dart';

void main() {
  group('AppRepositories Factory & DI Tests', () {
    test('Default repositories are configured and satisfy contracts', () {
      final repos = AppRepositories.instance;

      expect(repos.auth, isA<IAuthRepository>());
      expect(repos.rides, isA<IRidesRepository>());
      expect(repos.board, isA<IBoardRepository>());
      expect(repos.parcels, isA<IParcelsRepository>());
      expect(repos.wallet, isA<IWalletRepository>());
      expect(repos.chat, isA<IChatRepository>());
      expect(repos.providers, isA<IProviderRepository>());
      expect(repos.worksite, isA<IWorksiteRepository>());
    });

    test('useLocalMocks initializes all mock repositories', () {
      final repos = AppRepositories.instance;
      repos.useLocalMocks();

      expect(repos.auth, isNotNull);
      expect(repos.rides, isNotNull);
      expect(repos.board, isNotNull);
      expect(repos.parcels, isNotNull);
      expect(repos.wallet, isNotNull);
      expect(repos.chat, isNotNull);
      expect(repos.providers, isA<IProviderRepository>());
      expect(repos.worksite, isA<IWorksiteRepository>());
    });

    test('Explicit dev-mock worksite and provider repositories coordinate cleanly', () async {
      final repos = AppRepositories.instance;
      repos.useLocalMocks(allowDevMocks: true);

      final pilotSupplier = await repos.providers.getProviderProfile(
        ProviderRepositoryImpl.pilotApprovedProviderId,
      );
      expect(pilotSupplier, isNotNull);
      expect(pilotSupplier!.canAcceptWorksiteJobs, isTrue);

      final openRequests = await repos.worksite.listRequests();
      expect(openRequests, isNotEmpty);

      // Reset to default gated mocks after explicit dev test
      repos.useLocalMocks();
    });

    test('Local mock rides repository searches rides', () async {
      final repos = AppRepositories.instance;
      repos.useLocalMocks();

      final rides = await repos.rides.searchRides(
        fromCity: '',
        toCity: '',
      );
      expect(rides, isNotEmpty);
      expect(rides.first.pricePerSeat, greaterThan(0));
    });

    test('Local mock parcels repository retrieves initial parcels', () async {
      final repos = AppRepositories.instance;
      repos.useLocalMocks();

      final parcels = await repos.parcels.getParcels();
      expect(parcels, isNotEmpty);
      expect(parcels.first.fee, greaterThan(0));
    });

    test('Local mock board repository retrieves initial ads', () async {
      final repos = AppRepositories.instance;
      repos.useLocalMocks();

      final ads = await repos.board.getBoardAds();
      expect(ads, isNotEmpty);
    });

    test('Local mock wallet repository retrieves user balance and transactions', () async {
      final repos = AppRepositories.instance;
      repos.useLocalMocks();

      final balance = await repos.wallet.getBalance('u1');
      expect(balance, greaterThanOrEqualTo(0.0));

      final txs = await repos.wallet.getTransactions('u1');
      expect(txs, isA<List>());
    });
  });
}
