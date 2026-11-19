import 'dart:async';
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models/user_model.dart';
import '../data/repositories/app_repositories.dart';

enum AuthStatus {
  unauthenticated,
  phoneEntered,
  otpVerified,
  profileCreated,
  authenticated,
}

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.authenticated; // Default to authenticated for instant prototype exploration
  UserModel _user = MockData.currentUser;
  
  String _phoneNumber = '01012345678';
  String? _email;
  String _authMethod = 'phone'; // 'phone', 'email', 'google'
  final String _enteredOtp = '';
  int _resendCountdown = 59;
  Timer? _resendTimer;
  int _otpAttemptsLeft = 3;
  bool _isLocked = false;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel get user => _user;
  String get phoneNumber => _phoneNumber;
  String? get email => _email;
  String get authMethod => _authMethod;
  String get enteredOtp => _enteredOtp;
  int get resendCountdown => _resendCountdown;
  int get otpAttemptsLeft => _otpAttemptsLeft;
  bool get isLocked => _isLocked;
  bool get isLoading => _isLoading;

  void setPhoneNumber(String phone) {
    _phoneNumber = phone;
    _authMethod = 'phone';
    notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    _authMethod = 'email';
    notifyListeners();
  }

  // Egyptian phone number validator: 11 digits starting with 010, 011, 012, or 015
  static String? validateEgyptianPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'أدخل رقم موبايلك';
    }
    final regex = RegExp(r'^(010|011|012|015)[0-9]{8}$');
    if (!regex.hasMatch(value)) {
      return 'الرقم لازم يكون 11 رقم ويبدأ بـ 010 أو 011 أو 012 أو 015';
    }
    return null;
  }

  // Universal Email validator
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'أدخل بريدك الإلكتروني';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'أدخل بريد إلكتروني صحيح (مثال: name@example.com)';
    }
    return null;
  }

  Future<bool> sendOtp(String phone) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));
    _phoneNumber = phone;
    _authMethod = 'phone';
    _status = AuthStatus.phoneEntered;
    _isLoading = false;
    _resendCountdown = 59;
    _startCountdown();
    notifyListeners();
    return true;
  }

  Future<bool> sendEmailOtp(String email) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));
    _email = email.trim();
    _authMethod = 'email';
    _status = AuthStatus.phoneEntered;
    _isLoading = false;
    _resendCountdown = 59;
    _startCountdown();
    notifyListeners();
    return true;
  }

  Future<bool> verifyEmailOtp(String code) async {
    return verifyOtp(code);
  }

  Future<bool> signInWithGoogle({
    required String email,
    required String displayName,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));
    _email = email.trim();
    _authMethod = 'google';
    _user = _user.copyWith(
      fullName: displayName.trim(),
      email: email.trim(),
      avatarUrl: avatarUrl,
    );
    _status = AuthStatus.otpVerified;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void _startCountdown() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        _resendCountdown--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  Future<bool> verifyOtp(String code) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));
    _isLoading = false;

    // Demo code: '482911' or any 6 digits for testing
    if (code.length == 6) {
      _status = AuthStatus.otpVerified;
      notifyListeners();
      return true;
    } else {
      _otpAttemptsLeft--;
      if (_otpAttemptsLeft <= 0) {
        _isLocked = true;
      }
      notifyListeners();
      return false;
    }
  }

  void saveProfile({
    required String fullName,
    required UserGender gender,
    String? governorate,
    String? city,
    String? birthDate,
    String? email,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? occupation,
    String? smokingPreference,
    String? tripVibe,
    bool ladiesOnlyPreference = false,
    String? avatarUrl,
  }) {
    _user = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      phone: _phoneNumber,
      gender: gender,
      governorate: governorate,
      city: city,
      birthDate: birthDate,
      email: email,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      occupation: occupation,
      smokingPreference: smokingPreference,
      tripVibe: tripVibe,
      ladiesOnlyPreference: ladiesOnlyPreference,
      avatarUrl: avatarUrl,
      isVerified: false,
      idVerificationStatus: IdVerificationStatus.unverified,
      hasActiveAlerts: false,
      hasUpcomingBooking: false,
    );
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  void submitIdVerification({
    required String nationalId,
    required String frontPhoto,
    required String backPhoto,
    String? selfiePhoto,
  }) {
    _user = _user.copyWith(
      nationalId: nationalId,
      idFrontImage: frontPhoto,
      idBackImage: backPhoto,
      selfieImage: selfiePhoto,
      idVerificationStatus: IdVerificationStatus.underReview,
      isVerified: false,
    );
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  void approveIdVerification() {
    _user = _user.copyWith(
      idVerificationStatus: IdVerificationStatus.verified,
      isVerified: true,
    );
    notifyListeners();
  }

  void updateProfile({
    String? fullName,
    UserGender? gender,
    String? email,
    String? governorate,
    String? city,
    String? occupation,
    String? smokingPreference,
    String? tripVibe,
    bool? ladiesOnlyPreference,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    _user = _user.copyWith(
      fullName: fullName ?? _user.fullName,
      gender: gender ?? _user.gender,
      email: email ?? _user.email,
      governorate: governorate ?? _user.governorate,
      city: city ?? _user.city,
      occupation: occupation ?? _user.occupation,
      smokingPreference: smokingPreference ?? _user.smokingPreference,
      tripVibe: tripVibe ?? _user.tripVibe,
      ladiesOnlyPreference: ladiesOnlyPreference ?? _user.ladiesOnlyPreference,
      emergencyContactName: emergencyContactName ?? _user.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? _user.emergencyContactPhone,
    );
    notifyListeners();
    AppRepositories.instance.auth.updateProfile(_user).ignore();
  }

  void updateWalletBalance(double newBalance) {
    _user = _user.copyWith(walletBalance: newBalance);
    notifyListeners();
  }

  // Wallet Transactions & Payment Methods State
  String _selectedPaymentMethod = 'cash';
  String get selectedPaymentMethod => _selectedPaymentMethod;

  void setSelectedPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  final List<Map<String, dynamic>> _walletTransactions = [
    {
      'titleAr': 'شحن رصيد - فودافون كاش',
      'titleEn': 'Top-up - Vodafone Cash',
      'date': 'أمس، 4:30 م',
      'dateEn': 'Yesterday, 4:30 PM',
      'amount': '+200 ج.م',
      'amountValue': 200.0,
      'isPositive': true,
    },
    {
      'titleAr': 'رحلة كفر الشيخ ← القاهرة',
      'titleEn': 'Ride Kafr El-Sheikh -> Cairo',
      'date': '2 نوفمبر، 7:30 ص',
      'dateEn': 'Nov 2, 7:30 AM',
      'amount': '-65 ج.م',
      'amountValue': -65.0,
      'isPositive': false,
    },
    {
      'titleAr': 'تعويض ضمان طرد #4810',
      'titleEn': 'Parcel Insurance Refund #4810',
      'date': '28 أكتوبر',
      'dateEn': 'Oct 28',
      'amount': '+300 ج.م',
      'amountValue': 300.0,
      'isPositive': true,
    },
    {
      'titleAr': 'إرسال طرد طنطا ← الإسكندرية',
      'titleEn': 'Parcel Tanta -> Alexandria',
      'date': '22 أكتوبر',
      'dateEn': 'Oct 22',
      'amount': '-45 ج.م',
      'amountValue': -45.0,
      'isPositive': false,
    },
  ];

  List<Map<String, dynamic>> get walletTransactions => List.unmodifiable(_walletTransactions);

  void depositWalletFunds({
    required double amount,
    required String methodAr,
    required String methodEn,
  }) {
    _user = _user.copyWith(walletBalance: _user.walletBalance + amount);
    _walletTransactions.insert(0, {
      'titleAr': 'شحن رصيد - $methodAr',
      'titleEn': 'Top-up - $methodEn',
      'date': 'الآن',
      'dateEn': 'Just now',
      'amount': '+${amount.toStringAsFixed(0)} ج.م',
      'amountValue': amount,
      'isPositive': true,
    });
    notifyListeners();
  }

  bool withdrawWalletFunds({
    required double amount,
    required String destinationAr,
    required String destinationEn,
  }) {
    if (amount <= 0 || amount > _user.walletBalance) {
      return false;
    }
    _user = _user.copyWith(walletBalance: _user.walletBalance - amount);
    _walletTransactions.insert(0, {
      'titleAr': 'سحب رصيد إلى $destinationAr',
      'titleEn': 'Withdrawal to $destinationEn',
      'date': 'الآن',
      'dateEn': 'Just now',
      'amount': '-${amount.toStringAsFixed(0)} ج.م',
      'amountValue': -amount,
      'isPositive': false,
    });
    notifyListeners();
    return true;
  }

  // Driver Vehicle State
  String _driverCarModel = 'هيونداي إلنترا 2022';
  String _driverCarColor = 'أبيض لؤلؤي';
  String _driverPlateLetters = 'س ق ر';
  String _driverPlateNumbers = '1942';
  int _driverSeatsCount = 3;
  bool _driverHasAC = true;
  bool _driverLargeTrunk = true;

  String get driverCarModel => _driverCarModel;
  String get driverCarColor => _driverCarColor;
  String get driverPlateLetters => _driverPlateLetters;
  String get driverPlateNumbers => _driverPlateNumbers;
  int get driverSeatsCount => _driverSeatsCount;
  bool get driverHasAC => _driverHasAC;
  bool get driverLargeTrunk => _driverLargeTrunk;
  String get driverFormattedCar =>
      '$_driverCarModel، $_driverCarColor ($_driverPlateLetters $_driverPlateNumbers)';

  void updateDriverVehicle({
    String? model,
    String? color,
    String? plateLetters,
    String? plateNumbers,
    int? seatsCount,
    bool? hasAC,
    bool? largeTrunk,
  }) {
    if (model != null) _driverCarModel = model;
    if (color != null) _driverCarColor = color;
    if (plateLetters != null) _driverPlateLetters = plateLetters;
    if (plateNumbers != null) _driverPlateNumbers = plateNumbers;
    if (seatsCount != null) _driverSeatsCount = seatsCount;
    if (hasAC != null) _driverHasAC = hasAC;
    if (largeTrunk != null) _driverLargeTrunk = largeTrunk;
    notifyListeners();
  }

  void logout() {
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}


