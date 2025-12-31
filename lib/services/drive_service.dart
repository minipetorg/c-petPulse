import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class DriveService {
  static final _credentials = {
    "installed": {
      "client_id": "YOUR_CLIENT_ID",
      "project_id": "YOUR_PROJECT_ID",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "client_secret": "YOUR_CLIENT_SECRET",
    }
  };

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final accountCredentials = ServiceAccountCredentials.fromJson(_credentials);
      
      final client = await clientViaServiceAccount(
        accountCredentials,
        [drive.DriveApi.driveFileScope],
      );

      final driveApi = drive.DriveApi(client);
      
      // Create file metadata
      final driveFile = drive.File()
        ..name = 'pet_image_${DateTime.now().millisecondsSinceEpoch}.jpg'
        ..mimeType = 'image/jpeg'
        ..parents = ['1KBe0Eu1UvLkT5SOtJG4MuLDhKzpHUVKT']; // Your folder ID

      // Upload file
      final media = drive.Media(
        imageFile.openRead(),
        imageFile.lengthSync(),
      );

      final file = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      // Make file publicly accessible
      await driveApi.permissions.create(
        drive.Permission()
          ..role = 'reader'
          ..type = 'anyone',
        file.id!,
      );

      // Generate direct download link
      return 'https://drive.google.com/uc?id=${file.id}';
      
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }
}