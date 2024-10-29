import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exam_provider.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PreviewScreen extends StatefulWidget {
  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Önizleme'),
      ),
      body: Consumer<ExamProvider>(
        builder: (context, examProvider, child) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Sınav Başlığı',
                  ),
                  onChanged: (value) {
                    examProvider.setExamTitle(value);
                  },
                ),
                CheckboxListTile(
                  title: Text('Cevap Anahtarı Ekle'),
                  value: examProvider.includeAnswerKey,
                  onChanged: (value) {
                    examProvider.setIncludeAnswerKey(value ?? false);
                  },
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: examProvider.questions.length,
                    itemBuilder: (context, index) {
                      final question = examProvider.questions[index];
                      return ListTile(
                        leading: Image.file(
                          File(question.imagePath),
                          width: 50,
                          height: 50,
                        ),
                        title: Text('Soru ${index + 1}'),
                        subtitle: Text('Cevap: ${question.answer}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            examProvider.removeQuestion(index);
                          },
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _generatePDF(context, examProvider);
                  },
                  child: Text('PDF Oluştur'),
                ),
              ],
            ),
          );
        },
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

    // Her sayfada kaç soru olacağını hesapla (2 sütun x 3 satır = 6 soru)
    final questionsPerPage = 6;

    // Soruları sayfalara böl
    for (var pageIndex = 0;
        pageIndex < (examProvider.questions.length / questionsPerPage).ceil();
        pageIndex++) {
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (context) {
            final pageWidgets = [
              // Başlık
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

            // Bu sayfadaki soruları iki sütuna böl
            final leftColumnQuestions = <pw.Widget>[];
            final rightColumnQuestions = <pw.Widget>[];

            // Her sütun için maksimum 3 soru
            for (var i = 0; i < questionsPerPage / 2; i++) {
              final leftIndex = pageIndex * questionsPerPage + i;
              final rightIndex = leftIndex + (questionsPerPage ~/ 2);

              if (leftIndex < examProvider.questions.length) {
                leftColumnQuestions.add(
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '${leftIndex + 1}.',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          pw.SizedBox(width: 5),
                          pw.Expanded(
                            child: pw.Image(
                              pw.MemoryImage(
                                File(examProvider
                                        .questions[leftIndex].imagePath)
                                    .readAsBytesSync(),
                              ),
                              height: 180,
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                    ],
                  ),
                );
              }

              if (rightIndex < examProvider.questions.length) {
                rightColumnQuestions.add(
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '${rightIndex + 1}.',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          pw.SizedBox(width: 5),
                          pw.Expanded(
                            child: pw.Image(
                              pw.MemoryImage(
                                File(examProvider
                                        .questions[rightIndex].imagePath)
                                    .readAsBytesSync(),
                              ),
                              height: 180,
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                    ],
                  ),
                );
              }
            }

            // İki sütunu yan yana yerleştir
            pageWidgets.add(
  pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Column(children: leftColumnQuestions),
      ),
      pw.SizedBox(width: 20),
      pw.Expanded(
        child: pw.Column(children: rightColumnQuestions),
      ),
    ],
  ) as pw.StatelessWidget,
);

// Cevap anahtarını ekle
if (examProvider.includeAnswerKey) {
  pageWidgets.add(pw.SizedBox(height: 20));
  
  final startIndex = pageIndex * questionsPerPage;
  final endIndex = (startIndex + questionsPerPage) < examProvider.questions.length
      ? startIndex + questionsPerPage
      : examProvider.questions.length;
  
  final answers = <pw.Widget>[];
  for (var i = startIndex; i < endIndex; i++) {
    answers.add(
      pw.Text(
        '${i + 1}: ${examProvider.questions[i].answer}',
        style: pw.TextStyle(fontSize: 10),
      ),
    );
  }

  pageWidgets.add(
    pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: answers,
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
