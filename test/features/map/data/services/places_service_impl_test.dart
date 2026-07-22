import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uberclone/features/map/data/models/place_prediction.dart';
import 'package:uberclone/features/map/data/services/places_service_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late PlacesServiceImpl placesService;
  late MockDio mockDio;
  const apiKey = 'test_api_key';

  setUp(() {
    mockDio = MockDio();
    placesService = PlacesServiceImpl(dio: mockDio, apiKey: apiKey);
  });

  group('PlacesServiceImpl Tests', () {
    test(
      'Deve retornar lista de PlacePrediction quando a API de autocomplete for bem-sucedida',
      () async {
        final jsonResponse = {
          'predictions': [
            {
              'place_id': '123',
              'description': 'Av. Paulista, São Paulo - SP',
              'structured_formatting': {
                'main_text': 'Av. Paulista',
                'secondary_text': 'São Paulo - SP',
              },
            },
          ],
        };

        when(
          () => mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
        ).thenAnswer(
          (_) async => Response(
            data: jsonResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ),
        );

        final result = await placesService.getAutocompletePredictions('Paulista');

        expect(result, isA<List<PlacePrediction>>());
        expect(result.length, 1);
        expect(result.first.placeId, '123');
        expect(result.first.mainText, 'Av. Paulista');
      },
    );

    test('Deve retornar lista vazia quando a query estiver vazia', () async {
      final result = await placesService.getAutocompletePredictions('   ');
      expect(result, isEmpty);
      verifyZeroInteractions(mockDio);
    });

    test('Deve retornar LatLng quando getPlaceDetails for bem-sucedido', () async {
      final jsonResponse = {
        'result': {
          'geometry': {
            'location': {
              'lat': -23.563,
              'lng': -46.657,
            },
          },
        },
      };

      when(
        () => mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => Response(
          data: jsonResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await placesService.getPlaceDetails('123');

      expect(result, isNotNull);
      expect(result?.latitude, -23.563);
      expect(result?.longitude, -46.657);
    });
  });
}
