//
//  Repository.swift
//  Github Users
//
//  Created by Apple on 16/03/26.
//

import Foundation

struct Repository: Identifiable, Decodable {
    
    let id: Int
    let name: String
    let description: String?
    let stargazersCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case stargazersCount = "stargazers_count"
    }
}
