import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../bloc/map_bloc.dart';
import '../widgets/uber_bottom_sheet.dart';
import '../pages/search_destination_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    context.read<MapBloc>().add(FetchCurrentLocationEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<MapBloc, MapState>(
        listener: (context, state) {
          if (state.userLocation != null && _mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(state.userLocation!, 15),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(-23.561684, -46.655981),
                  zoom: 14,
                ),
                onMapCreated: (controller) => _mapController = controller,
                markers: state.markers,
                polylines: state.polylines,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onTap: (latLng) {
                  context.read<MapBloc>().add(SelectDestinationEvent(latLng));
                },
              ),

              Positioned(
                top: 50,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<MapBloc>(),
                          child: const SearchDestinationPage(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: Colors.black),
                        SizedBox(width: 10),
                        Text(
                          'Para onde?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              UberBottomSheet(
                onConfirmRide: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Procurando motoristas próximos...'),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
