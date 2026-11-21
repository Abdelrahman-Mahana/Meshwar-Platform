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
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24, vertical: AppDimens.space20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_isDenied) ...[
                          AlertBanner(
                            message: isAr
                                ? 'من غير الموقع هتختار نقطة الصعود بإيدك'
                                : 'Without location, you will pick pickup spots manually',
                            type: AlertBannerType.warning,
                          ),
                          const SizedBox(height: AppDimens.space24),
                        ] else
                          const SizedBox(height: AppDimens.space32),
                        Column(
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: AppColors.tealSurface,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
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
                          ],
                        ),
                        Column(
                          children: [
                            const SizedBox(height: AppDimens.space32),
                            MashwarButton(
                              text: _isDenied
                                  ? (isAr ? 'المتابعة واختيار الموقع يدوياً' : 'Continue with Manual Location')
                                  : (isAr ? 'تفعيل الموقع' : 'Enable Location'),
                              onPressed: _proceedNext,
                            ),
                            const SizedBox(height: AppDimens.space12),
                            SizedBox(
                              width: double.infinity,
                              height: AppDimens.minTouchTarget,
                              child: TextButton(
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
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
