part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.selectedApiType = TextResponseApiType.gemini,
  });

  final TextResponseApiType selectedApiType;

  SettingsState copyWith({
    TextResponseApiType? selectedApiType,
  }) {
    return SettingsState(
      selectedApiType: selectedApiType ?? this.selectedApiType,
    );
  }

  @override
  List<Object> get props => [selectedApiType];
}
