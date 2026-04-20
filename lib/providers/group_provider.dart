import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/supabase/database_service.dart';

/// Stream for a specific group (real-time updates)
final groupProvider = StreamProvider.family<ChatModel?, String>(
  (ref, groupId) {
    return DatabaseService.instance.streamGroup(groupId);
  },
);

/// Get all groups the user is a member of
final userGroupsProvider = Provider<AsyncValue<List<ChatModel>>>((ref) {
  final allChats = ref.watch(chatListProvider);
  
  return allChats.whenData((chats) {
    return chats.where((chat) => chat.type == ChatType.group).toList();
  });
});

/// Stream to watch chat list (imported from chat_provider)
final chatListProvider = StreamProvider<List<ChatModel>>((ref) {
  return DatabaseService.instance.streamUserChats();
});

/// Get members of a specific group (with user details)
final groupMembersProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, groupId) async {
    return DatabaseService.instance.getGroupMembers(groupId);
  },
);

/// Group creation state
final groupCreationProvider = StateNotifierProvider<GroupCreationNotifier, GroupCreationState>((ref) {
  return GroupCreationNotifier(ref);
});

class GroupCreationState {
  final String groupName;
  final String description;
  final List<String> selectedMemberIds;
  final String? avatarUrl;
  final bool isCreating;
  final String? error;

  const GroupCreationState({
    this.groupName = '',
    this.description = '',
    this.selectedMemberIds = const [],
    this.avatarUrl,
    this.isCreating = false,
    this.error,
  });

  GroupCreationState copyWith({
    String? groupName,
    String? description,
    List<String>? selectedMemberIds,
    String? avatarUrl,
    bool? isCreating,
    String? error,
  }) {
    return GroupCreationState(
      groupName: groupName ?? this.groupName,
      description: description ?? this.description,
      selectedMemberIds: selectedMemberIds ?? this.selectedMemberIds,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isCreating: isCreating ?? this.isCreating,
      error: error ?? this.error,
    );
  }
}

class GroupCreationNotifier extends StateNotifier<GroupCreationState> {
  final Ref ref;

  GroupCreationNotifier(this.ref) : super(const GroupCreationState());

  void setGroupName(String name) {
    state = state.copyWith(groupName: name);
  }

  void setDescription(String desc) {
    state = state.copyWith(description: desc);
  }

  void toggleMember(String userId) {
    final ids = {...state.selectedMemberIds};
    if (ids.contains(userId)) {
      ids.remove(userId);
    } else {
      ids.add(userId);
    }
    state = state.copyWith(selectedMemberIds: ids.toList());
  }

  void setAvatarUrl(String url) {
    state = state.copyWith(avatarUrl: url);
  }

  Future<ChatModel?> createGroup() async {
    if (state.groupName.isEmpty) {
      state = state.copyWith(error: 'Group name is required');
      return null;
    }

    if (state.selectedMemberIds.isEmpty) {
      state = state.copyWith(error: 'Select at least one member');
      return null;
    }

    state = state.copyWith(isCreating: true, error: null);

    try {
      final group = await DatabaseService.instance.createGroup(
        groupName: state.groupName,
        description: state.description,
        memberIds: state.selectedMemberIds,
        avatarUrl: state.avatarUrl,
      );

      // Reset form
      state = const GroupCreationState();
      return group;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        error: 'Failed to create group: ${e.toString()}',
      );
      return null;
    }
  }

  void reset() {
    state = const GroupCreationState();
  }
}

/// Group settings/editing state
final groupEditingProvider = StateNotifierProvider<GroupEditingNotifier, GroupEditingState>((ref) {
  return GroupEditingNotifier(ref);
});

class GroupEditingState {
  final String groupId;
  final String groupName;
  final String description;
  final String? avatarUrl;
  final bool isUpdating;
  final String? error;

  const GroupEditingState({
    required this.groupId,
    this.groupName = '',
    this.description = '',
    this.avatarUrl,
    this.isUpdating = false,
    this.error,
  });

  GroupEditingState copyWith({
    String? groupId,
    String? groupName,
    String? description,
    String? avatarUrl,
    bool? isUpdating,
    String? error,
  }) {
    return GroupEditingState(
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error ?? this.error,
    );
  }
}

