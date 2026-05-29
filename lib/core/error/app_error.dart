sealed class AppError {
  String get userMessage;
}

class DatabaseError extends AppError {
  final String message;
  final Object? originalError;
  DatabaseError(this.message, {this.originalError});
  @override
  String get userMessage => 'A database error occurred. Please try again.';
}

class EncryptionError extends AppError {
  final String message;
  final Object? originalError;
  EncryptionError(this.message, {this.originalError});
  @override
  String get userMessage => 'Could not secure your note. Please try again.';
}

class FileSystemError extends AppError {
  final String message;
  final Object? originalError;
  FileSystemError(this.message, {this.originalError});
  @override
  String get userMessage => 'Could not access the file. Please try again.';
}

class ImportError extends AppError {
  final String message;
  final Object? originalError;
  ImportError(this.message, {this.originalError});
  @override
  String get userMessage => 'Could not import notes. The file may be invalid.';
}

class ValidationError extends AppError {
  final String message;
  ValidationError(this.message);
  @override
  String get userMessage => message;
}

class UnexpectedError extends AppError {
  final Object? originalError;
  UnexpectedError({this.originalError});
  @override
  String get userMessage => 'Something unexpected happened. Please try again.';
}
