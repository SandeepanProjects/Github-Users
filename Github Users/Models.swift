//
//  Models.swift
//  Github Users
//
//  Created by Apple on 10/04/26.
//

import Foundation
import SwiftUI
import Combine
import CoreData

// MARK: - CONFIG (Plist)
final class AppConfig {
    static let shared = AppConfig()
    let baseURL: String
    
    private init() {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let url = dict["BASE_URL"] as? String else {
            fatalError("Missing Config.plist")
        }
        self.baseURL = url
    }
}

// MARK: - DOMAIN
struct GithubUser: Identifiable, Codable, Equatable {
    let id: Int
    let login: String
    let avatarUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id, login
        case avatarUrl = "avatar_url"
    }
}

// MARK: - CORE DATA STACK
final class CoreDataStack {
    static let shared = CoreDataStack()
    
    let container: NSPersistentContainer
    
    private init() {
        container = NSPersistentContainer(name: "GithubUsers")
        container.loadPersistentStores { _, error in
            if let error = error { fatalError("CoreData: \(error)") }
        }
    }
    
    var context: NSManagedObjectContext { container.viewContext }
}

// MARK: - ENTITY
@objc(UserEntity)
final class UserEntity: NSManagedObject {
    @NSManaged var id: Int64
    @NSManaged var login: String
    @NSManaged var avatarUrl: String
}

// MARK: - MAPPER
extension UserEntity {
    func toDomain() -> GithubUser {
        GithubUser(id: Int(id), login: login, avatarUrl: avatarUrl)
    }
}

// MARK: - LOCAL DATA SOURCE (UPSERT + TTL)
final class LocalUserDataSource {
    private let context = CoreDataStack.shared.context
    
    func fetchUsers() -> [GithubUser] {
        let req = NSFetchRequest<UserEntity>(entityName: "UserEntity")
        let result = (try? context.fetch(req)) ?? []
        return result.map { $0.toDomain() }
    }
    
    func upsert(users: [GithubUser]) {
        let req = NSFetchRequest<UserEntity>(entityName: "UserEntity")
        let existing = (try? context.fetch(req)) ?? []
        let map = Dictionary(uniqueKeysWithValues: existing.map { (Int($0.id), $0) })
        
        for user in users {
            if let entity = map[user.id] {
                entity.login = user.login
                entity.avatarUrl = user.avatarUrl
            } else {
                let entity = UserEntity(context: context)
                entity.id = Int64(user.id)
                entity.login = user.login
                entity.avatarUrl = user.avatarUrl
            }
        }
        
        try? context.save()
    }
}
