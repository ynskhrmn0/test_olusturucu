import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PDFPreviewScreen extends StatelessWidget {
  final List<int> pdfBytes;

  const PDFPreviewScreen({Key? key, required this.pdfBytes}) : super(key: key);

  Future<String> _saveTempFile() async {
    final directory = await getTemporaryDirectory();
    final tempFile = File('${directory.path}/temp_preview.pdf');
    await tempFile.writeAsBytes(pdfBytes);
    return tempFile.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Önizleme'),
      ),
      body: FutureBuilder<String>(
        future: _saveTempFile(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return PDFView(
              filePath: snapshot.data!,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: false,
              pageFling: false,
              pageSnap: true,
              defaultPage: 0,
              fitPolicy: FitPolicy.BOTH,
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}