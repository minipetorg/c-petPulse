import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

class Pet {
  final String id;
  final String name;
  final String type;
  final LatLng location;
  final String imageUrl;

  Pet({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.imageUrl,
  });
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  Location location = Location();
  Set<Marker> _markers = {};
  bool _isLoading = true;

  // Initial camera position (can be set to user's location later)
  static const LatLng _defaultLocation = LatLng(37.42796133580664, -122.085749655962);

  // Mock pet data - replace with real data from your backend
  final List<Pet> _pets = [
    Pet(
      id: '1',
      name: 'Max',
      type: 'Dog',
      location: const LatLng(37.42796133580664, -122.085749655962),
      imageUrl: 'assets/dog_marker.png',
    ),
    Pet(
      id: '2',
      name: 'Luna',
      type: 'Cat',
      location: const LatLng(37.42896133580664, -122.084749655962),
      imageUrl: 'assets/cat_marker.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadPetMarkers();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final LocationData currentLocation = await location.getLocation();
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(currentLocation.latitude!, currentLocation.longitude!),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _loadPetMarkers() {
    setState(() {
      _markers = _pets.map((pet) {
        return Marker(
          markerId: MarkerId(pet.id),
          position: pet.location,
          infoWindow: InfoWindow(
            title: pet.name,
            snippet: '${pet.type} - Tap for details',
          ),
          onTap: () => _showPetDetails(pet),
        );
      }).toSet();
      _isLoading = false;
    });
  }

  void _showPetDetails(Pet pet) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(pet.imageUrl),
              ),
              title: Text(pet.name),
              subtitle: Text(pet.type),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Navigate to detailed pet tracking view
                Navigator.pop(context);
              },
              child: const Text('View Detailed Tracking'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
          IconButton(
            icon: const Icon(Icons.pets),
            onPressed: _showPetList,
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: _defaultLocation,
          zoom: 14,
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          _getCurrentLocation();
        },
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        mapType: MapType.normal,
        zoomControlsEnabled: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFilterOptions(context),
        child: const Icon(Icons.filter_list),
      ),
    );
  }

  void _showPetList() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: _pets.length,
        itemBuilder: (context, index) {
          final pet = _pets[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(pet.imageUrl),
            ),
            title: Text(pet.name),
            subtitle: Text(pet.type),
            onTap: () {
              Navigator.pop(context);
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(pet.location, 16),
              );
            },
          );
        },
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.pets),
            title: const Text('Show All Pets'),
            onTap: () {
              Navigator.pop(context);
              _loadPetMarkers();
            },
          ),
          ListTile(
            leading: const Icon(Icons.pets_outlined),
            title: const Text('Show Only Dogs'),
            onTap: () {
              Navigator.pop(context);
              _filterPetsByType('Dog');
            },
          ),
          ListTile(
            leading: const Icon(Icons.catching_pokemon),
            title: const Text('Show Only Cats'),
            onTap: () {
              Navigator.pop(context);
              _filterPetsByType('Cat');
            },
          ),
        ],
      ),
    );
  }

  void _filterPetsByType(String type) {
    setState(() {
      _markers = _pets
          .where((pet) => pet.type == type)
          .map((pet) => Marker(
                markerId: MarkerId(pet.id),
                position: pet.location,
                infoWindow: InfoWindow(
                  title: pet.name,
                  snippet: '${pet.type} - Tap for details',
                ),
                onTap: () => _showPetDetails(pet),
              ))
          .toSet();
    });
  }
}