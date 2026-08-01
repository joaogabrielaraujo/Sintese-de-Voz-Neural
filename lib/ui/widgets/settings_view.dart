import 'package:flutter/material.dart';

import '../../core/engine/tts_engine_type.dart';
import '../app_theme.dart';

class SettingsView extends StatelessWidget {
  final List<TTSEngineType> engineTypes;
  final TTSEngineType selectedType;
  final String activeEngineLabel;
  final bool isProcessing;
  final ValueChanged<TTSEngineType> onEngineChanged;

  const SettingsView({
    super.key,
    required this.engineTypes,
    required this.selectedType,
    required this.activeEngineLabel,
    required this.isProcessing,
    required this.onEngineChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const Text('Motor de fala', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Escolha o motor usado para sintetizar a leitura. A síntese continua offline.',
              style: TextStyle(color: AppColors.paperDim),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.ink2,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.record_voice_over, color: AppColors.amber),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DropdownButton<TTSEngineType>(
                      key: const Key('tts-engine-selector'),
                      value: selectedType,
                      isExpanded: true,
                      dropdownColor: AppColors.ink2,
                      items: engineTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: isProcessing
                          ? null
                          : (type) {
                              if (type != null) onEngineChanged(type);
                            },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              child: Text(
                isProcessing
                    ? 'Inicializando motor…'
                    : 'Ativo: $activeEngineLabel',
                style: AppTextStyles.metric.copyWith(color: AppColors.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
