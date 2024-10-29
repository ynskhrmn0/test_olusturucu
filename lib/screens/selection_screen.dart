import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exam_provider.dart';
import 'dart:io';

class SelectionScreen extends StatefulWidget {
  final String imagePath;
  final VoidCallback onSaved;

  SelectionScreen({
    required this.imagePath,
    required this.onSaved,
  });

  @override
  _SelectionScreenState createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  String? selectedAnswer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seçim Kaydet'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.contain,
            ),
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
                          final provider =
                              Provider.of<ExamProvider>(context, listen: false);
                          provider.addQuestion(
                            Question(
                              imagePath: widget.imagePath,
                              answer: selectedAnswer!,
                              cropRect: Rect.zero,
                            ),
                          );
                          widget.onSaved();
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
    );
  }
}