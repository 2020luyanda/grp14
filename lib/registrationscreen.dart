import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController studentNumberController = TextEditingController();
  TextEditingController studentEmailController = TextEditingController();
  TextEditingController resController = TextEditingController();
  File? _image;
  String _faceDetectionMessage = ''; // To show face detection results

  @override
  void dispose() {
    nameController.dispose();
    studentNumberController.dispose();
    studentEmailController.dispose();
    resController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final File newImage = File(pickedFile.path);
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final File savedImage = await newImage.copy('$path/$fileName.png');

      developer.log('Image saved at: $path/$fileName.png');

      setState(() {
        _image = savedImage;
      });

      await _detectFaces(savedImage);
    }
  }

  Future<void> _detectFaces(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final faceDetector = FaceDetector(options: FaceDetectorOptions());

    try {
      final List<Face> faces = await faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        setState(() {
          _faceDetectionMessage =
              '${faces.length} face(s) detected in the image.';
        });
      } else {
        setState(() {
          _faceDetectionMessage = 'No faces detected in the image.';
        });
      }
    } catch (e) {
      developer.log('Failed to detect faces: $e');
    } finally {
      faceDetector.close();
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference storageRef = FirebaseStorage.instance
          .ref('USERES')
          .child('user_images/$fileName.png');
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      developer.log('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _registerUser(String name, String studentNumber, String email,
      String res, File? image) async {
    if (_formKey.currentState!.validate()) {
      try {
        // Sign in anonymously (optional, but useful to track the user session)
        await FirebaseAuth.instance.signInAnonymously();

        // Upload the image and get the URL
        String? imageUrl = image != null ? await _uploadImage(image) : null;

        // Create a map for user data
        Map<String, dynamic> userData = {
          'name': name,
          'studentNumber': studentNumber,
          'email': email,
          'res': res,
          'imageUrl': imageUrl ?? 'No image available',
          'timestamp': FieldValue.serverTimestamp(),
        };

        // Use studentNumber as the document ID
        await FirebaseFirestore.instance
            .collection('users')
            .doc(studentNumber) // Use studentNumber as the document ID
            .set(userData);

        // Show registration success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Registration Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _image == null
                    ? const Text('No image selected')
                    : Image.file(_image!, fit: BoxFit.cover),
                const SizedBox(height: 10),
                Text(_faceDetectionMessage),
                const SizedBox(height: 10),
                Text('Name: $name'),
                Text('Student Number: $studentNumber'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        developer.log('Error during registration: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during registration: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _image == null
                        ? const Icon(Icons.camera_alt, size: 50)
                        : Image.file(_image!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 20),
                Text(_faceDetectionMessage),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: 'Name:', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your name'
                      : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: studentNumberController,
                  decoration: const InputDecoration(
                      labelText: 'Student Number:',
                      border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your student number'
                      : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: studentEmailController,
                  decoration: const InputDecoration(
                      labelText: 'Email address:',
                      border: OutlineInputBorder()),
                  validator: (value) =>
                      value == null || value.isEmpty || !value.contains('@')
                          ? 'Please enter a valid email'
                          : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: resController,
                  decoration: const InputDecoration(
                      labelText: 'Res:', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your residence'
                      : null,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => _registerUser(
                      nameController.text,
                      studentNumberController.text,
                      studentEmailController.text,
                      resController.text,
                      _image),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
