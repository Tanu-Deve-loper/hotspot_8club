import 'package:dio/dio.dart';
import '../models/experience_model.dart';
import '../utils/constants.dart';

/// API Service class using Dio for network requests
/// Singleton pattern ensures only one instance exists
/// Handles all API calls with comprehensive error handling
class ApiService {
  // ========== SINGLETON PATTERN ==========
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late final Dio _dio;

  // Private constructor for singleton
  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ========== INTERCEPTORS ==========
    
    // 1. Logging Interceptor (Development only)
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: (obj) {
          print(obj);
        },
      ),
    );

    // 2. Custom Error Handler Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add custom headers here if needed (e.g., auth token)
          // options.headers['Authorization'] = 'Bearer $token';
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Handle successful responses
          return handler.next(response);
        },
        onError: (error, handler) {
          // Log error details
          _logError(error);
          return handler.next(error);
        },
      ),
    );
  }

  // ========== API METHODS ==========

  /// Fetch all active experiences from the server
  /// 
  /// Returns [ExperiencesResponse] containing list of experiences
  /// 
  /// Throws [Exception] with user-friendly message on failure
  /// 
  /// Example:
  /// ```
  /// final response = await apiService.fetchExperiences();
  /// final experiences = response.experiences;
  /// ```
  Future<ExperiencesResponse> fetchExperiences() async {
    try {
      final response = await _dio.get(AppConstants.experiencesEndpoint);

      if (response.statusCode == 200 && response.data != null) {
        return ExperiencesResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Invalid response from server',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  // ========== ERROR HANDLING ==========

  /// Handle Dio exceptions and return user-friendly error messages
  /// 
  /// [error] The DioException to handle
  /// 
  /// Returns a user-friendly error message string
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection and try again.';
      
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      
      case DioExceptionType.receiveTimeout:
        return 'Server is taking too long to respond. Please try again later.';
      
      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);
      
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network settings.';
      
      case DioExceptionType.badCertificate:
        return 'Security certificate error. Please try again later.';
      
      case DioExceptionType.unknown:
      default:
        return 'Network error occurred. Please try again.';
    }
  }

  /// Handle bad HTTP responses based on status code
  /// 
  /// [response] The Response object containing status code and data
  /// 
  /// Returns appropriate error message based on status code
  String _handleBadResponse(Response? response) {
    if (response == null) {
      return 'Server error. Please try again later.';
    }

    switch (response.statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden.';
      case 404:
        return 'Experiences not found.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Bad gateway. Server is temporarily unavailable.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'Server error (${response.statusCode}). Please try again.';
    }
  }

  /// Log error details for debugging
  /// 
  /// [error] The DioException to log
  void _logError(DioException error) {
    print('═════════════════════════════════════════');
    print('❌ API ERROR OCCURRED');
    print('═════════════════════════════════════════');
    print('Type: ${error.type}');
    print('Message: ${error.message}');
    print('URL: ${error.requestOptions.uri}');
    print('Method: ${error.requestOptions.method}');
    if (error.response != null) {
      print('Status Code: ${error.response?.statusCode}');
      print('Response Data: ${error.response?.data}');
    }
    print('═════════════════════════════════════════');
  }

  // ========== UTILITY METHODS ==========

  /// Cancel all pending requests
  /// Useful when disposing the service or navigating away
  void cancelAllRequests() {
    _dio.close(force: true);
  }

  /// Dispose the Dio client
  /// Call this when the service is no longer needed
  void dispose() {
    _dio.close();
  }
}
