//
//  UserListView.swift
//  Github Users
//
//  Created by Apple on 10/04/26.
//

import SwiftUI

// MARK: - UI
struct UserListView: View {
    @StateObject var vm: UserListViewModel
    
    init(vm: UserListViewModel) {
        _vm = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        List(vm.users) { user in
            UserRow(user: user)
                .onAppear {
                    if user.id == vm.users.last?.id {
                        vm.load()
                    }
                }
        }
        .searchable(text: $vm.search)
        .onAppear { vm.load() }
    }
}

struct UserRow: View {
    let user: GithubUser
    @State private var image: UIImage?
    
    var body: some View {
        HStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                ProgressView()
            }
            Text(user.login)
        }
        .task {
            if let cached = ImageCache.shared.get(user.avatarUrl) {
                image = cached
                return
            }
            
            guard let url = URL(string: user.avatarUrl) else { return }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                guard let img = UIImage(data: data) else { return }
                
                ImageCache.shared.set(img, key: user.avatarUrl)
                image = img
                
            } catch {
                // Optional: logging / analytics
                // print("Image load failed:", error)
            }
        }
    }
}
