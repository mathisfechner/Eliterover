//
//  File.swift
//  
//
//  Created by Mathis Fechner on 05.09.20.
//

import Vapor
import Fluent
import FluentPostgresDriver


final class User: Model, Authenticatable {
    
    static let schema = "user"
    
    //Custom Identifier
    
    @ID(key: .id) var id: UUID?
    @Field(key: "name") var name: String
    @Field(key: "passwordHash") var passwordHash: String
    
    init() { }
    
    init(id: UUID? = nil, username: String, passwordHash: String) {
        self.id = id
        self.name = username
        self.passwordHash = passwordHash
    }
}

extension User {
    struct DTO: Content {
        var username: String
        var password: String
    }
}

struct UserDTO: Content {
    var username: String
    var password: String
}
