// Azure Maps Widget to display maps using a WebView
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Import platform implementations
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../services/azure_maps_service.dart';
import '../models/tree_models.dart';

class AzureMapsWidget extends StatefulWidget {
  final List<Tree> trees;
  final Function(String)? onMarkerTapped;
  final double initialLatitude;
  final double initialLongitude;
  final double initialZoom;
  final bool showUserLocation;

  const AzureMapsWidget({
    super.key,
    required this.trees,
    this.onMarkerTapped,
    this.initialLatitude = 0.0236, // Default to Kenya's center
    this.initialLongitude = 37.9062,
    this.initialZoom = 7.0,
    this.showUserLocation = true,
  });

  @override
  State<AzureMapsWidget> createState() => _AzureMapsWidgetState();
}

class _AzureMapsWidgetState extends State<AzureMapsWidget> {
  late WebViewController _controller;
  final AzureMapsService _mapsService = AzureMapsService();
  bool _mapLoaded = false;
  bool _controllerInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize WebView platform before using WebViewController
    _initPlatformState();
  }

  @override
  void dispose() {
    // Clean up resources when widget is disposed
    super.dispose();
  }

  void _initPlatformState() {
    // Initialize WebView platform based on OS
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance == null) {
      if (PlatformUtils.isAndroid) {
        AndroidWebViewPlatform.registerWith();
        params = AndroidWebViewControllerCreationParams();
      } else if (PlatformUtils.isIOS) {
        WebKitWebViewPlatform.registerWith();
        params = WebKitWebViewControllerCreationParams();
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    // Now that platform is initialized, we can create the controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeController(params);
    });
  }

  void _initializeController([PlatformWebViewControllerCreationParams? params]) {
    _controller = params != null 
        ? WebViewController.fromPlatformCreationParams(params)
        : WebViewController();
    
    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _mapLoaded = false;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _mapLoaded = true;
              });
              
              // Slight delay to ensure the map is fully rendered
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  _initializeMap();
                }
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'TreeTrackerApp',
        onMessageReceived: (JavaScriptMessage message) {
          if (widget.onMarkerTapped != null) {
            widget.onMarkerTapped!(message.message);
          }
        },
      )
      ..loadHtmlString(_generateHtml());
    
    if (mounted) {
      setState(() {
        _controllerInitialized = true;
      });
    }
  }

  void _initializeMap() {
    _addTreesToMap();
  }

  Future<void> _addTreesToMap() async {
    if (!_mapLoaded || !_controllerInitialized) return;

    final geoJson = _mapsService.treesToGeoJson(widget.trees);
    final geoJsonString = jsonEncode(geoJson).replaceAll("'", "\\'");

    try {
      await _controller.runJavaScript('''
        try {
          // Add tree pins to map
          map.addSource('trees', {
            type: 'geojson',
            data: $geoJsonString
          });

          map.addLayer({
            id: 'tree-pins',
            type: 'symbol',
            source: 'trees',
            layout: {
              'icon-image': 'marker-green',
              'icon-size': 1.2,
              'icon-allow-overlap': true
            }
          });

          // Add popup for when user clicks on a tree pin
          map.on('click', 'tree-pins', function(e) {
            var properties = e.features[0].properties;
            var popupContent = '<div class="popup-content">' +
              '<h3>' + properties.title + '</h3>' +
              '<p>' + properties.description + '</p>';
              
            if (properties.isVerified) {
              popupContent += '<p><span class="verified-badge">✓ Verified</span></p>';
            }
              
            popupContent += '</div>';
            
            new atlas.Popup({
              position: e.features[0].geometry.coordinates,
              content: popupContent
            }).open(map);
            
            // Call JavaScript bridge to Flutter
            TreeTrackerApp.postMessage(properties.id);
          });
        } catch (error) {
          console.error("Error adding trees to map:", error);
        }
      ''');
    } catch (e) {
      debugPrint('Error initializing map markers: $e');
    }
  }

  void _showUserLocation() {
    if (!_mapLoaded || !_controllerInitialized) return;
    
    try {
      _controller.runJavaScript('''
        try {
          // Get user's location and show it on the map
          navigator.geolocation.getCurrentPosition(function(position) {
            var userLocation = [position.coords.longitude, position.coords.latitude];
            
            // Add a marker for user location if it doesn't exist
            if (!map.getLayer('user-location')) {
              map.addSource('user-location', {
                type: 'geojson',
                data: {
                  type: 'Feature',
                  geometry: {
                    type: 'Point',
                    coordinates: userLocation
                  }
                }
              });
              
              map.addLayer({
                id: 'user-location',
                type: 'symbol',
                source: 'user-location',
                layout: {
                  'icon-image': 'marker-blue',
                  'icon-size': 1.2
                }
              });
            } else {
              // Update existing marker
              map.getSource('user-location').setData({
                type: 'Feature',
                geometry: {
                  type: 'Point',
                  coordinates: userLocation
                }
              });
            }
            
            // Center map on user location
            map.setCamera({
              center: userLocation,
              zoom: 14
            });
          }, function(error) {
            console.error("Error getting user location:", error);
          });
        } catch (error) {
          console.error("Error showing user location:", error);
        }
      ''');
    } catch (e) {
      debugPrint('Error showing user location: $e');
    }
  }

  String _generateHtml() {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <title>PMI Tree Tracker Map</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
        
        <script type='text/javascript' 
          src='https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.js'>
        </script>
        
        <link rel="stylesheet" 
          href="https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.css" 
          type="text/css">
          
        <style>
          html, body, #map {
            width: 100%;
            height: 100%;
            margin: 0;
            padding: 0;
          }
          .popup-content {
            padding: 12px;
            max-width: 240px;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          }
          .popup-content h3 {
            margin-top: 0;
            margin-bottom: 8px;
          }
          .verified-badge {
            background-color: #2E7D32;
            color: white;
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 12px;
          }
        </style>
      </head>
      <body>
        <div id="map"></div>
        <script>
          // Initialize map          var map = new atlas.Map('map', {
            center: [${widget.initialLongitude}, ${widget.initialLatitude}],
            zoom: ${widget.initialZoom},
            authOptions: {
              // Azure Maps subscription key - This would be stored securely in production
              authType: 'subscriptionKey',
              subscriptionKey: '${_mapsService.subscriptionKey}'
            },
            style: 'satellite',  // Can be 'main', 'satellite', 'grayscale', etc.
            showLogo: false
          });
          
          map.events.add('ready', function() {
            // Create a symbol layer for tree markers
            var marker = new atlas.IconOptions();
            marker.image = 'marker-green';  // Built-in marker icon
            
            // Add zoom controls
            map.controls.add([
              new atlas.control.ZoomControl(),
              new atlas.control.CompassControl(),
              new atlas.control.StyleControl()
            ], {
              position: 'top-right'
            });
          });
        </script>
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Apply sizing constraints to the Stack
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            fit: StackFit.expand, // Ensure stack fills available space
            children: [
              if (_controllerInitialized)
                // Use a constrained box with definite dimensions
                SizedBox.expand(
                  child: WebViewWidget(
                    controller: _controller,
                  ),
                )
              else
                const SizedBox.expand(), // Placeholder when controller not ready
                
              if (!_mapLoaded || !_controllerInitialized)
                const Center(
                  child: CircularProgressIndicator(),
                ),
              
              // Only show interactive elements when map is ready
              if (_mapLoaded && _controllerInitialized && widget.showUserLocation)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    onPressed: _showUserLocation,
                    child: Icon(
                      Icons.my_location,
                      color: Theme.of(context).colorScheme.primary,
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

// Helper class to check platform
class PlatformUtils {
  static bool get isAndroid => identical(0, 0.0);
  static bool get isIOS => !isAndroid;
}