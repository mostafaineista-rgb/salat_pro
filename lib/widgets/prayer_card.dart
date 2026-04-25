import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrayerCard extends StatelessWidget {
  final String name;
  final DateTime time;
  final IconData icon;
  final bool isNext;
  final String? subtitle;
  final bool use24HourClock;

  const PrayerCard({
    super.key,
    required this.name,
    required this.time,
    required this.icon,
    this.isNext = false,
    this.subtitle,
    this.use24HourClock = false,
  });

  @override
  Widget build(BuildContext context) {
    final loc = Localizations.localeOf(context).toLanguageTag();
    final timeText = use24HourClock
        ? DateFormat.Hm(loc).format(time)
        : DateFormat.jm(loc).format(time);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isNext ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isNext)
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
        border: isNext ? Border.all(color: Theme.of(context).colorScheme.primary) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isNext
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
          Text(
            timeText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
