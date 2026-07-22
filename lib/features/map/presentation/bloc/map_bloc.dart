import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/services/location_service.dart';
import '../../data/models/place_prediction.dart';
import '../../domain/enums/trip_status.dart';
import '../../domain/services/i_directions_service.dart';
import '../../domain/services/i_places_service.dart';

abstract class MapEvent {}

class FetchCurrentLocationEvent extends MapEvent {}

class SelectDestinationEvent extends MapEvent {
  final LatLng destination;
  SelectDestinationEvent(this.destination);
}

class SearchPlacesEvent extends MapEvent {
  final String query;
  SearchPlacesEvent(this.query);
}

class SelectPlaceDestinationEvent extends MapEvent {
  final String placeId;
  SelectPlaceDestinationEvent(this.placeId);
}

class ConfirmRideEvent extends MapEvent {}

class CancelRideEvent extends MapEvent {}

class MapState {
  final LatLng? userLocation;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final List<PlacePrediction> predictions;
  final bool isLoadingPredictions;
  final String? distanceText;
  final String? durationText;
  final TripStatus tripStatus;
  final String? driverName;
  final String? carModel;
  final String? carPlate;

  MapState({
    this.userLocation,
    this.markers = const {},
    this.polylines = const {},
    this.predictions = const [],
    this.isLoadingPredictions = false,
    this.distanceText,
    this.durationText,
    this.tripStatus = TripStatus.initial,
    this.driverName,
    this.carModel,
    this.carPlate,
  });

  MapState copyWith({
    LatLng? userLocation,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    List<PlacePrediction>? predictions,
    bool? isLoadingPredictions,
    String? distanceText,
    String? durationText,
    TripStatus? tripStatus,
    Object? driverName = const _Undefined(),
    Object? carModel = const _Undefined(),
    Object? carPlate = const _Undefined(),
  }) {
    return MapState(
      userLocation: userLocation ?? this.userLocation,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      predictions: predictions ?? this.predictions,
      isLoadingPredictions: isLoadingPredictions ?? this.isLoadingPredictions,
      distanceText: distanceText ?? this.distanceText,
      durationText: durationText ?? this.durationText,
      tripStatus: tripStatus ?? this.tripStatus,
      driverName: driverName == const _Undefined()
          ? this.driverName
          : driverName as String?,
      carModel: carModel == const _Undefined() ? this.carModel : carModel as String?,
      carPlate: carPlate == const _Undefined() ? this.carPlate : carPlate as String?,
    );
  }
}

class _Undefined {
  const _Undefined();
}

class MapBloc extends Bloc<MapEvent, MapState> {
  final ILocationService locationService;
  final IPlacesService placesService;
  final IDirectionsService directionsService;

  Timer? _driverMovementTimer;

  MapBloc({
    required this.locationService,
    required this.placesService,
    required this.directionsService,
  }) : super(MapState()) {
    on<FetchCurrentLocationEvent>(_onFetchLocation);
    on<SelectDestinationEvent>(_onSelectDestination);
    on<SearchPlacesEvent>(_onSearchPlaces);
    on<SelectPlaceDestinationEvent>(_onSelectPlaceDestination);
    on<ConfirmRideEvent>(_onConfirmRide);
    on<CancelRideEvent>(_onCancelRide);
  }

  @override
  Future<void> close() {
    _driverMovementTimer?.cancel();
    return super.close();
  }

  void _onFetchLocation(FetchCurrentLocationEvent event, Emitter<MapState> emit) async {
    final location =
        await locationService.getCurrentLocation() ??
        const LatLng(-23.561684, -46.655981);

    final userMarker = Marker(
      markerId: const MarkerId('user_location'),
      position: location,
      infoWindow: const InfoWindow(title: 'Sua Localização'),
    );

    final driverMarkers = _generateMockDrivers(location);

    emit(
      state.copyWith(
        userLocation: location,
        markers: {userMarker, ...driverMarkers},
      ),
    );
  }

