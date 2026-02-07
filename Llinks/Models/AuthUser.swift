//
//  AuthUser.swift
//  Llinks
//

import Foundation

struct AuthUser: Identifiable, Codable {
    let id: String // uid из Firebase
    var displayName: String?
    var email: String?
    var photoURL: String?

    init(id: String, displayName: String? = nil, email: String? = nil, photoURL: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
    }
}
