import '../../models/wallet_transaction_model.dart';

abstract class IWalletRepository {
  Future<double> getBalance(String userId);
  Future<List<WalletTransactionModel>> getTransactions(String userId);
  Future<bool> deposit({
    required String userId,
    required double amount,
    required PaymentMethodType method,
    required String referenceNumber,
  });
  Future<bool> withdraw({
    required String userId,
    required double amount,
    required PaymentMethodType method,
    required String destinationAccount,
  });
}
