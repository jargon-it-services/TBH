import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../transaction_details_page.dart';

/// Full-screen success confirmation shown right after a Create save
/// succeeds — replaces the previous "₹2,100 · Paid" snackbar toast with
/// a clearer, harder-to-miss confirmation (in the spirit of a UPI app's
/// payment-success screen). Auto-dismisses after 5 seconds, revealing
/// the already-reset `TransactionEntryPage` underneath so the next
/// transaction can start immediately — this screen is an overlay on
/// the create flow, not a new destination.
///
/// A "View Details" action remains available (opt-in, same as the old
/// toast's "View" action) for the rare case someone wants to jump
/// straight to `TransactionDetailsPage` instead of waiting it out.
class TransactionSuccessOverlay extends StatefulWidget {
  const TransactionSuccessOverlay({
    super.key,
    required this.transactionId,
    required this.status,
    required this.amount,
    this.customerName,
    this.customerMobile,
  });

  final String transactionId;

  /// "paid" | "pending".
  final String status;
  final double amount;
  final String? customerName;
  final String? customerMobile;

  /// Pushes this as a full-screen, fade-in overlay. Resolves once the
  /// overlay itself is dismissed (auto-timeout or manual dismiss),
  /// regardless of whether "View Details" was tapped in between.
  static Future<void> show(
    BuildContext context, {
    required String transactionId,
    required String status,
    required double amount,
    String? customerName,
    String? customerMobile,
  }) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) => TransactionSuccessOverlay(
          transactionId: transactionId,
          status: status,
          amount: amount,
          customerName: customerName,
          customerMobile: customerMobile,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<TransactionSuccessOverlay> createState() => _TransactionSuccessOverlayState();
}

class _TransactionSuccessOverlayState extends State<TransactionSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _autoDismissTimer;

  bool get _isPaid => widget.status == 'paid';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _autoDismissTimer = Timer(const Duration(seconds: 5), _dismiss);
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  void _viewDetails() {
    _autoDismissTimer?.cancel();
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailsPage(transactionId: widget.transactionId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isPaid ? AppColors.success : AppColors.primary;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) _dismiss();
      },
      child: Scaffold(
        backgroundColor: accent,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(
                        _isPaid ? Icons.check_rounded : Icons.schedule_rounded,
                        size: 68,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _controller,
                    child: Text(
                      '₹${widget.amount.toStringAsFixed(0)}',
                      style: AppTextStyles.h1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _controller,
                    child: Text(
                      _isPaid ? 'Payment Successful' : 'Saved · Pending Payment',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h3.copyWith(color: Colors.white),
                    ),
                  ),
                  if (!_isPaid &&
                      (widget.customerName?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 6),
                    FadeTransition(
                      opacity: _controller,
                      child: Text(
                        '${widget.customerName} · ${widget.customerMobile ?? ''}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(color: Colors.white.withOpacity(0.9)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                  TextButton(
                    onPressed: _viewDetails,
                    child: Text(
                      'View Details',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
