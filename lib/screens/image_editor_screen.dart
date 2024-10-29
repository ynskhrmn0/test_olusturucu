import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import '../providers/exam_provider.dart';
import 'preview_screen.dart';
import 'dart:io';

class ImageEditorScreen extends StatefulWidget {
  final String filePath;

  ImageEditorScreen({required this.filePath});

  @override
  _ImageEditorScreenState createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  String? selectedAnswer;
  String? currentImagePath;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    currentImagePath = widget.filePath;
  }

  Future<void> _cropImage() async {
    setState(() {
      isLoading = true;
    });

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: currentImagePath!,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Görsel Kırpma',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          IOSUiSettings(
            title: 'Görsel Kırpma',
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          currentImagePath = croppedFile.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kırpma işlemi sırasında bir hata oluştu')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Görsel Düzenleyici'),
        actions: [
          IconButton(
            icon: Icon(Icons.crop),
            onPressed: isLoading ? null : _cropImage,
          ),
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PreviewScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: currentImagePath != null
                    ? Image.file(
                        File(currentImagePath!),
                        fit: BoxFit.contain,
                      )
                    : Center(child: Text('Görsel yüklenemedi')),
              ),
              Container(
                padding: EdgeInsets.all(16),
                color: Theme.of(context).cardColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: DropdownButton<String>(
                        value: selectedAnswer,
                        hint: Text('Cevap Seçiniz'),
                        dropdownColor: Theme.of(context).cardColor,
                        items: ['A', 'B', 'C', 'D', 'E']
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedAnswer = value;
                          });
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: selectedAnswer == null
                          ? null
                          : () {
                              final provider = Provider.of<ExamProvider>(context,
                                  listen: false);
                              provider.addQuestion(
                                Question(
                                  imagePath: currentImagePath!,
                                  answer: selectedAnswer!,
                                  cropRect: Rect.zero,
                                ),
                              );
                              Navigator.pop(context);
                            },
                      child: Text('Kaydet'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('İptal'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}