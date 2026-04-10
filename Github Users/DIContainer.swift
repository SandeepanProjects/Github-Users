//
//  DIContainer.swift
//  Github Users
//
//  Created by Apple on 10/04/26.
//

import Foundation

// MARK: - DI CONTAINER
final class DIContainer {
    static let shared = DIContainer()

    private init() {}

    lazy var network: NetworkService = AdvancedNetworkService()
    lazy var local = LocalUserDataSource()
    lazy var repo: UserRepository = UserRepositoryImpl(network: network, local: local)
    lazy var useCase = FetchUsersUseCase(repo: repo)

    @MainActor func makeVM() -> UserListViewModel {
        UserListViewModel(useCase: useCase)
    }
}
