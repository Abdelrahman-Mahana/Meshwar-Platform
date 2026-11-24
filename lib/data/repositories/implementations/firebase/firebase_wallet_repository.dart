import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/wallet_transaction_model.dart';
import '../../contracts/i_wallet_repository.dart';
import '../../../services/firebase_firestore_service.dart';

class FirebaseWalletRepository implements IWalletRepository {
  final FirebaseFirestore? _injectedFirestore;

  FirebaseWalletRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  @override
  Future<double> getBalance(String userId) async {
    final doc = await _firestore.collection(FirestoreCollections.users).doc(userId).get();
    if (doc.exists && doc.data() != null) {
      final piastres = (doc.data()!['walletBalancePiastres'] as num?)?.toInt();
      if (piastres != null) {
        return piastres / 100.0;
      }
      return (doc.data()!['walletBalance'] as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  @override
  Future<List<WalletTransactionModel>> getTransactions(String userId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.walletTransactions)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(25)
        .get();

    return snapshot.docs.map((doc) => WalletTransactionModel.fromJson(doc.data())).toList();
  }

  @override
  Future<bool> deposit({
    required String userId,
    required double amount,
    required PaymentMethodType method,
    required String referenceNumber,
  }) async {
    final txRef = _firestore.collection(FirestoreCollections.walletTransactions).doc();
    final tx = WalletTransactionModel(
      id: txRef.id,
      userId: userId,
      amount: amount,
      type: TransactionType.deposit,
      method: method,
      referenceNumber: referenceNumber,
      status: TransactionStatus.pending,
      titleAr: 'طلب شحن محفظة قيد المراجعة',
      titleEn: 'Wallet Deposit Pending Review',
      timestamp: DateTime.now(),
    );

    await txRef.set(tx.toJson());
    return true;
  }

  @override
  Future<bool> withdraw({
    required String userId,
    required double amount,
    required PaymentMethodType method,
    required String destinationAccount,
  }) async {
    final currentBalance = await getBalance(userId);
    if (currentBalance < amount) return false;

    final txRef = _firestore.collection(FirestoreCollections.walletTransactions).doc();
    final tx = WalletTransactionModel(
      id: txRef.id,
      userId: userId,
      amount: amount,
      type: TransactionType.withdraw,
      method: method,
      referenceNumber: 'WD-${DateTime.now().millisecondsSinceEpoch % 1000000}',
      status: TransactionStatus.pending,
      titleAr: 'طلب سحب أرباح إلى $destinationAccount',
      titleEn: 'Withdrawal Request to $destinationAccount',
      timestamp: DateTime.now(),
    );

    await txRef.set(tx.toJson());
    return true;
  }
}
