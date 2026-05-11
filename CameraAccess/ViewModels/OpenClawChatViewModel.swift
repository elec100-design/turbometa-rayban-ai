/*
 * OpenClaw Chat ViewModel
 * 앱 주도 촬영 → 이미지 수신 → Gemini 분석 → TTS 출력
 * App-Initiated Visual AI Workflow
 */

import Foundation
import UIKit

@MainActor
class OpenClawChatViewModel: ObservableObject {

    // 🌟 Siri App Intent 연동을 위한 싱글톤 공유 인스턴스
    static var shared: OpenClawChatViewModel?

    @Published var isProcessing = false
    @Published var statusMessage = ""
    @Published var lastAnalysisResult = ""

    private let service = OpenClawNodeService.shared
    private weak var streamViewModel: StreamSessionViewModel?

    init(streamViewModel: StreamSessionViewModel) {
        self.streamViewModel = streamViewModel
        // 🌟 앱 실행 시 초기화되면서 자신을 shared에 등록
        OpenClawChatViewModel.shared = self
    }

    // MARK: - App-Initiated Visual AI Session

    func startVisualAISession() async {
        guard !isProcessing else {
            print("[VisualAI] Already processing, skipping")
            return
        }
        isProcessing = true
        statusMessage = "준비 중..."
        lastAnalysisResult = ""

        let t0 = CFAbsoluteTimeGetCurrent()

        // ── Step 1: WSS 촬영 명령 전송 ──
        service.sendManualCaptureCommand()
        print("[VisualAI] [1/5] WSS 촬영 명령 전송 완료 (\(elapsed(t0)))")

        // ── Step 2: 스트림 활성화 및 프레임 수신 대기 ──
        statusMessage = "프레임 수신 대기..."
        guard let vm = streamViewModel else {
            fail("StreamViewModel 미초기화", t0: t0)
            return
        }

        if !vm.isStreaming {
            statusMessage = "스트림 시작 중..."
            await vm.handleStartStreaming()

            let deadline = Date().addingTimeInterval(5.0)
            while vm.currentVideoFrame == nil && Date() < deadline {
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }

        guard let frame = vm.currentVideoFrame else {
            fail("프레임 수신 실패 (타임아웃 5초)", t0: t0)
            return
        }
        print("[VisualAI] [2/5] 프레임 수신 완료 \(Int(frame.size.width))x\(Int(frame.size.height)) (\(elapsed(t0)))")

        // ── Step 3: 이미지 리사이징 ──
        statusMessage = "이미지 최적화..."
        let resized = Self.resizeForAnalysis(frame, maxDimension: 1024)
        print("[VisualAI] [3/5] 리사이징 완료 \(Int(resized.size.width))x\(Int(resized.size.height)) (\(elapsed(t0)))")

        // ── Step 4: Gemini Vision API 호출 ──
        statusMessage = "AI 분석 중..."
        let visionService = QuickVisionService()
        let prompt = "사진 속의 텍스트(메뉴판, 간판 등)를 우선적으로 읽어서 한국어로 번역 및 설명해줘."

        do {
            let result = try await visionService.analyzeImage(resized, customPrompt: prompt)
            print("[VisualAI] [4/5] AI 분석 완료: \(result.prefix(80))... (\(elapsed(t0)))")
            lastAnalysisResult = result

            // ── Step 5: TTS 출력 ──
            statusMessage = "음성 출력 중..."
            TTSService.shared.speak(result)
            print("[VisualAI] [5/5] TTS 출력 시작 (\(elapsed(t0)))")

            statusMessage = "완료"
        } catch {
            let msg = "AI 분석 실패: \(error.localizedDescription)"
            print("[VisualAI] [4/5] \(msg) (\(elapsed(t0)))")
            lastAnalysisResult = msg
            statusMessage = msg
        }

        isProcessing = false
    }

    // MARK: - Helpers

    private func fail(_ reason: String, t0: CFAbsoluteTime) {
        print("[VisualAI] FAIL: \(reason) (\(elapsed(t0)))")
        statusMessage = reason
        isProcessing = false
    }

    private func elapsed(_ start: CFAbsoluteTime) -> String {
        String(format: "T+%.0fms", (CFAbsoluteTimeGetCurrent() - start) * 1000)
    }

    private static func resizeForAnalysis(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let currentMax = max(image.size.width, image.size.height)
        guard currentMax > maxDimension else { return image }
        let scale = maxDimension / currentMax
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