class GroupEditingNotifier extends StateNotifier<GroupEditingState> {
  final Ref ref;

  GroupEditingNotifier(this.ref)
      : super(const GroupEditingState(groupId: ''));

  void initializeFromGroup(ChatModel group) {
    state = GroupEditingState(
      groupId: group.chatId,
      groupName: group.name ?? '',
      description: group.description ?? '',
      avatarUrl: group.avatarUrl,
    );
  }

  void setGroupName(String name) {
    state = state.copyWith(groupName: name);
  }

  void setDescription(String desc) {
    state = state.copyWith(description: desc);
  }

  void setAvatarUrl(String url) {
    state = state.copyWith(avatarUrl: url);
  }

  Future<bool> updateGroup() async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      await DatabaseService.instance.updateGroupInfo(
        state.groupId,
        name: state.groupName,
        description: state.description,
        avatarUrl: state.avatarUrl,
      );
      state = state.copyWith(isUpdating: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update group: ${e.toString()}',
      );
      return false;
    }
  }

  void reset() {
    state = const GroupEditingState(groupId: '');
  }
}

/// State for managing group members
final groupMemberManagementProvider = StateNotifierProvider<GroupMemberManagementNotifier, GroupMemberManagementState>((ref) {
  return GroupMemberManagementNotifier(ref);
});

class GroupMemberManagementState {
  final String groupId;
  final List<String> membersToAdd;
  final List<String> membersToRemove;
  final bool isUpdating;
  final String? error;

  const GroupMemberManagementState({
    required this.groupId,
    this.membersToAdd = const [],
    this.membersToRemove = const [],
    this.isUpdating = false,
    this.error,
  });

  GroupMemberManagementState copyWith({
    String? groupId,
    List<String>? membersToAdd,
    List<String>? membersToRemove,
    bool? isUpdating,
    String? error,
  }) {
    return GroupMemberManagementState(
      groupId: groupId ?? this.groupId,
      membersToAdd: membersToAdd ?? this.membersToAdd,
      membersToRemove: membersToRemove ?? this.membersToRemove,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error ?? this.error,
    );
  }
}

class GroupMemberManagementNotifier extends StateNotifier<GroupMemberManagementState> {
  final Ref ref;

  GroupMemberManagementNotifier(this.ref)
      : super(GroupMemberManagementState(groupId: ''));

  void initialize(String groupId) {
    state = GroupMemberManagementState(groupId: groupId);
  }

  void toggleMemberToAdd(String userId) {
    final members = {...state.membersToAdd};
    if (members.contains(userId)) {
      members.remove(userId);
    } else {
      members.add(userId);
    }
    state = state.copyWith(membersToAdd: members.toList());
  }

  void toggleMemberToRemove(String userId) {
    final members = {...state.membersToRemove};
    if (members.contains(userId)) {
      members.remove(userId);
    } else {
      members.add(userId);
    }
    state = state.copyWith(membersToRemove: members.toList());
  }

  Future<bool> applyChanges() async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      // Add members
      if (state.membersToAdd.isNotEmpty) {
        await DatabaseService.instance
            .addGroupMembers(state.groupId, state.membersToAdd);
      }

      // Remove members
      for (final memberId in state.membersToRemove) {
        await DatabaseService.instance
            .removeGroupMember(state.groupId, memberId);
      }

      state = state.copyWith(
        isUpdating: false,
        membersToAdd: [],
        membersToRemove: [],
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update members: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> removeMember(String userId) async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      await DatabaseService.instance
          .removeGroupMember(state.groupId, userId);
      state = state.copyWith(isUpdating: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to remove member: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> promoteToAdmin(String userId) async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      await DatabaseService.instance
          .promoteToAdmin(state.groupId, userId);
      state = state.copyWith(isUpdating: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to promote member: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> demoteFromAdmin(String userId) async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      await DatabaseService.instance
          .demoteFromAdmin(state.groupId, userId);
      state = state.copyWith(isUpdating: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to demote member: ${e.toString()}',
      );
      return false;
    }
  }

  void reset() {
    state = GroupMemberManagementState(groupId: state.groupId);
  }
}
