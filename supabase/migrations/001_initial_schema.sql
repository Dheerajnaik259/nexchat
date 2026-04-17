-- ============================================================
-- NexChat Supabase Database Schema
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- ── Enable necessary extensions ─────────────────────────────
create extension if not exists "uuid-ossp";

-- ============================================================
-- 1. USERS TABLE
-- ============================================================
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text unique not null,
  name text not null default '',
  username text unique,
  bio text default '',
  profile_pic_url text default '',
  public_key text default '',
  identity_key text default '',
  signed_pre_key text default '',
  one_time_pre_keys text[] default '{}',
  status text default 'offline' check (status in ('online', 'offline', 'typing')),
  last_seen timestamptz default now(),
  pinned_chats text[] default '{}',
  blocked_users text[] default '{}',
  privacy_settings jsonb default '{"lastSeen": "everyone", "profilePhoto": "everyone", "about": "everyone", "readReceipts": true}'::jsonb,
  notification_settings jsonb default '{"muteAll": false, "showPreview": true}'::jsonb,
  two_step_pin text,
  biometric_enabled boolean default false,
  created_at timestamptz default now(),
  device_tokens text[] default '{}'
);

-- Index for searching users
create index if not exists idx_users_phone on public.users (phone);
create index if not exists idx_users_username on public.users (username);
create index if not exists idx_users_status on public.users (status);

-- ============================================================
-- 2. CHATS TABLE
-- ============================================================
create table if not exists public.chats (
  id uuid primary key default uuid_generate_v4(),
  type text not null default 'private' check (type in ('private', 'group', 'channel', 'secret')),
  participants text[] not null default '{}',
  admins text[] default '{}',
  created_by uuid references public.users(id),
  name text,
  description text,
  avatar_url text,
  last_message jsonb,
  last_activity timestamptz default now(),
  muted_by text[] default '{}',
  pinned_message_id text,
  invite_link text unique,
  is_e2e_enabled boolean default true,
  disappearing_timer int default 0,
  max_members int,
  created_at timestamptz default now()
);

-- Index for querying user's chats
create index if not exists idx_chats_participants on public.chats using gin (participants);
create index if not exists idx_chats_last_activity on public.chats (last_activity desc);

-- ============================================================
-- 3. MESSAGES TABLE
-- ============================================================
create table if not exists public.messages (
  id uuid primary key default uuid_generate_v4(),
  message_id text unique not null default uuid_generate_v4()::text,
  chat_id uuid references public.chats(id) on delete cascade,
  sender_id uuid references public.users(id),
  type text not null default 'text',
  encrypted_text text not null default '',
  encrypted_media_url text,
  media_metadata jsonb,
  reply_to_message_id text,
  forwarded_from text,
  reactions jsonb default '{}'::jsonb,
  read_by jsonb default '{}'::jsonb,
  delivered_to jsonb default '{}'::jsonb,
  edited boolean default false,
  edited_at timestamptz,
  edit_history text[] default '{}',
  is_deleted boolean default false,
  deleted_for_everyone boolean default false,
  deleted_at timestamptz,
  self_destruct_time int default 0,
  is_pinned boolean default false,
  scheduled_at timestamptz,
  status text default 'sent' check (status in ('sent', 'delivered', 'read', 'failed')),
  timestamp timestamptz default now(),
  local_id text
);

-- Indexes for message queries
create index if not exists idx_messages_chat_id on public.messages (chat_id);
create index if not exists idx_messages_sender_id on public.messages (sender_id);
create index if not exists idx_messages_timestamp on public.messages (chat_id, timestamp desc);

-- ============================================================
-- 4. CALLS TABLE
-- ============================================================
create table if not exists public.calls (
  id uuid primary key default uuid_generate_v4(),
  type text not null default 'voice' check (type in ('voice', 'video')),
  caller_id uuid references public.users(id),
  receiver_ids text[] not null default '{}',
  status text not null default 'ringing' check (status in ('ringing', 'accepted', 'rejected', 'missed', 'ended')),
  started_at timestamptz,
  ended_at timestamptz,
  duration int,
  is_group boolean default false,
  signaling_data jsonb,
  created_at timestamptz default now()
);

-- Index for call history
create index if not exists idx_calls_caller_id on public.calls (caller_id);
create index if not exists idx_calls_status on public.calls (status);

-- ============================================================
-- 5. STATUS TABLE (Stories)
-- ============================================================
create table if not exists public.status (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users(id) on delete cascade,
  type text not null default 'text' check (type in ('text', 'image', 'video')),
  content text,
  media_url text,
  background_color text,
  font_style text,
  duration int,
  seen_by text[] default '{}',
  allowed_viewers text[] default '{}',
  expires_at timestamptz default (now() + interval '24 hours'),
  created_at timestamptz default now()
);

-- Index for active statuses
create index if not exists idx_status_user_id on public.status (user_id);
create index if not exists idx_status_expires_at on public.status (expires_at);

-- ============================================================
-- 6. POLLS TABLE
-- ============================================================
create table if not exists public.polls (
  id uuid primary key default uuid_generate_v4(),
  chat_id uuid references public.chats(id) on delete cascade,
  message_id text,
  question text not null,
  options jsonb not null default '[]'::jsonb,
  votes jsonb default '{}'::jsonb,
  is_anonymous boolean default false,
  is_multiple_choice boolean default false,
  is_quiz boolean default false,
  correct_option_id text,
  explanation text,
  closed_at timestamptz,
  created_by uuid references public.users(id),
  created_at timestamptz default now()
);

