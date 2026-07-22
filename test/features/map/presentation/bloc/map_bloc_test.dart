import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uberclone/core/services/location_service.dart';
import 'package:uberclone/features/map/data/models/place_prediction.dart';
import 'package:uberclone/features/map/data/models/route_info.dart';
import 'package:uberclone/features/map/domain/enums/trip_status.dart';
import 'package:uberclone/features/map/domain/services/i_directions_service.dart';
import 'package:uberclone/features/map/domain/services/i_places_service.dart';
import 'package:uberclone/features/map/presentation/bloc/map_bloc.dart';

class MockLocationService extends Mock implements ILocationService {}

class MockPlacesService extends Mock implements IPlacesService {}

class MockDirectionsService extends Mock implements IDirectionsService {}

void main() {
  late MapBloc mapBloc;
  late MockLocationService mockLocationService;
  late MockPlacesService mockPlacesService;
  late MockDirectionsService mockDirectionsService;

  setUpAll(() {
    registerFallbackValue(const LatLng(0.0, 0.0));
  });

  setUp(() {
    mockLocationService = MockLocationService();
    mockPlacesService = MockPlacesService();
    mockDirectionsService = MockDirectionsService();

    when(
      () => mockDirectionsService.getRouteDetails(
        origin: any(named: 'origin'),
        destination: any(named: 'destination'),
      ),
    ).thenAnswer(
      (_) async => const RouteInfo(
        points: [LatLng(-23.561684, -46.655981), LatLng(-23.562000, -46.656000)],
        distanceText: '1.2 km',
        durationText: '5 mins',
      ),
    );

    mapBloc = MapBloc(
      locationService: mockLocationService,
      placesService: mockPlacesService,
      directionsService: mockDirectionsService,
    );
  });

  tearDown(() {
    mapBloc.close();
  });

  group('MapBloc Unit Tests', () {
    const mockLatLng = LatLng(-23.561684, -46.655981);

    test(
      'O estado inicial do MapBloc deve conter userLocation nulo e marcadores vazios',
      () {
        expect(mapBloc.state.userLocation, isNull);
        expect(mapBloc.state.markers, isEmpty);
      },
    );

    blocTest<MapBloc, MapState>(
      'Deve emitir estado com localização e marcadores quando FetchCurrentLocationEvent for disparado com sucesso',
      build: () {
        when(
          () => mockLocationService.getCurrentLocation(),
        ).thenAnswer((_) async => mockLatLng);
        return mapBloc;
      },
      act: (bloc) => bloc.add(FetchCurrentLocationEvent()),
      expect: () => [
        isA<MapState>()
            .having((s) => s.userLocation, 'userLocation', mockLatLng)
            .having((s) => s.markers.isNotEmpty, 'markers not empty', true),
      ],
      verify: (_) {
        verify(() => mockLocationService.getCurrentLocation()).called(1);
      },
    );

    blocTest<MapBloc, MapState>(
      'Deve usar localização padrão quando a busca por localização retornar nulo',
      build: () {
        when(
          () => mockLocationService.getCurrentLocation(),
        ).thenAnswer((_) async => null);
        return mapBloc;
      },
      act: (bloc) => bloc.add(FetchCurrentLocationEvent()),
      expect: () => [
        isA<MapState>()
            .having(
              (s) => s.userLocation,
              'userLocation fallback',
              const LatLng(-23.561684, -46.655981),
            )
            .having((s) => s.markers.isNotEmpty, 'markers not empty', true),
      ],
      verify: (_) {
        verify(() => mockLocationService.getCurrentLocation()).called(1);
      },
    );

    blocTest<MapBloc, MapState>(
      'Deve adicionar o marcador de destino e a polyline quando SelectDestinationEvent for disparado',
      build: () => mapBloc,
      seed: () => MapState(
        userLocation: mockLatLng,
        markers: {
          const Marker(
            markerId: MarkerId('user_location'),
            position: mockLatLng,
          ),
        },
      ),
      act: (bloc) => bloc.add(
        SelectDestinationEvent(const LatLng(-23.562000, -46.656000)),
      ),
      expect: () => [
        isA<MapState>()
            .having((s) => s.markers.length, 'total de marcadores', 2)
            .having((s) => s.polylines.isNotEmpty, 'tem rota desenhada', true),
      ],
    );

    blocTest<MapBloc, MapState>(
      'Deve atualizar predictions e o status de loading quando SearchPlacesEvent for disparado',
      build: () {
        when(() => mockPlacesService.getAutocompletePredictions('Paulista')).thenAnswer(
          (_) async => const [
            PlacePrediction(
              placeId: '123',
              description: 'Av. Paulista, São Paulo - SP',
              mainText: 'Av. Paulista',
              secondaryText: 'São Paulo - SP',
            ),
          ],
        );
        return mapBloc;
      },
      act: (bloc) => bloc.add(SearchPlacesEvent('Paulista')),
      expect: () => [
        isA<MapState>().having((s) => s.isLoadingPredictions, 'loading', true),
        isA<MapState>()
            .having((s) => s.predictions.length, 'predictions count', 1)
            .having((s) => s.isLoadingPredictions, 'loading finished', false),
      ],
    );

    blocTest<MapBloc, MapState>(
      'Deve alterar o status para searching e depois para driverAccepted ao confirmar a corrida',
      build: () => mapBloc,
      act: (bloc) => bloc.add(ConfirmRideEvent()),
      expect: () => [
        isA<MapState>().having(
          (s) => s.tripStatus,
          'status searching',
          TripStatus.searching,
        ),
        isA<MapState>()
            .having(
              (s) => s.tripStatus,
              'status driverAccepted',
              TripStatus.driverAccepted,
            )
            .having((s) => s.driverName, 'driverName', 'Carlos Silva')
            .having((s) => s.carModel, 'carModel', 'Chevrolet Onix Prata')
            .having((s) => s.carPlate, 'carPlate', 'ABC-1234'),
        isA<MapState>()
            .having(
              (s) => s.tripStatus,
              'status driverAccepted',
              TripStatus.driverAccepted,
            )
            .having(
              (s) => s.markers.any((m) => m.markerId.value == 'accepted_driver'),
              'contém marcador do motorista',
              true,
            ),
      ],
      wait: const Duration(seconds: 3),
    );

    blocTest<MapBloc, MapState>(
      'Deve resetar os dados da corrida ao cancelar',
      build: () => mapBloc,
      seed: () => MapState(
        tripStatus: TripStatus.driverAccepted,
        driverName: 'Carlos Silva',
        carModel: 'Chevrolet Onix Prata',
        carPlate: 'ABC-1234',
      ),
      act: (bloc) => bloc.add(CancelRideEvent()),
      expect: () => [
        isA<MapState>()
            .having((s) => s.tripStatus, 'status initial', TripStatus.initial)
            .having((s) => s.driverName, 'driverName null', isNull)
            .having((s) => s.carModel, 'carModel null', isNull)
            .having((s) => s.carPlate, 'carPlate null', isNull),
      ],
    );
  });
}
