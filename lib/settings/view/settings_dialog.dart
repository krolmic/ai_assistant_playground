import 'package:ai_assistant_1/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Text Response API',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ...TextResponseApiType.values.map((apiType) {
                return RadioListTile<TextResponseApiType>(
                  title: Text(apiType.displayName),
                  value: apiType,
                  groupValue: state.selectedApiType,
                  onChanged: (value) async {
                    if (value != null) {
                      await context.read<SettingsCubit>().setApiType(value);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
