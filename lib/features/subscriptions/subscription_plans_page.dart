import 'package:flutter/material.dart';

import '../../core/network/apis/razorpay_api_service.dart';
import '../../core/services/DataModels/razorpay_payment_payload_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/slide_action_button.dart';
import '../subscriptions/razorpay_service.dart';
import '../subscriptions/subscription_controller.dart';
import 'subscription_plan_interface.dart';

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  final SubscriptionController _controller = SubscriptionController();
  final RazorpayService _razorpayService = RazorpayService();

  bool isLoading = false;

  final List<SubscriptionPlan> plans = const [
    SubscriptionPlan(
      id: PlanId.starter,
      title: "Starter",
      price: "₹499",
      billingNote: "per month",
      features: ["Basic reports", "Up to 5 users", "Email support"],
    ),
    SubscriptionPlan(
      id: PlanId.growth,
      title: "Growth",
      price: "₹999",
      billingNote: "per month",
      isPopular: true,
      features: [
        "Advanced reports",
        "Up to 25 users",
        "Priority support",
        "Auto backups",
      ],
    ),
    SubscriptionPlan(
      id: PlanId.enterprise,
      title: "Enterprise",
      price: "Custom",
      billingNote: "Contact sales",
      features: [
        "Unlimited users",
        "Dedicated manager",
        "Custom integrations",
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _razorpayService.init();
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  /// --------------------------------------------------
  /// Razorpay status resolver (SAFE & REAL)
  /// --------------------------------------------------
  String _resolvePaymentStatus(RazorpayPaymentResult result) {
    if (result.success) return "SUCCESS";

    // Razorpay uses errorCode == 2 for user cancelled
    if (result.errorCode == 2) {
      return "CANCELLED";
    }

    return "FAILED";
  }

  Future<void> _startSelectedPlanPayment() async {
    final plan = _controller.selectedPlan;
    if (plan == null) return;

    setState(() => isLoading = true);
    _controller.startPayment();

    final amount = plan.id == PlanId.starter ? 499 : 999;

    final razorpayApi = RazorpayApiService();

    /// 1️⃣ Create order from backend
    final orderResponse = await razorpayApi.createOrder(
      amountInPaise: amount * 100,
      currency: "INR",
      planId: plan.id.name,
    );

    if (!orderResponse.isSuccess || orderResponse.data == null) {
      setState(() => isLoading = false);
      AppSnackbar.error(context, orderResponse.error ?? "Unable to create order");
      return;
    }

    final order = orderResponse.data!;

    /// 2️⃣ Start Razorpay checkout
    final RazorpayPaymentResult result = await _razorpayService.startPayment(
      amountInRupees: amount,
      planName: plan.title,
      orderId: order.orderId,
    );

    if (!mounted) return;

    /// 3️⃣ Always persist payment result (SUCCESS / FAILED / CANCELLED)
    final status = _resolvePaymentStatus(result);

    await razorpayApi.savePaymentResult(
      payload: RazorpayPaymentPayload(
        orderId: order.orderId,
        status: status,
        amount: amount * 100,
        planId: plan.id.name,
        platform: "flutter",
        createdAt: DateTime.now(),

        // success fields
        paymentId: result.paymentId,
        signature: result.signature,

        // failure fields (ONLY what exists)
        errorCode: result.errorCode,
        errorReason: result.errorMessage,
      ),
    );

    setState(() => isLoading = false);

    /// 4️⃣ UI feedback
    if (result.success) {
      _controller.paymentSuccess();

      AppSnackbar.success(context, "Subscription activated 🎉");

      Navigator.pop(context);
    } else {
      _controller.paymentFailed();

      AppSnackbar.error(context, "Payment failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(
          "Choose Your Plan",
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),

      /// ---------- BOTTOM BAR ----------
      bottomNavigationBar: _controller.selectedPlan == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: SlideActionButton(
                label:
                    "Slide to pay ${_controller.selectedPlan!.price}/- Only",
                submitting: isLoading,
                onSlide: (controller) async {
                  if (isLoading) return;
                  await _startSelectedPlanPayment();
                },
              ),
            ),

      /// ---------- BODY ----------
      body: IgnorePointer(
        ignoring: isLoading,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              "Unlock more features and scale your business effortlessly.",
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ...plans.map(_planCard),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _mostPopularBadge() {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondary,
              AppColors.secondary.withOpacity(0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          "MOST POPULAR",
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  /// ---------- PLAN CARD ----------
  Widget _planCard(SubscriptionPlan plan) {
    final bool isSelected = _controller.selectedPlan?.id == plan.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.selectPlan(plan);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: plan.isPopular
              ? AppColors.primary.withOpacity(0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: 2,
            color: isSelected ? AppColors.secondary : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: plan.isPopular ? 18 : 12,
              color: Colors.black.withOpacity(0.06),
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.isPopular) _mostPopularBadge(),
            if (plan.isPopular) const SizedBox(height: 10),
            Text(plan.title, style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text(
              plan.price,
              style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              plan.billingNote,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ...plan.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
