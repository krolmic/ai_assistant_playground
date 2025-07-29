import 'dart:async';
import 'dart:developer';

import 'package:ai_assistant_1/firebase_options.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fimber/flutter_fimber.dart';

class LoggingBlocObserver extends BlocObserver {
  const LoggingBlocObserver();

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    Fimber.v('Creating instance of ${bloc.runtimeType}');

    super.onCreate(bloc);
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    Fimber.v(event.toString());

    super.onEvent(bloc, event);
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    Fimber.v('${change.nextState}');

    super.onChange(bloc, change);
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    Fimber.e(
      'Error in ${bloc.runtimeType}',
      ex: error,
      stacktrace: stackTrace,
    );

    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    Fimber.v('Closing instance of ${bloc.runtimeType}');

    super.onClose(bloc);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  final logTree = DebugTree(
    logLevels: DebugTree.defaultLevels.toList()..add('V'),
    useColors: true,
  );
  Fimber.plantTree(logTree);
  Bloc.observer = const LoggingBlocObserver();

  // Add cross-flavor configuration here
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFunctions.instance.useFunctionsEmulator('127.0.0.1', 5001);

  runApp(await builder());
}
