import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact_model.dart';

/// Contact list provider
final contactListProvider = StateNotifierProvider<ContactListNotifier, AsyncValue<List<ContactModel>>>((ref) {
  return ContactListNotifier();
});

class ContactListNotifier extends StateNotifier<AsyncValue<List<ContactModel>>> {
  ContactListNotifier() : super(const AsyncValue.data([]));

  /// Sync contacts from device
  Future<void> syncContacts() async {
    state = const AsyncValue.loading();
    try {
      // TODO: Connect to ContactSyncService when ready
      state = const AsyncValue.data([]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Search contacts
  List<ContactModel> search(String query, List<ContactModel> contacts) {
    if (query.isEmpty) return contacts;
    final lower = query.toLowerCase();
    return contacts.where((c) {
      return c.name.toLowerCase().contains(lower) ||
          c.phone.contains(lower) ||
          (c.username?.toLowerCase().contains(lower) ?? false);
    }).toList();
  }

  /// Get NexChat-registered contacts only
  List<ContactModel> get registeredContacts {
    return state.valueOrNull?.where((c) => c.isRegistered).toList() ?? [];
  }
}

/// Selected contacts (for group creation, forwarding, etc.)
final selectedContactsProvider = StateProvider<List<ContactModel>>((ref) => []);
