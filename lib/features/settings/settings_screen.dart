import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/data/datasources/settings_store.dart';

// ---------------------------------------------------------------------------
// Sound
// ---------------------------------------------------------------------------

final soundEnabledProvider = StateNotifierProvider<SoundSettingNotifier, bool>(
  (ref) => SoundSettingNotifier(),
);

class SoundSettingNotifier extends StateNotifier<bool> {
  final SettingsStore _store;

  SoundSettingNotifier({SettingsStore? store})
      : _store = store ?? SettingsStore(),
        super(true) {
    _load();
  }

  Future<void> _load() async {
    state = await _store.getSoundEnabled();
  }

  Future<void> toggle() async {
    state = !state;
    await _store.setSoundEnabled(state);
  }
}

// ---------------------------------------------------------------------------
// Theme mode
// ---------------------------------------------------------------------------

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SettingsStore _store;

  ThemeModeNotifier({SettingsStore? store})
      : _store = store ?? SettingsStore(),
        super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final raw = await _store.getThemeMode();
    state = _fromString(raw);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _store.setThemeMode(_toString(mode));
  }

  static ThemeMode _fromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundEnabled = ref.watch(soundEnabledProvider);
    final themeMode = ref.watch(themeModeProvider);
    final colors = context.appColors;

    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textSecondary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _SectionLabel(label: 'APPEARANCE'),
          const SizedBox(height: 8),
          _ThemeToggleTile(isDark: isDark, themeMode: themeMode),
          const SizedBox(height: 24),
          _SectionLabel(label: 'AUDIO'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: soundEnabled
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            label: 'Sound Effects',
            subtitle: soundEnabled ? 'On' : 'Off',
            trailing: Switch(
              value: soundEnabled,
              onChanged: (_) =>
                  ref.read(soundEnabledProvider.notifier).toggle(),
              activeThumbColor: colors.primaryNeon,
              activeTrackColor:
                  colors.primaryNeon.withValues(alpha: 0.3),
              inactiveThumbColor: colors.textDisabled,
              inactiveTrackColor: colors.border,
            ),
          ),
          const SizedBox(height: 24),
          _SectionLabel(label: 'ABOUT'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'Version',
            subtitle: '1.0.0',
          ),
          _SettingsTile(
            icon: Icons.grid_on_rounded,
            label: 'Sudoku Nova',
            subtitle: 'A neon-styled puzzle game',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme toggle tile — three-way: System / Light / Dark
// ---------------------------------------------------------------------------

class _ThemeToggleTile extends ConsumerWidget {
  final bool isDark;
  final ThemeMode themeMode;

  const _ThemeToggleTile({required this.isDark, required this.themeMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final notifier = ref.read(themeModeProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.accentPurple.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  color: colors.accentPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      themeMode == ThemeMode.system
                          ? 'Follow system'
                          : themeMode == ThemeMode.dark
                              ? 'Dark'
                              : 'Light',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Segmented control: System / Light / Dark
          Row(
            children: [
              _ThemeSegment(
                label: 'System',
                icon: Icons.brightness_auto_rounded,
                selected: themeMode == ThemeMode.system,
                onTap: () => notifier.setMode(ThemeMode.system),
              ),
              const SizedBox(width: 8),
              _ThemeSegment(
                label: 'Light',
                icon: Icons.light_mode_rounded,
                selected: themeMode == ThemeMode.light,
                onTap: () => notifier.setMode(ThemeMode.light),
              ),
              const SizedBox(width: 8),
              _ThemeSegment(
                label: 'Dark',
                icon: Icons.dark_mode_rounded,
                selected: themeMode == ThemeMode.dark,
                onTap: () => notifier.setMode(ThemeMode.dark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color =
        selected ? colors.accentPurple : colors.textDisabled;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? colors.accentPurple.withValues(alpha: 0.15)
                : colors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? colors.accentPurple.withValues(alpha: 0.6)
                  : colors.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colors.accentPurple.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Text(
      label,
      style: TextStyle(
        color: colors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primaryNeon.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colors.primaryNeon, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
