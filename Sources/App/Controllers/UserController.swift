//
//  File.swift
//
//
//  Created by Mathis Fechner on 17.09.20.
//

import Vapor
import Leaf
import Fluent

final class UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(":username", use: getUser)
        routes.get("profile", use: profile)
        routes.get("registrate", use: getRegistrate)
        routes.post("registrate", use: registrate)
        routes.get("login", use: getLogin)
        routes.post("login", use: login)
        routes.get("logout", use: logout)
        routes.post("edituser", use: changeUserData)
        routes.get("everybody", use: everybody)
    }
    
    
    
    func getUser(req: Request) throws -> EventLoopFuture<View> {
        if req.auth.get(User.self) == nil {
            req.session.data["backToPath"] = "/"+req.parameters.get("username")!
            return try! UserController().getLogin(req: req)
        } else {
            return User.query(on: req.db)
                .filter(\.$name == (req.parameters.get("username") ?? "Not Found"))
                .first()
                .flatMap{
                    do {
                        if let user = $0 {
                            return req.view.render("SubViews/profile", [
                                "title":"Profile",
                                "description":"Profile",
                                "username":user.name
                            ])
                        } else {
                            throw Abort(.notFound)
                        }
                    } catch {
                        return ErrorController().notFound(req: req)
                    }
            }
        }
    }
    
    func profile(req: Request) throws -> EventLoopFuture<View> {
        let user = try req.auth.require(User.self)
        return req.view.render("Main", MainContent(title: "Eliterover", description: "Profile", Content: [
            .init(simple: .init(title: "Profile", text: ["You are logged in as: "+user.name, "Nice to see you again!"]))
        ], for: req))
    }
    
    func getRegistrate(req: Request) throws -> EventLoopFuture<View> {
        let input = MainContent(title: "Registration", description: "...", Content: [
            .init(form: formView(title: "Registration", action: "registrate", input: [
                .init(description: "Username", identifier: "username", placeholder: "Enter Username", type: "text"),
                .init(description: "Password", identifier: "password", placeholder: "Enter Password", type: "password")
                ], links: [
                .init(href: "/login", description: "I have an account already")
            ]))
        ], for: req)
        return req.view.render("Main",input)
    }
    
    func registrate(req: Request) throws -> EventLoopFuture<String> {
        let userform = try req.content.decode(UserDTO.self)
        let user = User(username: userform.username, passwordHash: (try? req.password.hash(userform.password)) ?? "")
        return user.create(on: req.db).map{user.name}
    }
    
    func getLogin(req: Request) throws -> EventLoopFuture<View> {
        let newInput = mainViewData(title: "Login", content: [
            .init(id: "login", title: "Login", forms: [
                .init(
                    send: "login",
                    errorMessage: req.session.data["loginFail"] == nil ? nil : Date().timeIntervalSince(Elite.date.dateFormatter.date(from: req.session.data["loginFail"]!)!) < TimeInterval(60) ? "Invalid username or password, please try again" : nil,
                    input: [
                        .init(identifier: "username", placeholder: "Enter Username", type: "text"),
                        .init(identifier: "password", placeholder: "Enter Password", type: "password")
                ])
            ], links: [
                .init(href: "registrate", description: "Don't have an account", classID: "little")
            ])
        ], for: req)
        
        return req.view.render("NewMain", newInput)
    }
    
    func login(req: Request) throws -> Response {
        let user = (try? req.auth.require(User.self))
        if user == nil {
            req.session.data["loginFail"] = Elite.date.dateFormatter.string(from: Date())
            return req.redirect(to: "/login")
        }
        let backToPath = req.session.data["backToPath"] ?? "/"
        req.session.data["backToPath"] = nil
        req.session.data["loginFail"] = nil
        return req.redirect(to: backToPath)
    }
    
    func logout(req: Request) throws -> Response {
        req.session.destroy()
        return req.redirect(to: "/")
    }
    
    func changeUserData(req: Request) throws -> String {
        return ""
    }
    
    func everybody(req: Request) throws -> EventLoopFuture<[User]> {
        User.query(on: req.db).all()
    }
}
