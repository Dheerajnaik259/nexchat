import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/constants/route_constants.dart';
import '../../../providers/chat_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../widgets/chat_list_tile.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/fab_menu_widget.dart';
import '../../../core/widgets/skeleton_loader.dart';

/// Home screen — TabBar: Chats / Calls / Status + bottom nav
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  // Logo + Title
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppGradients.primary.createShader(bounds),
                    child: Text(
                      'NexChat',
                      style: AppTextStyles.h2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Search icon
                  _AppBarIcon(
                    icon: Icons.search_rounded,
                    onTap: () {
                      // TODO: Open search
                    },
                  ),
                  const SizedBox(width: 4),
                  // More options
                  _AppBarIcon(
                    icon: Icons.more_vert_rounded,
                    onTap: () {
                      // TODO: Show menu
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Tab Bar ──────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.bgDarkSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: AppGradients.purpleBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textTertiary,
                labelStyle: const TextStyle(

                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Chats'),
                  Tab(text: 'Calls'),
                  Tab(text: 'Status'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Tab Content ──────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ChatsTab(),
                  _CallsTab(),
                  _StatusTab(),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Bottom Navigation ────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bgDarkSecondary,
          border: Border(
            top: BorderSide(
              color: AppColors.divider.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _bottomNavIndex,
          onTap: (index) {
            setState(() => _bottomNavIndex = index);
            switch (index) {
              case 0:
                break; // Already on home
              case 1:
                context.push(RouteConstants.contacts);
                break;
              case 2:
                context.push(RouteConstants.myProfile);
                break;
              case 3:
                context.push(RouteConstants.settings);
                break;
            }
          },
          items: [
            _buildNavItem(Icons.chat_bubble_rounded, 'Chats', 0),
            _buildNavItem(Icons.people_rounded, 'Contacts', 1),
            _buildNavItem(Icons.person_rounded, 'Profile', 2),
            _buildNavItem(Icons.settings_rounded, 'Settings', 3),
          ],
        ),
      ),

      // ── FAB ──────────────────────────────────────────
      floatingActionButton: Container(
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
          onPressed: () {
            context.push(RouteConstants.contacts);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.edit_rounded, color: Colors.white),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    int index,
  ) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      activeIcon: ShaderMask(
        shaderCallback: (bounds) =>
            AppGradients.purpleBlue.createShader(bounds),
        child: Icon(icon, color: Colors.white),
      ),
      label: label,
    );
  }
}

// ─── App Bar Icon ────────────────────────────────────────────────

class _AppBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.bgDarkSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
      ),
    );
  }
}

// ─── Chats Tab ───────────────────────────────────────────────────

class _ChatsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatListProvider);

    return chatsAsync.when(
      loading: () => const ChatListSkeleton(),
      error: (e, _) => Center(
        child: Text('Error: $e', style: TextStyle(color: AppColors.error)),
      ),
      data: (chats) {
        if (chats.isEmpty) {
          return _EmptyStateWidget(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'No chats yet',
            subtitle: 'Start a conversation by tapping\nthe button below',
            accentColor: AppColors.neonPurple,
          );
        }
        return ListView.builder(
          itemCount: chats.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            final chat = chats[index];
            return ChatListTile(
              name: chat.name ?? 'Chat',
              lastMessage: chat.lastMessage?.text ?? '',
              time: chat.lastActivity != null
                  ? AppDateUtils.formatChatListTime(chat.lastActivity!)
                  : '',
              isOnline: false,
              onTap: () {
                // TODO: Navigate to chat detail screen
              },
            );
          },
        );
      },
    );
  }
}

// ─── Calls Tab ───────────────────────────────────────────────────

class _CallsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _EmptyStateWidget(
      icon: Icons.phone_outlined,
      title: 'No recent calls',
      subtitle: 'Your call history will appear here',
      accentColor: AppColors.neonCyan,
    );
  }
}

// ─── Status Tab ──────────────────────────────────────────────────

class _StatusTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // My status
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.purpleBlue,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonPurple.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neonCyan,
                    border: Border.all(color: AppColors.bgDark, width: 2),
                  ),
                  child: const Icon(Icons.add, size: 12, color: AppColors.bgDark),
                ),
              ),
            ],
          ),
          title: Text('My Status', style: AppTextStyles.chatName),
          subtitle: Text(
            'Tap to add status update',
            style: AppTextStyles.chatPreview,
          ),
          onTap: () {
            // TODO: Create status
          },
        ),
        const Divider(indent: 76, endIndent: 20),

        // Recent updates header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Recent Updates',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 1,
              ),
            ),
          ),
        ),

        // Empty state
        Expanded(
          child: _EmptyStateWidget(
            icon: Icons.auto_awesome_rounded,
            title: 'No updates',
            subtitle: 'Status updates from your contacts\nwill appear here',
            accentColor: AppColors.neonPink,
          ),
        ),
      ],
    );
  }
}

// ─── Empty State Widget ──────────────────────────────────────────

class _EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;

  const _EmptyStateWidget({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.1),
            ),
            child: Icon(icon, size: 40, color: accentColor.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
