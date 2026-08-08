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
  final AppThemePalette themePalette;
  final ValueChanged<AppThemePalette>? onThemePaletteChanged;

  const SettingsView({
    super.key,
    required this.engineTypes,
    required this.selectedType,
    required this.activeEngineLabel,
    required this.isProcessing,
    required this.onEngineChanged,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
    this.themePalette = AppThemePalette.padrao,
    this.onThemePaletteChanged,
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
            Text('Paleta de Cores do Aplicativo', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Escolha a paleta de cores editorial (Padrão, Botânico, Carmim ou Marinha).',
              style: TextStyle(color: ext?.textSoft ?? theme.colorScheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 520) {
                  return Wrap(
                    key: const Key('theme-palette-selector-wrap'),
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: AppThemePalette.values.map((palette) {
                      final isSelected = themePalette == palette;
                      return ChoiceChip(
                        label: Text(palette.label),
                        selected: isSelected,
                        selectedColor: theme.colorScheme.primary.withAlpha(40),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : ext?.textSoft ?? theme.colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        onSelected: (selected) {
                          if (selected && onThemePaletteChanged != null) {
                            onThemePaletteChanged!(palette);
                          }
                        },
                      );
                    }).toList(),
                  );
                }

                return SegmentedButton<AppThemePalette>(
                  key: const Key('theme-palette-selector'),
                  segments: [
                    ButtonSegment(
                      value: AppThemePalette.padrao,
                      label: Text(AppThemePalette.padrao.label),
                      icon: const Icon(Icons.palette_outlined),
                    ),
                    ButtonSegment(
                      value: AppThemePalette.botanico,
                      label: Text(AppThemePalette.botanico.label),
                      icon: const Icon(Icons.eco_outlined),
                    ),
                    ButtonSegment(
                      value: AppThemePalette.carmim,
                      label: Text(AppThemePalette.carmim.label),
                      icon: const Icon(Icons.auto_awesome_outlined),
                    ),
                    ButtonSegment(
                      value: AppThemePalette.marinha,
                      label: Text(AppThemePalette.marinha.label),
                      icon: const Icon(Icons.water_drop_outlined),
                    ),
                  ],
                  selected: {themePalette},
                  onSelectionChanged: (selected) {
                    if (selected.isNotEmpty && onThemePaletteChanged != null) {
                      onThemePaletteChanged!(selected.first);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Modo de Iluminação', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.xl),
            Text('Informações Legais', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Consulte os termos de licença dos componentes open-source e modelos neurais.',
              style: TextStyle(color: ext?.textSoft ?? theme.colorScheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              key: const Key('open-source-licenses-button'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
              ),
              icon: const Icon(Icons.gavel),
              label: const Text('Ver Licenças Open-Source'),
              onPressed: () {
                showLicensePage(
                  context: context,
                  applicationName: 'VozLume',
                  applicationVersion: '1.0.0+1',
                  applicationLegalese: '© 2026 João Gabriel Araújo Almeida — UEFS TCC',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
