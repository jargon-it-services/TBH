import 'package:flutter/material.dart';

import '../../core/connectivity/connectivity_aware_refresh.dart';
import '../../core/navigation/notification_navigator.dart';
import '../../core/network/apis/notification_api.dart';
import '../../core/services/DataModels/notification_model.dart';
import '../../core/services/notification_push_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/animated_empty_state.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/notification_list_shimmer.dart';
import 'widgets/notification_card.dart';

enum _ReadFilter { all, unread, read }

/// Notification History screen.
///
/// Follows the exact same shape as `PaymentHistoryPage`: fetch once on
/// open (`GET /api/v1/notifications`), keep the full response in
/// `_all`, and derive `_filtered`/grouped sections locally from the
/// search box + filter chips -- no server-side search/pagination per
/// the API contract. The only thing this screen ever does with a
/// notification's `display_mode`/`destination`/`actions` is hand the
/// whole model to `NotificationNavigator` -- it never branches on
/// notification type itself.
class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage>
    with ConnectivityAwareRefresh<NotificationListPage> {
  final NotificationApi _api = NotificationApi();
  final TextEditingController _searchController = TextEditingController();

  List<NotificationModel> _all = [];
  List<NotificationModel> _filtered = [];
  int _unreadCount = 0;

  bool _isLoading = true;
  String? _error;
  bool _isOffline = false;
  _ReadFilter _filter = _ReadFilter.all;

  @override
  void initState() {
    super.initState();
    _fetch();
    // "Foreground: ... Refresh list" (04_OneSignal_Integration.md) --
    // only wired while this screen is actually on screen; cleared in
    // dispose so a push received after the user navigates away never
    // touches a disposed State.
    NotificationPushService.onForegroundNotificationReceived =
        () => _fetch(silent: true);
  }

  @override
  Future<void> onReconnected() => _fetch(silent: true);

  @override
  void dispose() {
    if (NotificationPushService.onForegroundNotificationReceived != null) {
      NotificationPushService.onForegroundNotificationReceived = null;
    }
    _searchController.dispose();
    super.dispose();
  }

  // ---------------- API ----------------
  Future<void> _fetch({bool silent = false}) async {
    if (!mounted) return;

    setState(() {
      if (!silent && _all.isEmpty) _isLoading = true;
      _error = null;
    });

    final response = await _api.fetchNotifications();
    if (!mounted) return;

    lastLoadFailedDueToConnectivity =
        !response.isSuccess && response.isConnectivityError;

    if (response.isSuccess && response.data != null) {
      _all = response.data!.notifications;
      _unreadCount = response.data!.unreadCount;
      _isOffline = false;
      _applyFilters();
    } else if (_all.isEmpty) {
      _error = response.error ?? "We couldn't load notifications right now.";
      _isOffline = response.isConnectivityError;
    }

    setState(() => _isLoading = false);
  }

  // ---------------- local filter/search ----------------
  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    _filtered = _all.where((n) {
      if (_filter == _ReadFilter.unread && n.isRead) return false;
      if (_filter == _ReadFilter.read && !n.isRead) return false;
      if (query.isNotEmpty) {
        final matchesTitle = n.title.toLowerCase().contains(query);
        final matchesMessage = n.message.toLowerCase().contains(query);
        if (!matchesTitle && !matchesMessage) return false;
      }
      return true;
    }).toList();

    if (mounted) setState(() {});
  }

  void _onFilterSelected(_ReadFilter filter) {
    _filter = filter;
    _applyFilters();
  }

  bool get _isSearchOrFilterActive =>
      _searchController.text.trim().isNotEmpty || _filter != _ReadFilter.all;

  // ---------------- grouping: Today / Yesterday / Earlier ----------------
  List<MapEntry<String, List<NotificationModel>>> get _groupedSections {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final List<NotificationModel> todayItems = [];
    final List<NotificationModel> yesterdayItems = [];
    final List<NotificationModel> earlierItems = [];

    for (final n in _filtered) {
      final created = n.createdAt?.toLocal();
      if (created == null) {
        earlierItems.add(n);
        continue;
      }
      final createdDate = DateTime(created.year, created.month, created.day);
      if (createdDate == today) {
        todayItems.add(n);
      } else if (createdDate == yesterday) {
        yesterdayItems.add(n);
      } else {
        earlierItems.add(n);
      }
    }

    return [
      if (todayItems.isNotEmpty) MapEntry('Today', todayItems),
      if (yesterdayItems.isNotEmpty) MapEntry('Yesterday', yesterdayItems),
      if (earlierItems.isNotEmpty) MapEntry('Earlier', earlierItems),
    ];
  }

  // ---------------- actions ----------------
  Future<void> _onTapNotification(NotificationModel notification) async {
    await NotificationNavigator.open(
      context,
      notification,
      onMarkedRead: () => _markReadLocally(notification.id),
    );
  }

  void _markReadLocally(int id) {
    final index = _all.indexWhere((n) => n.id == id);
    if (index == -1 || _all[index].isRead) return;
    setState(() {
      _all[index] = _all[index].markedRead();
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      _applyFilters();
    });
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final removedIndex = _all.indexWhere((n) => n.id == notification.id);
    if (removedIndex == -1) return;

    final removed = _all[removedIndex];
    setState(() {
      _all.removeAt(removedIndex);
      if (!removed.isRead) {
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      }
      _applyFilters();
    });

    final response = await _api.deleteNotification(notification.id);
    if (!mounted) return;
    if (!response.isSuccess) {
      // Failed server-side -- restore locally rather than silently
      // losing the notification, per "gracefully handle failed" APIs.
      setState(() {
        _all.insert(removedIndex, removed);
        if (!removed.isRead) _unreadCount += 1;
        _applyFilters();
      });
      AppSnackbar.error(context, response.error ?? "Couldn't delete notification.");
    }
  }

  Future<void> _markAllRead() async {
    if (_unreadCount == 0) return;
    final previous = List<NotificationModel>.from(_all);
    final previousUnread = _unreadCount;

    setState(() {
      _all = _all.map((n) => n.isRead ? n : n.markedRead()).toList();
      _unreadCount = 0;
      _applyFilters();
    });

    final response = await _api.markAllRead();
    if (!mounted) return;
    if (!response.isSuccess) {
      setState(() {
        _all = previous;
        _unreadCount = previousUnread;
        _applyFilters();
      });
      AppSnackbar.error(context, response.error ?? "Couldn't mark all as read.");
    } else {
      AppSnackbar.success(context, "All notifications marked as read.");
    }
  }

  Future<void> _deleteAllRead() async {
    final hasRead = _all.any((n) => n.isRead);
    if (!hasRead) {
      AppSnackbar.info(context, "No read notifications to delete.");
      return;
    }

    final previous = List<NotificationModel>.from(_all);
    setState(() {
      _all = _all.where((n) => !n.isRead).toList();
      _applyFilters();
    });

    final response = await _api.deleteAllRead();
    if (!mounted) return;
    if (!response.isSuccess) {
      setState(() {
        _all = previous;
        _applyFilters();
      });
      AppSnackbar.error(
        context,
        response.error ?? "Couldn't delete read notifications.",
      );
    } else {
      AppSnackbar.success(context, "Read notifications deleted.");
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: _appBar(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.page,
                AppSpacing.page,
                0,
              ),
              child: AppSearchBar(
                controller: _searchController,
                hintText: "Search notifications",
                onChanged: (_) => _applyFilters(),
              ),
            ),
            const SizedBox(height: AppSpacing.verticalMedium),
            _filterChips(),
            const SizedBox(height: AppSpacing.verticalMedium),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      centerTitle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.large),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Notifications", style: AppTextStyles.h2.copyWith(color: Colors.white)),
          if (_unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(AppRadius.circle),
              ),
              child: Text(
                _unreadCount > 99 ? "99+" : "$_unreadCount",
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'mark_all_read') _markAllRead();
            if (value == 'delete_all_read') _deleteAllRead();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'mark_all_read',
              child: Row(
                children: [
                  Icon(Icons.done_all, size: 18, color: AppColors.textPrimary),
                  SizedBox(width: 10),
                  Text("Mark All Read"),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete_all_read',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep_outlined,
                      size: 18, color: AppColors.textPrimary),
                  SizedBox(width: 10),
                  Text("Delete All Read"),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _filterChips() {
    final chips = [
      (_ReadFilter.all, "All"),
      (_ReadFilter.unread, "Unread"),
      (_ReadFilter.read, "Read"),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label) = chips[i];
          final selected = _filter == value;
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _onFilterSelected(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _body() {
    if (_isLoading) return const NotificationListShimmer();

    if (_error != null) {
      return NetworkStateView(
        isOffline: _isOffline,
        message: _error,
        onRetry: _fetch,
      );
    }

    if (_filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetch(silent: true),
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AnimatedEmptyState(
              icon: _isSearchOrFilterActive
                  ? Icons.search_off
                  : Icons.notifications_none_rounded,
              title: _isSearchOrFilterActive
                  ? "No matching notifications"
                  : "No Notifications",
              message: _isSearchOrFilterActive
                  ? "Try a different search term or filter."
                  : "You're all caught up.",
              height: 320,
            ),
          ],
        ),
      );
    }

    final sections = _groupedSections;

    return RefreshIndicator(
      onRefresh: () => _fetch(silent: true),
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        itemCount: _sectionedItemCount(sections),
        itemBuilder: (context, index) =>
            _buildSectionedItem(context, sections, index),
      ),
    );
  }

  int _sectionedItemCount(List<MapEntry<String, List<NotificationModel>>> sections) {
    var count = 0;
    for (final section in sections) {
      count += 1 + section.value.length; // header + items
    }
    return count;
  }

  Widget _buildSectionedItem(
    BuildContext context,
    List<MapEntry<String, List<NotificationModel>>> sections,
    int flatIndex,
  ) {
    var remaining = flatIndex;
    for (final section in sections) {
      if (remaining == 0) {
        return _sectionHeader(section.key);
      }
      remaining -= 1;
      if (remaining < section.value.length) {
        final item = section.value[remaining];
        final isLastInSection = remaining == section.value.length - 1;
        return Padding(
          padding: EdgeInsets.only(
            bottom: isLastInSection
                ? AppSpacing.verticalLarge
                : AppSpacing.verticalMedium,
          ),
          child: _swipeableCard(item),
        );
      }
      remaining -= section.value.length;
    }
    // Unreachable given _sectionedItemCount, but keeps the method
    // total and null-safe rather than throwing on a stray index.
    return const SizedBox.shrink();
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.verticalSmall),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _swipeableCard(NotificationModel item) {
    return Dismissible(
      key: ValueKey('notification_${item.id}'),
      direction: DismissDirection.horizontal,
      background: _swipeBackground(
        alignment: Alignment.centerLeft,
        color: AppColors.success,
        icon: Icons.done_rounded,
        label: "Mark Read",
      ),
      secondaryBackground: _swipeBackground(
        alignment: Alignment.centerRight,
        color: AppColors.error,
        icon: Icons.delete_outline,
        label: "Delete",
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right -> Mark Read: apply the update but keep the
          // card in the list, so this direction never removes it.
          _markReadLocally(item.id);
          return false;
        }
        // Swipe left -> Delete.
        await _deleteNotification(item);
        return false; // we already remove it from _all ourselves above
      },
      child: NotificationCard(
        notification: item,
        onTap: () => _onTapNotification(item),
      ),
    );
  }

  Widget _swipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerRight) ...[
            Text(label, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
          ],
          Icon(icon, color: color),
          if (alignment == Alignment.centerLeft) ...[
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}
