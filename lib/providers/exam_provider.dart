import 'package:flutter/material.dart';

class Question {
  final String imagePath;
  final String answer;
  final Rect cropRect;

  Question({
    required this.imagePath,
    required this.answer,
    required this.cropRect,
  });
}

class ExamProvider with ChangeNotifier {
  List<Question> _questions = [];
  bool _includeAnswerKey = false;
  String _examTitle = '';

  List<Question> get questions => _questions;
  bool get includeAnswerKey => _includeAnswerKey;
  String get examTitle => _examTitle;

  void addQuestion(Question question) {
    _questions.add(question);
    notifyListeners();
  }

  void removeQuestion(int index) {
    _questions.removeAt(index);
    notifyListeners();
  }

  void setIncludeAnswerKey(bool value) {
    _includeAnswerKey = value;
    notifyListeners();
  }

  void setExamTitle(String title) {
    _examTitle = title;
    notifyListeners();
  }

  void clear() {
    _questions.clear();
    _examTitle = '';
    _includeAnswerKey = false;
    notifyListeners();
  }
}