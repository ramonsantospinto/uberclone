import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteInfo {
  final List<LatLng> points;
  final String distanceText;
  final String durationText;

  const RouteInfo({
    required this.points,
    required this.distanceText,
    required this.durationText,
  });
}
