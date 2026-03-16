//
//  RepositoryRowView.swift
//  Github Users
//
//  Created by Apple on 16/03/26.
//

import SwiftUI

struct RepositoryRowView: View {
    
    let repo: Repository
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 6) {
            
            Text(repo.name)
                .font(.headline)
            
            if let description = repo.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Image(systemName: "star")
                Text("\(repo.stargazersCount)")
            }
            .font(.caption)
        }
        .padding(.vertical, 6)
    }
}
