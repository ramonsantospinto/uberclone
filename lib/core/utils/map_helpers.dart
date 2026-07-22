import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapHelpers {
  static LatLng interpolateLatLng(LatLng start, LatLng end, double t) {
    final lat = start.latitude + (end.latitude - start.latitude) * t;
    final lng = start.longitude + (end.longitude - start.longitude) * t;
    return LatLng(lat, lng);
  }
}
