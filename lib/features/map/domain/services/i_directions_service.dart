import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/route_info.dart';

abstract class IDirectionsService {
  Future<RouteInfo?> getRouteDetails({
    required LatLng origin,
    required LatLng destination,
  });
}
