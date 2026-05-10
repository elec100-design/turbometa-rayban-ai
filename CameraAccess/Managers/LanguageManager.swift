/*
 * Language Manager
 * App 语言管理器 - 모든 에러 수정 및 한국어 TTS 완벽 지원 버전
 */

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable {
    case system = "system"
    case chinese = "zh-Hans"
    case english = "en"
    case korean = "ko"

    var displayName: String {
        switch self {
        case .system: return "跟随系统 / System"
        case .chinese: return "中文"
        case .english: return "English"
        case .korean: return "한국어"
        }
    }
}

@MainActor
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    private let languageKey = "app_language"

    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
        }
    }

    nonisolated(unsafe) static var currentBundle: Bundle = .main

    private init() {
        let savedLanguage = UserDefaults.standard.string(forKey: languageKey) ?? "system"
        self.currentLanguage = AppLanguage(rawValue: savedLanguage) ?? .system
    }

    // MARK: - Static Helpers (TTSService 및 기타 서비스에서 호출)
    
    // 1. 중국어 여부 체크 (기존 에러 방지용)
    nonisolated static var staticIsChinese: Bool {
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "system"
        return savedLanguage == "zh-Hans"
    }

    // 2. 시스템 TTS용 언어 코드 (ko-KR, zh-CN, en-US) - 이번 에러의 원인 해결!
    nonisolated static var staticTtsLanguageCode: String {
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "system"
        switch savedLanguage {
        case "zh-Hans": return "zh-CN"
        case "ko": return "ko-KR"
        default: return "en-US"
        }
    }

    // 3. API 통신용 언어 명칭
    nonisolated static var staticApiLanguageCode: String {
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "system"
        switch savedLanguage {
        case "zh-Hans": return "Chinese"
        case "ko": return "Korean"
        default: return "English"
        }
    }

    // 4. TTS 목소리 식별자
    nonisolated static var staticTtsVoice: String {
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "system"
        switch savedLanguage {
        case "zh-Hans": return "Cherry"
        case "ko": return "Yuna"
        default: return "Ethan"
        }
    }
}

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
