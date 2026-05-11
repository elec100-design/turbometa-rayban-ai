import UIKit

extension UIImage {

    // MARK: - Base64 Decoding

    static func fromBase64(_ base64String: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64String) else {
            print("[UIImage+Ext] Base64 디코딩 실패")
            return nil
        }
        return UIImage(data: data)
    }

    // MARK: - Resizing (aspect-ratio preserved)

    func resized(maxDimension: CGFloat) -> UIImage {
        let currentMax = max(size.width, size.height)
        guard currentMax > maxDimension else { return self }

        let scale = maxDimension / currentMax
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
