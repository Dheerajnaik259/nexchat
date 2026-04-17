import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/status_model.dart';
import '../services/supabase/database_service.dart';

/// My status updates from Supabase
final myStatusesProvider = FutureProvider<List<StatusModel>>((ref) async {
  return DatabaseService.instance.getMyStatuses();
});

/// Contact statuses — grouped by userId
/// Pass list of contact user IDs to fetch their active stories
final contactStatusesProvider = FutureProvider.family<List<StatusModel>, List<String>>(
  (ref, contactUserIds) async {
    return DatabaseService.instance.getActiveStatuses(contactUserIds);
  },
);

/// Grouped statuses: userId → List<StatusModel>
final groupedStatusesProvider = Provider.family<Map<String, List<StatusModel>>, List<StatusModel>>(
  (ref, statuses) {
    final Map<String, List<StatusModel>> grouped = {};
    for (final status in statuses) {
      grouped.putIfAbsent(status.userId, () => []).add(status);
    }
    return grouped;
  },
);

/// Currently viewing status index
final currentStatusIndexProvider = StateProvider<int>((ref) => 0);

/// Status creation loading state
final statusUploadingProvider = StateProvider<bool>((ref) => false);
