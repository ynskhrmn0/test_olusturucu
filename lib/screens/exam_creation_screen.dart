// exam_creation_screen.dart

import 'package:file_picker/file_picker.dart';

import 'package:flutter/services.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/exam_provider.dart';

import 'dart:io';

import 'package:pdf/pdf.dart';

import 'package:pdf/widgets.dart' as pw;

import 'home_screen.dart';

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

  // Dosya adı için uygun olmayan karakterleri temizle

  result = result.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

  // Birden fazla alt çizgiyi tek alt çizgiye dönüştür

  result = result.replaceAll(RegExp(r'_{2,}'), '_');

  // Baştaki ve sondaki alt çizgileri kaldır

  result = result.trim().replaceAll(RegExp(r'^_+|_+$'), '');

  return result;
}

class SaveHelper {
  static Future<void> save(List<int> bytes, String fileName) async {
    String? directory = await FilePicker.platform.getDirectoryPath();

    if (directory != null) {
      final File file = File('$directory/$fileName');

      if (file.existsSync()) {
        await file.delete();
      }

      await file.writeAsBytes(bytes);
    }
  }
}

class ExamCreationScreen extends StatefulWidget {
  @override
  State<ExamCreationScreen> createState() => _ExamCreationScreenState();
}

class _ExamCreationScreenState extends State<ExamCreationScreen> {
  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final examProvider = Provider.of<ExamProvider>(context, listen: false);

      _titleController.text = examProvider.examTitle;

      _descriptionController.text = examProvider.examDescription!;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();

    _descriptionController.dispose();

