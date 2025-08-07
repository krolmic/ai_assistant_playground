import 'package:ai_assistant_1/apis/apis.dart';
import 'package:ai_assistant_1/app/view/main_page.dart';
import 'package:ai_assistant_1/l10n/l10n.dart';
import 'package:ai_assistant_1/repositories/repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => SpeechToTextRepository(),
        ),
        RepositoryProvider(
          create: (context) => TextResponsesRepository(
            api: GenkitGeminiTextResponsesApi(),
          ),
        ),
        RepositoryProvider(
          create: (context) => ImageGenerationRepository(
            api: DallEImageGenerationApi(),
          ),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          appBarTheme: AppBarTheme(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          useMaterial3: true,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MainPage(),
      ),
    );
  }
}
