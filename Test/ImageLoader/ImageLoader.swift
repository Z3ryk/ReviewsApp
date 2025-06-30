import UIKit

final class ImageLoader {

    private let memoryCache = NSCache<NSURL, UIImage>()

    static let shared = ImageLoader()

    private init() {
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // ~50 MB
    }

    func image(for url: URL) async -> UIImage? {
        if let cachedImage = memoryCache.object(forKey: url as NSURL) {
            return cachedImage
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            if let image = UIImage(data: data) {
                memoryCache.setObject(
                    image,
                    forKey: url as NSURL,
                    cost: imageCost(image: image)
                )

                return image
            }
        } catch {
            print("При загрузке изображения произошла ошибка: \(error)")
        }

        return nil
    }

    private func imageCost(image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 1 }

        return cgImage.bytesPerRow * cgImage.height
    }

}
