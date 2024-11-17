// exam_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedExam {
  final String title;
  final String description;
  final List<Map<String, dynamic>> questions;
  final bool includeAnswerKey;
  final double questionSpacing;

  SavedExam({
    required this.title,
    required this.description,
    required this.questions,
    required this.includeAnswerKey,
    required this.questionSpacing,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'questions': questions,
      'includeAnswerKey': includeAnswerKey,
      'questionSpacing': questionSpacing,
    };
  }

  factory SavedExam.fromJson(Map<String, dynamic> json) {
    return SavedExam(
      title: json['title'],
      description: json['description'],
      questions: List<Map<String, dynamic>>.from(json['questions']),
      includeAnswerKey: json['includeAnswerKey'],
      questionSpacing: json['questionSpacing'],
    );
  }
}

class ExamStorage {
  static const String _storageKey = 'saved_exams';

  static Future<void> saveExam(SavedExam exam) async {
    final prefs = await SharedPreferences.getInstance();
    final savedExams = await getSavedExams();
    
    savedExams.add(exam);
    
    final jsonList = savedExams.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  static Future<List<SavedExam>> getSavedExams() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    
    if (jsonString == null) return [];
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => SavedExam.fromJson(json)).toList();
  }

  static Future<void> deleteExam(String title) async {
    final prefs = await SharedPreferences.getInstance();
    final savedExams = await getSavedExams();
    
    savedExams.removeWhere((exam) => exam.title == title);
    
    final jsonList = savedExams.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }
}