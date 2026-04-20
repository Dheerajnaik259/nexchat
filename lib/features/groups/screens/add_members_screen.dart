import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../providers/contact_provider.dart';
import '../../../providers/group_provider.dart';

/// Add members to existing group
class AddMembersScreen extends ConsumerStatefulWidget {
  final String chatId;

  const AddMembersScreen({super.key, required this.chatId});

  @override
  ConsumerState<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends ConsumerState<AddMembersScreen> {
  late TextEditingController _searchController;
  bool _showAllContacts = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Initialize member management for this group
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupMemberManagementProvider.notifier)
          .initialize(widget.chatId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addMembers() async {
    final memberMgmt = ref.read(groupMemberManagementProvider);
    
    if (memberMgmt.membersToAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select members to add')),
      );
      return;
    }

    final success = await ref
        .read(groupMemberManagementProvider.notifier)
        .applyChanges();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Members added successfully')),
        );
        context.pop();
      } else {
        final error = ref.read(groupMemberManagementProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to add members')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberMgmt = ref.watch(groupMemberManagementProvider);
    final selectedCount = memberMgmt.membersToAdd.length;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        title: Text(
          'Add Members',
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            ref.read(groupMemberManagementProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selection count
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.neonPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Selected: $selectedCount member${selectedCount != 1 ? 's' : ''}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neonPurple,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Filter options
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _searchController,
                    hintText: 'Search members...',
                    prefixIcon: Icons.search_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() => _showAllContacts = !_showAllContacts);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgDarkSecondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _showAllContacts ? 'All' : 'Reg.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.neonPurple),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Members list
            _buildMembersList(
              showAll: _showAllContacts,
              searchQuery: _searchController.text,
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Cancel',
                    isOutlined: true,
                    onPressed: () {
                      ref
                          .read(groupMemberManagementProvider.notifier)
                          .reset();
                      context.pop();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Add Members',
                    isLoading: memberMgmt.isUpdating,
                    onPressed:
                        memberMgmt.isUpdating ? null : _addMembers,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList({
    required bool showAll,
    required String searchQuery,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        final contactsAsync = ref.watch(contactListProvider);
        final membersToAdd =
            ref.watch(groupMemberManagementProvider).membersToAdd;

        return contactsAsync.when(
          data: (contacts) {
            // Filter contacts
            var filteredContacts = contacts;

            if (!showAll) {
              filteredContacts = contacts
                  .where((c) => c.isRegistered)
                  .toList();
            }

            if (searchQuery.isNotEmpty) {
              final query = searchQuery.toLowerCase();
              filteredContacts = filteredContacts
                  .where((c) =>
                      c.name.toLowerCase().contains(query) ||
                      (c.username?.toLowerCase().contains(query) ?? false))
                  .toList();
            }

            if (filteredContacts.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    searchQuery.isEmpty
                        ? 'No contacts available'
                        : 'No results found',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white38),
                  ),
                ),
              );
            }

            return Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = filteredContacts[index];
                  final isSelected = membersToAdd.contains(contact.userId);

                  return GlassContainer(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage: contact.avatarUrl != null
                            ? NetworkImage(contact.avatarUrl!)
                            : null,
                        child: contact.avatarUrl == null
                            ? Text(
                                contact.name.characters.first
                                    .toUpperCase(),
                                style: AppTextStyles.button,
                              )
                            : null,
                      ),
                      title: Text(
                        contact.name,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: Colors.white),
                      ),
                      subtitle: contact.username != null
                          ? Text(
                              '@${contact.username}',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: Colors.white54),
                            )
                          : null,
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          ref
                              .read(
                                  groupMemberManagementProvider.notifier)
                              .toggleMemberToAdd(contact.userId);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: const BorderSide(
                          color: AppColors.neonPurple,
                        ),
                        fillColor: MaterialStateProperty.resolveWith(
                          (states) {
                            if (states
                                .contains(MaterialState.selected)) {
                              return AppColors.neonPurple;
                            }
                            return Colors.transparent;
                          },
                        ),
                      ),
                      onTap: () {
                        ref
                            .read(
                                groupMemberManagementProvider.notifier)
                            .toggleMemberToAdd(contact.userId);
                      },
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
                color: AppColors.neonPurple),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error loading contacts',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: Colors.white38),
            ),
          ),
        );
      },
    );
  }
}
