// Function to handle image selection and saving
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class Services {
  Future<File?> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final File newImage = File(pickedFile.path);
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      return await newImage.copy('$path/$fileName.png');
    }
    return null;
  }

  Future<void> saveDataToFirestore(
      String name, int studentNumber, String res, String? imagePath) async {
    try {
      await FirebaseFirestore.instance.collection('USERS').add({
        'name': name,
        'studentNumber': studentNumber,
        'res': res,
        'imagePath': imagePath,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print(e);
    }
  }
}
