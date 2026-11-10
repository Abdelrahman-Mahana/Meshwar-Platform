import 'package:flutter_test/flutter_test.dart';
import 'package:mashwar/main.dart';
import 'package:mashwar/core/constants/app_colors.dart';

void main() {
  testWidgets('MASHWAR app smoke test and brand initialization', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MashwarApp());

    // Advance clock past the splash screen timer
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify app renders cleanly and brand tokens match specification
    expect(find.byType(MashwarApp), findsOneWidget);
    expect(AppColors.navy.toARGB32(), 0xFF0F2A43);
    expect(AppColors.gold.toARGB32(), 0xFFF5A524);
    expect(AppColors.teal.toARGB32(), 0xFF1B7F79);
    expect(AppColors.sand.toARGB32(), 0xFFFAF7F0);
  });
}
