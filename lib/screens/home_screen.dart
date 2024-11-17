import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:test_olusturucu/providers/exam_storage.dart';
import 'package:test_olusturucu/screens/exam_creation_screen.dart';
import '../providers/exam_provider.dart';
import 'image_editor_screen.dart';
import 'dart:io';

import 'pdf_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SavedExam> savedExams = [];

  @override
  void initState() {
    super.initState();
    _loadSavedExams();
  }

  Future<void> _loadSavedExams() async {
    final exams = await ExamStorage.getSavedExams();
    setState(() {
      savedExams = exams;
    });
  }

  Future<void> _deleteExam(String title) async {
    bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Testi Sil'),
              content: Text('Bu testi silmek istediğinizden emin misiniz?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('İptal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Sil',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmDelete) {
      await ExamStorage.deleteExam(title);
      await _loadSavedExams(); // Listeyi yenile
    }
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null) {
        final String filePath = result.files.single.path!;
        final String fileExtension = filePath.split('.').last.toLowerCase();

        if (fileExtension == 'pdf') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerScreen(filePath: filePath),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageEditorScreen(filePath: filePath),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya açılırken bir hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Oluşturucu'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.add_circle_sharp),
              label: Text('PDF Oluştur'),
              onPressed: () => _pickFile(context),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: savedExams.length,
                itemBuilder: (context, index) {
                  final exam = savedExams[index];
                  return Card(
                    child: Stack(
                      children: [
                        InkWell(
                          onTap: () async {
                            final examProvider = Provider.of<ExamProvider>(
                              context,
                              listen: false,
                            );
                            await examProvider.loadSavedExam(exam);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExamCreationScreen(),
                              ),
                            );
                          },
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.description, size: 40),
                                SizedBox(height: 8),
                                Text(
                                  exam.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '${exam.questions.length} Soru',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Silme butonu
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: Icon(
                              Icons.delete_rounded,
                              size: 20,
                            ),
                            onPressed: () => _deleteExam(exam.title),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
