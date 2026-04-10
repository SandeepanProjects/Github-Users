//
//  AdvancedNetworkService.swift
//  Github Users
//
//  Created by Apple on 10/04/26.
//

import Foundation

// MARK: - NETWORK LAYER
protocol NetworkService {
    func request<T: Decodable>(_ req: URLRequest) async throws -> T
}

// Rate Limit + Retry + Dedup
actor RequestDeduplicator {
    private var tasks: [URL: Task<Data, Error>] = [:]
    
    func run(url: URL, task: @escaping () async throws -> Data) async throws -> Data {
        if let existing = tasks[url] { return try await existing.value }
        
        let newTask = Task { try await task() }
        tasks[url] = newTask
        defer { tasks[url] = nil }
        
        return try await newTask.value
    }
}

final class AdvancedNetworkService: NetworkService {
    private let deduplicator = RequestDeduplicator()
    
    func request<T>(_ req: URLRequest) async throws -> T where T : Decodable {
        guard let url = req.url else { throw URLError(.badURL) }
        
        let data = try await deduplicator.run(url: url) {
            let (data, response) = try await URLSession.shared.data(for: req)
            
            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            // Rate limit handling
            if http.statusCode == 403,
               let reset = http.value(forHTTPHeaderField: "X-RateLimit-Reset"),
               let time = Double(reset) {
                let wait = Date(timeIntervalSince1970: time).timeIntervalSinceNow
                if wait > 0 {
                    try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                }
            }
            guard 200..<300 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }
            
            return data
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}
