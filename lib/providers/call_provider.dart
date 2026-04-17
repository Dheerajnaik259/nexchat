import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Call state enum
enum CallState { idle, ringing, connecting, connected, ended }

/// Call provider — manages call UI state
final callStateProvider = StateNotifierProvider<CallStateNotifier, CallUIState>((ref) {
  return CallStateNotifier();
});

class CallUIState {
  final CallState state;
  final String? callId;
  final String? callerId;
  final String? callerName;
  final String? callerAvatar;
  final bool isVideo;
  final bool isMuted;
  final bool isSpeaker;
  final bool isCameraOff;
  final Duration duration;

  const CallUIState({
    this.state = CallState.idle,
    this.callId,
    this.callerId,
    this.callerName,
    this.callerAvatar,
    this.isVideo = false,
    this.isMuted = false,
    this.isSpeaker = false,
    this.isCameraOff = false,
    this.duration = Duration.zero,
  });

  CallUIState copyWith({
    CallState? state,
    String? callId,
    String? callerId,
    String? callerName,
    String? callerAvatar,
    bool? isVideo,
    bool? isMuted,
    bool? isSpeaker,
    bool? isCameraOff,
    Duration? duration,
  }) {
    return CallUIState(
      state: state ?? this.state,
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerAvatar: callerAvatar ?? this.callerAvatar,
      isVideo: isVideo ?? this.isVideo,
      isMuted: isMuted ?? this.isMuted,
      isSpeaker: isSpeaker ?? this.isSpeaker,
      isCameraOff: isCameraOff ?? this.isCameraOff,
      duration: duration ?? this.duration,
    );
  }
}

class CallStateNotifier extends StateNotifier<CallUIState> {
  CallStateNotifier() : super(const CallUIState());

  void startCall({
    required String callId,
    required String callerId,
    required String callerName,
    String? callerAvatar,
    bool isVideo = false,
  }) {
    state = CallUIState(
      state: CallState.ringing,
      callId: callId,
      callerId: callerId,
      callerName: callerName,
      callerAvatar: callerAvatar,
      isVideo: isVideo,
    );
  }

  void acceptCall() => state = state.copyWith(state: CallState.connected);
  void endCall() => state = const CallUIState(state: CallState.ended);
  void resetCall() => state = const CallUIState();

  void toggleMute() => state = state.copyWith(isMuted: !state.isMuted);
  void toggleSpeaker() => state = state.copyWith(isSpeaker: !state.isSpeaker);
  void toggleCamera() => state = state.copyWith(isCameraOff: !state.isCameraOff);

  void updateDuration(Duration duration) => state = state.copyWith(duration: duration);
}
