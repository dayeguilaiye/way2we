import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:way2we_app/features/profile/data/providers/profile_provider.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required ProfileProvider profileProvider,
  }) : _profileProvider = profileProvider,
       super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileUpdateRequested>(_onUpdateRequested);
  }

  final ProfileProvider _profileProvider;

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(
      ProfileLoading(
        nickname: state.nickname,
        avatarUrl: state.avatarUrl,
      ),
    );

    try {
      final profile = await _profileProvider.getProfile();
      emit(
        ProfileLoadSuccess(
          nickname: profile['nickname'] as String? ?? '',
          avatarUrl: profile['avatar'] as String? ?? '',
        ),
      );
    } on ProfileApiException catch (e) {
      emit(
        ProfileFailure(
          errorCode: e.code,
          errorMessage: e.message,
          nickname: state.nickname,
          avatarUrl: state.avatarUrl,
        ),
      );
    }
  }

  Future<void> _onUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(
      ProfileLoading(
        nickname: state.nickname,
        avatarUrl: state.avatarUrl,
      ),
    );

    try {
      String? newAvatarUrl;

      // Upload avatar if provided
      if (event.avatarFile != null) {
        newAvatarUrl = await _profileProvider.uploadAvatar(event.avatarFile!);
      }

      // Update profile
      final profile = await _profileProvider.updateProfile(
        nickname: event.nickname,
        avatar: newAvatarUrl,
      );

      emit(
        ProfileUpdateSuccess(
          nickname: profile['nickname'] as String? ?? state.nickname,
          avatarUrl: profile['avatar'] as String? ?? state.avatarUrl,
        ),
      );
    } on ProfileApiException catch (e) {
      emit(
        ProfileFailure(
          errorCode: e.code,
          errorMessage: e.message,
          nickname: state.nickname,
          avatarUrl: state.avatarUrl,
        ),
      );
    }
  }
}
