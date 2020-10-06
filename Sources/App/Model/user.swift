//
//  File.swift
//  
//
//  Created by Mathis Fechner on 05.09.20.
//

import Vapor
import Fluent
import FluentPostgresDriver


final class User: Model, Authenticatable, Content {
    
    static let schema = "user"
    
    //Custom Identifier
    
    @ID(key: .id) var id: UUID?
    @Field(key: "firstname") var firstname: String
    @Field(key: "lastname") var lastname: String
    @Field(key: "username") var username: String
    @Field(key: "passwordHash") var passwordHash: String
    @Field(key: "email") var email: String
    @Field(key: "birthday") var birthday: Date
    
    init() { }
    
    init(id: UUID? = nil, firstname: String, lastname: String, username: String, passwordHash: String, email: String, birthday: Date) {
        self.id = id
        self.firstname = firstname
        self.lastname = lastname
        self.username = username
        self.passwordHash = passwordHash
        self.email = email
        self.birthday = birthday
    }
}

extension User {
    struct DTO: Content {
        var firstname: String
        var lastname: String
        var username: String
        var password: String?
        var repassword: String?
        var email: String
        var birthday: String
    }
}
