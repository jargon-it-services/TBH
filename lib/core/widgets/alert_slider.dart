import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AlertSlider<T> extends StatefulWidget {
  final List<T> alerts;
  final Widget Function(BuildContext context, T alert) itemBuilder;

  const AlertSlider({
    super.key,
    required this.alerts,
    required this.itemBuilder,
  });

  @override
  State<AlertSlider<T>> createState() => _AlertSliderState<T>();
}

class _AlertSliderState<T> extends State<AlertSlider<T>>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();

  final GlobalKey _firstItemKey = GlobalKey();
  final List<GlobalKey> _itemKeys = [];

  int _currentIndex = 0;
  double? _currentHeight;

  @override
  void initState() {
    super.initState();
    _generateKeys();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureFirstItem();
    });
  }

  @override
  void didUpdateWidget(covariant AlertSlider<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alerts.length != widget.alerts.length) {
      _generateKeys();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureFirstItem();
      });
    }
  }

  void _generateKeys() {
    _itemKeys
      ..clear()
      ..addAll(List.generate(widget.alerts.length, (_) => GlobalKey()));
  }

  void _measureFirstItem() {
    final context = _firstItemKey.currentContext;
    if (context != null) {
      final height = context.size?.height;
      if (height != null && mounted) {
        setState(() => _currentHeight = height);
      }
    }
  }

  void _updateHeight(int index) {
    final context = _itemKeys[index].currentContext;
    if (context != null) {
      final height = context.size?.height;
      if (height != null && mounted) {
        setState(() => _currentHeight = height);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// 🔹 Hidden first item (for initial height measurement)
        Offstage(
          offstage: true,
          child: KeyedSubtree(
            key: _firstItemKey,
            child: widget.itemBuilder(context, widget.alerts.first),
          ),
        ),

        /// 🔹 PageView (shown only after height is known)
        if (_currentHeight != null)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: _currentHeight,
              width: double.infinity,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.alerts.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _updateHeight(index));
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: KeyedSubtree(
                      key: _itemKeys[index],
                      child: widget.itemBuilder(
                        context,
                        widget.alerts[index],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        /// 🔵 Indicator
        if (widget.alerts.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.alerts.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: _currentIndex == index ? 18 : 6,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
