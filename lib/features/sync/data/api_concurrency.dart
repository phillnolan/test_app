import 'dart:async';

/// Runs [tasks] with a soft concurrency cap.
///
/// Results are returned in the same order as the input tasks.
Future<List<T>> runWithConcurrencyLimit<T>(
  List<Future<T> Function()> tasks, {
  int limit = 6,
  void Function(int completed, int total)? onProgress,
}) async {
  if (tasks.isEmpty) {
    return <T>[];
  }

  final effectiveLimit = limit < 1 ? 1 : limit;
  final results = List<T?>.filled(tasks.length, null, growable: false);
  var nextIndex = 0;
  var completed = 0;

  void reportProgress() {
    onProgress?.call(completed, tasks.length);
  }

  Future<void> worker() async {
    while (true) {
      final currentIndex = nextIndex++;
      if (currentIndex >= tasks.length) {
        return;
      }

      results[currentIndex] = await tasks[currentIndex]();
      completed++;
      reportProgress();
    }
  }

  await Future.wait(
    List.generate(
      effectiveLimit > tasks.length ? tasks.length : effectiveLimit,
      (_) => worker(),
    ),
  );

  return results.cast<T>();
}
