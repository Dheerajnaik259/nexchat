import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';

/// Expandable FAB menu widget
class FabMenuWidget extends StatefulWidget {
  final List<FabMenuItem> items;

  const FabMenuWidget({super.key, required this.items});

  @override
  State<FabMenuWidget> createState() => _FabMenuWidgetState();
}

class _FabMenuWidgetState extends State<FabMenuWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      _isOpen ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Menu items
        if (_isOpen)
          ...widget.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 150 + (index * 50)),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgDarkSecondary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.color ?? AppColors.neonPurple,
                        boxShadow: [
                          BoxShadow(
                            color: (item.color ?? AppColors.neonPurple)
                                .withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          _toggle();
                          item.onTap();
                        },
                        icon: Icon(item.icon, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

        // Main FAB
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.purpleBlue,
            boxShadow: [
              BoxShadow(
                color: AppColors.neonPurple.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _toggle,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: AnimatedRotation(
              turns: _isOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                _isOpen ? Icons.close_rounded : Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Menu item for the FAB
class FabMenuItem {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const FabMenuItem({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });
}
