//
//  NetworkError.swift
//  Github Users
//
//  Created by Apple on 16/03/26.
//

import Foundation

enum NetworkError: Error, LocalizedError {
    
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let code):
            return "HTTP Error \(code)"
        case .decodingError:
            return "Decoding failed"
        case .unknown:
            return "Unknown error"
        }
    }
}

struct APIEndpoint {
    
    static func repositories(username: String) throws -> URL {
        
        guard let url = URL(
            string: "https://api.github.com/users/\(username)/repos"
        ) else {
            throw NetworkError.invalidURL
        }
        
        return url
    }
}