  void _onSelectDestination(SelectDestinationEvent event, Emitter<MapState> emit) async {
    if (state.userLocation == null) return;

    final destMarker = Marker(
      markerId: const MarkerId('destination_location'),
      position: event.destination,
      infoWindow: const InfoWindow(title: 'Destino'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    final routeInfo = await directionsService.getRouteDetails(
      origin: state.userLocation!,
      destination: event.destination,
    );

    final points = routeInfo?.points ?? [state.userLocation!, event.destination];

    final routePolyline = Polyline(
      polylineId: const PolylineId('ride_route'),
      points: points,
      color: const ui.Color(0xFF000000),
      width: 5,
    );

    final updatedMarkers = state.markers
        .where((m) => m.markerId.value != 'destination_location')
        .toSet();

    emit(
      state.copyWith(
        markers: {...updatedMarkers, destMarker},
        polylines: {routePolyline},
        predictions: [],
        distanceText: routeInfo?.distanceText,
        durationText: routeInfo?.durationText,
      ),
    );
  }

  void _onSearchPlaces(SearchPlacesEvent event, Emitter<MapState> emit) async {
    if (event.query.trim().isEmpty) {
      emit(state.copyWith(predictions: [], isLoadingPredictions: false));
      return;
    }

    emit(state.copyWith(isLoadingPredictions: true));

    final predictions = await placesService.getAutocompletePredictions(event.query);

    emit(
      state.copyWith(
        predictions: predictions,
        isLoadingPredictions: false,
      ),
    );
  }

  void _onSelectPlaceDestination(
    SelectPlaceDestinationEvent event,
    Emitter<MapState> emit,
  ) async {
    emit(state.copyWith(isLoadingPredictions: true));

    final latLng = await placesService.getPlaceDetails(event.placeId);

    if (latLng != null) {
      add(SelectDestinationEvent(latLng));
    }

    emit(
      state.copyWith(
        predictions: [],
        isLoadingPredictions: false,
      ),
    );
  }

  void _onConfirmRide(ConfirmRideEvent event, Emitter<MapState> emit) async {
    emit(state.copyWith(tripStatus: TripStatus.searching));

    await Future.delayed(const Duration(seconds: 2));

    final userLoc = state.userLocation ?? const LatLng(-23.561684, -46.655981);
    final initialDriverPos = LatLng(userLoc.latitude + 0.005, userLoc.longitude + 0.005);

    emit(
      state.copyWith(
        tripStatus: TripStatus.driverAccepted,
        driverName: 'Carlos Silva',
        carModel: 'Chevrolet Onix Prata',
        carPlate: 'ABC-1234',
      ),
    );

    await _startDriverMovementStream(initialDriverPos, userLoc, emit);
  }

  Future<void> _startDriverMovementStream(
    LatLng currentPos,
    LatLng targetPos,
    Emitter<MapState> emit,
  ) async {
    _driverMovementTimer?.cancel();

    const steps = 20;
    final latStep = (targetPos.latitude - currentPos.latitude) / steps;
    final lngStep = (targetPos.longitude - currentPos.longitude) / steps;

    int currentStep = 0;

    await emit.forEach<int>(
      Stream.periodic(const Duration(milliseconds: 500), (count) => count).take(steps),
      onData: (_) {
        currentStep++;
        final newLat = currentPos.latitude + (latStep * currentStep);
        final newLng = currentPos.longitude + (lngStep * currentStep);
        final updatedDriverPos = LatLng(newLat, newLng);

        final userMarker = state.markers
            .where((m) => m.markerId.value == 'user_location')
            .toSet();
        final destMarker = state.markers
            .where((m) => m.markerId.value == 'destination_location')
            .toSet();

        final driverMarker = Marker(
          markerId: const MarkerId('accepted_driver'),
          position: updatedDriverPos,
          infoWindow: const InfoWindow(title: 'Carlos Silva - A caminho'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        );

        return state.copyWith(
          markers: {...userMarker, ...destMarker, driverMarker},
        );
      },
    );
  }

  void _onCancelRide(CancelRideEvent event, Emitter<MapState> emit) {
    _driverMovementTimer?.cancel();

    final userMarker = state.markers
        .where((m) => m.markerId.value == 'user_location')
        .toSet();

    emit(
      state.copyWith(
        tripStatus: TripStatus.initial,
        markers: userMarker,
        polylines: {},
        distanceText: null,
        durationText: null,
        driverName: null,
        carModel: null,
        carPlate: null,
      ),
    );
  }

  Set<Marker> _generateMockDrivers(LatLng center) {
    final random = Random();
    final markers = <Marker>{};

    for (int i = 1; i <= 3; i++) {
      final latOffset = (random.nextDouble() - 0.5) * 0.01;
      final lngOffset = (random.nextDouble() - 0.5) * 0.01;
      final driverPos = LatLng(center.latitude + latOffset, center.longitude + lngOffset);

      markers.add(
        Marker(
          markerId: MarkerId('driver_$i'),
          position: driverPos,
          infoWindow: InfoWindow(title: 'Motorista #$i'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }
    return markers;
  }
}
