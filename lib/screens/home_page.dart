import 'package:deepar_flutter/deepar_flutter.dart';
import 'package:deepar_test/screens/filter_data.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // For handling file paths
import 'dart:io';
import 'profile_page.dart';
import 'package:permission_handler/permission_handler.dart'; // For requesting permissions

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final deepArController = DeepArController();

  Future<void> initializeController() async {
    await deepArController.initialize(
      androidLicenseKey:
      '86fb3f83b00c927a80e31555b7525625baeabff03377d40115e16beb976f395ddbe8f2136ed10550',
      iosLicenseKey: '',
    );
  }

  // // Function to request storage permissions
  // Future<void> requestPermissions() async {
  //   final status = await Permission.storage.request();
  //   if (!status.isGranted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Permission denied, cannot save screenshot')),
  //     );
  //   }
  // }

  // Function to create the 'cipherlens' directory under the Downloads folder if it doesn't exist
  Future<void> createCipherLensFolder() async {
    final Directory downloadsDir = Directory('/storage/emulated/0/Download');
    final Directory cipherlensDir = Directory('${downloadsDir.path}/cipherlens');

    if (!cipherlensDir.existsSync()) {
      cipherlensDir.createSync(recursive: true);
    }
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
          // Request permissions before attempting to save the screenshot
          // await requestPermissions();

          // Create 'cipherlens' folder if it doesn't exist
          await createCipherLensFolder();

          try {
            // Take the screenshot and get the File object
            final File screenshotFile = await deepArController.takeScreenshot();

            // Get the external storage directory (general Downloads folder)
            final Directory downloadsDir = Directory('/storage/emulated/0/Download/cipherlens');
            if (!downloadsDir.existsSync()) {
              downloadsDir.createSync(recursive: true);
            }

            // Create a new file path inside 'cipherlens' folder
            final String newFilePath =
                '${downloadsDir.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png';

            // Move the screenshot to the 'cipherlens' folder
            final File newFile = await screenshotFile.copy(newFilePath);

            // Notify the user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Screenshot saved to ${newFile.path}')),
            );
          } catch (e) {
            // Notify the user of failure without internal debugging messages
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(content: Text('Failed to save screenshot')),
            // );
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
                  top: 16, // Jarak dari atas layar
                  right: 16, // Jarak dari kanan layar
                  child: IconButton(
                    onPressed: () {
                      // Navigasi ke halaman ProfilePage()
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      );
                    },
                    icon: const Icon(
                      Icons.settings,
                      size: 34, // Ukuran ikon sama seperti tombol lainnya
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
  }}
