import 'package:flutter/material.dart';

import '../../core/engine/tts_engine_type.dart';
import '../app_theme.dart';

class SettingsView extends StatelessWidget {
  final List<TTSEngineType> engineTypes;
  final TTSEngineType selectedType;
  final String activeEngineLabel;
  final bool isProcessing;
  final ValueChanged<TTSEngineType> onEngineChanged;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  const SettingsView({
    super.key,
    required this.engineTypes,
    required this.selectedType,
    required this.activeEngineLabel,
    required this.isProcessing,
    required this.onEngineChanged,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text('Tema do Aplicativo', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Escolha a aparência visual do leitor e da interface.',
              style: TextStyle(color: ext?.textSoft ?? theme.colorScheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<ThemeMode>(
              key: const Key('theme-mode-selector'),
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Sistema'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Claro'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Escuro'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (selected) {
                if (selected.isNotEmpty && onThemeModeChanged != null) {
                  onThemeModeChanged!(selected.first);
                }
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Motor de fala', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Escolha o motor usado para sintetizar a leitura. A síntese continua offline.',
              style: TextStyle(color: ext?.textSoft ?? theme.colorScheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: ext?.card ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Row(
                children: [
                  Icon(Icons.record_voice_over, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DropdownButton<TTSEngineType>(
                      key: const Key('tts-engine-selector'),
                      value: selectedType,
                      isExpanded: true,
                      dropdownColor: ext?.card ?? theme.colorScheme.surface,
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
                style: AppTextStyles.statusMono.copyWith(color: ext?.moss ?? theme.colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
