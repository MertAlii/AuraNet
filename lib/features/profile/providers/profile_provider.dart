import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

/// Profil state
class ProfileState {
  final String displayName;
  final String email;
  final bool isPremium;
  final DateTime? premiumExpiry;
  final int totalScans;
  final List<String> badges;
  final bool isLoading;

  const ProfileState({
    this.displayName = '',
    this.email = '',
    this.isPremium = false,
    this.premiumExpiry,
    this.totalScans = 0,
    this.badges = const [],
    this.isLoading = false,
  });

  ProfileState copyWith({
    String? displayName,
    String? email,
    bool? isPremium,
    DateTime? premiumExpiry,
    int? totalScans,
    List<String>? badges,
    bool? isLoading,
  }) {
    return ProfileState(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
      totalScans: totalScans ?? this.totalScans,
      badges: badges ?? this.badges,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Profil provider
class ProfileNotifier extends StateNotifier<ProfileState> {
  final Ref _ref;

  ProfileNotifier(this._ref) : super(const ProfileState()) {
    loadProfile();
  }

  /// Profil bilgilerini yükle
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);

    final authState = _ref.read(authProvider);
    final user = authState.user;
    if (user != null) {
      try {
        final firestoreService = _ref.read(firestoreServiceProvider);
        final profile = await firestoreService.getUserProfile(user.uid);

        state = ProfileState(
          displayName: user.displayName ?? profile?['displayName'] ?? 'Kullanıcı',
          email: user.email ?? '',
          isPremium: profile?['isPremium'] ?? false,
          totalScans: profile?['totalScans'] ?? 0,
          badges: List<String>.from(profile?['badges'] ?? []),
          isLoading: false,
        );
      } catch (e) {
        state = ProfileState(
          displayName: user.displayName ?? 'Kullanıcı',
          email: user.email ?? '',
          isLoading: false,
        );
      }
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref);
});
