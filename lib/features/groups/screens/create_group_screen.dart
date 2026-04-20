import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../providers/contact_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../services/media/media_picker_service.dart';
import '../../../core/constants/route_constants.dart';
import '../../../models/contact_model.dart';

/// Create a new group chat
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  late TextEditingController _groupNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _searchController;
  File? _avatarFile;
  String? _avatarUrl;
  bool _showAllContacts = false;

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickGroupAvatar() async {
    try {
      final image = await MediaPickerService.instance
          .pickImage(ImageSource.gallery);
      if (image != null) {
        final compressed = await MediaPickerService.instance.compressImage(image);
        setState(() {
          _avatarFile = compressed;
          _avatarUrl = compressed.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _createGroup() async {
    if (_groupNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    // Get selected members from provider
    final selectedMembers = ref.read(groupCreationProvider).selectedMemberIds;
    if (selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    // Update group name and description in provider
    ref.read(groupCreationProvider.notifier)
        .setGroupName(_groupNameController.text);
    ref.read(groupCreationProvider.notifier)
        .setDescription(_descriptionController.text);
    if (_avatarUrl != null) {
      ref.read(groupCreationProvider.notifier).setAvatarUrl(_avatarUrl!);
    }

    // Create group
    final group = await ref
        .read(groupCreationProvider.notifier)
        .createGroup();

    if (mounted) {
      if (group != null) {
        context.pop();
        // Navigate to group chat
        context.pushNamed(
          RouteConstants.groupChat,
          pathParameters: {'groupId': group.chatId},
        );
      } else {
        final error = ref.read(groupCreationProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to create group')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupCreation = ref.watch(groupCreationProvider);
    final selectedCount = groupCreation.selectedMemberIds.length;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        title: Text(
          'Create Group',
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            ref.read(groupCreationProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Group Avatar ────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _pickGroupAvatar,
                child: GlassContainer(
                  borderRadius: 60,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bgDarkSecondary,
                    ),
                    child: _avatarFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.file(
                              _avatarFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.camera_alt_rounded,
                            color: AppColors.neonPurple,
                            size: 40,
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Group Name ──────────────────────────────
            Text(
              'Group Name *',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _groupNameController,
              hintText: 'Enter group name',
              prefixIcon: Icons.groups_rounded,
            ),

            const SizedBox(height: 16),

            // ── Description (optional) ──────────────────
            Text(
              'Description (Optional)',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _descriptionController,
              hintText: 'What is this group about?',
              prefixIcon: Icons.edit_rounded,
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // ── Members Selection ────────────────────────
            Row(
              children: [
                Text(
                  'Add Members ($selectedCount)',
                  style: AppTextStyles.h4.copyWith(color: Colors.white),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() => _showAllContacts = !_showAllContacts);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgDarkSecondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _showAllContacts ? 'Registered' : 'All',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.neonPurple),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Search members
            CustomTextField(
              controller: _searchController,
              hintText: 'Search members...',
              prefixIcon: Icons.search_rounded,
            ),

            const SizedBox(height: 12),

            // ── Members List ────────────────────────────
            _buildMembersList(
              showAll: _showAllContacts,
              searchQuery: _searchController.text,
            ),

            const SizedBox(height: 24),

            // ── Create Button ────────────────────────────
            CustomButton(
              text: 'Create Group',
              isLoading: groupCreation.isCreating,
              onPressed: groupCreation.isCreating ? null : _createGroup,
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
        final selectedMembers =
            ref.watch(groupCreationProvider).selectedMemberIds;

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
                  final isSelected =
                      selectedMembers.contains(contact.userId);

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
                                contact.name.characters.first.toUpperCase(),
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
                              .read(groupCreationProvider.notifier)
                              .toggleMember(contact.userId);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: const BorderSide(
                          color: AppColors.neonPurple,
                        ),
                        fillColor: MaterialStateProperty.resolveWith(
                          (states) {
                            if (states.contains(MaterialState.selected)) {
                              return AppColors.neonPurple;
                            }
                            return Colors.transparent;
                          },
                        ),
                      ),
                      onTap: () {
                        ref
                            .read(groupCreationProvider.notifier)
                            .toggleMember(contact.userId);
                      },
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonPurple),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error loading contacts',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white38),
            ),
          ),
        );
      },
    );
  }
}
