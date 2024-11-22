import 'package:deepar_flutter/deepar_flutter.dart';
import 'package:deepar_test/screens/filter_data.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // For handling file paths
import 'dart:io';
import 'profile_page.dart';
import 'package:permission_handler/permission_handler.dart'; //
import 'photo_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final deepArController = DeepArController();
  bool isInitialized = false;

  // Initialize the camera controller
  Future<void> initializeController() async {
    if (!isInitialized) {
      await deepArController.initialize(
        androidLicenseKey:
        '86fb3f83b00c927a80e31555b7525625baeabff03377d40115e16beb976f395ddbe8f2136ed10550',
        iosLicenseKey: '',
      );
      setState(() {
        isInitialized = true;
      });
    }
  }

  // Clean up and release resources when the camera page is inactive
  Future<void> disposeController() async {
    if (isInitialized) {
      await deepArController.destroy();
      setState(() {
        isInitialized = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize the camera when the page is active
    initializeController();
  }

  @override
  void deactivate() {
    super.deactivate();
    // Dispose of the controller when the page is inactive
    disposeController();
  }

  Widget buildCameraPreview() => SizedBox(
    height: MediaQuery.of(context).size.height * 0.82,
    child: Transform.scale(
      scale: 1.5,
      child: DeepArPreview(deepArController),
    ),
  );

  Widget buildButtons() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      IconButton(
        onPressed: deepArController.flipCamera,
        icon: const Icon(
          Icons.flip_camera_ios_outlined,
          size: 34,
          color: Colors.white,
        ),
      ),
      FilledButton(
        onPressed: () async {
          try {
            // Capture the photo
            final File screenshotFile = await deepArController.takeScreenshot();

            // Navigate to Photo Preview Screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PhotoPreviewPage(photo: screenshotFile),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to capture photo.')),
            );
          }
        },
        child: const Icon(Icons.camera),
      ),
      IconButton(
        onPressed: deepArController.toggleFlash,
        icon: const Icon(
          Icons.flash_on,
          size: 34,
          color: Colors.white,
        ),
      ),
    ],
  );

  Widget buildFilters() => SizedBox(
    height: MediaQuery.of(context).size.height * 0.1,
    child: ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      itemCount: filters.length,
      itemBuilder: (context, index) {
        final filter = filters[index];
        final effectFile = File('assets/effects/${filter.filterPath}').path;
        return InkWell(
          onTap: () => deepArController.switchEffect(effectFile),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                image: DecorationImage(
                  image: AssetImage('assets/previews/${filter.imagePath}'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: initializeController(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    buildCameraPreview(),
                    buildButtons(),
                    buildFilters(),
                  ],
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      );
                    },
                    icon: const Icon(
                      Icons.settings,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}

// class PhotoPreviewPage extends StatelessWidget {
//   final File photo;
//
//   const PhotoPreviewPage({super.key, required this.photo});
//
//   Future<void> saveToGallery(File photo) async {
//     final Directory downloadsDir = Directory('/storage/emulated/0/Download/cipherlens');
//     if (!downloadsDir.existsSync()) {
//       downloadsDir.createSync(recursive: true);
//     }
//
//     final String newFilePath =
//         '${downloadsDir.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
//     await photo.copy(newFilePath);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Photo Preview')),
//       body: Column(
//         children: [
//           Expanded(
//             child: Image.file(photo, fit: BoxFit.contain),
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               ElevatedButton(
//                 onPressed: () async {
//                   await saveToGallery(photo);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Photo saved to gallery!')),
//                   );
//                   Navigator.pop(context);
//                 },
//                 child: const Text('Save to Gallery'),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Feature not implemented yet.')),
//                   );
//                 },
//                 child: const Text('Send to Timeline'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
