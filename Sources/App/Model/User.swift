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
    @Timestamp(key: .dateOfJoin, on: .create) var dateOfJoin: Date?
    @OptionalField(key: .characteristics) var characteristics: Characteristics?
    
    @Children(for: \.$user) var profilePic: [ProfilePic]
    @Children(for: \.$user) var chats: [Chat]

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
    
    static func getUser(username: String, req: Request) -> EventLoopFuture<User> {
        return User.query(on: req.db)
            .filter(\.$username == username)
            .first()
            .flatMapThrowing {
                if let user = $0 {
                    return user
                } else {
                    throw Abort(.notFound)
                }
            }
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
    static let migrations: [Migration] = [migration_v1_0_0(), migration_v1_0_1()]
    
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
    
    struct migration_v1_0_1: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(User.schema)
                .field(.dateOfJoin, .date)
                .field(.characteristics, .dictionary)
                .update()
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
    static var dateOfJoin: Self {"dateOfJoin"}
    static var characteristics: Self {"characteristics"}
    static var kindOfInto: Self {"kindOfInto"}
}
