import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../providers/group_provider.dart';
import '../../../features/groups/controllers/group_controller.dart';
import '../../../services/media/media_picker_service.dart';
import '../../../core/constants/route_constants.dart';
import '../../../models/chat_model.dart';

/// Group info and settings screen
class GroupInfoScreen extends ConsumerStatefulWidget {
  final String chatId;

  const GroupInfoScreen({super.key, required this.chatId});

  @override
  ConsumerState<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends ConsumerState<GroupInfoScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _groupNameController;
  late TextEditingController _descriptionController;
  late TabController _tabController;
  File? _newAvatarFile;
  String? _editingGroupName;
  String? _editingDescription;
  bool _isEditingBasicInfo = false;

  final _currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickGroupAvatar() async {
    try {
      final image = await MediaPickerService.instance
          .pickImage(ImageSource.gallery);
      if (image != null) {
        final compressed = await MediaPickerService.instance.compressImage(image);
        setState(() => _newAvatarFile = compressed);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _startEditingBasicInfo(ChatModel group) {
    _groupNameController.text = group.name ?? '';
    _descriptionController.text = group.description ?? '';
    setState(() => _isEditingBasicInfo = true);
  }

  void _saveBasicInfo() async {
    ref.read(groupEditingProvider.notifier).initializeFromGroup(
          ref.watch(groupProvider(widget.chatId)).value ??
              const ChatModel(
                chatId: '',
                type: ChatType.group,
                participants: [],
                createdBy: '',
              ),
        );

    ref.read(groupEditingProvider.notifier)
        .setGroupName(_groupNameController.text);
    ref.read(groupEditingProvider.notifier)
        .setDescription(_descriptionController.text);

    if (_newAvatarFile != null) {
      ref.read(groupEditingProvider.notifier)
          .setAvatarUrl(_newAvatarFile!.path);
    }

    final success = await ref
        .read(groupEditingProvider.notifier)
        .updateGroup();

    if (mounted) {
      setState(() => _isEditingBasicInfo = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group updated successfully')),
        );
      } else {
        final error = ref.read(groupEditingProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to update group')),
        );
      }
    }
  }

  void _leaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgDarkSecondary,
        title: Text(
          'Leave Group?',
          style: AppTextStyles.h4.copyWith(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to leave this group?',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              context.pop();
              final success = await ref
                  .read(groupChatControllerProvider(widget.chatId).notifier)
                  .leaveGroup();
              if (mounted) {
                if (success) {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You left the group')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to leave group')),
                  );
                }
              }
            },
            child: const Text(
              'Leave',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupProvider(widget.chatId));
    final membersAsync = ref.watch(groupMembersProvider(widget.chatId));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return const Center(
              child: Text('Group not found'),
            );
          }

          final isAdmin = group.admins.contains(_currentUserId);

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                backgroundColor: AppColors.bgDark,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                expandedHeight: 240,
                flexibleSpace: FlexibleSpaceBar(
                  background: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // Group Avatar
                        GestureDetector(
                          onTap: isAdmin ? _pickGroupAvatar : null,
                          child: GlassContainer(
                            borderRadius: 60,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.bgDarkSecondary,
                              ),
                              child: _newAvatarFile != null
                                  ? ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(60),
                                      child: Image.file(
                                        _newAvatarFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : group.avatarUrl != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(60),
                                          child: Image.network(
                                            group.avatarUrl!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Icon(
                                          Icons.groups_rounded,
                                          color: AppColors.neonPurple,
                                          size: 50,
                                        ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Group Name
                        Text(
                          group.name ?? 'Group',
                          style: AppTextStyles.h3.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Member Count
                        Text(
                          '${group.participants.length} members',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            body: Column(
              children: [
                // Tab Bar
                Container(
                  color: AppColors.bgDarkSecondary,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.neonPurple,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    tabs: const [
                      Tab(text: 'Info'),
                      Tab(text: 'Members'),
                    ],
                  ),
                ),
                // Tab View
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Info Tab
                      _buildInfoTab(group, isAdmin),
                      // Members Tab
                      _buildMembersTab(group, isAdmin, membersAsync),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.neonPurple),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading group',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white38),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab(ChatModel group, bool isAdmin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info Section
          GlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Group Details',
                        style: AppTextStyles.h4.copyWith(color: Colors.white),
                      ),
                      const Spacer(),
                      if (isAdmin && !_isEditingBasicInfo)
                        GestureDetector(
                          onTap: () => _startEditingBasicInfo(group),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neonPurple.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              color: AppColors.neonPurple,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isEditingBasicInfo) ...[
                    Text(
                      'Group Name',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _groupNameController,
                      hintText: 'Group name',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Description',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _descriptionController,
                      hintText: 'Group description',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Cancel',
                            isOutlined: true,
                            onPressed: () {
                              setState(
                                  () => _isEditingBasicInfo = false);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'Save',
                            onPressed: _saveBasicInfo,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _buildInfoRow('Name', group.name ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Description',
                        group.description ?? 'No description'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Created',
                        _formatDate(group.createdAt)),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Admin',
                      group.admins.isNotEmpty ? 'Yes' : 'No',
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Actions
          if (isAdmin)
            GlassContainer(
              child: ListTile(
                leading: const Icon(
                  Icons.person_add_rounded,
                  color: AppColors.neonPurple,
                ),
                title: Text(
                  'Add Members',
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                ),
                onTap: () {
                  context.pushNamed(
                    RouteConstants.addMembers,
                    pathParameters: {'groupId': widget.chatId},
                  );
                },
              ),
            ),

          const SizedBox(height: 12),

          GlassContainer(
            child: ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              title: Text(
                'Leave Group',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.redAccent,
                ),
              ),
              onTap: _leaveGroup,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(
    ChatModel group,
    bool isAdmin,
    AsyncValue<List<Map<String, dynamic>>> membersAsync,
  ) {
    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return Center(
            child: Text(
              'No members',
              style:
                  AppTextStyles.bodyMedium.copyWith(color: Colors.white38),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            final userId = member['user_id'] as String? ?? '';
            final displayName = member['display_name'] as String? ??
                member['name'] as String? ??
                'User';
            final avatarUrl = member['avatar_url'] as String?;
            final isAdminMember = group.admins.contains(userId);
            final isCurrentUser = userId == _currentUserId;

            return GlassContainer(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          displayName.characters.first.toUpperCase(),
                          style: AppTextStyles.button,
                        )
                      : null,
                ),
                title: Text(
                  displayName,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: Colors.white),
                ),
                subtitle: isAdminMember
                    ? Text(
                        'Admin',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neonPurple,
                        ),
                      )
                    : null,
                trailing: isAdmin &&
                        !isCurrentUser &&
                        (isAdminMember || group.admins.contains(_currentUserId))
                    ? PopupMenuButton<String>(
                        color: AppColors.bgDarkSecondary,
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'promote',
                            child: Text(
                              isAdminMember ? 'Demote' : 'Promote to Admin',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'remove',
                            child: const Text(
                              'Remove',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'promote') {
                            if (isAdminMember) {
                              ref
                                  .read(groupMemberManagementProvider.notifier)
                                  .demoteFromAdmin(
                                    widget.chatId,
                                    userId,
                                  );
                            } else {
                              ref
                                  .read(groupMemberManagementProvider.notifier)
                                  .promoteToAdmin(
                                    widget.chatId,
                                    userId,
                                  );
                            }
                          } else if (value == 'remove') {
                            ref
                                .read(groupMemberManagementProvider.notifier)
                                .removeMember(userId);
                          }
                        },
                      )
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.neonPurple),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Error loading members',
          style:
              AppTextStyles.bodyMedium.copyWith(color: Colors.white38),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
