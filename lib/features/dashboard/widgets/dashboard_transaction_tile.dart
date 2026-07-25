import 'package:flutter/material.dart';

import '../../../core/services/DataModels/dashboard_models.dart';
import '../../../core/services/currency_utils.dart';
import '../../../core/services/dashboard_date_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/status_badge.dart';
import '../../transactions/transaction_details_page.dart';

/// Lightweight, dashboard-specific transaction row for the
/// `recent_transactions` section.
///
/// Deliberately a new, small widget rather than reusing
/// `TransactionsPage`'s private `_transactionCard` (that method isn't
/// exported and lives on a `State` — pulling it out cleanly would mean
/// changing the Transactions screen, which is out of scope here).
/// Visually it stays consistent with that screen by reusing the same
/// shared building blocks it does ([StatusBadge], [CurrencyUtils]),
/// so the two don't look like unrelated designs even though they're
/// separate widgets. Tapping a row opens the same
/// [TransactionDetailsPage] the Transactions tab uses.
class DashboardTransactionTile extends StatelessWidget {
  final DashboardTransactionItem transaction;
  final String currencySymbol;
  final String dateFormat;
  final String timezone;

  const DashboardTransactionTile({
    super.key,
    required this.transaction,
    required this.currencySymbol,
    required this.dateFormat,
    required this.timezone,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = DashboardDateFormatter.formatIso(
      transaction.transactionDate,
      pattern: dateFormat,
      timezone: timezone,
    );

    final subtitle = [
      transaction.service,
      transaction.branch,
    ].where((s) => s.isNotEmpty).join(' · ');

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      onTap: () {
        if (transaction.id.isEmpty) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                TransactionDetailsPage(transactionId: transaction.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.customerName.isNotEmpty
                        ? transaction.customerName
                        : transaction.invoiceNo,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (dateLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CurrencyUtils.format(
                    transaction.amount,
                    symbol: currencySymbol,
                  ),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                StatusBadge(status: transaction.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
