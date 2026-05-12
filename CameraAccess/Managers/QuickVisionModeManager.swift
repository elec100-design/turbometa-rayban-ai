/*
 * Quick Vision Mode Manager
 * 快速识图模式管理器 - 管理当前模式、自定义提示词、翻译目标语言
 */

import Foundation
import Observation
import SwiftUI

@Observable
final class QuickVisionModeManager {
    static let shared = QuickVisionModeManager()
    
    private let userDefaults = UserDefaults.standard
    private let modeKey = "quickVisionMode"
    private let customPromptKey = "quickVisionCustomPrompt"
    private let translateTargetLanguageKey = "quickVisionTranslateTargetLanguage"
    
    var currentMode: QuickVisionMode = .standard {
        didSet {
            userDefaults.set(currentMode.rawValue, forKey: modeKey)
            print("📋 [QuickVisionModeManager] 모드 변경: \(currentMode.displayName)")
        }
    }
    
    var customPrompt: String = "" {
        didSet {
            userDefaults.set(customPrompt, forKey: customPromptKey)
        }
    }
    
    var translateTargetLanguage: String = "ko-KR" {
        didSet {
            userDefaults.set(translateTargetLanguage, forKey: translateTargetLanguageKey)
        }
    }
    
    // 지원 언어
    static let supportedLanguages: [(code: String, name: String)] = [
        ("ko-KR", "한국어"),
        ("en-US", "영어"),
        ("ja-JP", "일본어"),
        ("zh-CN", "중국어"),
        ("fr-FR", "프랑스어"),
        ("de-DE", "독일어"),
        ("es-ES", "스페인어"),
        ("it-IT", "이탈리아어"),
        ("pt-BR", "포르투갈어"),
        ("ru-RU", "러시아어")
    ]
    
    private init() {
        // 저장된 모드 불러오기
        if let savedMode = userDefaults.string(forKey: modeKey),
           let mode = QuickVisionMode(rawValue: savedMode) {
            self.currentMode = mode
        } else {
            self.currentMode = .standard
        }
        
        // 커스텀 프롬프트 불러오기
        self.customPrompt = userDefaults.string(forKey: customPromptKey) ?? "이미지를 자세히 분석해 주세요."
        
        // 번역 대상 언어 (기본 한국어)
        self.translateTargetLanguage = userDefaults.string(forKey: translateTargetLanguageKey) ?? "ko-KR"
    }
    
    // 현재 모드의 프롬프트 반환
    func getPrompt() -> String {
        return getPrompt(for: currentMode)
    }

    // 특정 모드의 프롬프트 반환
    func getPrompt(for mode: QuickVisionMode) -> String {
        switch mode {
        case .custom:
            return customPrompt
        case .translate:
            return getTranslatePrompt()
        default:
            return mode.prompt
        }
    }
    
    private func getTranslatePrompt() -> String {
        let targetName = Self.supportedLanguages.first { $0.code == translateTargetLanguage }?.name ?? "한국어"
        return """
        너는 Ray-Ban Meta 안경의 번역 전문 AI 비서다.
        이미지에 보이는 모든 텍스트를 즉시 \(targetName)로 자연스럽게 번역하라.
        원문과 번역문을 함께 표시하고, 변명·설명·사과·"이미지가 잘 안보인다" 같은 말은 절대 하지 마라.
        오직 번역 결과만 출력하라.
        """
    }
    
    func setMode(_ mode: QuickVisionMode) {
        currentMode = mode
    }
    
    func setTranslateTargetLanguage(_ languageCode: String) {
        translateTargetLanguage = languageCode
    }
}
