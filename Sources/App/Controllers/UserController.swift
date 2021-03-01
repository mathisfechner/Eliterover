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
        let authProtectedRoutes = routes.grouped(AuthMiddlware())
        authProtectedRoutes.get(":username", use: getUser)
        authProtectedRoutes.get("profile", use: profile)
        authProtectedRoutes.get("image", ":username", use: getProfilPic)
        routes.get("registrate", use: getRegistrate)
        routes.post("registrate", use: postRegistrate)
        routes.get("login", use: getLogin)
        routes.post("login", use: postLogin)
        routes.get("logout", use: logout)
        authProtectedRoutes.on(.POST, "adduserinformation", body: .collect(maxSize: 5000000), use: addUserInformation)
        authProtectedRoutes.on(.POST, "characteristics", body: .collect(maxSize: "10mb"), use: postCharacteristics)
        authProtectedRoutes.get("edit", use: getEdit)
        authProtectedRoutes.post("editUser", use: postEditUser)
        authProtectedRoutes.post("changePassword", use: postChangePassword)
        authProtectedRoutes.get("everybody", use: everybody)
        authProtectedRoutes.get("deleteAllUsers", use: deleteAllUsers)
    }
    
    func getUser(req: Request) throws -> EventLoopFuture<View> {
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
    
    
    
    func profile(req: Request) throws -> EventLoopFuture<View> {
        let user = try req.auth.require(User.self)
        let data = mainViewData(title: "Eliterover", content: [
            .init(id: user.username, title: "Profil", text: ["Du bist angemeldet als: "+user.username, "Schön, dich wiederzusehen!"], links: [.init(href: "/edit", description: "Daten bearbeiten", classID: "normal")]),
        ], for: req)
        if(user.characteristics == nil) {data.content.append(try characteristicsForm(req: req))}
        return req.view.render(Elite.view.mainPath, data)
    }
    
    
    
    func getRegistrate(req: Request) throws -> EventLoopFuture<View> {
        let input = mainViewData( title: "Registration", content: [
            .init(id: "registration", title: "Registration", forms: [
                .init(send: "registrate",
                      errorMessage: Elite.date.stillActiveError(req.session.data["registrationError"]) ? "Try again, username or eMail may already be taken." : nil,
                      input: [
                    .init(description: "First name", identifier: "firstname", placeholder: "Max", type: "text", restrictions: "required"),
                    .init(description: "Last name", identifier: "lastname", placeholder: "Mustermann", type: "text", restrictions: "required"),
                    .init(description: "Sex | M - W", identifier: "sex", placeholder: "", type: "range", restrictions: "min=\"0\" max=\"1\" step=\"0.01\" required"),
                    .init(description: "Username", identifier: "username", placeholder: "Enter Username", type: "text", restrictions: "required"),
                    .init(description: "Password", identifier: "password", placeholder: "Enter Password", type: "password", restrictions: "required"),
                    .init(description: "Retype password", identifier: "repassword", placeholder: "Retype Password", type: "password", restrictions: "required"),
                    .init(description: "eMail", identifier: "email", placeholder: "max.mustermann@elite.rover", type: "email", restrictions: "required"),
                    .init(description: "Date of birth", identifier: "birthday", placeholder: "DD.MM.YYYY", type: "date", restrictions: "pattern=\"[0-3][0-9].[0-1][0-9].[0-9]{4}\" required")
                ])
            ], links: [
                .init(href: "/login", description: "i have an account already", classID: "little")
            ])
        ], for: req)
        return req.view.render(Elite.view.mainPath, input)
    }
    
    
    
    func postRegistrate(req: Request) throws ->
    EventLoopFuture<Response> {
        try req.csrf.verifyToken()
        let userform = try req.content.decode(User.DTO.self)
        if (userform.firstname == "" || userform.birthday == "" || userform.email == "" || userform.lastname == "" || userform.password == "" || userform.username == ""  || userform.repassword == "" || userform.sex == ""){
        }
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
                        req.session.data["backToPath"] = nil
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
        try req.csrf.verifyToken()
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
        struct ImageDTO: Content {
            var imageData: File
        }
        
        try req.csrf.verifyToken()
        let image = try req.content.decode(ImageDTO.self)
        let user = req.auth.get(User.self)
        if let filetype = image.imageData.contentType?.subType {
            return req.fileio.writeFile(image.imageData.data, at: "profilepicture/\(user!.id!.uuidString).\(filetype)").map() {
                req.fileio.streamFile(at: "profilepicture/\(user!.id!.uuidString).\(filetype)")
            }
        }
        return req.eventLoop.makeSucceededFuture(req.redirect(to: "/"))
    }
    
    func characteristicsForm(req: Request) throws -> contentViewData {
        contentViewData(id: "Characteristics", title: "Characteristics", text: ["Wir wissen gar nichts über dich.", "Beschreib dich bitte mal kurz."], forms: [
            .init(send: "characteristics", input: [
                .init(identifier: "imageData", placeholder: "Profilbild", type: "file", restrictions: "required"),
                .init(description: "Beschreibung", identifier: "description", placeholder: "Erzähl mal was über dich", type: "text"),
                .init(description: "Größe", identifier: "height", placeholder: "180", type: "number", restrictions: "required min='135' max='235'"),
                .init(description: "Region", identifier: "region", placeholder: "Nord", type: "text", restrictions: "required"),
                .init(description: "Lebenssituation", identifier: "lifeSituation", placeholder: "Was machst du so?", type: "text", restrictions: "required"),
                .init(description: "Amt im Stamm", identifier: "positions", placeholder: "Stammesführer", type: "text"),
                .init(description: "Dialekt", identifier: "dialect", placeholder: "Sächsisch", type: "text"),
                .init(description: "Hajk Enthusiasmus", identifier: "hajkEnthusiasm", placeholder: "50", type: "range", restrictions: "min=\"0\" max=\"1\" step=\"0.01\" required"),
                .init(description: "Sarkasmus", identifier: "sarcasm", placeholder: "50", type: "range", restrictions: "min=\"0\" max=\"1\" step=\"0.01\" required"),
                .init(description: "Level Christ", identifier: "christianLevel", placeholder: "50", type: "range", restrictions: "min=\"0\" max=\"1\" step=\"0.01\" required"),
                .init(description: "Musikalität", identifier: "musicality", placeholder: "50", type: "range", restrictions: "min=\"0\" max=\"1\" step=\"0.01\" required"),
                .init(description: "Kochskills", identifier: "cookingSkills", placeholder: "50", type: "range", restrictions: "min=\"0\" max=\"1\" step=\"0.01\" required")
            ])
        ])
    }
    
    func postCharacteristics(req: Request) throws -> EventLoopFuture<Response> {
        _ = try? postProfileImage(req: req)
        let characteristics = try req.content.decode(Characteristics.self)
        let user = try req.auth.require(User.self)
        user.characteristics = characteristics
        return user.update(on: req.db).map() {
            req.redirect(to: "/")
        }
    }
    
    func postProfileImage(req: Request) throws -> EventLoopFuture<Response> {
        let image = ProfilePic(DTO: try req.content.decode(ProfilePic.DTO.self), user: try req.auth.require(User.self))
        if let profilePic = image {
            return profilePic.$user.get(on: req.db).flatMap() {
                return $0.$profilePic.get(on: req.db).flatMap() {
                    if let previous = $0.first {
                        return previous.delete(on: req.db).flatMap() {
                            profilePic.create(on: req.db).map() {
                                req.redirect(to: "/")
                            }
                        }
                    } else {
                        return profilePic.create(on: req.db).map() {
                            req.redirect(to: "/")
                        }
                    }
                }
            }
        }
        return req.eventLoop.makeSucceededFuture(req.redirect(to: "/"))
    }
    
    func getProfilPic(req: Request) throws -> EventLoopFuture<Response> {
        print("am i getting here?")
        return User.query(on: req.db)
            .filter(\.$username == (req.parameters.get("username") ?? "Not Found"))
            .first()
            .flatMap() {
                $0?.$profilePic.get(on: req.db).map() {
                    if let image = $0.first {
                        let response = Response(status: .ok, headers: [:])
                        if let type = HTTPMediaType.fileExtension(image.imageType) {
                            response.headers.contentType = type
                        }
                        response.body = .init(data: image.imageData)
                        return response
                    } else {
                        return (req.fileio.streamFile(at: "Public/eliteProfilbild.png"))
                    }
                } ?? req.eventLoop.makeSucceededFuture(req.fileio.streamFile(at: "Public/eliteProfilbild.png"))
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
        let user = try req.auth.require(User.self)
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
    }
    
    
    
    func postEditUser(req: Request) throws -> EventLoopFuture<Response> {
        try req.csrf.verifyToken()
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
        try req.csrf.verifyToken()
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
        let viewData = mainViewData(title: "Everybody", content: [], for: req)
        return User.query(on: req.db).all().flatMap {
            for user in $0 {
                viewData.content.append(.init(id: user.id!.uuidString, profile: .init(firstname: user.firstname, lastname: user.lastname, username: user.username, sex: Int(user.sex*100)), links: [.init(href: "/"+user.username, description: "View more", classID: "normal")]))
            }
            return  req.view.render(Elite.view.mainPath, viewData)
        }
    }
    
    
    
    func deleteAllUsers(req: Request) throws -> EventLoopFuture<Response> {
        return User.query(on: req.db).delete().map {
            return req.redirect(to: "/")
        }
    }
}
