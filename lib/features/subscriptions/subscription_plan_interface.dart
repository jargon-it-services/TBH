enum PlanId { starter, growth, enterprise }

class SubscriptionPlan {
  final PlanId id;
  final String title;
  final String price;
  final String billingNote;
  final List<String> features;
  final bool isPopular;

  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.price,
    required this.billingNote,
    required this.features,
    this.isPopular = false,
  });
}
