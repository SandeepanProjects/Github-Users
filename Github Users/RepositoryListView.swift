//
//  RepositoryListView.swift
//  Github Users
//
//  Created by Apple on 16/03/26.
//

import SwiftUI

struct RepositoryListView: View {
    
    @StateObject private var viewModel: RepositoryViewModel
    @State private var username = ""
    
    // MARK: - Init
    init(viewModel: RepositoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // Convenience initializer for default service
    init() {
        let service = RepositoryService(
            networkService: NetworkService(),
            cache: RepositoryCache()
        )
        _viewModel = StateObject(wrappedValue: RepositoryViewModel(service: service))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Enter GitHub username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: username) {
                        viewModel.searchDebounced(username: $0)
                    }
                
                content
            }
            .padding()
            .navigationTitle("GitHub Search")
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
        } else if let error = viewModel.errorMessage {
            Text(error).foregroundColor(.red)
        } else if viewModel.repositories.isEmpty {
            Text("No repositories found").foregroundColor(.secondary)
        } else {
            List(viewModel.repositories) { repo in
                RepositoryRow(repository: repo)
            }
            .listStyle(.plain)
        }
    }
}

private struct RepositoryRow: View {
    let repository: Repository
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(repository.name).font(.headline)
            if let desc = repository.description {
                Text(desc).font(.subheadline).foregroundColor(.secondary)
            }
            Text("⭐️ \(repository.stargazersCount)").font(.caption).foregroundColor(.orange)
        }
        .padding(.vertical, 4)
    }
}
