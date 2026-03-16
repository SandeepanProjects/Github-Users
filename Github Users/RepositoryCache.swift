//
//  RepositoryCache.swift
//  Github Users
//
//  Created by Apple on 16/03/26.
//

import Foundation

actor RepositoryCache {
    
    private var storage: [String: [Repository]] = [:]
    
    func get(username: String) -> [Repository]? {
        storage[username]
    }
    
    func save(username: String, repos: [Repository]) {
        storage[username] = repos
    }
}
