import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

class FetchCurrentLocationEvent extends MapEvent {}

class SelectDestinationEvent extends MapEvent {
  final LatLng destination;
  const SelectDestinationEvent(this.destination);

  @override
  List<Object?> get props => [destination];
}

class SearchPlacesEvent extends MapEvent {
  final String query;
  const SearchPlacesEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectPlaceDestinationEvent extends MapEvent {
  final String placeId;
  const SelectPlaceDestinationEvent(this.placeId);

  @override
  List<Object?> get props => [placeId];
}
