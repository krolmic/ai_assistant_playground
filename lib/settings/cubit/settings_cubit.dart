import 'package:ai_assistant_1/apis/apis.dart';
import 'package:ai_assistant_1/repositories/repositories.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required TextResponsesRepository textResponsesRepository,
  })  : _textResponsesRepository = textResponsesRepository,
        super(const SettingsState());

  final TextResponsesRepository _textResponsesRepository;

  Future<void> setApiType(TextResponseApiType apiType) async {
    final api = TextResponseApiFactory.createApi(apiType);
    await _textResponsesRepository.updateApi(api);
    emit(state.copyWith(selectedApiType: apiType));
  }
}

class TextResponseApiFactory {
  static TextResponsesApi createApi(TextResponseApiType type) {
    switch (type) {
      case TextResponseApiType.gemini:
        return GenkitGeminiTextResponsesApi();
      case TextResponseApiType.gpt:
        return GenkitGptTextResponsesApi();
      case TextResponseApiType.grok:
        return GenkitGrokTextResponsesApi();
    }
  }
}

enum TextResponseApiType {
  gemini,
  gpt,
  grok;

  String get displayName {
    switch (this) {
      case TextResponseApiType.gemini:
        return 'Gemini';
      case TextResponseApiType.gpt:
        return 'GPT';
      case TextResponseApiType.grok:
        return 'Grok';
    }
  }
}
