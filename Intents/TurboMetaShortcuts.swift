//
//  TurboMetaShortcuts.swift
//  CameraAccess
//
//  Created by 전기백 on 5/11/26.
//

import AppIntents

struct TurboMetaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        [
            // 1. 맞춤 지시 (가장 자유로운 명령)
            AppShortcut(
                intent: TurboMetaCustomIntent(),
                phrases: [
                    "터보메타",
                    "레이반",
                    "터보야",
                    "레이반에게 시키기",
                    "터보메타한테 $$   \.$userSpokenText   $$ 해줘",
                    "$$   .applicationName)한테 \(\.$userSpokenText   $$"
                ],
                shortTitle: "터보 맞춤 지시",
                systemImageName: "sparkles"
            ),
            
            // 2. 분석 (퀵비전)
            AppShortcut(
                intent: QuickVisionIntent(),
                phrases: [
                    "터보메타 분석",
                    "레이반 분석",
                    "터보 분석",
                    "터보메타 지금 찍어",
                    "레이반으로 찍어",
                    "터보 퀵비전"
                ],
                shortTitle: "터보 분석",
                systemImageName: "camera.fill"
            ),
            
            // 3. 번역 (Apple Translate와 완전 분리)
            AppShortcut(
                intent: TurboTranslateIntent(),
                phrases: [
                    "터보메타 비전 번역",
                    "레이반 비전 번역",
                    "터보 이미지 번역",
                    "레이반으로 번역해",
                    "터보메타 OCR",
                    "레이반 글자 읽어",
                    "터보 번역"
                ],
                shortTitle: "터보 비전 번역",
                systemImageName: "globe"
            )
        ]
    }
}
