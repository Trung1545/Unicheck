import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class DayScheduleInfo {
  final String dayLabel; // T2, T3, T4, T5, T6, T7, CN
  final int dayNumber; // 11, 12, 13...
  final DateTime date;
  final int classCount;
  final bool isToday;

  const DayScheduleInfo({
    required this.dayLabel,
    required this.dayNumber,
    required this.date,
    this.classCount = 0,
    this.isToday = false,
  });
}

/// UniCheck Standard Weekly 7-Day Picker Strip
/// Based on Google Stitch Screen: 04f28f5550b446529b8929a541a68dbd
class WeeklyDayPickerStrip extends StatelessWidget {
  final List<DayScheduleInfo> days;
  final int selectedIndex;
  final ValueChanged<int> onDaySelected;

  const WeeklyDayPickerStrip({
    super.key,
    required this.days,
    required this.selectedIndex,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: UniSpacing.screenMargin, vertical: 2),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: UniSpacing.spaceSm),
        itemBuilder: (context, index) {
          final item = days[index];
          final isSelected = selectedIndex == index;

          return _buildDayPill(
            context: context,
            item: item,
            isSelected: isSelected,
            onTap: () => onDaySelected(index),
          );
        },
      ),
    );
  }

  Widget _buildDayPill({
    required BuildContext context,
    required DayScheduleInfo item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    Color bg = isSelected ? UniColors.primary : UniColors.card;
    Color fg = isSelected ? Colors.white : UniColors.textPrimary;
    Color subFg = isSelected
        ? Colors.white.withValues(alpha: 0.8)
        : UniColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: UniSpacing.borderRadiusLg,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 54,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: UniSpacing.borderRadiusLg,
            border: isSelected
                ? null
                : Border.all(color: UniColors.border, width: 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: UniColors.primary.withValues(alpha: 0.28),
                      offset: const Offset(0, 3),
                      blurRadius: 8,
                    ),
                  ]
                : UniSpacing.cardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top indicator dot if today
              if (item.isToday)
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? UniColors.accentContainer
                        : UniColors.primary,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(height: 5),

              // Day label: T2, T3...
              Text(
                item.dayLabel,
                style: UniTypography.caption.copyWith(
                  color: subFg,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),

              // Day number: 11, 12...
              Text(
                '${item.dayNumber}',
                style: UniTypography.titleLarge.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  height: 1.2,
                ),
              ),

              // Class count label: e.g. "2 lớp", "Nghỉ"
              Text(
                item.classCount > 0 ? '${item.classCount} lớp' : 'Nghỉ',
                style: UniTypography.caption.copyWith(
                  color: subFg,
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
