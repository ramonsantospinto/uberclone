import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/services/i_places_service.dart';
import '../models/place_prediction.dart';

class PlacesServiceImpl implements IPlacesService {
  final Dio dio;
  final String apiKey;

  PlacesServiceImpl({required this.dio, required this.apiKey});

  @override
  Future<List<PlacePrediction>> getAutocompletePredictions(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': apiKey,
          'language': 'pt-BR',
          'components': 'country:br',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final predictions = response.data['predictions'] as List? ?? [];
        return predictions.map((p) => PlacePrediction.fromJson(p)).toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  @override
  Future<LatLng?> getPlaceDetails(String placeId) async {
    try {
      final response = await dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': apiKey,
          'fields': 'geometry',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final location = response.data['result']?['geometry']?['location'];
        if (location != null) {
          return LatLng(location['lat'], location['lng']);
        }
      }
      return null;
    } on DioException {
      return null;
    }
  }
}
