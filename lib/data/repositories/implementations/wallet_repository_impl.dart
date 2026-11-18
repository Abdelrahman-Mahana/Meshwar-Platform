import '../../models/wallet_transaction_model.dart';
import '../contracts/i_wallet_repository.dart';

class WalletRepositoryImpl implements IWalletRepository {
  double _balance = 450.0;
  final List<WalletTransactionModel> _transactions = [
    WalletTransactionModel(
      id: 'tx_1',
      userId: 'usr_me_01',
      amount: 150.0,
      type: TransactionType.deposit,
      method: PaymentMethodType.instapay,
      referenceNumber: 'IP-984210',
      titleAr: 'شحن محفظة عبر إنستاباي',
      titleEn: 'Wallet Deposit via InstaPay',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ),
    WalletTransactionModel(
      id: 'tx_2',
      userId: 'usr_me_01',
      amount: 70.0,
      type: TransactionType.ridePayment,
      method: PaymentMethodType.cash,
      referenceNumber: 'RD-541290',
      titleAr: 'سفر تشاركي: كفر الشيخ ← القاهرة',
      titleEn: 'Carpooling: Kafr El-Sheikh ← Cairo',
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  @override
  Future<double> getBalance(String userId) async {
    return _balance;
  }

  @override
  Future<List<WalletTransactionModel>> getTransactions(String userId) async {
    return _transactions;
  }

  @override
  Future<bool> deposit({
    required String userId,
    required double amount,
    required PaymentMethodType method,
    required String referenceNumber,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _balance += amount;
    _transactions.insert(
      0,
      WalletTransactionModel(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        amount: amount,
        type: TransactionType.deposit,
        method: method,
        referenceNumber: referenceNumber,
        titleAr: 'شحن رصيد للمحفظة',
        titleEn: 'Wallet Deposit',
        timestamp: DateTime.now(),
      ),
    );
    return true;
  }

  @override
  Future<bool> withdraw({
    required String userId,
    required double amount,
    required PaymentMethodType method,
    required String destinationAccount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_balance >= amount) {
      _balance -= amount;
      _transactions.insert(
        0,
        WalletTransactionModel(
          id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          amount: amount,
          type: TransactionType.withdraw,
          method: method,
          referenceNumber: 'WD-${DateTime.now().millisecondsSinceEpoch % 1000000}',
          titleAr: 'طلب سحب أرباح إلى $destinationAccount',
          titleEn: 'Withdrawal to $destinationAccount',
          timestamp: DateTime.now(),
        ),
      );
      return true;
    }
    return false;
  }
}
