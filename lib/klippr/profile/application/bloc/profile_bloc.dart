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
    res.when(
      onSuccess: (_) => emit(
        state.copyWith(
          isSubmittingVerification: false,
          verificationSubmitted: true,
          actionMessage: 'Verificacion enviada.',
        ),
      ),
      onFailure: (error) => emit(
        state.copyWith(isSubmittingVerification: false, error: error.message),
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
