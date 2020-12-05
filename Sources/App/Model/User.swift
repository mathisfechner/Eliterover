//
//  File.swift
//  
//
//  Created by Mathis Fechner on 05.09.20.
//

import Vapor
import Fluent
import FluentPostgresDriver


class User: Model, Authenticatable {
    static let schema = "user"
        
    @ID(key: .id) var id: UUID?
    @Field(key: .firstname) var firstname: String
    @Field(key: .lastname) var lastname: String
    @Field(key: .sex) var sex: Float
    @Field(key: .username) var username: String
    @Field(key: .passwordHash) var passwordHash: String
    @Field(key: .email) var email: String
    @Field(key: .birthday) var birthday: Date
    
    @Children(for: \.$user) var userInformation: [UserInformation]
    
    required init() { }
    
    init(id: UUID? = nil, firstname: String, lastname: String, sex: Float, username: String, passwordHash: String, email: String, birthday: Date) {
        self.id = id
        self.firstname = firstname
        self.lastname = lastname
        self.sex = sex
        self.username = username
        self.passwordHash = passwordHash
        self.email = email
        self.birthday = birthday
    }
}


//MARK: DTOs

extension User {
    struct DTO: Content {
        var firstname: String
        var lastname: String
        var sex: String
        var username: String
        var password: String?
        var repassword: String?
        var email: String
        var birthday: String
    }
    
    struct passwordDTO: Content {
        var oldPassword: String
        var password: String
        var repassword: String
    }
}


//MARK: Migrations

extension User {
    static let migrations = [migration_v1_0_0()]
    
    struct migration_v1_0_0: Migration {
        // Prepares the database for storing User models.
         func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(User.schema)
                .id()
                .field(.firstname, .string, .required)
                .field(.lastname, .string, .required)
                .field(.sex, .float, .required)
                .field(.username, .string, .required)
                .field(.passwordHash, .string, .required)
                .field(.email, .string, .required)
                .field(.birthday, .date, .required)
                .unique(on: .username)
                .unique(on: .email)
                .create()
         }

        func revert(on database: Database) -> EventLoopFuture<Void> {
             database.schema(User.schema).delete()
         }
    }
}


//MARK: FieldKeyExtension

extension FieldKey {
    static var firstname: Self {"firstname"}
    static var lastname: Self {"lastname"}
    static var sex: Self {"sex"}
    static var username: Self {"username"}
    static var passwordHash: Self {"passwordHash"}
    static var email: Self {"email"}
    static var birthday: Self {"birthday"}
}
