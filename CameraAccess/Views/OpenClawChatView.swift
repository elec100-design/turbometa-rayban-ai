import SwiftUI

struct OpenClawChatMessage: Identifiable {
    let id = UUID()
    let role: String
    let text: String
    let image: UIImage?
    let timestamp = Date()
}

struct OpenClawChatView: View {
    @ObservedObject var streamViewModel: StreamSessionViewModel
    @ObservedObject var openClawService = OpenClawNodeService.shared
    @StateObject private var visualAI: OpenClawChatViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var messages: [OpenClawChatMessage] = []
    @State private var inputText = ""
    @State private var pendingResponse = ""

    // Navigation
    @State private var showNavInput = false
    @State private var navDestination = ""

    // History
    @State private var showHistorySheet = false

    // ASR
    @State private var isListening = false
    @State private var asrText = ""
    @State private var asrPartial = ""
    @State private var asrService: OpenClawASRService?

    init(streamViewModel: StreamSessionViewModel) {
        self.streamViewModel = streamViewModel
        _visualAI = StateObject(wrappedValue: OpenClawChatViewModel(streamViewModel: streamViewModel))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                connectionBanner
                messagesList
                Divider()
                bottomControls
            }
            .navigationTitle("터보메타")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 10) {
                        Button { startNewConversation() } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 14))
                        }
                        Circle()
                            .fill(openClawService.connectionState == .connected ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        NavigationLink { OpenClawSettingsView() } label: {
                            Image(systemName: "gear").font(.system(size: 14))
                        }
                    }
                }
            }
        }
        .onAppear { setupHandlers() }
        .onDisappear { cleanup() }
        .sheet(isPresented: $showHistorySheet) {
            ChatHistoryView { loadedMessages in
                saveCurrentSession()
                messages = loadedMessages
            }
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var connectionBanner: some View {
        if openClawService.connectionState != .connected {
            HStack(spacing: 8) {
                ProgressView().scaleEffect(0.8)
                Text("openclaw.status.connecting".localized).font(.system(size: 13))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.15))
        }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { msg in
                        ChatBubble(message: msg).id(msg.id)
                    }
                    if !pendingResponse.isEmpty {
                        ChatBubble(message: OpenClawChatMessage(role: "assistant", text: pendingResponse, image: nil))
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) {
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 10) {
            // Processing status
            if visualAI.isProcessing {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.8)
                    Text(visualAI.statusMessage).font(.system(size: 13)).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }

            // ASR transcript preview
            if isListening || !asrText.isEmpty {
                asrPreviewArea
            }

            // Navigation destination input
            if showNavInput {
                navInputArea
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // 하단 메뉴: 촬영 - 마이크 - 길찾기 - 대화기록
            HStack {
                Spacer()

                // 1. 촬영 분석
                Button {
                    Task { await triggerSceneDescription() }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "camera.fill").font(.system(size: 28))
                        Text("촬영 분석").font(.caption2)
                    }
                    .foregroundColor(visualAI.isProcessing ? .gray : .white)
                }
                .disabled(visualAI.isProcessing)

                Spacer()

                // 2. 큰 마이크 (음성 대화)
                Button { toggleListening() } label: {
                    Image(systemName: isListening ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 52))
                        .foregroundColor(isListening ? .red : .blue)
                        .shadow(radius: 5)
                }

                Spacer()

                // 3. 길찾기 네비게이션
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showNavInput.toggle()
                        if !showNavInput { navDestination = "" }
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "location.north.circle.fill").font(.system(size: 28))
                        Text("길찾기").font(.caption2)
                    }
                    .foregroundColor(showNavInput ? .yellow : .white)
                }

                Spacer()

                // 4. 대화 기록
                Button {
                    showHistorySheet = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath").font(.system(size: 28))
                        Text("대화 기록").font(.caption2)
                    }
                    .foregroundColor(.white)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.85))
            .cornerRadius(16)

            // Text input (always visible for text chat)
            HStack(spacing: 10) {
                TextField("터보메타에게 말하기...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.send)
                    .onSubmit { sendText() }

                Button { sendText() } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(inputText.isEmpty ? .gray : .purple)
                }
                .disabled(inputText.isEmpty || openClawService.connectionState != .connected)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }

    private var asrPreviewArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(displayASRText)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)

            if !isListening && !asrText.isEmpty {
                HStack(spacing: 12) {
                    Button {
                        asrText = ""
                        asrPartial = ""
                    } label: {
                        Text("cancel".localized)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .cornerRadius(10)
                    }

                    Button { sendASRText() } label: {
                        Text("openclaw.chat.sendvoice".localized)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.purple)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var navInputArea: some View {
        HStack(spacing: 10) {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 20))

            TextField("목적지를 입력하세요...", text: $navDestination)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.go)
                .onSubmit { startNavigation() }

            Button { startNavigation() } label: {
                Text("시작")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(navDestination.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(8)
            }
            .disabled(navDestination.isEmpty)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Computed

    private var displayASRText: String {
        if asrText.isEmpty && asrPartial.isEmpty {
            return isListening ? "openclaw.chat.listening".localized : ""
        }
        return asrText + (asrPartial.isEmpty ? "" : asrPartial)
    }

    // MARK: - Setup

    private func setupHandlers() {
        openClawService.onChatEvent = { (text: String) in
            if text.hasPrefix("[[FINAL]]") {
                let fullText = String(text.dropFirst(9))
                pendingResponse = ""
                if !fullText.isEmpty {
                    messages.append(OpenClawChatMessage(role: "assistant", text: fullText, image: nil))
                }
            } else {
                pendingResponse = text
            }
        }
        visualAI.onDescribeResult = { result in
            messages.append(OpenClawChatMessage(role: "assistant", text: result, image: nil))
        }
        if openClawService.connectionState != .connected,
           openClawService.loadGatewayToken() != nil {
            openClawService.connect()
        }
    }

    private func cleanup() {
        stopListening()
        if !pendingResponse.isEmpty {
            messages.append(OpenClawChatMessage(role: "assistant", text: pendingResponse, image: nil))
            pendingResponse = ""
        }
        saveCurrentSession()
        openClawService.onChatEvent = nil
        visualAI.onDescribeResult = nil
    }

    private func saveCurrentSession() {
        OpenClawSessionStorage.shared.saveSession(messages: messages)
    }

    private func startNewConversation() {
        saveCurrentSession()
        messages = []
        pendingResponse = ""
    }

    // MARK: - Actions

    private func triggerSceneDescription() async {
        messages.append(OpenClawChatMessage(role: "user", text: "📷 지금 보는 거 설명해줘", image: nil))
        flushPendingResponse()
        await visualAI.captureAndDescribe()
    }

    private func triggerTranslate() async {
        messages.append(OpenClawChatMessage(role: "user", text: "🌐 보이는 텍스트 번역해줘", image: nil))
        flushPendingResponse()
        await visualAI.captureAndTranslate()
    }

    private func startNavigation() {
        let dest = navDestination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !dest.isEmpty else { return }
        messages.append(OpenClawChatMessage(role: "user", text: "🗺️ \(dest) 로 안내해줘", image: nil))
        flushPendingResponse()
        withAnimation { showNavInput = false }
        navDestination = ""
        Task {
            await GoogleMapsNavigator.shared.startVoiceNavigation(destination: dest)
            messages.append(OpenClawChatMessage(role: "assistant", text: "✅ \(dest) 네비게이션을 시작합니다.", image: nil))
        }
    }

    private func sendText() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messages.append(OpenClawChatMessage(role: "user", text: text, image: nil))
        flushPendingResponse()
        inputText = ""
        openClawService.sendChatMessage(text)
    }

    // MARK: - Voice (ASR)

    private func toggleListening() {
        if isListening { stopListening() } else { startListening() }
    }

    private func startListening() {
        guard let apiKey = APIKeyManager.shared.getAPIKey(for: .openrouter), !apiKey.isEmpty else {
            let errorMsg = NSLocalizedString("livetranslate.error.noApiKey", comment: "")
            messages.append(OpenClawChatMessage(role: "assistant", text: errorMsg, image: nil))
            return
        }

        asrText = ""
        asrPartial = ""

        let service = OpenClawASRService(apiKey: apiKey)
        self.asrService = service

        service.onPartialResult = { (text: String) in
            DispatchQueue.main.async { self.asrPartial = text }
        }

        service.onFinalResult = { (text: String) in
            DispatchQueue.main.async {
                self.asrText += text
                self.asrPartial = ""
            }
        }

        service.onError = { (error: String) in
            DispatchQueue.main.async {
                self.isListening = false
                print("[ASR] Error: \(error)")
            }
        }

        service.start()
        isListening = true
    }

    private func stopListening() {
        asrService?.stop()
        asrService = nil
        isListening = false
        asrPartial = ""
    }

    private func sendASRText() {
        let text = asrText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messages.append(OpenClawChatMessage(role: "user", text: text, image: nil))
        flushPendingResponse()
        openClawService.sendChatMessage(text)
        asrText = ""
    }

    private func flushPendingResponse() {
        if !pendingResponse.isEmpty {
            messages.append(OpenClawChatMessage(role: "assistant", text: pendingResponse, image: nil))
            pendingResponse = ""
        }
    }
}

// MARK: - Chat Bubble

private struct ChatBubble: View {
    let message: OpenClawChatMessage

    var body: some View {
        HStack {
            if message.role == "user" { Spacer(minLength: 60) }

            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 6) {
                if let image = message.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 200, maxHeight: 150)
                        .cornerRadius(12)
                        .clipped()
                }

                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundColor(message.role == "user" ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.role == "user"
                            ? AnyShapeStyle(LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(Color(.systemGray5))
                    )
                    .cornerRadius(18)
            }

            if message.role == "assistant" { Spacer(minLength: 60) }
        }
    }
}
