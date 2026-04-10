//
//  UserRepositoryImpl.swift
//  Github Users
//
//  Created by Apple on 10/04/26.
//

import Foundation

// MARK: - REPOSITORY (Single Source of Truth)
protocol UserRepository {
    func users(page: Int) async throws -> [GithubUser]
}

final class UserRepositoryImpl: UserRepository {
    private let network: NetworkService
    private let local: LocalUserDataSource
    
    init(network: NetworkService, local: LocalUserDataSource) {
        self.network = network
        self.local = local
    }
    
    func users(page: Int) async throws -> [GithubUser] {
        // 1. return cache immediately
        let cached = local.fetchUsers()
        
        Task.detached { [weak self] in
            guard let self else { return }
            let base = AppConfig.shared.baseURL
            let url = URL(string: "\(base)/users?since=\(page)")!
            let req = URLRequest(url: url)
            
            if let fresh: [GithubUser] = try? await self.network.request(req) {
                self.local.upsert(users: fresh)
            }
        }
        
        return cached
    }
}

// MARK: - USE CASE
final class FetchUsersUseCase {
    private let repo: UserRepository

    init(repo: UserRepository) { self.repo = repo }

    func execute(page: Int) async throws -> [GithubUser] {
        try await repo.users(page: page)
    }
}
