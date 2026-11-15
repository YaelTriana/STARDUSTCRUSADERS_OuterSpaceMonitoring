import 'package:flutter/material.dart';

import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import '../theme.dart';

/// Selector de entorno de misión (ISS / Luna / Marte).
///
/// En pantallas anchas usa botones segmentados; por debajo de
/// [compactBreakpoint] pasa a un menú desplegable para que ninguna opción
/// quede cortada. Las áreas táctiles miden al menos 44 px.
class EnvSelector extends StatelessWidget {
  const EnvSelector({super.key, required this.value, required this.onChanged});

  final MissionEnv value;
  final ValueChanged<MissionEnv> onChanged;

  static const compactBreakpoint = 640.0;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < compactBreakpoint;
    final l = context.l10n;
    return compact ? _menu(l) : _segmented(l);
  }

  Widget _segmented(AppLocalizations l) => SegmentedButton<MissionEnv>(
        showSelectedIcon: false,
        style: const ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(64, 44)),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        segments: [
          for (final e in MissionEnv.values)
            ButtonSegment(value: e, label: Text(l.envLabel(e), maxLines: 1, softWrap: false)),
        ],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
      );

  Widget _menu(AppLocalizations l) => PopupMenuButton<MissionEnv>(
        key: const Key('env-menu'),
        tooltip: l.envSelectorLabel,
        initialValue: value,
        onSelected: onChanged,
        itemBuilder: (_) => [
          for (final e in MissionEnv.values)
            PopupMenuItem(
              value: e,
              height: 48,
              child: Row(children: [
                Icon(e == value ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 18, color: e == value ? VColors.signal : VColors.muted),
                const SizedBox(width: 10),
                Flexible(
                  child: Text('${l.envLabel(e)} · ${l.envDelay(e)}', maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
        ],
        child: Semantics(
          label: '${l.envSelectorLabel}: ${l.envLabel(value)}',
          button: true,
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: VColors.borderStrong),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(l.envLabel(value), style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: VColors.muted),
            ]),
          ),
        ),
      );
}
