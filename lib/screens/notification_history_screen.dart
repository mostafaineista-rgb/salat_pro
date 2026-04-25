import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:salat_pro/core/app_colors.dart';
import 'package:salat_pro/l10n/l10n.dart';
import 'package:salat_pro/services/notification_service.dart';
import 'package:salat_pro/utils/platform_support.dart';

/// Shows the two pieces of OS-level notification state the user actually cares about:
/// pending scheduled adhan alerts and notifications currently in the shade. This is
/// deliberately not the app's settings page — settings stay under the main Settings tab.
class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  Future<_HistorySnapshot>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<_HistorySnapshot> _load() async {
    if (!supportsPrayerNotifications) {
      return const _HistorySnapshot(pending: [], active: []);
    }
    final pending = await NotificationService.pendingRequests();
    final active = await NotificationService.activeNotifications();
    // Sort pending by id so repeated refreshes show stable ordering (ids encode day/prayer).
    pending.sort((a, b) => a.id.compareTo(b.id));
    return _HistorySnapshot(pending: pending, active: active);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = context.strings;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        title: Text(s.notificationHistoryTitle),
        actions: [
          IconButton(
            tooltip: s.notificationHistoryRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<_HistorySnapshot>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data ?? const _HistorySnapshot(pending: [], active: []);
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  s.notificationHistorySubtitle,
                  style: TextStyle(color: palette.textSecondary, height: 1.4, fontSize: 13),
                ),
                const SizedBox(height: 20),
                _SectionHeader(label: s.notificationHistoryActiveSection),
                const SizedBox(height: 8),
                if (data.active.isEmpty)
                  _EmptyRow(text: s.notificationHistoryEmptyActive)
                else
                  ...data.active.map((n) => _ActiveNotificationTile(n: n)),
                const SizedBox(height: 24),
                _SectionHeader(label: s.notificationHistoryScheduledSection),
                const SizedBox(height: 8),
                if (data.pending.isEmpty)
                  _EmptyRow(text: s.notificationHistoryEmptyScheduled)
                else
                  ...data.pending.map((p) => _PendingNotificationTile(p: p)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HistorySnapshot {
  const _HistorySnapshot({required this.pending, required this.active});
  final List<PendingNotificationRequest> pending;
  final List<ActiveNotification> active;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Text(
      label,
      style: TextStyle(
        color: palette.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.strokeVerySubtle),
      ),
      child: Row(
        children: [
          Icon(Icons.inbox_outlined, color: palette.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: palette.textSecondary, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _PendingNotificationTile extends StatelessWidget {
  const _PendingNotificationTile({required this.p});
  final PendingNotificationRequest p;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = context.strings;
    final title = p.title ?? '';
    final body = p.body ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.strokeVerySubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule, color: palette.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(title, style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w600)),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(body, style: TextStyle(color: palette.textSecondary, fontSize: 12)),
                ],
                const SizedBox(height: 4),
                Text(
                  s.notificationIdLabel(p.id),
                  style: TextStyle(color: palette.textSecondary.withValues(alpha: 0.7), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveNotificationTile extends StatelessWidget {
  const _ActiveNotificationTile({required this.n});
  final ActiveNotification n;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = context.strings;
    final title = n.title ?? '';
    final body = n.body ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_active, color: palette.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(title, style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w600)),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(body, style: TextStyle(color: palette.textSecondary, fontSize: 12)),
                ],
                if (n.id != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    s.notificationIdLabel(n.id!),
                    style: TextStyle(color: palette.textSecondary.withValues(alpha: 0.7), fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
