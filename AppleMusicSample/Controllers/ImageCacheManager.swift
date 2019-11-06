/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`ImageCacheManager` serves as a simple image cache for caching media artwork from a remote server.
*/

import UIKit

class ImageCacheManager {
    
    // MARK: Types
    
    static let imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        
        cache.name = "ImageCacheManager"
        
        // Max 20 images in memory.
        cache.countLimit = 20
        
        // Max 10MB used.
        cache.totalCostLimit = 10 * 1024 * 1024
        
        return cache
    }()
    
    // MARK: Image Caching Methods
    
    func cachedImage(url: URL) -> UIImage? {
        return ImageCacheManager.imageCache.object(forKey: url.absoluteString as NSString)
    }
    
    func fetchImage(url: URL, completion: @escaping ((UIImage?) -> Void)) {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard error == nil, let urlResponse = response as? HTTPURLResponse, urlResponse.statusCode == 200, let data = data else {
                    // Your application should handle these errors appropriately depending on the kind of error.
                    
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    
                    return
            }
            
            if let image = UIImage(data: data) {
                
                ImageCacheManager.imageCache.setObject(image, forKey: url.absoluteString as NSString)
                
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                DispatchQueue.main.async {
                    completion(UIImage())
                }
            }
        }
        
        task.resume()
    }
    
}