-- ============================================================
-- 7. SCHEDULED MESSAGES TABLE
-- ============================================================
create table if not exists public.scheduled_messages (
  id uuid primary key default uuid_generate_v4(),
  chat_id uuid references public.chats(id) on delete cascade,
  sender_id uuid references public.users(id),
  encrypted_text text not null default '',
  scheduled_at timestamptz not null,
  status text default 'pending' check (status in ('pending', 'sent', 'cancelled')),
  type text not null default 'text',
  created_at timestamptz default now()
);

create index if not exists idx_scheduled_messages_sender on public.scheduled_messages (sender_id);
create index if not exists idx_scheduled_messages_status on public.scheduled_messages (status, scheduled_at);

-- ============================================================
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================

-- Enable RLS on all tables
alter table public.users enable row level security;
alter table public.chats enable row level security;
alter table public.messages enable row level security;
alter table public.calls enable row level security;
alter table public.status enable row level security;
alter table public.polls enable row level security;
alter table public.scheduled_messages enable row level security;

-- ── Users policies ──────────────────────────────────────────
create policy "Users can view all profiles"
  on public.users for select using (true);

create policy "Users can update own profile"
  on public.users for update using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.users for insert with check (auth.uid() = id);

-- ── Chats policies ──────────────────────────────────────────
create policy "Users can view chats they participate in"
  on public.chats for select
  using (auth.uid()::text = any(participants));

create policy "Authenticated users can create chats"
  on public.chats for insert
  with check (auth.uid() is not null);

create policy "Participants can update their chats"
  on public.chats for update
  using (auth.uid()::text = any(participants));

-- ── Messages policies ───────────────────────────────────────
create policy "Chat participants can view messages"
  on public.messages for select
  using (
    exists (
      select 1 from public.chats
      where chats.id = messages.chat_id
        and auth.uid()::text = any(chats.participants)
    )
  );

create policy "Authenticated users can send messages"
  on public.messages for insert
  with check (auth.uid() = sender_id);

create policy "Senders can update their messages"
  on public.messages for update
  using (auth.uid() = sender_id);

-- ── Calls policies ──────────────────────────────────────────
create policy "Users can view their calls"
  on public.calls for select
  using (
    auth.uid() = caller_id
    or auth.uid()::text = any(receiver_ids)
  );

create policy "Authenticated users can create calls"
  on public.calls for insert
  with check (auth.uid() is not null);

create policy "Call participants can update calls"
  on public.calls for update
  using (
    auth.uid() = caller_id
    or auth.uid()::text = any(receiver_ids)
  );

-- ── Status policies ─────────────────────────────────────────
create policy "Users can view active statuses"
  on public.status for select using (true);

create policy "Users can create own status"
  on public.status for insert
  with check (auth.uid() = user_id);

create policy "Users can update own status"
  on public.status for update
  using (auth.uid() = user_id);

-- ── Polls policies ──────────────────────────────────────────
create policy "Chat participants can view polls"
  on public.polls for select using (true);

create policy "Authenticated users can create polls"
  on public.polls for insert
  with check (auth.uid() is not null);

create policy "Authenticated users can update polls"
  on public.polls for update
  using (auth.uid() is not null);

-- ── Scheduled messages policies ─────────────────────────────
create policy "Users can manage own scheduled messages"
  on public.scheduled_messages for all
  using (auth.uid() = sender_id);

-- ============================================================
-- 9. HELPER FUNCTIONS (RPCs)
-- ============================================================

-- Add a device token to user (avoids duplicates)
create or replace function public.add_device_token(user_id uuid, token text)
returns void as $$
begin
  update public.users
  set device_tokens = array_append(
    array_remove(device_tokens, token),
    token
  )
  where id = user_id;
end;
$$ language plpgsql security definer;

-- Mark messages as read (batch update)
create or replace function public.mark_messages_read(p_chat_id uuid, p_user_id text)
returns void as $$
begin
  update public.messages
  set read_by = read_by || jsonb_build_object(p_user_id, now()::text),
      status = 'read'
  where chat_id = p_chat_id
    and sender_id::text != p_user_id
    and not (read_by ? p_user_id);
end;
$$ language plpgsql security definer;

-- Mark status as seen
create or replace function public.mark_status_seen(p_status_id uuid, p_user_id text)
returns void as $$
begin
  update public.status
  set seen_by = array_append(
    array_remove(seen_by, p_user_id),
    p_user_id
  )
  where id = p_status_id;
end;
$$ language plpgsql security definer;

-- Vote on a poll
create or replace function public.vote_poll(p_poll_id uuid, p_option_id text, p_user_id text)
returns void as $$
declare
  current_votes jsonb;
  option_voters jsonb;
begin
  select votes into current_votes from public.polls where id = p_poll_id;
  option_voters := coalesce(current_votes->p_option_id, '[]'::jsonb);

  -- Add user to voters if not already present
  if not (option_voters @> to_jsonb(p_user_id)) then
    option_voters := option_voters || to_jsonb(p_user_id);
    current_votes := jsonb_set(current_votes, array[p_option_id], option_voters);
    update public.polls set votes = current_votes where id = p_poll_id;
  end if;
end;
$$ language plpgsql security definer;

-- ============================================================
-- 10. ENABLE REALTIME
-- ============================================================
alter publication supabase_realtime add table public.chats;
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.calls;
alter publication supabase_realtime add table public.status;
alter publication supabase_realtime add table public.users;
