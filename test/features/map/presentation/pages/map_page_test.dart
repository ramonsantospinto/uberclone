import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uberclone/features/map/presentation/bloc/map_bloc.dart';
import 'package:uberclone/features/map/presentation/pages/map_page.dart';
import 'package:uberclone/features/map/presentation/pages/search_destination_page.dart';

class MockMapBloc extends MockBloc<MapEvent, MapState> implements MapBloc {}

void main() {
  late MockMapBloc mockMapBloc;

  setUpAll(() {
    registerFallbackValue(FetchCurrentLocationEvent());
    registerFallbackValue(
      SelectDestinationEvent(const LatLng(-23.563000, -46.657000)),
    );
    registerFallbackValue(SearchPlacesEvent(''));
    registerFallbackValue(SelectPlaceDestinationEvent(''));
  });

  setUp(() {
    mockMapBloc = MockMapBloc();
  });

  Widget buildSubject() {
    return MaterialApp(
      home: BlocProvider<MapBloc>.value(
        value: mockMapBloc,
        child: const MapPage(),
      ),
    );
  }

  group('MapPage Widget Tests', () {
    testWidgets(
      'Deve renderizar o campo "Buscar destino" e disparar FetchCurrentLocationEvent',
      (tester) async {
        when(() => mockMapBloc.state).thenReturn(MapState());

        await tester.pumpWidget(buildSubject());

        expect(find.text('Buscar destino'), findsOneWidget);
        verify(
          () => mockMapBloc.add(any(that: isA<FetchCurrentLocationEvent>())),
        ).called(1);
      },
    );

    testWidgets(
      'Deve navegar para a SearchDestinationPage ao clicar no campo Buscar destino',
      (tester) async {
        when(() => mockMapBloc.state).thenReturn(MapState());

        await tester.pumpWidget(buildSubject());

        await tester.tap(find.text('Buscar destino'));
        await tester.pumpAndSettle();

        expect(find.byType(SearchDestinationPage), findsOneWidget);
      },
    );

    testWidgets(
      'Deve exibir o painel inferior com detalhes da rota e o botão de confirmação quando houver polylines',
      (tester) async {
        const mockLatLng = LatLng(-23.561684, -46.655981);
        final mockPolyline = Polyline(
          polylineId: const PolylineId('ride_route'),
          points: [mockLatLng, const LatLng(-23.562000, -46.656000)],
        );

        when(() => mockMapBloc.state).thenReturn(
          MapState(
            polylines: {mockPolyline},
            distanceText: '1.2 km',
            durationText: '5 mins',
          ),
        );

        await tester.pumpWidget(buildSubject());

        expect(find.text('Opção de Viagem'), findsOneWidget);
        expect(find.text('UberX'), findsOneWidget);
        expect(find.text('5 mins (1.2 km)'), findsOneWidget);
        expect(find.text('Confirmar UberX'), findsOneWidget);
      },
    );
  });
}
