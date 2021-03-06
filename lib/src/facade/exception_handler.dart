import 'package:angular2/src/facade/base_wrapped_exception.dart'
    show BaseWrappedException;
import 'package:logging/logging.dart';

/// Provides a hook for centralized exception handling.
///
/// The default implementation of `ExceptionHandler` when use AngularDart is
/// actually `BrowserExceptionHandler`, which prints error message directly to
/// the console.
///
/// It's possible to instead write a _custom exception handler_:
/// ```
/// import 'package:angular2/angular2.dart';
/// import 'package:angular2/platform/browser.dart';
///
/// @Injectable()
/// class MyExceptionHandler implements ExceptionHandler {
///   @override
///   void call(exception, [stackTrace, String reason]) {
///     // Do something with this exception, like send to an online service.
///   }
/// }
///
/// void main() {
///   bootstrap(MyApp, [
///     provide(ExceptionHandler, useClass: MyExceptionHandler),
///   ]);
/// }
/// ```
class ExceptionHandler {
  static String _extractMessage(exception) => exception is BaseWrappedException
      ? exception.wrapperMessage
      : exception.toString();

  static _findContext(exception) {
    try {
      return exception is BaseWrappedException
          ? exception.context ?? _findContext(exception.originalException)
          : null;
    } catch (_) {
      return null;
    }
  }

  static _findOriginalException(exception) {
    while (exception is BaseWrappedException) {
      exception = exception.originalException;
    }
    return exception;
  }

  static _findOriginalStackTrace(exception) {
    var stackTrace;
    while (exception is BaseWrappedException) {
      stackTrace = exception.originalStack;
      exception = exception.originalException;
    }
    return stackTrace;
  }

  static String _longStackTrace(stackTrace) => stackTrace is Iterable
      ? stackTrace.join('\n\n-----async gap-----\n')
      : stackTrace.toString();

  /// Internal use only: Converts a caught angular exception into a string.
  static String exceptionToString(
    exception, [
    stackTrace,
    String reason,
  ]) {
    final originalStackTrace = _findOriginalStackTrace(exception);
    final originalException = _findOriginalException(exception);
    final context = _findContext(exception);
    final buffer = new StringBuffer();
    buffer.writeln('EXCEPTION: ${_extractMessage(exception)}');
    if (stackTrace != null) {
      buffer.writeln('STACKTRACE: ');
      buffer.writeln(_longStackTrace(stackTrace));
    }
    if (reason != null) {
      buffer.writeln('REASON: $reason');
    }
    if (originalException != null) {
      buffer.writeln(
        'ORIGINAL EXCEPTION: ${_extractMessage(originalException)}',
      );
    }
    if (originalStackTrace != null) {
      buffer.writeln('ORIGINAL STACKTRACE:');
      buffer.writeln(_longStackTrace(originalStackTrace));
    }
    if (context != null) {
      buffer.writeln('ERROR CONTEXT:');
      buffer.writeln(context);
    }
    return buffer.toString();
  }

  final Logger _logger;

  const ExceptionHandler(
    this._logger, [
    @Deprecated('Not supported') bool _rethrow,
  ]);

  /// Handles an exception caught at runtime.
  ///
  /// Can be overridden by clients for different behavior other than printing to
  /// the console (such as backend reporting, other forms of logging, etc).
  void call(exception, [stackTrace, String reason]) {
    _logger.severe(exceptionToString(exception, stackTrace, reason));
  }
}
