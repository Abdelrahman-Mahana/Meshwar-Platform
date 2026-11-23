enum TransactionType {
  deposit,        // شحن رصيد
  withdraw,       // سحب أرباح
  ridePayment,    // دفع قيمة مشوار
  rideEarning,    // تحصيل أرباح كابتن
  errandPayment,  // دفع خدمة مصلحة أو شراء
  errandEarning,  // أرباح منفذ المصلحة
  parcelPayment,  // دفع شحن طرد
  parcelEarning,  // أرباح ناقل الطرد
}

enum PaymentMethodType {
  fawran,
  qpay,
  skipCash,
  applePay,
  cash,
}

enum TransactionStatus {
  pending,
  success,
  failed,
  cancelled,
}

class WalletTransactionModel {
  final String id;
  final String userId;
  final double amount;
  final TransactionType type;
  final PaymentMethodType method;
  final String referenceNumber;
  final TransactionStatus status;
  final String titleAr;
  final String titleEn;
  final DateTime timestamp;

  const WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.method,
    required this.referenceNumber,
    this.status = TransactionStatus.success,
    required this.titleAr,
    required this.titleEn,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type.name,
      'method': method.name,
      'referenceNumber': referenceNumber,
      'status': status.name,
      'titleAr': titleAr,
      'titleEn': titleEn,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.ridePayment,
      ),
      method: PaymentMethodType.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => PaymentMethodType.cash,
      ),
      referenceNumber: (json['referenceNumber'] ?? '').toString(),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.success,
      ),
      titleAr: (json['titleAr'] ?? '').toString(),
      titleEn: (json['titleEn'] ?? '').toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
