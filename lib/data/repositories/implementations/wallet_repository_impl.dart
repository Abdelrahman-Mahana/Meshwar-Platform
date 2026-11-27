import '../../models/wallet_transaction_model.dart';
import '../contracts/i_wallet_repository.dart';

class WalletRepositoryImpl implements IWalletRepository {
  double _balance = 450.0;
  int _txSeq = 2;

  final List<WalletTransactionModel> _transactions = [
    WalletTransactionModel(
      id: 'tx_1',
      userId: 'usr_me_01',
      amount: 150.0,
      type: TransactionType.deposit,
      method: PaymentMethodType.fawran,
      referenceNumber: 'FW-984210',
      titleAr: 'شحن محفظة عبر فوراً (Fawran)',
      titleEn: 'Wallet Deposit via Fawran',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ),
    WalletTransactionModel(
      id: 'tx_2',
      userId: 'usr_me_01',
      amount: 35.0,
      type: TransactionType.ridePayment,
      method: PaymentMethodType.cash,
      referenceNumber: 'RD-541290',
      titleAr: 'سفر تشاركي: الدوحة ← الخور',
      titleEn: 'Carpooling: Doha → Al Khor',
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static String _methodLabelAr(PaymentMethodType method) {
    switch (method) {
      case PaymentMethodType.fawran:
        return 'فوراً (Fawran)';
      case PaymentMethodType.qpay:
        return 'كيوباي (QPay)';
      case PaymentMethodType.skipCash:
      case PaymentMethodType.applePay:
        return 'سكيب كاش / Apple Pay';
      case PaymentMethodType.cash:
        return 'نقداً';
    }
  }

  static String _methodLabelEn(PaymentMethodType method) {
    switch (method) {
      case PaymentMethodType.fawran:
        return 'Fawran';
      case PaymentMethodType.qpay:
        return 'QPay';
      case PaymentMethodType.skipCash:
      case PaymentMethodType.applePay:
        return 'SkipCash / Apple Pay';
      case PaymentMethodType.cash:
        return 'Cash';
    }
  }

  @override
  Future<double> getBalance(String userId) async {
    return _balance;
  }

  @override
  Future<List<WalletTransactionModel>> getTransactions(String userId) async {
    return List<WalletTransactionModel>.unmodifiable(_transactions);
  }

  /// Syncs remote balance and transactions into local fallback cache when available.
  void syncRemoteSnapshot({
    double? balance,
    List<WalletTransactionModel>? remoteTransactions,
  }) {
    if (balance != null && balance >= 0) {
      _balance = balance;
    }
    if (remoteTransactions != null && remoteTransactions.isNotEmpty) {
      final byId = <String, WalletTransactionModel>{
        for (final tx in _transactions) tx.id: tx,
      };
      for (final tx in remoteTransactions) {
        if (tx.id.isNotEmpty) {
          byId[tx.id] = tx;
        }
      }
      final merged = byId.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _transactions
        ..clear()
        ..addAll(merged);
    }
  }

  @override
  Future<bool> deposit({
    required String userId,
    required double amount,
    required PaymentMethodType method,
    required String referenceNumber,
  }) async {
    if (amount <= 0) return false;
    final cleanUserId = userId.trim().isEmpty ? 'usr_me_01' : userId.trim();
    _balance += amount;
    _transactions.insert(
      0,
      WalletTransactionModel(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}_${++_txSeq}',
        userId: cleanUserId,
        amount: amount,
        type: TransactionType.deposit,
        method: method,
        referenceNumber: referenceNumber.trim().isEmpty
            ? 'DEP-${DateTime.now().millisecondsSinceEpoch % 1000000}'
            : referenceNumber.trim(),
        titleAr: 'شحن رصيد - ${_methodLabelAr(method)}',
        titleEn: 'Top-up - ${_methodLabelEn(method)}',
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
    if (amount <= 0 || _balance < amount) return false;
    final cleanUserId = userId.trim().isEmpty ? 'usr_me_01' : userId.trim();
    final dest = destinationAccount.trim().isEmpty
        ? _methodLabelEn(method)
        : destinationAccount.trim();
    _balance -= amount;
    _transactions.insert(
      0,
      WalletTransactionModel(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}_${++_txSeq}',
        userId: cleanUserId,
        amount: amount,
        type: TransactionType.withdraw,
        method: method,
        referenceNumber: 'WD-${DateTime.now().millisecondsSinceEpoch % 1000000}',
        titleAr: 'سحب رصيد إلى $dest',
        titleEn: 'Withdrawal to $dest',
        timestamp: DateTime.now(),
      ),
    );
    return true;
  }
}
