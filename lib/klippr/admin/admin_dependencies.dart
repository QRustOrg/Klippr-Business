import 'package:get_it/get_it.dart';

import 'data/network/admin_analytics_web_service.dart';
import 'data/network/admin_profile_web_service.dart';
import 'data/network/admin_promotions_web_service.dart';
import 'data/stores/http_admin_analytics_store.dart';
import 'data/stores/http_admin_profile_store.dart';
import 'data/stores/http_admin_promotions_store.dart';
import 'domain/stores/admin_analytics_store.dart';
import 'domain/stores/admin_profile_store.dart';
import 'domain/stores/admin_promotions_store.dart';
import 'application/bloc/admin_bloc.dart';

void registerAdminDependencies(GetIt sl) {
  // Web Services
  sl.registerFactory(() => AdminPromotionsWebService(sl()));
  sl.registerFactory(() => AdminProfileWebService(sl()));
  sl.registerFactory(() => AdminAnalyticsWebService(sl()));

  // Stores
  sl.registerLazySingleton<AdminPromotionsStore>(
    () => HttpAdminPromotionsStore(sl()),
  );
  sl.registerLazySingleton<AdminProfileStore>(
    () => HttpAdminProfileStore(sl()),
  );
  sl.registerLazySingleton<AdminAnalyticsStore>(
    () => HttpAdminAnalyticsStore(sl()),
  );

  // BLoC
  sl.registerFactory(
    () => AdminBloc(
      promotionsStore: sl(),
      profileStore: sl(),
      analyticsStore: sl(),
    ),
  );
}
