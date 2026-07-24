import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'card_wrapper.dart';

class InfoCard extends StatefulWidget {
  final String title;
  final IconData? titleIcon;
  final List<InfoRowData> rows;
  final bool initiallyExpanded;
  final bool isAccordion; // NEW: toggle accordion behavior

  const InfoCard({
    super.key,
    required this.title,
    required this.rows,
    this.titleIcon,
    this.initiallyExpanded = false,
    this.isAccordion = false,
  });

  @override
  State<InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<InfoCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CardWrapper(
      child: widget.isAccordion ? _buildAccordion() : _buildFixedContent(),
    );
  }

  /// ================= FIXED (NON-ACCORDION) CONTENT =================
  Widget _buildFixedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.titleIcon != null)
              Icon(widget.titleIcon, color: AppColors.primary),
            if (widget.titleIcon != null)
              const SizedBox(width: AppSpacing.iconText),
            Text(widget.title, style: AppTextStyles.h3),
          ],
        ),
        const SizedBox(height: AppSpacing.verticalMedium),
        ..._buildRows(),
      ],
    );
  }

  /// ================= CUSTOM ACCORDION =================
  Widget _buildAccordion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggleExpanded,
          behavior: HitTestBehavior.translucent,
          child: Row(
            children: [
              if (widget.titleIcon != null)
                Icon(widget.titleIcon, color: AppColors.primary),
              if (widget.titleIcon != null)
                const SizedBox(width: AppSpacing.iconText),
              Expanded(
                child: Text(widget.title, style: AppTextStyles.h3),
              ),
              Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppColors.iconSecondary,
              ),
            ],
          ),
        ),
        _expanded
            ? const SizedBox(height: AppSpacing.verticalMedium)
            : SizedBox.shrink(),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(children: _buildRows()),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  List<Widget> _buildRows() {
    final List<Widget> widgets = [];
    for (var i = 0; i < widget.rows.length; i++) {
      widgets.add(_InfoRow(
        icon: widget.rows[i].icon,
        label: widget.rows[i].label,
        value: widget.rows[i].value,
      ));
      if (i != widget.rows.length - 1) {
        widgets.add(const Divider(color: AppColors.divider));
      }
    }
    return widgets;
  }
}

/// ================= ROW DATA =================
class InfoRowData {
  final IconData icon;
  final String label;
  final String value;

  InfoRowData({required this.icon, required this.label, required this.value});
}

/// ================= SINGLE ROW WIDGET =================
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.iconSecondary),
          const SizedBox(width: AppSpacing.horizontalMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(value, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
