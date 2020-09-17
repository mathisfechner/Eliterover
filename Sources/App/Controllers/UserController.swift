//
//  File.swift
//  
//
//  Created by Mathis Fechner on 17.09.20.
//

import Vapor

final class UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(":username", use: getUser)
        routes.get("me", use: profile)
        routes.post("registrate", use: registrate)
        routes.post("login", use: login)
        routes.get("logout", use: logout)
        routes.post("edituser", use: changeUserData)
    }
    
    func getUser(req: Request) throws -> String {
        return ""
    }
    func profile(req: Request) throws -> String {
        let user = try req.auth.require(User.self)
        return user.name + "\n"
    }
    func registrate(req: Request) throws -> EventLoopFuture<String> {
        let userform = try req.content.decode(UserDTO.self)
        let user = User(username: userform.username, passwordHash: (try? req.password.hash(userform.password)) ?? "")
        return user.create(on: req.db).map{user.name}
    }
    func login(req: Request) throws -> String {
        let user = try req.auth.require(User.self)
        return user.name+"\n"
    }
    func logout(req: Request) throws -> String {
        req.session.destroy()
        return "your session is destroyed"
    }
    func changeUserData(req: Request) throws -> String {
        return ""
    }
}
