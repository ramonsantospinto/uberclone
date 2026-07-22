import 'package:flutter/material.dart';

class UberBottomSheet extends StatefulWidget {
  final VoidCallback onConfirmRide;

  const UberBottomSheet({super.key, required this.onConfirmRide});

  @override
  State<UberBottomSheet> createState() => _UberBottomSheetState();
}

class _UberBottomSheetState extends State<UberBottomSheet> {
  String _selectedRideType = 'UberX';
  String _selectedPrice = 'R\$ 24,90';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.2,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Escolha uma viagem',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _RideOptionTile(
                title: 'UberX',
                price: 'R\$ 24,90',
                time: '4 min',
                icon: Icons.directions_car,
                isSelected: _selectedRideType == 'UberX',
                onTap: () {
                  setState(() {
                    _selectedRideType = 'UberX';
                    _selectedPrice = 'R\$ 24,90';
                  });
                },
              ),
              _RideOptionTile(
                title: 'Uber Comfort',
                price: 'R\$ 31,50',
                time: '6 min',
                icon: Icons.car_rental,
                isSelected: _selectedRideType == 'Uber Comfort',
                onTap: () {
                  setState(() {
                    _selectedRideType = 'Uber Comfort';
                    _selectedPrice = 'R\$ 31,50';
                  });
                },
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: widget.onConfirmRide,
                  child: Text(
                    'Confirmar $_selectedRideType ($_selectedPrice)',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RideOptionTile extends StatelessWidget {
  final String title, price, time;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RideOptionTile({
    required this.title,
    required this.price,
    required this.time,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey[100] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.black : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, size: 36, color: Colors.black),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(time),
        trailing: Text(
          price,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onTap: onTap,
      ),
    );
  }
}
