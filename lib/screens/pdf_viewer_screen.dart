import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:flutter/rendering.dart';

import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'dart:ui' as ui;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:test_olusturucu/screens/exam_creation_screen.dart';

import 'selection_screen.dart';

class PDFViewerScreen extends StatefulWidget {
  final String filePath;

  PDFViewerScreen({required this.filePath});

  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  final PdfViewerController _pdfController = PdfViewerController();

  bool isSelectionMode = false;

  Offset? startPosition;

  Offset? currentPosition;

  final GlobalKey _boundaryKey = GlobalKey();

  List<Rect> savedSelections = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Görüntüleyici'),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.check_circle, color: Colors.white),
            label:
                Text('Seçimi Tamamla', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ExamCreationScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              isSelectionMode ? Icons.crop_square : Icons.crop,
              color: isSelectionMode ? Colors.blue : Colors.white,
            ),
            onPressed: () {
              setState(() {
                isSelectionMode = !isSelectionMode;

                if (!isSelectionMode) {
                  startPosition = null;

                  currentPosition = null;
                }
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isSelectionMode
                        ? 'Seçim moduna geçildi. İstediğiniz alanı seçin.'
                        : 'Seçim modu kapatıldı.',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _boundaryKey,
              child: Stack(
                children: [
                  Listener(
                    onPointerDown: isSelectionMode
                        ? (details) {
                            setState(() {
                              startPosition = details.localPosition;

                              currentPosition = details.localPosition;
                            });
                          }
                        : null,
                    onPointerMove: isSelectionMode
                        ? (details) {
                            setState(() {
                              currentPosition = details.localPosition;
                            });
                          }
                        : null,
                    onPointerUp: isSelectionMode
                        ? (details) async {
                            if (startPosition != null &&
                                currentPosition != null) {
                              await _captureSelectedArea();
                            }
                          }
                        : null,
                    child: GestureDetector(
                      onVerticalDragUpdate: isSelectionMode ? (_) {} : null,
                      onHorizontalDragUpdate: isSelectionMode ? (_) {} : null,
                      child: SfPdfViewer.file(
                        File(widget.filePath),
                        key: _pdfViewerKey,
                        controller: _pdfController,
                        onPageChanged: (PdfPageChangedDetails details) {
                          setState(() {
                            startPosition = null;

                            currentPosition = null;

                            savedSelections.clear();
                          });
                        },
                        canShowScrollHead: !isSelectionMode,
                        enableDoubleTapZooming: !isSelectionMode,
                      ),
                    ),
                  ),
                  if (isSelectionMode &&
                      startPosition != null &&
                      currentPosition != null)
                    CustomPaint(
                      painter: SelectionPainter(
                        startPosition!,
                        currentPosition!,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!isSelectionMode)
            Container(
              color: Colors.white70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.zoom_out),
                    color: Colors.black,
                    onPressed: () {
                      setState(() {
                        _pdfController.zoomLevel -= 0.25;
                      });
                    },
                  ),
                  Text(
                    '${(_pdfController.zoomLevel * 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: Colors.black),
                  ),
                  IconButton(
                    icon: Icon(Icons.zoom_in),
                    color: Colors.black,
                    onPressed: () {
                      setState(() {
                        _pdfController.zoomLevel += 0.25;
                      });
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _captureSelectedArea() async {
    try {
      if (startPosition == null || currentPosition == null) return;

      final RenderRepaintBoundary boundary = _boundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      double left = startPosition!.dx < currentPosition!.dx
          ? startPosition!.dx
          : currentPosition!.dx;

      double top = startPosition!.dy < currentPosition!.dy
          ? startPosition!.dy
          : currentPosition!.dy;

      double width = (currentPosition!.dx - startPosition!.dx).abs();

      double height = (currentPosition!.dy - startPosition!.dy).abs();

      left += 2;

      top += 2;

      width -= 4;

      height -= 4;

      // Seçilen alanı kaydet

      savedSelections.add(Rect.fromLTWH(left, top, width, height));

      if (width < 10 || height < 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lütfen daha büyük bir alan seçin')),
        );

        return;
      }

      final ui.Image fullImage = await boundary.toImage();

      final pictureRecorder = ui.PictureRecorder();

      final Canvas canvas = Canvas(pictureRecorder);

      canvas.drawImageRect(
        fullImage,
        Rect.fromLTWH(left, top, width, height),
        Rect.fromLTWH(0, 0, width, height),
        Paint(),
      );

      final ui.Image croppedImage = await pictureRecorder
          .endRecording()
          .toImage(width.toInt(), height.toInt());

      final ByteData? byteData =
          await croppedImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final tempDir = await getTemporaryDirectory();

        final tempFile = File(
            '${tempDir.path}/selected_area_${DateTime.now().millisecondsSinceEpoch}.png');

        await tempFile.writeAsBytes(byteData.buffer.asUint8List());

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SelectionScreen(
                imagePath: tempFile.path,
                onSaved: () {
                  setState(() {
                    isSelectionMode = false;

                    startPosition = null;

                    currentPosition = null;
                  });
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seçim yapılırken bir hata oluştu: $e')),
        );
      }
    }
  }
}

class SelectionPainter extends CustomPainter {
  final Offset startPosition;
  final Offset currentPosition;

  SelectionPainter(this.startPosition, this.currentPosition);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromPoints(startPosition, currentPosition);


    // Seçilen alanı şeffaf beyaz ile boya
    final paint = Paint()

      ..color = Colors.white.withOpacity(0)

      ..strokeWidth = 2.0

      ..style = PaintingStyle.fill;


    // Seçili alan için kesikli kenarlık paint
    final strokePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    
    // Kesikli çizgiyi manuel olarak çiz
    _drawDashedRect(canvas, rect, strokePaint);
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    
    // Üst kenar
    double start = rect.left;
    while (start < rect.right) {
      double end = start + dashWidth;
      if (end > rect.right) end = rect.right;
      canvas.drawLine(
        Offset(start, rect.top),
        Offset(end, rect.top),
        paint,
      );
      start = end + dashSpace;
    }

    // Alt kenar
    start = rect.left;
    while (start < rect.right) {
      double end = start + dashWidth;
      if (end > rect.right) end = rect.right;
      canvas.drawLine(
        Offset(start, rect.bottom),
        Offset(end, rect.bottom),
        paint,
      );
      start = end + dashSpace;
    }

    // Sol kenar
    start = rect.top;
    while (start < rect.bottom) {
      double end = start + dashWidth;
      if (end > rect.bottom) end = rect.bottom;
      canvas.drawLine(
        Offset(rect.left, start),
        Offset(rect.left, end),
        paint,
      );
      start = end + dashSpace;
    }

    // Sağ kenar
    start = rect.top;
    while (start < rect.bottom) {
      double end = start + dashWidth;
      if (end > rect.bottom) end = rect.bottom;
      canvas.drawLine(
        Offset(rect.right, start),
        Offset(rect.right, end),
        paint,
      );
      start = end + dashSpace;
    }
  }

  @override
  bool shouldRepaint(SelectionPainter oldDelegate) => true;
}
