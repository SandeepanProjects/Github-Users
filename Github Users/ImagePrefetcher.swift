//
//  ImagePrefetcher.swift
//  Github Users
//
//  Created by Apple on 10/04/26.
//

import Foundation
import UIKit

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    func get(_ key: String) -> UIImage? { cache.object(forKey: key as NSString) }
    func set(_ img: UIImage, key: String) { cache.setObject(img, forKey: key as NSString) }
}

final class ImagePrefetcher {
    static let shared = ImagePrefetcher()

    func prefetch(_ urls: [String]) {
        for u in urls {
            guard ImageCache.shared.get(u) == nil,
                  let url = URL(string: u) else { continue }

            Task.detached(priority: .background) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)

                    guard let img = UIImage(data: data) else { return }

                    ImageCache.shared.set(img, key: u)

                } catch {
                    // Optional: log error for debugging / observability
                    // print("Prefetch failed for \(u): \(error)")
                }
            }
        }
    }
}
