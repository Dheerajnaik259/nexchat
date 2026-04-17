/// Supabase configuration for NexChat
///
/// Replace the placeholder values below with your actual Supabase credentials.
/// Find them at: https://supabase.com/dashboard → Project Settings → API
class SupabaseConfig {
  SupabaseConfig._();

  /// Your Supabase project URL
  static const String url = 'https://fqsrstkkaptupiicndvf.supabase.co';

  /// Your Supabase anon (public) key
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZxc3JzdGtrYXB0dXBpamNuZHZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0MDI5OTQsImV4cCI6MjA5MTk3ODk5NH0.1lJbIkwNUra27pmZBT9YjXVxQoEO46WgGvfPEHyx_ew';

  /// Storage bucket names
  static const String avatarBucket = 'avatars';
  static const String mediaBucket = 'chat-media';
  static const String statusBucket = 'status-media';
}
