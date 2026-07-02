import 'package:get_it/get_it.dart';

import '../shared/data/network/api_client.dart';
import 'application/bloc/profile_bloc.dart';
import 'data/network/profile_web_service.dart';
import 'data/stores/http_profile_store.dart';
import 'domain/stores/profile_store.dart';

abstract final class ProfileDependencies {
  static void register(GetIt sl) {
    sl
      ..registerLazySingleton<ProfileWebService>(
        () => ProfileWebService(sl<ApiClient>()),
      )
      ..registerLazySingleton<ProfileStore>(
        () => HttpProfileStore(sl<ProfileWebService>()),
      )
      ..registerFactory<ProfileBloc>(() => ProfileBloc(sl<ProfileStore>()));
  }
}
