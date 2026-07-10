import 'package:bloc/bloc.dart';

import '../../domain/stores/profile_store.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._store) : super(const ProfileState()) {
    on<LoadBusinessProfile>(_onLoad);
    on<UpdateBusinessProfileRequested>(_onUpdate);
    on<SubmitVerificationRequested>(_onSubmitVerification);
    on<ProfileFlagsConsumed>(_onConsumeFlags);
  }

  final ProfileStore _store;

  Future<void> _onLoad(
    LoadBusinessProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    final res = await _store.loadBusinessProfile();
    res.when(
      onSuccess: (profile) =>
          emit(state.copyWith(isLoading: false, profile: profile, error: null)),
      onFailure: (error) =>
          emit(state.copyWith(isLoading: false, error: error.message)),
    );
  }

  Future<void> _onUpdate(
    UpdateBusinessProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, error: null, actionMessage: null));
    final res = await _store.updateBusinessProfile(event.update);
    res.when(
      onSuccess: (profile) => emit(
        state.copyWith(
          isSaving: false,
          profile: profile,
          actionMessage: 'Perfil actualizado.',
          error: null,
        ),
      ),
      onFailure: (error) =>
          emit(state.copyWith(isSaving: false, error: error.message)),
    );
  }

  Future<void> _onSubmitVerification(
    SubmitVerificationRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        isSubmittingVerification: true,
        verificationSubmitted: false,
        error: null,
      ),
    );
    final res = await _store.submitVerification(event.document);
    if (res.errorOrNull != null) {
      emit(
        state.copyWith(
          isSubmittingVerification: false,
          error: res.errorOrNull!.message,
        ),
      );
      return;
    }

    // Releer perfil para persistir visualmente Pending/Verified del backend.
    final reload = await _store.loadBusinessProfile();
    final profile = reload.dataOrNull ?? state.profile;
    final refreshed = profile == null
        ? null
        : profile.copyWith(
            verificationStatus:
                (profile.verificationStatus == null ||
                    profile.verificationStatus!.trim().isEmpty ||
                    profile.verificationStatus!.toLowerCase() == 'none')
                ? 'Pending'
                : profile.verificationStatus,
            documentUrl: event.document.documentUrl,
          );

    emit(
      state.copyWith(
        isSubmittingVerification: false,
        verificationSubmitted: true,
        profile: refreshed,
        actionMessage: 'Verificacion enviada. El admin la revisara pronto.',
        error: null,
      ),
    );
  }

  void _onConsumeFlags(ProfileFlagsConsumed event, Emitter<ProfileState> emit) {
    emit(
      state.copyWith(
        error: null,
        actionMessage: null,
        verificationSubmitted: false,
      ),
    );
  }
}
