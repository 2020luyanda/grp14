import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ExitPage extends StatefulWidget {
  @override
  _ExitPageState createState() => _ExitPageState();
}

class _ExitPageState extends State<ExitPage> {
  final TextEditingController studentNumberController = TextEditingController();
  late CameraController cameraController;
  late Future<void> initializeCameraFuture;
  bool isCameraInitialized = false;
  String capturedFaceImage = ''; // Placeholder for the captured face image

  @override
  void initState() {
    super.initState();
    // Initialize the camera
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    // Get a list of available cameras
    final cameras = await availableCameras();
    // Use the first available camera (you can choose a different one if needed)
    cameraController = CameraController(cameras[0], ResolutionPreset.high);
    initializeCameraFuture = cameraController.initialize();

    setState(() {
      isCameraInitialized = true;
    });
  }

  @override
  void dispose() {
    cameraController.dispose();
    studentNumberController.dispose();
    super.dispose();
  }

  Future<void> verifyExit(String studentNumber) async {
    final response = await http.post(
      Uri.parse('http://10.11.154.218:8000/exit/'),
      body: {'student_number': studentNumber},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Handle success, display duration
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Success"),
          content:
              Text("Exit recorded successfully! Duration: ${data['duration']}"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
    } else {
      // Handle error
      final errorData = jsonDecode(response.body);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text(errorData['message']),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            )
          ],
        ),
      );
    }
  }

  Future<void> captureFace() async {
    // Capture an image from the camera
    try {
      await initializeCameraFuture;
      final image = await cameraController.takePicture();
      setState(() {
        capturedFaceImage = image.path; // Store the captured image path
      });
      // TODO: Implement image processing and base64 conversion if needed
      // Example: Send captured face image to backend for verification

      // Now call verifyExit() with the student number
      String studentNumber = studentNumberController.text;
      verifyExit(studentNumber);
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Exit Residence")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: studentNumberController,
              decoration: InputDecoration(labelText: "Enter Student Number"),
            ),
            SizedBox(height: 20),
            isCameraInitialized
                ? Column(
                    children: [
                      // Camera Preview
                      AspectRatio(
                        aspectRatio: cameraController.value.aspectRatio,
                        child: CameraPreview(cameraController),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: captureFace,
                        child: Text("Scan Face"),
                      ),
                    ],
                  )
                : Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
