import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../page.dart';
import '../../shared/shared.dart';

/// Example demonstrating that widgets on top of the map properly intercept clicks
/// This example specifically tests the fix for the web platform click-through issue
class ClickThroughTestExample extends ExamplePage {
  const ClickThroughTestExample({super.key})
      : super(
          const Icon(Icons.touch_app),
          'Click through test (Web)',
          category: ExampleCategory.basics,
        );

  @override
  Widget build(BuildContext context) => const _ClickThroughTestBody();
}

class _ClickThroughTestBody extends StatefulWidget {
  const _ClickThroughTestBody();

  @override
  State<_ClickThroughTestBody> createState() => _ClickThroughTestBodyState();
}

class _ClickThroughTestBodyState extends State<_ClickThroughTestBody> {
  int _mapClickCount = 0;
  int _buttonClickCount = 0;
  String _lastEvent = 'None';

  void _onMapClick(Point<double> point, LatLng coordinates) {
    setState(() {
      _mapClickCount++;
      _lastEvent = 'Map clicked at ${coordinates.latitude.toStringAsFixed(2)}, ${coordinates.longitude.toStringAsFixed(2)}';
    });
  }

  void _onButtonClick() {
    setState(() {
      _buttonClickCount++;
      _lastEvent = 'Button clicked';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The map
          MapLibreMap(
            styleString: ExampleConstants.demoMapStyle,
            onMapClick: _onMapClick,
            initialCameraPosition: ExampleConstants.defaultCameraPosition,
            logoEnabled: false,
            trackCameraPosition: true,
          ),
          // Widget overlay on top of the map
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Click Through Test',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Map clicks: $_mapClickCount'),
                  Text('Button clicks: $_buttonClickCount'),
                  Text('Last event: $_lastEvent'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _onButtonClick,
                    child: const Text('Click Me'),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'This button should NOT\ntrigger map clicks',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom instruction
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Click the map or the button above to test',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
