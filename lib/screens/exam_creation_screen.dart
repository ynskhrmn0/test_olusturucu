// exam_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exam_provider.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'home_screen.dart';

class ExamCreationScreen extends StatelessWidget {
  final TextEditingController _titleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sınav Oluştur'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Provider.of<ExamProvider>(context, listen: false).clear();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: Consumer<ExamProvider>(
        builder: (context, examProvider, child) {
          _titleController.text = examProvider.examTitle;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Sınav Başlığı',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) =>
                              examProvider.setExamTitle(value),
                        ),
                        SizedBox(height: 16),
                        SwitchListTile(
                          title: Text('Cevap Anahtarı Ekle'),
                          value: examProvider.includeAnswerKey,
                          onChanged: (value) =>
                              examProvider.setIncludeAnswerKey(value),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.visibility),
                        label: Text('Soruları Görüntüle'),
                        onPressed: () =>
                            _showQuestionsDialog(context, examProvider),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.add),
                        label: Text('Soru Ekle'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text('PDF Oluştur'),
                  onPressed: examProvider.questions.isEmpty
                      ? null
                      : () => _generatePDF(context, examProvider),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showQuestionsDialog(BuildContext context, ExamProvider examProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text('Seçilen Sorular'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: examProvider.questions.length,
                  itemBuilder: (context, index) {
                    final question = examProvider.questions[index];
                    return ListTile(
                      leading: Container(
                        width: 60,
                        height: 60,
                        child: Image.file(
                          File(question.imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text('Soru ${index + 1}'),
                      subtitle: Text('Cevap: ${question.answer}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          examProvider.removeQuestion(index);
                          if (examProvider.questions.isEmpty) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generatePDF(
      BuildContext context, ExamProvider examProvider) async {
    final pdf = pw.Document();

    // Türkçe karakterleri düzelt
    String sanitizeFileName(String fileName) {
      final Map<String, String> turkishChars = {
        'ı': 'i',
        'ğ': 'g',
        'ü': 'u',
        'ş': 's',
        'ö': 'o',
        'ç': 'c',
        'İ': 'I',
        'Ğ': 'G',
        'Ü': 'U',
        'Ş': 'S',
        'Ö': 'O',
        'Ç': 'C',
      };

      String result = fileName;
      turkishChars.forEach((key, value) {
        result = result.replaceAll(key, value);
      });
      return result;
    }

    // A4 boyutunda sayfa oluştur
    final pageFormat = PdfPageFormat.a4;

    // Soruları sayfalara böl
    for (var i = 0; i < examProvider.questions.length; i += 8) {
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (context) {
            final List<pw.Widget> pageWidgets = [
              pw.Header(
                level: 0,
                child: pw.Center(
                  child: pw.Text(
                    examProvider.examTitle,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
            ];

            final leftColumn = <pw.Widget>[];
            final rightColumn = <pw.Widget>[];

            // İlk sütun dolana kadar soruları ekleyin
            for (var j = i;
                j < i + 4 && j < examProvider.questions.length;
                j++) {
              final image = pw.MemoryImage(
                File(examProvider.questions[j].imagePath).readAsBytesSync(),
              );
              final questionWidget = pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${j + 1}.',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.SizedBox(width: 5),
                  pw.Expanded(
                    child: pw.Image(image, fit: pw.BoxFit.contain),
                  ),
                ],
              );

              leftColumn.add(questionWidget);
              leftColumn.add(pw.SizedBox(height: 60)); // Boşluk ekle
            }

            // Sonraki sütun dolana kadar soruları ekleyin
            for (var j = i + 4;
                j < i + 8 && j < examProvider.questions.length;
                j++) {
              final image = pw.MemoryImage(
                File(examProvider.questions[j].imagePath).readAsBytesSync(),
              );
              final questionWidget = pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${j + 1}.',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.SizedBox(width: 5),
                  pw.Expanded(
                    child: pw.Image(image, fit: pw.BoxFit.contain),
                  ),
                ],
              );

              rightColumn.add(questionWidget);
              rightColumn.add(pw.SizedBox(height: 60)); // Boşluk ekle
            }

            pageWidgets.add(
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(children: leftColumn),
                  ),
                  pw.Container(
                    width: 1,
                    height: pageFormat.availableHeight -
                        100, // Başlık ve cevap anahtarı için boşluk bırak
                    color: PdfColors.grey,
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Column(children: rightColumn),
                  ),
                ],
              ),
            );

            // Cevap anahtarı ekle
            if (examProvider.includeAnswerKey) {
              final answers = <String>[];
              for (var j = i;
                  j < i + 8 && j < examProvider.questions.length;
                  j++) {
                answers.add('${j + 1}: ${examProvider.questions[j].answer}');
              }

              pageWidgets.add(pw.Spacer());

              pageWidgets.add(
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: answers.map((answer) => pw.Text(answer)).toList(),
                  ),
                ),
              );
            }

            return pw.Column(children: pageWidgets);
          },
        ),
      );
    }

    try {
      // PDF'i kaydet
      final output = await getApplicationDocumentsDirectory();
      final sanitizedTitle = sanitizeFileName(examProvider.examTitle);
      final file = File('${output.path}/$sanitizedTitle.pdf');
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF başarıyla kaydedildi: ${file.path}'),
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'TAMAM',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF oluşturulurken bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}