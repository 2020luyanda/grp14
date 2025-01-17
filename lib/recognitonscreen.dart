import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({super.key});

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  File? _image;
  bool _isCameraReady = false;
  String _recognitionMessage = ''; // To show recognition results
  TextEditingController studentNumberController = TextEditingController();
  bool _isVerifying = false; // Indicates if verification is in progress
  bool _isStudentNumberConfirmed = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      CameraDescription frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraReady = true;
      });
    } catch (e) {
      developer.log('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    studentNumberController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_cameraController!.value.isInitialized ||
        !_isCameraReady ||
        _isVerifying) {
      return;
    }

    try {
      XFile picture = await _cameraController!.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final savedImage = File('$path/$fileName.png');

      File imageFile = await File(picture.path).copy(savedImage.path);
      setState(() {
        _image = imageFile;
        _recognitionMessage = "Image captured successfully.";
      });
    } catch (e) {
      developer.log('Error taking picture: $e');
      setState(() {
        _recognitionMessage = 'Error taking picture: $e';
      });
    }
  }

  void _confirmStudentNumber() {
    String studentNumber = studentNumberController.text.trim();
    if (studentNumber.isEmpty) {
      setState(() {
        _recognitionMessage = 'Please enter a valid student number.';
        _isStudentNumberConfirmed = false;
      });
    } else {
      setState(() {
        _recognitionMessage = 'Student number confirmed: $studentNumber';
        _isStudentNumberConfirmed = true;
      });
    }
  }

  Future<void> _fetchStudentImageAndCompare() async {
    if (!_isStudentNumberConfirmed) {
      setState(() {
        _recognitionMessage = 'Please confirm the student number first.';
      });
      return;
    }

    if (_image == null) {
      setState(() {
        _recognitionMessage = 'Please capture an image first.';
      });
      return;
    }

    String studentNumber = studentNumberController.text.trim();
    if (studentNumber.isEmpty) {
      setState(() {
        _recognitionMessage = 'Please enter a valid student number.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _recognitionMessage = "Verifying, please wait...";
    });

    // Send the image to the backend for verification
    await _sendImageToBackend(_image!, studentNumber);
  }

  Future<void> _sendImageToBackend(
      File capturedImage, String studentNumber) async {
    developer.log('Sending student number to backend: $studentNumber');

    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://10.11.153.204:8000/compare/'));

      // Add the captured image file
      request.files
          .add(await http.MultipartFile.fromPath('camera', capturedImage.path));

      // Add the student number field
      request.fields['student_number'] = studentNumber;

      // Log the request details for debugging
      developer.log('Request fields: ${request.fields}');
      developer.log('Request files: ${request.files.map((f) => f.filename)}');

      // Send the request to the backend
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseBody);

        // Check the value of "verified" field in the response
        if (jsonResponse['verified'] == true) {
          String studentName = jsonResponse['name'] ?? 'Student';
          _showPopupDialog('Access Granted', 'Welcome, $studentName');
          // Log access to Firebase (if verified)
          await _logAccessToFirebase(studentNumber, 'entered');
        } else {
          _showPopupDialog('Access Denied', jsonResponse['reason']);
        }
      } else {
        developer.log('Error from backend: ${response.statusCode}');
        var responseBody = await response.stream.bytesToString();
        developer.log('Response body: $responseBody');
        _showPopupDialog('Error', 'Error from backend: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error sending image to backend: $e');
      _showPopupDialog('Error', 'Error sending image to backend: $e');
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  Future<void> _logAccessToFirebase(String studentNumber, String status) async {
    try {
      final entryTime = DateTime.now().toIso8601String();
      final logData = {
        'student_number': studentNumber,
        'status': status,
        'entry_time': entryTime,
      };

      var response = await http.post(
        Uri.parse('http://10.11.153.204:8000/log_access/'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: logData.map((key, value) => MapEntry(key, value.toString())),
      );

      if (response.statusCode == 200) {
        developer.log('Access logged successfully.');
      } else if (response.statusCode == 422) {
        developer.log('Unprocessable Entity: ${response.body}');
        _showPopupDialog('Error',
            'There was an error processing your request. Please check your inputs.');
      } else {
        developer.log('Failed to log access: ${response.statusCode}');
        _showPopupDialog(
            'Error', 'Failed to log access. Please try again later.');
      }
    } catch (e) {
      developer.log('Error logging access to Firebase: $e');
      _showPopupDialog('Error', 'Failed to log access: $e');
    }
  }

  void _showPopupDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Face Recognition')),
      body: Column(
        children: [
          // Camera preview
          Expanded(child: CameraPreview(_cameraController!)),

          // Student number input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: studentNumberController,
              decoration: const InputDecoration(
                labelText: 'Student Number',
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // Confirm student number button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Confirm Student Number'),
              onPressed: _confirmStudentNumber,
            ),
          ),

          // Capture button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capture Image'),
              onPressed: _takePicture,
            ),
          ),

          // Verify button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.verified_user),
              label: const Text('Verify Student'),
              onPressed: _fetchStudentImageAndCompare,
            ),
          ),

          // Recognition message
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_recognitionMessage),
          ),

          // Loading indicator while verifying
          if (_isVerifying)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
