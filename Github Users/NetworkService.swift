//
//  NetworkService.swift
//  Github Users
//
//  Created by Apple on 16/03/26.
//

import Foundation

protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ url: URL) async throws -> T
}

final class NetworkService: NetworkServiceProtocol {
    
    func request<T: Decodable>(_ url: URL) async throws -> T {
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(http.statusCode) else {
            throw NetworkError.httpError(http.statusCode)
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
}
