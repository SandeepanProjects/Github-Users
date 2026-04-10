//
//  Github_UsersApp.swift
//  Github Users
//
//  Created by Apple on 16/03/26.
//

import SwiftUI

@main
struct Github_UsersApp: App {
    // MARK: - Dependency Injection Container
    private let container = DIContainer.shared
    
    var body: some Scene {
        WindowGroup {
            UserListView(vm: container.makeVM())
        }
    }
}
