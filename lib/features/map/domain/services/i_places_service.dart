import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/place_prediction.dart';

abstract class IPlacesService {
  Future<List<PlacePrediction>> getAutocompletePredictions(String query);
  Future<LatLng?> getPlaceDetails(String placeId);
}
