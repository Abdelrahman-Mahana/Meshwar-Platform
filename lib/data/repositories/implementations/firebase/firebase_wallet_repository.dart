import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/config/app_environment.dart';
import '../../../models/wallet_transaction_model.dart';
import '../../../services/firebase_firestore_service.dart';
import '../../contracts/i_wallet_repository.dart';
import '../wallet_repository_impl.dart';

class FirebaseWalletRepository implements IWalletRepository {
  final FirebaseFirestore? _injectedFirestore;
  final WalletRepositoryImpl _localFallback = WalletRepositoryImpl();

  FirebaseWalletRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  bool get _isLiveBackendMode =>
      AppEnvironment.isFirebaseRuntimeActive ||
      AppEnvironment.flavor != AppFlavor.development;

  bool get _canUseFirestore {
    if (_injectedFirestore != null) return true;
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String? get _currentAuthUid {
    try {
      if (Firebase.apps.isEmpty) return null;
      final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid;
      return (uid != null && uid.trim().isNotEmpty) ? uid.trim() : null;
    } catch (_) {
      return null;
    }
  }

  bool get _isFirestoreSessionActive =>
      _canUseFirestore &&
      (_injectedFirestore != null || _currentAuthUid != null);

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  @override
  Future<double> getBalance(String userId) async {
    final effectiveUserId = (_currentAuthUid != null && _currentAuthUid!.isNotEmpty)
        ? _currentAuthUid!
        : (userId.trim().isEmpty ? 'usr_me_01' : userId.trim());

    if (!_isFirestoreSessionActive) {
      if (_isLiveBackendMode) return 0.0;
      return _localFallback.getBalance(effectiveUserId);
    }

    try {
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(effectiveUserId)
          .get()
          .timeout(const Duration(seconds: 4));

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final piastres = (data['walletBalancePiastres'] as num?)?.toInt();
        final resolved = piastres != null
            ? piastres / 100.0
            : ((data['walletBalance'] as num?)?.toDouble() ?? 0.0);
        return resolved;
      }
      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  @override
  Future<List<WalletTransactionModel>> getTransactions(String userId) async {
    final effectiveUserId = (_currentAuthUid != null && _currentAuthUid!.isNotEmpty)
        ? _currentAuthUid!
        : (userId.trim().isEmpty ? 'usr_me_01' : userId.trim());

    if (!_isFirestoreSessionActive) {
      if (_isLiveBackendMode) return const [];
      return _localFallback.getTransactions(effectiveUserId);
    }

    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.walletTransactions)
          .where('userId', isEqualTo: effectiveUserId)
          .orderBy('timestamp', descending: true)
          .limit(25)
          .get()
          .timeout(const Duration(seconds: 4));

      final remoteTxs = snapshot.docs
          .map(
            (doc) => WalletTransactionModel.fromJson(
              normalizeFirestoreDocument(doc.data(), fallbackId: doc.id),
            ),
          )
          .toList();

      return remoteTxs;
    } catch (_) {
      return const [];
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
    final effectiveUserId = (_currentAuthUid != null && _currentAuthUid!.isNotEmpty)
        ? _currentAuthUid!
        : (userId.trim().isEmpty ? 'usr_me_01' : userId.trim());

    if (!_isFirestoreSessionActive) {
      if (_isLiveBackendMode) return false;
      return _localFallback.deposit(
        userId: effectiveUserId,
        amount: amount,
        method: method,
        referenceNumber: referenceNumber,
      );
    }

    try {
      final txRef =
          _firestore.collection(FirestoreCollections.walletTransactions).doc();
      final tx = WalletTransactionModel(
        id: txRef.id,
        userId: effectiveUserId,
        amount: amount,
        type: TransactionType.deposit,
        method: method,
        referenceNumber: referenceNumber.trim().isEmpty
            ? 'DEP-${DateTime.now().millisecondsSinceEpoch % 1000000}'
            : referenceNumber.trim(),
        status: TransactionStatus.pending,
        titleAr: 'طلب شحن محفظة قيد المراجعة',
        titleEn: 'Wallet Deposit Pending Review',
        timestamp: DateTime.now(),
      );

      await txRef.set(tx.toJson()).timeout(const Duration(seconds: 4));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> withdraw({
    required String userId,
    required double amount,
    required PaymentMethodType method,
    required String destinationAccount,
  }) async {
    if (amount <= 0) return false;
    final effectiveUserId = (_currentAuthUid != null && _currentAuthUid!.isNotEmpty)
        ? _currentAuthUid!
        : (userId.trim().isEmpty ? 'usr_me_01' : userId.trim());

    if (!_isFirestoreSessionActive) {
      if (_isLiveBackendMode) return false;
      return _localFallback.withdraw(
        userId: effectiveUserId,
        amount: amount,
        method: method,
        destinationAccount: destinationAccount,
      );
    }

    final currentBalance = await getBalance(effectiveUserId);
    if (currentBalance < amount) return false;

    try {
      final txRef =
          _firestore.collection(FirestoreCollections.walletTransactions).doc();
      final tx = WalletTransactionModel(
        id: txRef.id,
        userId: effectiveUserId,
        amount: amount,
        type: TransactionType.withdraw,
        method: method,
        referenceNumber: 'WD-${DateTime.now().millisecondsSinceEpoch % 1000000}',
        status: TransactionStatus.pending,
        titleAr: 'طلب سحب أرباح إلى $destinationAccount',
        titleEn: 'Withdrawal Request to $destinationAccount',
        timestamp: DateTime.now(),
      );

      await txRef.set(tx.toJson()).timeout(const Duration(seconds: 4));
      return true;
    } catch (_) {
      return false;
    }
  }
}
