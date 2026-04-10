//
//  UserListViewModel.swift
//  Github Users
//
//  Created by Apple on 10/04/26.
//

import Foundation
import Combine

// MARK: - VIEWMODEL (STATE MACHINE)
@MainActor
final class UserListViewModel: ObservableObject {
    
    enum State {
        case idle, loading, loaded, error
    }
    
    @Published var users: [GithubUser] = []
    @Published var state: State = .idle
    @Published var search = ""
    
    private var page = 0
    private let useCase: FetchUsersUseCase
    private var cancellables = Set<AnyCancellable>()
    
    init(useCase: FetchUsersUseCase) {
        self.useCase = useCase
        bindSearch()
    }
    
    func load() {
        guard state != .loading else { return }
        state = .loading
        
        Task {
            do {
                let result = try await useCase.execute(page: page)
                
                ImagePrefetcher.shared.prefetch(result.map { $0.avatarUrl })
                
                users = result
                page = result.last?.id ?? 0
                state = .loaded
            } catch {
                state = .error
            }
        }
    }
    
    private func bindSearch() {
        $search
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self else { return }
                if text.isEmpty { return }
                self.users = self.users.filter { $0.login.lowercased().contains(text.lowercased()) }
            }
            .store(in: &cancellables)
    }
}
