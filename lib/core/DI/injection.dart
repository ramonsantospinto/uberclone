import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../features/map/data/services/directions_service_impl.dart';
import '../../features/map/data/services/places_service_impl.dart';
import '../../features/map/domain/services/i_directions_service.dart';
import '../../features/map/domain/services/i_places_service.dart';
import '../../features/map/presentation/bloc/map_bloc.dart';
import '../services/location_service.dart';

final sl = GetIt.instance;

void setupInjector() {
  sl.registerLazySingleton<Dio>(() => Dio());

  const googleApiKey = 'Key aqui';

  sl.registerLazySingleton<ILocationService>(() => LocationService());

  sl.registerLazySingleton<IPlacesService>(
    () => PlacesServiceImpl(dio: sl(), apiKey: googleApiKey),
  );

  sl.registerLazySingleton<IDirectionsService>(
    () => DirectionsServiceImpl(dio: sl(), apiKey: googleApiKey),
  );

  sl.registerFactory(
    () => MapBloc(
      locationService: sl(),
      placesService: sl(),
      directionsService: sl(),
    ),
  );
}
