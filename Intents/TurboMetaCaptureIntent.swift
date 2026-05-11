//
//  TurboMetaCaptureIntent.swift
//  CameraAccess
//
//  Created by 전기백 on 5/11/26.
//

import AppIntents
import UIKit


init(streamViewModel: StreamSessionViewModel) {
    self.streamViewModel = streamViewModel
    OpenClawChatViewModel.shared = self
    
    // 🌟 로컬 네트워크 권한 팝업을 강제로 유도하는 코드
    let host = NWEndpoint.Host("127.0.0.1")
    let connection = NWConnection(host: host, port: .unprivileged, using: .udp)
    connection.stateUpdateHandler = { _ in }
    connection.start(queue: .main)
}


struct TurboMetaCaptureIntent: AppIntent {
    static var title: LocalizedStringResource = "안경으로 촬영 및 분석"
    static var description = IntentDescription("레이벤 메타 안경으로 사진을 찍고 AI가 상황을 한국어로 설명합니다.")

    // Siri가 앱을 열지 않고 백그라운드에서 실행하도록 설정
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // 1. ViewModel 싱글톤 또는 인스턴스 접근 (프로젝트 구조에 맞게 수정 필요)
        // 여기서는 OpenClawChatViewModel.shared가 있다고 가정합니다.
        let viewModel = OpenClawChatViewModel.shared
        
        // 2. 촬영 및 분석 프로세스 시작 알림
        // Siri의 목소리로 먼저 안내하고 싶다면 Dialog를 사용할 수 있습니다.
        
        do {
            // 3. 기존에 만들어둔 촬영-분석 통합 메서드 호출
            // 메서드명이 다르다면 실제 ViewModel의 메서드로 교체하세요.
            try await viewModel.startVisualAISession()
            
            return .result(value: "분석을 시작합니다.", dialog: "안경으로 사진을 찍어 분석을 시작할게요.")
        } catch {
            return .result(value: "실패", dialog: "안경 연결을 확인해 주세요.")
        }
    }
}
