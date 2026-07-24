import 'package:flutter/material.dart';

class FirmDetailShimmer extends StatelessWidget {
  const FirmDetailShimmer({super.key});

  // -------------------- OVERVIEW CARD --------------------
  static const overviewCard = _OverviewCardShimmer();
  static const headerCard = _HeaderCardShimmer();
  static const trendChart = _TrendChartShimmer();
  static const businessSummary = _BusinessSummaryShimmer();
  static const staff = _StaffShimmer();
  static const services = _ServicesShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          overviewCard,
          SizedBox(height: 24),
          headerCard,
          SizedBox(height: 24),
          trendChart,
          SizedBox(height: 24),
          businessSummary,
          SizedBox(height: 24),
          staff,
          SizedBox(height: 24),
          services,
        ],
      ),
    );
  }
}

// -------------------- GENERIC SHIMMER BOX --------------------
class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const _ShimmerBox({
    this.width = double.infinity,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300, // <-- shimmer placeholder color
        borderRadius: borderRadius,
      ),
    );
  }
}

// -------------------- OVERVIEW CARD SHIMMER --------------------
class _OverviewCardShimmer extends StatelessWidget {
  const _OverviewCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _ShimmerBox(height: 24, width: 150),
        SizedBox(height: 12),
        _ShimmerBox(height: 16),
        SizedBox(height: 8),
        _ShimmerBox(height: 16),
        SizedBox(height: 8),
        _ShimmerBox(height: 16),
        SizedBox(height: 8),
        _ShimmerBox(height: 16),
      ],
    );
  }
}

// -------------------- HEADER CARD SHIMMER --------------------
class _HeaderCardShimmer extends StatelessWidget {
  const _HeaderCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _ShimmerBox(height: 28, width: 200),
        SizedBox(height: 12),
        _ShimmerBox(height: 16),
        SizedBox(height: 8),
        _ShimmerBox(height: 16),
      ],
    );
  }
}

// -------------------- TREND CHART SHIMMER --------------------
class _TrendChartShimmer extends StatelessWidget {
  const _TrendChartShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey.shade300,
    );
  }
}

// -------------------- BUSINESS SUMMARY SHIMMER --------------------
class _BusinessSummaryShimmer extends StatelessWidget {
  const _BusinessSummaryShimmer();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        _ShimmerBox(height: 80, width: 80),
        _ShimmerBox(height: 80, width: 80),
        _ShimmerBox(height: 80, width: 80),
        _ShimmerBox(height: 80, width: 80),
      ],
    );
  }
}

// -------------------- STAFF SHIMMER --------------------
class _StaffShimmer extends StatelessWidget {
  const _StaffShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: const [
              _ShimmerBox(
                  height: 50,
                  width: 50,
                  borderRadius: BorderRadius.all(Radius.circular(25))),
              SizedBox(width: 16),
              Expanded(
                child: _ShimmerBox(height: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- SERVICES SHIMMER --------------------
class _ServicesShimmer extends StatelessWidget {
  const _ServicesShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ShimmerBox(height: 50),
        ),
      ),
    );
  }
}
