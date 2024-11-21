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

  void _createNewExam(BuildContext context) {
    final examProvider = Provider.of<ExamProvider>(context, listen: false);
    examProvider.clear(); // Clear any existing data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamCreationScreen(),
      ),
    );
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2; // Default
                  if (constraints.maxWidth > 1200) {
                    crossAxisCount = 6;
                  } else if (constraints.maxWidth > 800) {
                    crossAxisCount = 4;
                  }

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.8, // Adjust for better visual balance
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
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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
