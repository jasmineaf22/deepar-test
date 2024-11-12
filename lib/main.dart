import 'package:flutter/material.dart';
import 'package:deepar_flutter/deepar_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late DeepArController _controller; // DeepArController instance
  bool isCameraReady = false;
  int currentPage = 0; // To track the current mask page
  final vp = PageController(viewportFraction: .24); // Page controller for masks

  @override
  void initState() {
    super.initState();
    _initializeDeepAr(); // Initialize DeepAR when the app starts
  }

  void _initializeDeepAr() async {
    // Initialize DeepAR with license keys
    _controller = DeepArController();
    await _controller.initialize(
      androidLicenseKey: "86fb3f83b00c927a80e31555b7525625baeabff03377d40115e16beb976f395ddbe8f2136ed10550",
      iosLicenseKey: "YOUR_IOS_LICENSE_KEY",
      resolution: Resolution.high,
    );
    setState(() {
      isCameraReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            isCameraReady
                ? DeepArPreview(_controller)
                : Center(child: Text("Loading Camera...")),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(6, (index) {
                          bool active = currentPage == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                currentPage = index;
                                _controller.switchEffect('assets/effects/Vendetta_Mask.deepar'); // Replace with actual effect paths
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.all(5),
                              width: active ? 40 : 30,
                              height: active ? 50 : 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: active ? Colors.green : Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "Mask $index",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: active ? 16 : 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
