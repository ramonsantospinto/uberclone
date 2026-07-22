// features/map/presentation/pages/search_destination_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/map_bloc.dart';

class SearchDestinationPage extends StatefulWidget {
  const SearchDestinationPage({super.key});

  @override
  State<SearchDestinationPage> createState() => _SearchDestinationPageState();
}

class _SearchDestinationPageState extends State<SearchDestinationPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Para onde vamos?'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (query) {
                context.read<MapBloc>().add(SearchPlacesEvent(query));
              },
              decoration: InputDecoration(
                hintText: 'Pesquisar endereço ou local...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          context.read<MapBloc>().add(SearchPlacesEvent(''));
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<MapBloc, MapState>(
              builder: (context, state) {
                if (state.isLoadingPredictions) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.predictions.isEmpty) {
                  return const Center(
                    child: Text(
                      'Digite um endereço para buscar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: state.predictions.length,
                  itemBuilder: (context, index) {
                    final prediction = state.predictions[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.black12,
                        child: Icon(Icons.location_on, color: Colors.black),
                      ),
                      title: Text(
                        prediction.mainText,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        prediction.secondaryText,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      onTap: () {
                        context.read<MapBloc>().add(
                          SelectPlaceDestinationEvent(prediction.placeId),
                        );
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
