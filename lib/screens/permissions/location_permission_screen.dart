import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/localization/app_strings.dart';
import 'notification_permission_screen.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isDenied = false;

  void _proceedNext() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const NotificationPermissionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              if (_isDenied) ...[
                const SizedBox(height: AppDimens.space12),
                AlertBanner(
                  message: isAr
                      ? 'من غير الموقع هتختار نقطة الصعود بإيدك'
                      : 'Without location, you will pick pickup spots manually',
                  type: AlertBannerType.warning,
                ),
              ],
              const Spacer(flex: 3),
              // Pin Icon with Circle
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.navy,
                  size: 38,
                ),
              ),
              const SizedBox(height: AppDimens.space24),
              Text(
                _isDenied
                    ? (isAr ? 'إذن الموقع مقفول' : 'Location Permission Denied')
                    : (isAr ? 'نلاقي رحلات قريبة منك' : 'Find Rides Near You'),
                textAlign: TextAlign.center,
                style: AppTypography.largeTitle(),
              ),
              const SizedBox(height: AppDimens.space12),
              Text(
                isAr
                    ? 'عشان نقترح نقطة صعود سهلة ونحسب المسافة بدقة.'
                    : 'To suggest convenient pickup spots and calculate distances accurately.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const Spacer(flex: 4),

              MashwarButton(
                text: _isDenied ? (isAr ? 'افتح الإعدادات' : 'Open Settings') : (isAr ? 'تفعيل الموقع' : 'Enable Location'),
                onPressed: () {
                  if (_isDenied) {
                    _proceedNext();
                  } else {
                    _proceedNext();
                  }
                },
              ),
              const SizedBox(height: AppDimens.space12),
              TextButton(
                onPressed: () {
                  if (!_isDenied) {
                    setState(() => _isDenied = true);
                  } else {
                    _proceedNext();
                  }
                },
                child: Text(
                  isAr ? 'مش دلوقتي' : 'Not now',
                  style: AppTypography.bodySecondary(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: AppDimens.space24),
            ],
          ),
        ),
      ),
    );
  }
}
