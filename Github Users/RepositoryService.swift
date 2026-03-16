//
//  RepositoryService.swift
//  Github Users
//
//  Created by Apple on 16/03/26.
//

import Foundation


protocol RepositoryServiceProtocol {
    func fetchRepositories(username: String) async throws -> [Repository]
}


final class RepositoryService: RepositoryServiceProtocol {
    
    private let networkService: NetworkServiceProtocol
    private let cache: RepositoryCache
    
    init(
        networkService: NetworkServiceProtocol,
        cache: RepositoryCache
    ) {
        self.networkService = networkService
        self.cache = cache
    }
    
    func fetchRepositories(username: String) async throws -> [Repository] {
            
            if let cached = await cache.get(username: username) {
                return cached
            }
            
            let url = try APIEndpoint.repositories(username: username)
            
            let repos: [Repository] = try await retry(times: 3) {
                try await self.networkService.request(url)
            }
            
        await cache.save(username: username, repos: repos)
            
            return repos
        }
    
    func retry<T>(
        times: Int,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        
        var currentTry = 0
        
        while true {
            do {
                return try await operation()
            } catch {
                
                currentTry += 1
                
                if currentTry >= times {
                    throw error
                }
                
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
}
