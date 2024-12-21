import 'dart:async';
import 'dart:js_interop';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps/google_maps.dart' as Maps;
import 'package:google_maps/google_maps_places.dart' as Places;

const kGoogleApiKey = "API_KEY";

main() {
  runApp(const RoutesWidget());
}

final customTheme = ThemeData(
  brightness: Brightness.dark,
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.00)),
    ),
    contentPadding: EdgeInsets.symmetric(
      vertical: 12.50,
      horizontal: 10.00,
    ),
  ),
);

class RoutesWidget extends StatelessWidget {
  const RoutesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: "My App",
        darkTheme: customTheme,
        themeMode: ThemeMode.dark,
        routes: {
          "/": (_) => const MyApp(),
          "/search": (_) => CustomSearchScaffold(),
        },
      );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

final homeScaffoldKey = GlobalKey<ScaffoldState>();
final searchScaffoldKey = GlobalKey<ScaffoldState>();

class _MyAppState extends State<MyApp> {
  Mode? _mode = Mode.overlay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: homeScaffoldKey,
      appBar: AppBar(
        title: const Text("My App"),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _buildDropdownMenu(),
          ElevatedButton(
            onPressed: _handlePressButton,
            child: const Text("Search places"),
          ),
          ElevatedButton(
            child: const Text("Custom"),
            onPressed: () {
              Navigator.of(context).pushNamed("/search");
            },
          ),
        ],
      )),
    );
  }

  Widget _buildDropdownMenu() => DropdownButton(
        value: _mode,
        items: const <DropdownMenuItem<Mode>>[
          DropdownMenuItem<Mode>(
            child: Text("Overlay"),
            value: Mode.overlay,
          ),
          DropdownMenuItem<Mode>(
            child: Text("Fullscreen"),
            value: Mode.fullscreen,
          ),
        ],
        onChanged: (dynamic m) {
          setState(() {
            _mode = m;
          });
        },
      );

  void onError(List<Places.AutocompleteSuggestion> response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.toString()!)),
    );
  }

  Future<void> _handlePressButton() async {
    // show input autocomplete with selected mode
    // then get the Prediction selected
    Places.PlacePrediction? p = await PlacesAutocomplete.show(
      context: context,
      apiKey: kGoogleApiKey,
      onError: onError,
      mode: _mode!,
      language: "fr",
      decoration: InputDecoration(
        hintText: 'Search',
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Colors.white,
          ),
        ),
      ),
      components: Places.ComponentRestrictions()..country = "fr" as JSAny?,
    );

    displayPrediction(p, context);
  }
}

Future<void> displayPrediction(Places.PlacePrediction? p, BuildContext context) async {
  if (p != null) {
    // get detail (lat/lng)
    final place = p.toPlace();
    place.fetchFields(Places.FetchFieldsRequest(
      fields: ["location".toJS].toJS
    ));

    final lat = place.location!.lat;
    final lng = place.location!.lng;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${p.text.text} - $lat/$lng")),
    );
  }
}

// custom scaffold that handle search
// basically your widget need to extends [GooglePlacesAutocompleteWidget]
// and your state [GooglePlacesAutocompleteState]
class CustomSearchScaffold extends PlacesAutocompleteWidget {
  CustomSearchScaffold({Key? key})
      : super(
          key: key,
          apiKey: kGoogleApiKey,
          sessionToken: Places.AutocompleteSessionToken(),
          language: "en",
          components: Places.ComponentRestrictions()..country = "uk" as JSAny?,
        );

  @override
  _CustomSearchScaffoldState createState() => _CustomSearchScaffoldState();
}

class _CustomSearchScaffoldState extends PlacesAutocompleteState {
  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(title: const AppBarPlacesAutoCompleteTextField());
    final body = PlacesAutocompleteResult(
      onTap: (p) {
        displayPrediction(p, context);
      },
      logo: Row(
        children: const [FlutterLogo()],
        mainAxisAlignment: MainAxisAlignment.center,
      ),
    );
    return Scaffold(key: searchScaffoldKey, appBar: appBar, body: body);
  }

  @override
  void onResponseError(List<Places.AutocompleteSuggestion> response) {
    super.onResponseError(response);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.toString()!)),
    );
  }

  @override
  void onResponse(List<Places.AutocompleteSuggestion>? response) {
    super.onResponse(response);
    if (response != null && response.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Got answer")),
      );
    }
  }
}

class Uuid {
  final Random _random = Random();

  String generateV4() {
    // Generate xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx / 8-4-4-4-12.
    final int special = 8 + _random.nextInt(4);

    return '${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}-'
        '${_bitsDigits(16, 4)}-'
        '4${_bitsDigits(12, 3)}-'
        '${_printDigits(special, 1)}${_bitsDigits(12, 3)}-'
        '${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}';
  }

  String _bitsDigits(int bitCount, int digitCount) =>
      _printDigits(_generateBits(bitCount), digitCount);

  int _generateBits(int bitCount) => _random.nextInt(1 << bitCount);

  String _printDigits(int value, int count) =>
      value.toRadixString(16).padLeft(count, '0');
}
