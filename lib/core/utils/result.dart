/// A lightweight `Result` type used across repositories/services.
sealed class Result<T> {
  const Result();
}

final class ResultSuccess<T> extends Result<T> {
  const ResultSuccess(this.value);

  final T value;
}

final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.error, {this.code});

  final Object error;
  final String? code;

  @override
  String toString() => 'ResultFailure($code: $error)';
}