import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../constants/diary_limits.dart';

/// Gemini API — `.env` 또는 `--dart-define` (우선순위: dart-define > .env)
class AiConfig {
  AiConfig._();

  static String get geminiApiKey {
    const fromDefine = String.fromEnvironment('GEMINI_API_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
  }

  /// Google AI Studio 키 — `AIza`(레거시) 또는 `AQ.`(auth key, 2025~)
  static bool get isGeminiConfigured {
    final key = geminiApiKey;
    if (key.isEmpty) return false;
    return key.startsWith('AIza') || key.startsWith('AQ.');
  }

  static String? get geminiConfigIssue {
    final key = geminiApiKey;
    if (key.isEmpty) {
      return '.env의 GEMINI_API_KEY가 비어 있어요. '
          '파일 저장(Cmd+S) 후 앱을 재시작해 주세요. '
          '키 발급: https://aistudio.google.com/apikey';
    }
    if (!key.startsWith('AIza') && !key.startsWith('AQ.')) {
      return 'GEMINI_API_KEY 형식을 확인해 주세요. '
          'AIza… 또는 AQ.… 로 시작해야 해요.';
    }
    return null;
  }

  /// 비전+텍스트용 (빠르고 저렴)
  static const String geminiModel = 'gemini-2.0-flash';

  static int get maxPhotosForVision => DiaryLimits.maxPhotosPerEntry;
  static const int maxPhotoBytes = 3 * 1024 * 1024;
  static const int photoMaxEdgePx = 1024;
}
