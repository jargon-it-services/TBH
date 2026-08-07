import 'package:flutter/material.dart';

import '../../../core/services/DataModels/transaction_entry_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// "+ More" services picker — every bootstrap service (not just the
/// frequent ones already shown as chips), client-side searchable.
///
/// Multi-select: tapping a row adds/increments it immediately (via
/// [onAdd], called once per tap — the parent's cart owns the actual
/// running quantity) and the sheet stays open so several services can
/// be added in one visit instead of reopening the sheet per service.
/// [initialQuantities] seeds each row's own qty badge from whatever's
/// already in the parent's cart when the sheet opens, and this widget
/// keeps a local copy in sync as the user taps so the badges update
/// live without needing to thread the parent's full state back down.
class ServicePickerSheet extends StatefulWidget {
  const ServicePickerSheet({
    super.key,
    required this.services,
    required this.initialQuantities,
    required this.onAdd,
  });

  final List<BootstrapService> services;
  final Map<int, int> initialQuantities;
  final ValueChanged<BootstrapService> onAdd;

  static Future<void> show(
    BuildContext context, {
    required List<BootstrapService> services,
    required Map<int, int> initialQuantities,
    required ValueChanged<BootstrapService> onAdd,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ServicePickerSheet(
        services: services,
        initialQuantities: initialQuantities,
        onAdd: onAdd,
      ),
    );
  }

  @override
  State<ServicePickerSheet> createState() => _ServicePickerSheetState();
}

class _ServicePickerSheetState extends State<ServicePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late final Map<int, int> _qty = {...widget.initialQuantities};

  List<BootstrapService> get _filtered {
    if (_query.trim().isEmpty) return widget.services;
    final q = _query.trim().toLowerCase();
    return widget.services.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  void _tap(BootstrapService service) {
    setState(() => _qty[service.id] = (_qty[service.id] ?? 0) + 1);
    widget.onAdd(service);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalAdded = _qty.values.fold(0, (a, b) => a + b);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        final results = _filtered;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('All Services', style: AppTextStyles.h3),
                  const Spacer(),
                  if (totalAdded > 0)
                    Text(
                      '$totalAdded added',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search services',
                  hintStyle: AppTextStyles.bodySmall,
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.pageBackground,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Text(
                          'No services match "$_query"',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final service = results[index];
                          final qty = _qty[service.id] ?? 0;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(service.name, style: AppTextStyles.body),
                            subtitle: Text(
                              '₹${service.price.toStringAsFixed(0)}',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                            trailing: qty > 0
                                ? Container(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Added × $qty',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                : Icon(Icons.add_circle_outline, color: AppColors.primary),
                            onTap: () => _tap(service),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
