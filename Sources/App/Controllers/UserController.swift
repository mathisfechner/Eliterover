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
        routes.get("edit", use: edit)
        routes.post("editUser", use: editUser)
        routes.post("changePassword", use: changePassword)
        routes.get("everybody", use: everybody)
        routes.get("deleteAllUsers", use: deleteAllUsers)
    }
    
    
    
    func getUser(req: Request) throws -> EventLoopFuture<View> {
        if req.auth.get(User.self) == nil {
            req.session.data["backToPath"] = "/"+req.parameters.get("username")!
            return try! UserController().getLogin(req: req)
        } else {
            return User.query(on: req.db)
                .filter(\.$username == (req.parameters.get("username") ?? "Not Found"))
                .first()
                .flatMap{
                    do {
                        if let user = $0 {
                            return req.view.render("SubViews/profile", [
                                "title":"Profile",
                                "description":"Profile",
                                "username":user.username
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
        return req.view.render(Elite.view.mainPath, mainViewData(title: "Eliterover", content: [
            .init(id: user.username, title: "Profile", text: ["You are logged in as: "+user.username, "Nice to see you again!"])
        ], for: req))
    }
    
    func getRegistrate(req: Request) throws -> EventLoopFuture<View> {
        let input = mainViewData(title: "Registration", content: [
            .init(id: "registration", title: "Registration", forms: [
                .init(send: "registrate", input: [
                    .init(description: "First name", identifier: "firstname", placeholder: "Max", type: "text"),
                    .init(description: "Last name", identifier: "lastname", placeholder: "Mustermann", type: "text"),
                    .init(description: "Username", identifier: "username", placeholder: "Enter Username", type: "text"),
                    .init(description: "Password", identifier: "password", placeholder: "Enter Password", type: "password"),
                    .init(description: "Retype password", identifier: "repassword", placeholder: "Retype Password", type: "password"),
                    .init(description: "eMail", identifier: "email", placeholder: "max.mustermann@elite.rover", type: "email"),
                    .init(description: "Date of birth", identifier: "birthday", placeholder: "DD.MM.JJJJ", type: "date", restrictions: "pattern=\"[0-3][0-9].[0-1][0-9].[0-9]{4}\"")
                ])
            ], links: [
                .init(href: "/login", description: "i have an account already", classID: "little")
            ])
        ], for: req)
        if req.session.data["registrationError"] != nil && Date().timeIntervalSince(Elite.date.dateFormatter.date(from: req.session.data["registrationError"]!)!) < TimeInterval(60) {
            input.content.insert(ErrorController.registrationError(req: req), at: 0)
        }
        return req.view.render(Elite.view.mainPath, input)
    }
    
    func registrate(req: Request) throws -> EventLoopFuture<Response> {
        let userform = try req.content.decode(User.DTO.self)
        let user = User(firstname: userform.firstname, lastname: userform.lastname, username: userform.username, passwordHash: (try req.password.hash(userform.password ?? "")), email: userform.email, birthday: Elite.date.inputFormatter.date(from: userform.birthday) ?? Date())
        return User.query(on: req.db).filter(\.$username == user.username)
            .first()
            .map{
                if $0 == nil && userform.password == userform.repassword {
                    _ = user.create(on: req.db)
                    req.session.data["id"] = user.id?.uuidString
                    let backToPath = req.session.data["backToPath"] ?? "/"
                    req.session.data["bakToPath"] = nil
                    req.session.data["registrationError"] = nil
                    return req.redirect(to: backToPath)
                } else {
                    req.session.data["registrationError"] = Elite.date.dateFormatter.string(from: Date())
                    return req.redirect(to: "registrate")
                }
        }
    }
    
    func getLogin(req: Request) throws -> EventLoopFuture<View> {
        let input = mainViewData(title: "Login", content: [
            .init(id: "Login", title: "Login", forms: [
                .init(
                    send: "login",
                    errorMessage: req.session.data["loginFail"] == nil ? nil : Date().timeIntervalSince(Elite.date.dateFormatter.date(from: req.session.data["loginFail"]!)!) < TimeInterval(60) ? "Invalid username or password, please try again" : nil,
                    input: [
                        .init(identifier: "username", placeholder: "Enter Username", type: "text", restrictions: "autofocus required"),
                        .init(identifier: "password", placeholder: "Enter Password", type: "password", restrictions: "required")
                ])
            ], links: [
                .init(href: "registrate", description: "Don't have an account", classID: "little")
            ])
        ], for: req)
        return req.view.render(Elite.view.mainPath, input)
    }
    
    func login(req: Request) throws -> Response {
        print(req)
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
    
    func edit(req: Request) throws -> EventLoopFuture<View> {
        if let user = req.auth.get(User.self) {
            let input = mainViewData(title: "Edit Userdata", content: [
                .init(id: "EditUser", title: "Edit Userdata", text: ["Just type in the data you wanna change, don't touch the other fields and click editUser."], forms: [
                    .init(send: "editUser", input: [
                        .init(description: "First Name", identifier: "firstname", placeholder: user.firstname, type: "text"),
                        .init(description: "Last Name", identifier: "lastname", placeholder: user.lastname, type: "text"),
                        .init(description: "Usernam", identifier: "username", placeholder: user.username, type: "text"),
                        .init(description: "eMail", identifier: "email", placeholder: user.email, type: "email"),
                        .init(description: "Date of birth", identifier: "birthday", placeholder: Elite.date.inputFormatter.string(from: user.birthday), type: "date", restrictions: "pattern=\"[0-3][0-9].[0-1][0-9].[0-9]{4}\"")
                    ])
                ]),
                .init(id: "changePassword", title: "Change Password", forms: [
                    .init(send: "changePassword", input: [
                        .init(description: "Old password", identifier: "oldPassword", placeholder: "Enter old password", type: "password"),
                        .init(description: "New password", identifier: "password", placeholder: "Enter new password", type: "password"),
                        .init(description: "Retype password", identifier: "repassword", placeholder: "Retype new password", type: "password")
                    ])
                ])
            ], for: req)
            return req.view.render(Elite.view.mainPath, input)
        } else {
            req.session.data["backToPath"] = "edit"
            return try getLogin(req: req)
        }
    }
    
    func editUser(req: Request) throws -> Response {
        if let user = req.auth.get(User.self) {
            let userform = try req.content.decode(User.DTO.self)
            user.firstname = userform.firstname == "" ? user.firstname : userform.firstname
            user.lastname = userform.lastname == "" ? user.lastname : userform.lastname
            if userform.username != "" {
                User.query(on: req.db).filter(\.$username == userform.username)
                    .first()
                    .map {
                        if $0 == nil {
                            user.username = userform.username
                            user.update(on: req.db)
                        }
                }
            }
            user.email = userform.email == "" ? user.email : userform.email
            user.birthday = userform.birthday == "" ? user.birthday : Elite.date.inputFormatter.date(from: userform.birthday) ?? Date()
            user.update(on: req.db)
            return req.redirect(to: "edit")
        } else {
            return req.redirect(to: "edit")
        }
    }
    
    func changePassword(req: Request) throws -> Response {
        req.redirect(to: "edit")
    }

    func everybody(req: Request) throws -> EventLoopFuture<[User]> {
        User.query(on: req.db).all()
    }
    
    func deleteAllUsers(req: Request) throws -> Response {
        User.query(on: req.db).delete()
        return req.redirect(to: "/")
    }
}
