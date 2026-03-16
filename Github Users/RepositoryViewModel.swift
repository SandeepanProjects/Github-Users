//
//  RepositoryViewModel.swift
//  Github Users
//
//  Created by Apple on 16/03/26.
//

import Foundation

@MainActor
final class RepositoryViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published private(set) var repositories: [Repository] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let service: RepositoryServiceProtocol
    
    // MARK: - Debounce
    private var searchTask: Task<Void, Never>?
    
    // MARK: - Init (Dependency Injected)
    init(service: RepositoryServiceProtocol) {
        self.service = service
    }
    
    // MARK: - Public API
    
    /// Normal search (immediate)
    func search(username: String) async {
        guard isValid(username) else {
            repositories = []
            return
        }
        
        await fetchRepositories(for: username)
    }
    
    /// Debounced search (waits 400ms before calling API)
    func searchDebounced(username: String) {
        // Cancel previous in-flight search
        searchTask?.cancel()
        
        searchTask = Task {
            do {
                // Wait 400ms before executing
                try await Task.sleep(nanoseconds: 400_000_000)
                
                // Check cancellation
                guard !Task.isCancelled else { return }
                
                await fetchRepositories(for: username)
            } catch {
                // Ignore task cancellation errors
            }
        }
    }
}

// MARK: - Private Helpers
private extension RepositoryViewModel {
    
    func fetchRepositories(for username: String) async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            repositories = try await service.fetchRepositories(username: username)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func isValid(_ username: String) -> Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