    super.dispose();
  }

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
                          onChanged: (value) {
                            examProvider.setExamTitle(value);
                          },
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Sınav Açıklaması',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            examProvider.setExamDescription(value);
                          },
                        ),
                        SizedBox(height: 16),
                        Slider(
                          value: examProvider.questionSpacing ?? 10,
                          min: 5,
                          max: 55,
                          divisions: 5,
                          label:
                              '${examProvider.questionSpacing?.toInt() ?? 10}px',
                          onChanged: (value) =>
                              examProvider.setQuestionSpacing(value),
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
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return ReorderableListView.builder(
                      shrinkWrap: true,
                      itemCount: examProvider.questions.length,
                      onReorderStart: (index) {
                        HapticFeedback.mediumImpact();
                      },
                      onReorder: (oldIndex, newIndex) {
                        examProvider.reorderQuestions(oldIndex, newIndex);

                        setState(() {}); // UI'ı yenile
                      },
                      itemBuilder: (context, index) {
                        final question = examProvider.questions[index];

                        return Dismissible(
                          key: ValueKey('${question.imagePath}_$index'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Soruyu Sil'),
                                  content: Text(
                                      'Bu soruyu silmek istediğinizden emin misiniz?'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text('İPTAL'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: Text('SİL'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text("")),
                          onDismissed: (direction) {
                            // Soruyu kaydet (geri alma için)

                            final deletedQuestion = question;

                            final deletedIndex = index;

                            // Soruyu sil

                            examProvider.removeQuestion(index);

                            setState(() {}); // UI'ı yenile

                            // Snackbar göster

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Soru başarıyla silindi'),
                                duration: Duration(seconds: 2),
                                action: SnackBarAction(
                                  label: 'GERİ AL',
                                  onPressed: () {
                                    // Soruyu geri ekle

                                    examProvider.addQuestion(deletedQuestion);

                                    setState(() {}); // UI'ı yenile
                                  },
                                ),
                              ),
                            );

                            // Eğer son soru silindiyse dialogu kapat

                            if (examProvider.questions.isEmpty) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Card(
                            key: ValueKey('card_${question.imagePath}_$index'),
                            margin: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AppBar(
                                              title: Text('Soru ${index + 1}'),
                                              automaticallyImplyLeading: false,
                                              actions: [
                                                IconButton(
                                                  icon: Icon(Icons.close),
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                ),
                                              ],
                                            ),
                                            InteractiveViewer(
                                              panEnabled: true,
                                              boundaryMargin:
                                                  EdgeInsets.symmetric(
                                                      vertical: 60,
                                                      horizontal: 20),
                                              minScale: 1,
                                              maxScale: 8,
                                              child: Image.file(
                                                File(question.imagePath),
                                                fit: BoxFit.fitWidth,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.5),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Stack(
                                    children: [
                                      Image.file(
                                        File(question.imagePath),
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: EdgeInsets.all(2),
                                          color: Colors.black54,
                                          child: Icon(
                                            Icons.zoom_in,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              title: Text('Soru ${index + 1}'),
                              subtitle: Text('Cevap: ${question.answer}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Silme butonu

                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      final delete = await showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Soruyu Sil'),
                                            content: Text(
                                                'Bu soruyu silmek istediğinizden emin misiniz?'),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: Text('İPTAL'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true),
                                                child: Text('SİL'),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (delete == true) {
                                        final deletedQuestion = question;

                                        examProvider.removeQuestion(index);

                                        setState(() {}); // UI'ı yenile

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('Soru başarıyla silindi'),
                                            duration: Duration(seconds: 2),
                                            action: SnackBarAction(
                                              label: 'GERİ AL',
                                              onPressed: () {
                                                examProvider.addQuestion(
                                                    deletedQuestion);

                                                setState(() {}); // UI'ı yenile
                                              },
                                            ),
                                          ),
                                        );

                                        if (examProvider.questions.isEmpty) {
                                          Navigator.of(context).pop();
                                        }
                                      }
                                    },
                                  ),

                                  SizedBox(width: 10),

                                  // Sürükleme tutacağı

                                  ReorderableDragStartListener(
                                    index: index,
                                    child: Text(""),
                                  ),
                                ],
                              ),
                            ),
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
      ),
    );
  }

  Future<void> _generatePDF(
      BuildContext context, ExamProvider examProvider) async {
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');

    final ttf = pw.Font.ttf(fontData);

    final pdf = pw.Document();

    final theme = pw.ThemeData.withFont(
      base: ttf,
      bold: ttf,
    );

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

    final pageFormat = PdfPageFormat.a4;

    final pageWidth = pageFormat.availableWidth;

    final columnWidth = pageWidth / 2; // İki eşit sütun

    final questionSpacing = examProvider.questionSpacing?.toDouble() ?? 10.0;

    // Header builder remains the same

    pw.Widget buildHeader({bool includeDescription = false}) {
      return pw.Container(
        width: pageWidth,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black),
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.only(top: 8),
              child: pw.Center(
                child: pw.Text(
                  examProvider.examTitle,
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
            if (includeDescription &&
                examProvider.examDescription?.isNotEmpty == true) ...[
              pw.Divider(color: PdfColors.black, thickness: 1),
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  examProvider.examDescription!,
                  style: pw.TextStyle(fontSize: 12),
                  textAlign: pw.TextAlign.justify,
                ),
              ),
            ],
          ],
        ),
      );
    }

    int currentPage = 0;

    // Footer builder remains the same

    pw.Widget buildFooter(int currentPage, List<String> answers) {
      return pw.Container(
        width: pageWidth,
        padding: pw.EdgeInsets.all(10),
        child: pw.Row(
          children: [
            if (examProvider.includeAnswerKey) ...[
              pw.Expanded(
                child: pw.Container(
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
              ),
              pw.SizedBox(width: 10),
            ],
            pw.Container(
              width: 30,
              height: 30,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                '${currentPage + 1}', // pageNumber + 1 eklendi

                style: pw.TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Optimize question widget builder

    Future<(pw.Widget, double)> buildQuestionWidget(
        Question question, int index) async {
      final imageBytes = File(question.imagePath).readAsBytesSync();

      final image = pw.MemoryImage(imageBytes);

      final imageFile = File(question.imagePath);

      final imageData = await imageFile.readAsBytes();

      final decodedImage = await decodeImageFromList(imageData);

      final imageRatio = decodedImage.width / decodedImage.height;

      // Görsel genişliği sütun genişliğine göre ayarlandı - daha geniş

      final containerWidth = (pageWidth / 2) + 36;

      final imageWidth = containerWidth - 36; // Soru numarası için boşluk

      final imageHeight = imageWidth / imageRatio;

      final questionWidget = pw.Padding(
        padding: pw.EdgeInsets.only(bottom: questionSpacing),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Container(
              width: 12,
              child: pw.Text(
                '${index + 1}.',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
            ),

            pw.SizedBox(width: 5), // Minimum boşluk

            pw.Expanded(
              child: pw.Image(
                image,

                width: imageWidth, // Soru numarası için minimal boşluk

                height: imageHeight,

                fit: pw.BoxFit.contain,
              ),
            ),

            if (index < examProvider.questions.length - 1)
              pw.SizedBox(height: questionSpacing),
          ],
        ),
      );

      return (questionWidget, imageHeight + questionSpacing);
    }

    int currentQuestion = 0;

    while (currentQuestion < examProvider.questions.length) {
      final bool isFirstPage = currentPage == 0;

      final headerHeight =
          isFirstPage && examProvider.examDescription?.isNotEmpty == true
              ? 100.0
              : 60.0;

      final footerHeight = examProvider.includeAnswerKey ? 60.0 : 30.0;

      final availableHeight =
          pageFormat.availableHeight - headerHeight - footerHeight - 40;

      List<pw.Widget> leftColumn = [];

      List<pw.Widget> rightColumn = [];

      List<String> pageAnswers = [];

      double leftColumnHeight = 0;

      double rightColumnHeight = 0;

      bool isLeftColumnFull = false;

      // Soruları sütunlara yerleştirme mantığı güncellendi

      while (currentQuestion < examProvider.questions.length) {
        final question = examProvider.questions[currentQuestion];

        final (questionWidget, questionHeight) =
            await buildQuestionWidget(question, currentQuestion);

        final totalHeight = questionHeight;

        if (!isLeftColumnFull &&
            leftColumnHeight + totalHeight <= availableHeight) {
          leftColumn.add(questionWidget);

          leftColumnHeight += totalHeight;

          pageAnswers.add('${currentQuestion + 1}-${question.answer}');

          currentQuestion++;

          continue;
        }

        if (!isLeftColumnFull) {
          isLeftColumnFull = true;
        }

        if (rightColumnHeight + totalHeight <= availableHeight) {
          rightColumn.add(questionWidget);

          rightColumnHeight += totalHeight;

          pageAnswers.add('${currentQuestion + 1}-${question.answer}');

          currentQuestion++;
        } else {
          break;
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          theme: theme,
          margin: pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Stack(
              children: [
                // Ortadaki çizgi - tam ortada ve daha uzun

                pw.Positioned(
                  left: (pageWidth / 2) + 36, // Tam ortalama

                  top: headerHeight + 1, // Başlığa daha yakın

                  bottom: footerHeight + 1, // Cevap anahtarına daha yakın

                  child: pw.Container(
                    width: 1,
                    color: PdfColors.grey,
                  ),
                ),

                // Ana içerik

                pw.Column(
                  children: [
                    buildHeader(includeDescription: isFirstPage),

                    pw.SizedBox(height: 20), // Azaltıldı

                    pw.Expanded(
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          // Sol sütun - orta çizgiye yakın

                          pw.Padding(
                            padding: pw.EdgeInsets.only(
                                right: 0), // Minimal sağ boşluk

                            child: pw.Container(
                              width:
                                  (pageWidth / 2) + 18, // Sol sütun genişliği

                              child: pw.Column(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: leftColumn,
                              ),
                            ),
                          ),

                          // Sağ sütun - orta çizgiye yakın

                          pw.Padding(
                            padding: pw.EdgeInsets.only(
                                left: 5), // Minimal sol boşluk

                            child: pw.Container(
                              width:
                                  (pageWidth / 2) + 18, // Sağ sütun genişliği

                              child: pw.Column(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: rightColumn,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    buildFooter(currentPage, pageAnswers),
                  ],
                ),
              ],
            );
          },
        ),
      );

      currentPage++;
    }

    final pdfBytes = await pdf.save();

    try {
      SaveHelper.save(pdfBytes, "${examProvider.examTitle}.pdf");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF başarıyla kaydedildi'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF kaydedilirken hata oluştu: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
