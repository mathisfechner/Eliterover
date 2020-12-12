//
//  File.swift
//
//
//  Created by Mathis Fechner on 17.09.20.
//

import Vapor
import Leaf
import Fluent
import VaporCSRF

final class UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let csrfTokenProtectedRoutes = routes.grouped(CSRFMiddleware())
        routes.get(":username", use: getUser)
        routes.get("profile", use: profile)
        routes.get("registrate", use: getRegistrate)
        routes.post("registrate", use: postRegistrate)
        routes.get("login", use: getLogin)
        routes.get("logout", use: logout)
        routes.on(.POST, "adduserinformation", body: .collect(maxSize: 5000000), use: addUserInformation)
        routes.get("edit", use: getEdit)
        routes.post("editUser", use: postEditUser)
        routes.post("changePassword", use: postChangePassword)
        routes.get("everybody", use: everybody)
        routes.get("deleteAllUsers", use: deleteAllUsers)

        routes.post("login", use: postLogin)
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
                            return req.view.render(Elite.view.mainPath, mainViewData(title: user.username, content: [.init(id: user.id!.uuidString, title: user.username, text: [user.firstname+" "+user.lastname, Elite.date.inputFormatter.string(from: user.birthday), user.email,"Auf der Weiblichkeitsskala von 0 bis 1 eine \(user.sex)"])], for: req))
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
            .init(id: user.username, title: "Profile", text: ["You are logged in as: "+user.username, "Nice to see you again!"], links: [.init(href: "/edit", description: "Edit Userdata", classID: "normal")]),
        ], for: req))
    }
    
    
    
    func getRegistrate(req: Request) throws -> EventLoopFuture<View> {
        let input = mainViewData( title: "Registration", content: [
            .init(id: "registration", title: "Registration", forms: [
                .init(send: "registrate",
                      errorMessage: Elite.date.stillActiveError(req.session.data["registrationError"]) ? "Try again, username or eMail may already be taken." : nil,
                      input: [
                    .init(description: "First name", identifier: "firstname", placeholder: "Max", type: "text"),
                    .init(description: "Last name", identifier: "lastname", placeholder: "Mustermann", type: "text"),
                    .init(description: "Sex | M - W", identifier: "sex", placeholder: "", type: "range", restrictions: "min=\"0\" max=\"1\" step=\"0.01\""),
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
        return req.view.render(Elite.view.mainPath, input)
    }
    
    
    
    func postRegistrate(req: Request) throws -> EventLoopFuture<Response> {
        let userform = try req.content.decode(User.DTO.self)
        let user = User(firstname: userform.firstname.validate(),
                        lastname: userform.lastname.validate(),
                        sex: (userform.sex as NSString).floatValue,
                        username: userform.username.validate(),
                        passwordHash: (try Bcrypt.hash(userform.password ?? "")),
                        email: userform.email.uppercased().validate(),
                        birthday: Elite.date.inputFormatter.date(from: userform.birthday) ?? Date())
        return User.query(on: req.db).group(.or) { group in
            group.filter(\.$username == userform.username)
                .filter(\.$email == userform.email)
        }.first().map{ result -> Response in
                    if result == nil && userform.password == userform.repassword {
                        _ = user.create(on: req.db)
                        
                        MailController.sendVerificationLink(req: req, user: user)
                        
                        req.session.data["id"] = user.id?.uuidString
                        let backToPath = req.session.data["backToPath"] ?? "/"
                        req.session.data["bakToPath"] = nil
                        req.session.data["registrationError"] = nil
                        
                        return req.redirect(to: backToPath)
                    } else {
                        req.session.data["registrationError"] = Elite.date.setErrorDate()
                        return req.redirect(to: "registrate")
                    }
            }
    }
    
    
    
    func getLogin(req: Request) throws -> EventLoopFuture<View> {
        let input = mainViewData(title: "Login", content: [
            .init(id: "Login", title: "Login", forms: [
                .init(
                    send: "login",
                 errorMessage: Elite.date.stillActiveError(req.session.data["loginFail"]) ? "Invalid username or password, please try again" : nil,
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
    
    
    
    func postLogin(req: Request) throws -> Response {
        print(try? req.content.get(String.self, at: req.application.csrf.tokenContentKey))
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
    
    
    
    static func addUserInformationForm(req: Request) -> contentViewData {
        contentViewData.init(id: "image", title: "Upload Image", forms: [
            .init(send: "adduserinformation", input: [
                .init(identifier: "imageData", placeholder: "imageData", type: "file")
            ])
        ])
    }

    
    func addUserInformation(req: Request) throws -> EventLoopFuture<Response> {
        let image = try req.content.decode(ImageDTO.self)
        let user = req.auth.get(User.self)
        if(user == nil){
            return req.eventLoop.makeSucceededFuture(req.redirect(to: "/"))
        }
        if let filetype = image.imageData.contentType?.subType {
            return req.fileio.writeFile(image.imageData.data, at: "profilepicture/\(user!.id!.uuidString).\(filetype)").map() {
                req.fileio.streamFile(at: "profilepicture/\(user!.id!.uuidString).\(filetype)")
            }
        }
        return req.eventLoop.makeSucceededFuture(req.redirect(to: "/"))

        struct ImageDTO: Content {
            var imageData: File
        }
    }
    
/*
    func streamPng(req: Request) throws -> Response {
        var count = 0
        var count2 = 0
        var stream = OutputStream(toFileAtPath: "id" + count2.description + ".png", append: false)
        stream?.open()
        req.body.drain() {
            switch $0 {
            case .buffer(let buffer):
                count += 1
                var data = Data(buffer.readableBytesView).first
                if data != nil {
                    if stream!.hasSpaceAvailable {
                        stream?.write(&data!, maxLength: buffer.readableBytesView.count)
                    } else {
                        stream?.close()
                        try? FileManager().copyItem(at: URL(fileURLWithPath: "id" + count2.description + ".png"), to: URL(fileURLWithPath: "id" + (count2 + 1).description + ".png"))
                        count2 += 1
                        stream = OutputStream(toFileAtPath: "id" + count2.description + ".png", append: true)
                        stream?.open()
                        stream?.write(&data!, maxLength: buffer.readableBytesView.count)
                    }
                }
//                var header = HTTPHeaders()
//                header.add(name: "Image", value: "image/png")
//                return Response(status: .ok, version: .init(major: .max, minor: .min), headers: header, body: .init(buffer: buffer))
                return req.eventLoop.makeSucceededFuture(())
            case .error(let error):
                print(error.localizedDescription)
                return req.eventLoop.makeSucceededFuture(())
            case .end:
                print("last")
                stream?.close()
                return req.eventLoop.makeSucceededFuture(())
            }
        }
        return Response()
    }
*/
    
    func getEdit(req: Request) throws -> EventLoopFuture<View> {
        if let user = req.auth.get(User.self) {
            let input = mainViewData(title: "Edit Userdata", content: [
                .init(id: "EditUser", title: "Edit Userdata", text: ["Just type in the data you wanna change, don't touch the other fields and click editUser."], forms: [
                    .init(send: "editUser",input: [
                        .init(description: "First Name", identifier: "firstname", placeholder: user.firstname, type: "text"),
                        .init(description: "Last Name", identifier: "lastname", placeholder: user.lastname, type: "text"),
                        .init(description: "Sex | M - W", identifier: "sex", placeholder: "", type: "range", restrictions: "min=\"0\" max=\"1\" step=\"0.01\" value=\"\(user.sex)\""),
                        .init(description: "Username", identifier: "username", placeholder: user.username, type: "text"),
                        .init(description: "eMail", identifier: "email", placeholder: user.email.lowercased(), type: "email"),
                        .init(description: "Date of birth", identifier: "birthday", placeholder: Elite.date.inputFormatter.string(from: user.birthday), type: "date", restrictions: "pattern=\"[0-3][0-9].[0-1][0-9].[0-9]{4}\"")
                    ])
                ]),
                .init(id: "ChangePassword", title: "Change Password", forms: [
                    .init(send: "changePassword", errorMessage: Elite.date.stillActiveError(req.session.data["changePasswordError"]) ? "Failure, please try again." : nil, input: [
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
    
    
    
    func postEditUser(req: Request) throws -> EventLoopFuture<Response> {
        if let user = req.auth.get(User.self) {
            let userform = try req.content.decode(User.DTO.self)
            user.firstname = userform.firstname == "" ? user.firstname : userform.firstname.validate()
            user.lastname = userform.lastname == "" ? user.lastname : userform.lastname.validate()
            user.birthday = userform.birthday == "" ? user.birthday : Elite.date.inputFormatter.date(from: userform.birthday) ?? Date()
            user.sex = (userform.sex as NSString).floatValue
            
            if userform.username != "" || userform.email != "" {
                return User.query(on: req.db).group(.or) {
                    if userform.username != "" {$0.filter(\.$username == userform.username.validate())}
                    if userform.email != "" {
                        $0.filter(\.$email == userform.email.lowercased().validate())
                        $0.filter(\.$email == userform.email.uppercased().validate())
                    }
                }.all().flatMap { users -> EventLoopFuture<Response> in
                    if userform.username != "" && users.filter({$0.username == userform.username.validate()}).first == nil {
                        user.username = userform.username.validate()
                    }
                    if userform.email != "" && users.filter({$0.email == userform.email}).first == nil {
                        user.email = userform.email.uppercased().validate()
                        MailController.sendVerificationLink(req: req, user: user)
                    }
                    return user.update(on: req.db).map {
                        req.redirect(to: "edit")
                    }
                }
            } else {
                return user.update(on: req.db).map {
                    req.redirect(to: "edit")
                }
            }
        } else {
            req.session.data["changePasswordError"] = nil
            return req.eventLoop.makeSucceededFuture(req.redirect(to: "edit"))
        }
    }
    
    
    
    func postChangePassword(req: Request) throws -> EventLoopFuture<Response> {
        let passwordform = try req.content.decode(User.passwordDTO.self)
        if let user = req.auth.get(User.self), try Bcrypt.verify(passwordform.oldPassword, created: user.passwordHash) && passwordform.password == passwordform.repassword {
            user.passwordHash = try Bcrypt.hash(passwordform.password)
            req.session.data["changePasswordError"] = nil
            return user.update(on: req.db).map {
                req.redirect(to: "edit")
            }
        } else {
            req.session.data["changePasswordError"] = Elite.date.setErrorDate()
            return req.eventLoop.makeSucceededFuture(req.redirect(to: "edit"))
        }
    }

    
    
    func everybody(req: Request) throws -> EventLoopFuture<View> {
        if req.auth.get(User.self) != nil {
            let viewData = mainViewData(title: "Everybody", content: [], for: req)
            return User.query(on: req.db).all().flatMap {
                for user in $0 {
                    viewData.content.append(.init(id: user.id!.uuidString, title: user.username, text: [user.firstname+" "+user.lastname, user.email], links: [.init(href: "/"+user.username, description: "View more", classID: "normal")]))
                }
                return  req.view.render(Elite.view.mainPath, viewData)
            }
        } else {
            req.session.data["backToPath"] = "everybody"
            return try getLogin(req: req)
        }
    }
    
    
    
    func deleteAllUsers(req: Request) throws -> EventLoopFuture<Response> {
        return User.query(on: req.db).delete().map {
            return req.redirect(to: "/")
        }
    }
}
