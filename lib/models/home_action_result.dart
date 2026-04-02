enum HomeActionStatus { success, failure }

class HomeActionResult {
  const HomeActionResult.success([this.message])
    : status = HomeActionStatus.success;

  const HomeActionResult.failure(this.message)
    : status = HomeActionStatus.failure;

  final HomeActionStatus status;
  final String? message;

  bool get isSuccess => status == HomeActionStatus.success;
}

class AttachmentOpenResult {
  const AttachmentOpenResult({required this.didOpen, this.message});

  final bool didOpen;
  final String? message;
}
