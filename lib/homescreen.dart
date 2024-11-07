import 'package:camera_platform_interface/src/types/camera_description.dart';
import 'package:demo_application/recognitonscreen.dart';
import 'package:demo_application/registrationscreen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final CameraDescription camera;

  const HomeScreen({super.key, required this.camera});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unizulu Face_Recognition'),
        backgroundColor: const Color.fromARGB(255, 10, 23, 145),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: screenWidth,
          height: screenHeight -
              AppBar().preferredSize.height -
              MediaQuery.of(context).padding.top,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade900, Colors.blue.shade100],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "images/logo.png",
                width: 300,
              ),
              SizedBox(
                  height:
                      screenHeight * 0.05), // Use SizedBox to control spacing
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegistrationScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                  minimumSize: Size(screenWidth * 0.8, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Register"),
              ),
              SizedBox(height: screenHeight * 0.02), // consistent spacing
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RecognitionScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                  minimumSize: Size(screenWidth * 0.8, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Recognize"),
              ),
              SizedBox(
                  height: screenHeight * 0.01), // Adjust spacing at the bottom
            ],
          ),
        ),
      ),
    );
  }
}
