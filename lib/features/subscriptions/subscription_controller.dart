import 'package:flutter/material.dart';

import 'subscription_plan_interface.dart';
import 'subscription_state.dart';

class SubscriptionController extends ChangeNotifier {
  SubscriptionStatus status = SubscriptionStatus.none;
  SubscriptionPlan? selectedPlan;

  void selectPlan(SubscriptionPlan plan) {
    selectedPlan = plan;
    status = SubscriptionStatus.selectingPlan;
    notifyListeners();
  }

  void startPayment() {
    status = SubscriptionStatus.paymentInProgress;
    notifyListeners();
  }

  void paymentSuccess() {
    status = SubscriptionStatus.active;
    notifyListeners();
  }

  void paymentFailed() {
    status = SubscriptionStatus.failed;
    notifyListeners();
  }
}
