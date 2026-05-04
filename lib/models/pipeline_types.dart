/// Pipeline stage tracking for the unified input pipeline.
///
/// Each stage represents a discrete, observable phase of the
/// pick → validate → compress → upload → save → navigate flow.
enum PipelineStage {
  idle,
  picking,
  processing,
  uploading,
  saving,
  navigating,
  success,
  error,
}

/// Extension to query convenience booleans on [PipelineStage].
extension PipelineStageX on PipelineStage {
  /// True during any active processing phase (picking through saving).
  bool get isActive =>
      this == PipelineStage.picking ||
      this == PipelineStage.processing ||
      this == PipelineStage.uploading ||
      this == PipelineStage.saving;

  /// True when the pipeline is blocked and UI should prevent new inputs.
  bool get isBusy => isActive || this == PipelineStage.navigating;

  /// True for terminal states.
  bool get isTerminal =>
      this == PipelineStage.success ||
      this == PipelineStage.error ||
      this == PipelineStage.idle;
}

/// Standardized exception thrown at any stage of the pipeline.
///
/// Every service in the pipeline (picker, processor, API, storage)
/// must throw [PipelineException] so the controller can set
/// [PipelineStage.error] with a deterministic [stage] + [message].
class PipelineException implements Exception {
  /// Human-readable error description.
  final String message;

  /// The stage at which the failure occurred.
  final PipelineStage stage;

  /// Whether the user can retry from this error.
  final bool canRetry;

  const PipelineException({
    required this.message,
    required this.stage,
    this.canRetry = true,
  });

  @override
  String toString() => 'PipelineException($stage): $message';
}
