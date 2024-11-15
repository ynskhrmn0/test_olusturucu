import 'package:flutter/material.dart';

class Question {
  final String imagePath;

  final String answer;

  final Rect cropRect;

  final String examDescription;

  final double questionSpacing;

  const Question({
    required this.imagePath,
    required this.answer,
    required this.cropRect,
    this.examDescription = '',
    this.questionSpacing = 10,
  });

  // Question sınıfına copyWith metodu ekliyoruz

  Question copyWith({
    String? imagePath,
    String? answer,
    Rect? cropRect,
    String? examDescription,
    double? questionSpacing,
  }) {
    return Question(
      imagePath: imagePath ?? this.imagePath,
      answer: answer ?? this.answer,
      cropRect: cropRect ?? this.cropRect,
      examDescription: examDescription ?? this.examDescription,
      questionSpacing: questionSpacing ?? this.questionSpacing,
    );
  }
}

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

class ExamProvider with ChangeNotifier {
  List<Question> _questions = [];

  bool _includeAnswerKey = false;

  String _examTitle = '';

  String? _examDescription = '';

  double? _questionSpacing;

  // Getters'ı immutable yapıyoruz

  List<Question> get questions => List.unmodifiable(_questions);

  bool get includeAnswerKey => _includeAnswerKey;

  String get examTitle => _examTitle;

  String? get examDescription => _examDescription;

  double get questionSpacing => _questionSpacing ?? 10.0;

  // Optimize edilmiş setters

  void setExamDescription(String description) {
    _examDescription = description;

    notifyListeners();
  }

  void setQuestionSpacing(double spacing) {
    if (_questionSpacing != spacing) {
      _questionSpacing = spacing.clamp(5.0, 55.0); // Sınırları belirliyoruz

      notifyListeners();
    }
  }

  void addQuestion(Question question) {
    if (question.imagePath.isNotEmpty && question.answer.isNotEmpty) {
      _questions = [..._questions, question];

      notifyListeners();
    }
  }

  void removeQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _questions = List.from(_questions)..removeAt(index);

      notifyListeners();
    }
  }

  void setIncludeAnswerKey(bool value) {
    if (_includeAnswerKey != value) {
      _includeAnswerKey = value;

      notifyListeners();
    }
  }

  void setExamTitle(String title) {
    _examTitle = title;

    notifyListeners();
  }

  void reorderQuestions(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final Question item = _questions.removeAt(oldIndex);

    _questions.insert(newIndex, item);

    notifyListeners();
  }

  // Soruları güncellemek için yeni method

  void updateQuestion(int index, Question updatedQuestion) {
    if (index >= 0 && index < _questions.length) {
      _questions = List.from(_questions)..[index] = updatedQuestion;

      notifyListeners();
    }
  }

  void clear() {
    _questions = [];

    _examTitle = '';

    _includeAnswerKey = false;

    _examDescription = '';

    _questionSpacing = null;

    notifyListeners();
  }

  // Tek bir soru için cevap güncelleme metodu

  void updateQuestionAnswer(int index, String newAnswer) {
    if (index >= 0 && index < _questions.length) {
      final question = _questions[index];

      _questions = List.from(_questions)
        ..[index] = question.copyWith(answer: newAnswer);

      notifyListeners();
    }
  }
}
