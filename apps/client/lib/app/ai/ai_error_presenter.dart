import '../../l10n/app_localizations.dart';
import 'ai_repository.dart';
import 'speech_input_service.dart';

String localizeAiError(
  AppLocalizations l10n,
  AiRepositoryException error,
) {
  switch (error.code) {
    case AiErrorCode.authorizationRequired:
      return l10n.aiErrorAuthorization;
    case AiErrorCode.azureSpeechNotConfigured:
      return l10n.aiErrorAzureConfig;
    case AiErrorCode.azureSpeechFailed:
      return l10n.aiErrorAzureFailed;
    case AiErrorCode.azureSpeechEmpty:
      return l10n.aiErrorAzureEmpty;
    case AiErrorCode.invalidRequest:
      return error.details.isEmpty
          ? l10n.aiErrorInvalidRequest
          : '${l10n.aiErrorInvalidRequest} ${error.details.join(' ')}';
    case AiErrorCode.openAiAnswerInvalid:
      return l10n.aiErrorAnswerFailed;
    case AiErrorCode.openAiStructuredInvalid:
      return l10n.aiErrorParseFailed;
    case AiErrorCode.remoteUnavailable:
    case AiErrorCode.requestFailed:
    case AiErrorCode.unexpectedResponse:
      return l10n.aiErrorGeneric;
  }
}

String localizeSpeechInputError(
  AppLocalizations l10n,
  SpeechInputException error,
) {
  switch (error.code) {
    case SpeechInputErrorCode.microphonePermissionDenied:
      return l10n.captureVoiceUnavailableBody;
    case SpeechInputErrorCode.recordingStartFailed:
      return l10n.captureVoiceStartErrorBody;
    case SpeechInputErrorCode.recordingStopFailed:
      return l10n.captureVoiceStopErrorBody;
  }
}
