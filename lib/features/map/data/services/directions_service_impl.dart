import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/services/i_directions_service.dart';
import '../models/route_info.dart';

class DirectionsServiceImpl implements IDirectionsService {
  final Dio dio;
  final String apiKey;

  DirectionsServiceImpl({required this.dio, required this.apiKey});

  @override
  Future<RouteInfo?> getRouteDetails({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final response = await dio.get(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode': 'driving',
          'key': apiKey,
        },
      );

      if (response.statusCode == 200 && response.data['routes'].isNotEmpty) {
        final route = response.data['routes'][0];
        final leg = route['legs'][0];

        final points = _decodePolyline(route['overview_polyline']['points']);

        return RouteInfo(
          points: points,
          distanceText: leg['distance']['text'],
          durationText: leg['duration']['text'],
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
