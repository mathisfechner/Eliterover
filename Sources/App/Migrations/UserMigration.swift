//
//  File.swift
//  
//
//  Created by Mathis Fechner on 16.09.20.
//

import Vapor
import Fluent

struct CreateUser: Migration {
    // Prepares the database for storing User models.
     func prepare(on database: Database) -> EventLoopFuture<Void> {
         database.schema("user")
            .id()
            .field("firstname", .string)
            .field("lastname", .string)
            .field("username", .string)
            .field("passwordHash", .string)
            .field("email", .string)
            .field("birthday", .date)
            .create()
     }

     // Optionally reverts the changes made in the prepare method.
     func revert(on database: Database) -> EventLoopFuture<Void> {
         database.schema("user").delete()
     }
}
