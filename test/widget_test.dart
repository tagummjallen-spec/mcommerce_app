import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcommerce_app/core/constants/app_colors.dart';
import 'package:mcommerce_app/core/theme/app_theme.dart';

void main() {
  testWidgets('App theme applies the Ascended Athletics palette',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(child: Text('Ascended Athletics')),
        ),
      ),
    );

    final BuildContext context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).scaffoldBackgroundColor, AppColors.primaryBackground);
    expect(find.text('Ascended Athletics'), findsOneWidget);
  });
}
