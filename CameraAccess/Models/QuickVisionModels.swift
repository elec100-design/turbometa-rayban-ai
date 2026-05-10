/*
 * Quick Vision Models
 * 快速识图数据模型 - 识图模式和历史记录
 */

import Foundation
import UIKit

// MARK: - Quick Vision Mode

enum QuickVisionMode: String, CaseIterable, Codable, Identifiable {
    case standard = "standard"      // 默认模式
    case health = "health"          // 健康识图
    case blind = "blind"            // 盲人模式
    case reading = "reading"        // 阅读模式
    case translate = "translate"    // 翻译模式
    case encyclopedia = "encyclopedia" // 百科（博物馆）模式
    case custom = "custom"          // 自定义提示词
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .standard:
            return "quickvision.mode.standard".localized
        case .health:
            return "quickvision.mode.health".localized
        case .blind:
            return "quickvision.mode.blind".localized
        case .reading:
            return "quickvision.mode.reading".localized
        case .translate:
            return "quickvision.mode.translate".localized
        case .encyclopedia:
            return "quickvision.mode.encyclopedia".localized
        case .custom:
            return "quickvision.mode.custom".localized
        }
    }
    
    var icon: String {
        switch self {
        case .standard:
            return "eye.circle"
        case .health:
            return "heart.circle"
        case .blind:
            return "figure.walk.circle"
        case .reading:
            return "text.viewfinder"
        case .translate:
            return "character.bubble"
        case .encyclopedia:
            return "books.vertical.circle"
        case .custom:
            return "pencil.circle"
        }
    }
    
    var description: String {
        switch self {
        case .standard:
            return "quickvision.mode.standard.desc".localized
        case .health:
            return "quickvision.mode.health.desc".localized
        case .blind:
            return "quickvision.mode.blind.desc".localized
        case .reading:
            return "quickvision.mode.reading.desc".localized
        case .translate:
            return "quickvision.mode.translate.desc".localized
        case .encyclopedia:
            return "quickvision.mode.encyclopedia.desc".localized
        case .custom:
            return "quickvision.mode.custom.desc".localized
        }
    }
    
    /// 获取模式对应的提示词
    var prompt: String {
        switch self {
        case .standard:
            return "이 사진을 자세히 설명해줘. 반드시 한국어로 답변해줘."
        case .health:
            return "이 사진 속 음식이나 물건의 건강 및 영양 정보를 한국어로 자세히 알려줘."
        case .blind:
            return "시각 장애인을 위해 내 눈앞의 상황을 아주 상세하게 한국어로 묘사해줘."
        case .reading:
            return "사진 속에 보이는 글자들을 모두 읽고, 그 내용을 한국어로 요약해서 설명해줘."
        case .translate:
            return "사진 속에 보이는 외국어를 모두 한국어로 번역해서 알려줘."
        case .encyclopedia:
            return "사진 속의 사물, 예술품, 혹은 장소에 대해 백과사전처럼 자세한 정보를 한국어로 설명해줘."
        case .custom:
            return "" // 사용자 정의 모드는 그대로 둡니다.
        }
    }
}

// MARK: - Quick Vision Record

struct QuickVisionRecord: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let mode: QuickVisionMode
    let prompt: String
    let result: String
    let thumbnailData: Data?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        mode: QuickVisionMode,
        prompt: String,
        result: String,
        thumbnail: UIImage? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.mode = mode
        self.prompt = prompt
        self.result = result
        // 压缩缩略图到 100x100，质量 0.5
        if let image = thumbnail {
            let size = CGSize(width: 100, height: 100)
            let renderer = UIGraphicsImageRenderer(size: size)
            let resized = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
            self.thumbnailData = resized.jpegData(compressionQuality: 0.5)
        } else {
            self.thumbnailData = nil
        }
    }

    // Computed properties
    var thumbnail: UIImage? {
        guard let data = thumbnailData else { return nil }
        return UIImage(data: data)
    }

    var title: String {
        let content = result
        return content.count > 30 ? String(content.prefix(30)) + "..." : content
    }

    var summary: String {
        let content = result
        return content.count > 80 ? String(content.prefix(80)) + "..." : content
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(timestamp) {
            formatter.dateFormat = "HH:mm"
            return "quickvision.today".localized + " " + formatter.string(from: timestamp)
        } else if calendar.isDateInYesterday(timestamp) {
            formatter.dateFormat = "HH:mm"
            return "quickvision.yesterday".localized + " " + formatter.string(from: timestamp)
        } else if calendar.isDate(timestamp, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE HH:mm"
            return formatter.string(from: timestamp)
        } else {
            formatter.dateFormat = "MM-dd HH:mm"
            return formatter.string(from: timestamp)
        }
    }
}
