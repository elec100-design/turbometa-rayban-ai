//
//  TurboMetaShortcuts.swift
//  CameraAccess
//
//  Created by 전기백 on 5/11/26.
//

import AppIntents

struct TurboMetaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
                intent: QuickVisionCustomIntent(),
                phrases: [
                    "터보메타에게 시키기",       // 👈 앱 이름 변수를 빼고 한글로 쾅 박아버립니다.
                    "터보메타 맞춤 지시",
                    "터보메타에게 물어보기"
                ],
                shortTitle: "터보 맞춤 지시",
                systemImageName: "mic.and.signal.meter"
            )
        AppShortcut(
            intent: QuickVisionIntent(),
            phrases: ["\(.applicationName) 터보 분석", "\(.applicationName) 분석해줘"],
            shortTitle: "터보 분석",
            systemImageName: "eye.circle.fill"
        )
        AppShortcut(
            intent: QuickVisionTranslateIntent(),
            phrases: ["\(.applicationName) 터보 번역", "\(.applicationName) 번역해줘"],
            shortTitle: "터보 번역",
            systemImageName: "character.bubble.fill"
        )
    }
}

