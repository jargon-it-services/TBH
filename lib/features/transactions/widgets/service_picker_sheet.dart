import 'package:flutter/material.dart';

import '../../../core/services/DataModels/transaction_entry_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// "+ More" services picker — every bootstrap service (not just the
/// frequent ones already shown as chips), client-side searchable, tap
/// to add. No network round-trip: filtering is purely local against
/// the already-fetched bootstrap list, per the "Performance
/// Requirements" spec.
class ServicePickerSheet extends StatefulWidget {
  const ServicePickerSheet({super.key, required this.services});

  final List<BootstrapService> services;

  static Future<BootstrapService?> show(
    BuildContext context, {
    required List<BootstrapService> services,
  }) {
    return showModalBottomSheet<BootstrapService>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ServicePickerSheet(services: services),
    );
  }

  @override
  State<ServicePickerSheet> createState() => _ServicePickerSheetState();
}

class _ServicePickerSheetState extends State<ServicePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<BootstrapService> get _filtered {
    if (_query.trim().isEmpty) return widget.services;
    final q = _query.trim().toLowerCase();
    return widget.services.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
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
              Text('All Services', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                autofocus: false,
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
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(service.name, style: AppTextStyles.body),
                            trailing: Text(
                              '₹${service.price.toStringAsFixed(0)}',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            onTap: () => Navigator.pop(context, service),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
