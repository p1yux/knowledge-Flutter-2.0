import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:knowledge/core/network/api_service.dart';
import 'package:knowledge/data/models/quiz.dart';

part 'quiz_repository.g.dart';

class QuizRepository {
  final ApiService _apiService;

  QuizRepository() : _apiService = ApiService();

  // Fetch quiz for a specific story
  Future<Quiz?> getStoryQuiz(String storyId) async {
    try {
      final response = await _apiService.get('/story/$storyId/quiz/');

      if (response.statusCode == 401) {
        throw 'Please log in again to continue';
      }

      if (response.statusCode != 200) {
        final errorMessage = response.data['detail'] ??
            response.data['message'] ??
            'Failed to fetch quiz';
        throw errorMessage.toString();
      }

      // Check if the response is empty or null
      if (response.data == null ||
          (response.data is List && response.data.isEmpty) ||
          (response.data is Map && response.data.isEmpty)) {
        return null; // No quiz available for this story
      }

      // Parse the response data
      if (response.data is List && response.data.isNotEmpty) {
        return Quiz.fromApiResponse(response.data[0]);
      } else if (response.data is Map) {
        return Quiz.fromApiResponse(response.data);
      } else {
        throw 'Invalid response format for quiz';
      }
    } catch (e) {
      print('Error fetching quiz for story $storyId: $e');
      rethrow;
    }
  }

  // Submit quiz answers and get results
  Future<Map<String, dynamic>> submitQuizAnswers(
      String quizId, List<QuizAnswer> answers) async {
    try {
      // Format the answers as required by the API
      final List<Map<String, dynamic>> formattedAnswers = answers
          .map((answer) => {
                'question_id': answer.questionId,
                'selected_option_id': answer.selectedOptionId,
              })
          .toList();

      final response = await _apiService.post(
        '/quiz/submit',
        data: {
          'quiz_id': quizId,
          'answers': formattedAnswers,
        },
      );

      if (response.statusCode == 401) {
        throw 'Please log in again to continue';
      }

      if (response.statusCode != 200) {
        final errorMessage = response.data['detail'] ??
            response.data['message'] ??
            'Failed to submit quiz';
        throw errorMessage.toString();
      }

      return response.data;
    } catch (e) {
      print('Error submitting quiz answers: $e');
      rethrow;
    }
  }
}

// Class to represent a quiz answer for submission
class QuizAnswer {
  final String questionId;
  final String selectedOptionId;

  QuizAnswer({
    required this.questionId,
    required this.selectedOptionId,
  });
}

@riverpod
QuizRepository quizRepository(QuizRepositoryRef ref) {
  return QuizRepository();
}

@riverpod
Future<Quiz?> storyQuiz(StoryQuizRef ref, String storyId) async {
  final repository = ref.watch(quizRepositoryProvider);
  return repository.getStoryQuiz(storyId);
}

// Provider for submitting quiz answers
@riverpod
Future<Map<String, dynamic>> submitQuiz(
  SubmitQuizRef ref,
  String quizId,
  List<QuizAnswer> answers,
) async {
  final repository = ref.watch(quizRepositoryProvider);
  return repository.submitQuizAnswers(quizId, answers);
}
