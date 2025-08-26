import 'package:ai_assistant_1/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsCubit extends Mock implements SettingsCubit {}

void main() {
  group('SettingsDialog', () {
    late SettingsCubit settingsCubit;

    setUpAll(() {
      registerFallbackValue(TextResponseApiType.gemini);
    });

    setUp(() {
      settingsCubit = _MockSettingsCubit();
      when(() => settingsCubit.stream).thenAnswer(
        (_) => const Stream<SettingsState>.empty(),
      );
      when(() => settingsCubit.state).thenReturn(
        const SettingsState(selectedApiType: TextResponseApiType.gemini),
      );
      when(() => settingsCubit.setApiType(any())).thenAnswer((_) async {});
    });

    Widget _buildDialog() {
      return BlocProvider<SettingsCubit>.value(
        value: settingsCubit,
        child: const MaterialApp(
          home: Scaffold(
            body: SettingsDialog(),
          ),
        ),
      );
    }

    testWidgets('renders all API options with correct labels', (tester) async {
      await tester.pumpWidget(_buildDialog());

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Text Response API'), findsOneWidget);

      for (final apiType in TextResponseApiType.values) {
        expect(find.text(apiType.displayName), findsOneWidget);
      }
    });

    testWidgets('tapping option calls setApiType on cubit', (tester) async {
      await tester.pumpWidget(_buildDialog());

      await tester.tap(find.text(TextResponseApiType.grok.displayName));
      await tester.pump();

      verify(() => settingsCubit.setApiType(TextResponseApiType.grok)).called(1);
    });

    testWidgets('Close button pops the dialog', (tester) async {
      await tester.pumpWidget(
        BlocProvider<SettingsCubit>.value(
          value: settingsCubit,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const SettingsDialog(),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}