//
//  User.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/4/26.
//

struct UserDTO: Codable {
    let primaryKey: String
    let uid: String
    let displayname: String
    let type: Int
}
