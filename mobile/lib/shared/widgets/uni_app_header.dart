import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// UniCheck Standard Mobile App Header
/// Based on Google Stitch Screen: e5dc325d674f478ca6d5ac7c910898a6 & 201c64df9c7d465d8bc8dacc30b91828
class UniAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final bool showBrand;
  final bool showBackButton;
  final VoidCallback? onBack;
  final VoidCallback? onNotificationTap;
  final int unreadNotifications;
  final VoidCallback? onProfileTap;
  final String? avatarUrl;
  final String? userInitial;
  final List<Widget>? actions;

  const UniAppHeader({
    super.key,
    this.title,
    this.subtitle,
    this.showBrand = true,
    this.showBackButton = false,
    this.onBack,
    this.onNotificationTap,
    this.unreadNotifications = 0,
    this.onProfileTap,
    this.avatarUrl,
    this.userInitial,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UniColors.card,
        border: const Border(
          bottom: BorderSide(color: UniColors.border, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: UniSpacing.screenMargin),
          child: Row(
            children: [
              if (showBackButton) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  color: UniColors.textPrimary,
                  tooltip: 'Quay lại',
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  constraints: const BoxConstraints(
                    minWidth: UniSpacing.minTouchTarget,
                    minHeight: UniSpacing.minTouchTarget,
                  ),
                ),
                const SizedBox(width: UniSpacing.spaceXs),
              ],
              if (showBrand && !showBackButton)
                _buildBrandTitle()
              else
                _buildCustomTitle(),

              const Spacer(),

              // Custom actions or default notification + profile avatar
              if (actions != null)
                ...actions!
              else ...[
                // Notification Button with Unread Badge
                _buildNotificationButton(),
                const SizedBox(width: UniSpacing.spaceSm),
                // Profile Avatar / Initial
                _buildProfileAvatar(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: UniColors.primary,
            borderRadius: UniSpacing.borderRadiusSm,
          ),
          child: const Icon(
            Icons.school_rounded,
            color: UniColors.onPrimary,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UniCheck',
              style: UniTypography.headlineSmall.copyWith(
                color: UniColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Cổng học vụ số',
              style: UniTypography.caption.copyWith(
                color: UniColors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Text(
            title!,
            style: UniTypography.titleLarge,
          ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: UniTypography.caption,
          ),
      ],
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 24),
          color: UniColors.textSecondary,
          tooltip: 'Thông báo',
          constraints: const BoxConstraints(
            minWidth: UniSpacing.minTouchTarget,
            minHeight: UniSpacing.minTouchTarget,
          ),
          onPressed: onNotificationTap,
        ),
        if (unreadNotifications > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: UniColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadNotifications > 99 ? '99+' : '$unreadNotifications',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    return InkWell(
      onTap: onProfileTap,
      borderRadius: UniSpacing.borderRadiusFull,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: UniColors.primaryLight,
          shape: BoxShape.circle,
          border: Border.all(
              color: UniColors.primary.withValues(alpha: 0.2), width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: avatarUrl != null
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackInitial(),
              )
            : _buildFallbackInitial(),
      ),
    );
  }

  Widget _buildFallbackInitial() {
    return Center(
      child: Text(
        userInitial ?? 'SV',
        style: UniTypography.labelSmall.copyWith(
          color: UniColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
