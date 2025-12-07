import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Enhanced Stat Card dengan animasi
class EnhancedStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final Widget? subtitle;

  const EnhancedStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.subtitle,
  });

  @override
  State<EnhancedStatCard> createState() => _EnhancedStatCardState();
}

class _EnhancedStatCardState extends State<EnhancedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.durationNormal,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Card(
            elevation: 0,
            color: AppTheme.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.radiusMedium,
              side: BorderSide(color: AppTheme.borderColor.withOpacity(0.5)),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppTheme.radiusMedium,
                boxShadow: AppTheme.shadowMd,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.1),
                        borderRadius: AppTheme.radiusMedium,
                      ),
                      child: Icon(
                        widget.icon,
                        size: 32,
                        color: widget.color,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      widget.title,
                      style: AppTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      widget.value,
                      style: AppTheme.headingSmall.copyWith(color: widget.color),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: AppTheme.spacingS),
                      widget.subtitle!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Enhanced Action Button
class EnhancedActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const EnhancedActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<EnhancedActionButton> createState() => _EnhancedActionButtonState();
}

class _EnhancedActionButtonState extends State<EnhancedActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.durationNormal,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: 0,
          color: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.radiusLarge,
            side: BorderSide(color: widget.color.withOpacity(0.3)),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppTheme.radiusLarge,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color.withOpacity(0.05),
                  widget.color.withOpacity(0.02),
                ],
              ),
              boxShadow: AppTheme.shadowMd,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [widget.color, widget.color.withOpacity(0.8)],
                      ),
                      borderRadius: AppTheme.radiusMedium,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    widget.label,
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Enhanced Alert Card
class EnhancedAlertCard extends StatelessWidget {
  final String title;
  final String message;
  final AlertType type;
  final VoidCallback? onDismiss;
  final List<Widget>? actions;

  const EnhancedAlertCard({
    required this.title,
    required this.message,
    required this.type,
    this.onDismiss,
    this.actions,
  });

  Color get _backgroundColor {
    switch (type) {
      case AlertType.success:
        return const Color(0xFFF0FDF4);
      case AlertType.error:
        return const Color(0xFFFEF2F2);
      case AlertType.warning:
        return const Color(0xFFFEF3C7);
      case AlertType.info:
        return const Color(0xFFF0F9FF);
    }
  }

  Color get _borderColor {
    switch (type) {
      case AlertType.success:
        return const Color(0x4010B981);
      case AlertType.error:
        return const Color(0x40EF4444);
      case AlertType.warning:
        return const Color(0x40F59E0B);
      case AlertType.info:
        return const Color(0x402563EB);
    }
  }

  Color get _iconColor {
    switch (type) {
      case AlertType.success:
        return const Color(0xFF10B981);
      case AlertType.error:
        return const Color(0xFFEF4444);
      case AlertType.warning:
        return const Color(0xFFF59E0B);
      case AlertType.info:
        return const Color(0xFF2563EB);
    }
  }

  IconData get _icon {
    switch (type) {
      case AlertType.success:
        return Icons.check_circle_outline;
      case AlertType.error:
        return Icons.error_outline;
      case AlertType.warning:
        return Icons.warning_amber;
      case AlertType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.radiusMedium,
        side: BorderSide(color: _borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_icon, color: _iconColor, size: 24),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Text(
                        message,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: AppTheme.textSecondaryColor,
                    onPressed: onDismiss,
                  ),
              ],
            ),
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum AlertType { success, error, warning, info }

// Enhanced List Tile dengan swipe action
class EnhancedListTile extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? tileColor;

  const EnhancedListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.tileColor,
  });

  @override
  State<EnhancedListTile> createState() => _EnhancedListTileState();
}

class _EnhancedListTileState extends State<EnhancedListTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.durationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
          color: widget.tileColor ?? AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.radiusMedium,
            side: BorderSide(color: AppTheme.borderColor.withOpacity(0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingM,
            ),
            child: Row(
              children: [
                if (widget.leading != null) ...[
                  Icon(widget.leading, color: AppTheme.primaryColor),
                  const SizedBox(width: AppTheme.spacingL),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          widget.subtitle!,
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: AppTheme.spacingM),
                  widget.trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Animated Progress Indicator
class EnhancedProgressIndicator extends StatelessWidget {
  final double progress;
  final Color color;
  final String? label;

  const EnhancedProgressIndicator({
    required this.progress,
    this.color = AppTheme.primaryColor,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTheme.bodySmall),
          const SizedBox(height: AppTheme.spacingS),
        ],
        ClipRRect(
          borderRadius: AppTheme.radiusSmall,
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: AppTheme.radiusSmall,
                ),
              ),
              AnimatedFractionallySizedBox(
                widthFactor: progress.clamp(0, 1),
                duration: AppTheme.durationNormal,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withOpacity(0.8)],
                    ),
                    borderRadius: AppTheme.radiusSmall,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Animated Loading Button
class EnhancedLoadingButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  final Color color;
  final IconData? icon;

  const EnhancedLoadingButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.color = AppTheme.primaryColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingL,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.radiusMedium,
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading) ...[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
          ] else if (icon != null) ...[
            Icon(icon),
            const SizedBox(width: AppTheme.spacingM),
          ],
          Text(
            isLoading ? 'Memproses...' : label,
            style: AppTheme.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
