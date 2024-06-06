import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sf_jrwosm/include/tile_providers.dart';

class HomePage extends StatefulWidget {
  static const String route = '/';

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final MapController _mapController;
  MapEvent? _latestEvent;
  LatLng? tappedCoords;
  Point<double>? tappedPoint;

  static const _startedId = 'AnimatedMapController#MoveStarted';
  static const _inProgressId = 'AnimatedMapController#MoveInProgress';
  static const _finishedId = 'AnimatedMapController#MoveFinished';

  int flags = InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom;

  static const _tokyo = LatLng(35.6764, 139.6500);
  static const _cebu = LatLng(10.3157, 123.8854);
  static const _manila = LatLng(14.5995, 120.9842);

  static const _markers = [
    Marker(
      width: 45,
      height: 45,
      point: _tokyo,
      child: Icon(Icons.location_pin, size: 45, color: Colors.red),
    ),
    Marker(
      width: 45,
      height: 45,
      point: _cebu,
      child: Icon(Icons.location_pin, size: 45, color: Colors.blue),
    ),
    Marker(
      width: 45,
      height: 45,
      point: _manila,
      child: Icon(Icons.location_pin, size: 45, color: Colors.yellow),
    ),
  ];

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final camera = _mapController.camera;
    final latTween = Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    final controller = AnimationController( duration: const Duration(milliseconds: 500), vsync: this);
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    final startIdWithTarget = '$_startedId#${destLocation.latitude},${destLocation.longitude},$destZoom';
    bool hasTriggeredMove = false;

    controller.addListener(() {
      final String id;

      if (animation.value == 1.0) { id = _finishedId; }
      else if (!hasTriggeredMove) { id = startIdWithTarget; }
      else { id = _inProgressId; }

      hasTriggeredMove |= _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
        id: id,
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('JRW (OSM)'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(29.045365, 130.891524),
              initialZoom: 4,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onMapEvent: (evt) => setState(() => _latestEvent = evt),
              onTap: (_, latLng) {
                final point = _mapController.camera.latLngToScreenPoint(tappedCoords = latLng);
                setState(() => tappedPoint = Point(point.x, point.y));
              },
            ),
            children: [
              openStreetMapTileLayer,
              const MarkerLayer(
                markers: _markers,
              ),

              // OverlayImageLayer(
              //   overlayImages: [
              //     OverlayImage(
              //       bounds: LatLngBounds(
              //         const LatLng(51.5, -0.09),
              //         const LatLng(48.8566, 2.3522),
              //       ),
              //       opacity: 1,
              //       imageProvider: const NetworkImage('https://images.pexels.com/photos/2614818/pexels-photo-2614818.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'),
              //     ),
              //   ],
              // ),

              if (tappedCoords != null) ...[
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 55,
                      height: 55,
                      point: tappedCoords!,
                      child: const Icon(
                        Icons.star,
                        size: 15,
                        color: Colors.red,
                      ),
                    )
                  ],
                ),
              ],
            ],
          ),

          if (tappedPoint != null) ...[
            Positioned(
              left: tappedPoint!.x - 60 / 2,
              top: tappedPoint!.y - 60 / 2,
              child: const IgnorePointer(
                child: Icon(
                  Icons.center_focus_strong_outlined,
                  color: Colors.black,
                  size: 60,
                ),
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Map Event: ${_latestEvent?.source.name ?? "none"}',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {  },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              MaterialButton(
                onPressed: () => _animatedMapMove(_tokyo, 8),
                child: const Text('Tokyo'),
              ),
              MaterialButton(
                onPressed: () => _animatedMapMove(_cebu, 9),
                child: const Text('Cebu'),
              ),
              MaterialButton(
                onPressed: () => _animatedMapMove(_manila, 9),
                child: const Text('Manila'),
              ),
            ],
          ),
        ),
    );
  }
}